# SystemConfig (SYS) — Complete Analysis Pack
**Version:** 1.0 | **Date:** 2026-06-30 | **Author:** Business Analyst Agent
**FRD Reference:** `SYS_FRD_2026-06-30.md` (all REQ-/BR-/RPT-/ENH- IDs originate there)
**Module:** SystemConfig | **Code:** SYS | **Type:** Central | **DB:** prime_db + global_db

> All artifact sections below share the IDs defined in the FRD. No parallel numbering is introduced here.

---

## Index

| Section | Artifact |
|---------|---------|
| 1 | FRD Summary |
| 2 | Requirements Traceability Matrix (RTM) |
| 3 | Business Rules Register + Requirement Conditions Catalog + Validation & Edge-Case Catalog |
| 4 | Process Flows + FSM Catalog |
| 5 | Data Dictionary + Cross-Module Dependency Map |
| 6 | NFR Catalog + Risk Register |
| 7 | Prioritization (MoSCoW) + Effort Estimation & Sprint Task Breakdown |
| 8 | User Stories + Reporting & KPI Spec |

---

## Section 1 — FRD Summary

| Attribute | Value |
|-----------|-------|
| FRD File | `SYS_FRD_2026-06-30.md` |
| FRD Date | 2026-06-30 |
| Module Type | Central — central domain only; prime_db + global_db |
| Controllers (verified) | 11 |
| Models (verified) | 8 |
| Services | 2 (BackupService, BackupScheduleService) |
| Total REQs | 10 (4 P0, 4 P1, 2 P2) |
| Total BRs | 20 |
| Total RPTs | 2 |
| Total ENHs | 5 |
| Overall Estimated Completion | 65–70% (post June 2026 additions) |
| P0 Security Gaps Open | 5 (SEC-SYS-01 through SEC-SYS-05 in module knowledge) |

---

## Section 2 — Requirements Traceability Matrix (RTM)

| REQ-ID | Feature | BR Refs | Screen(s) | Workflow(s) | Report(s) | Code Status | Key Gap |
|--------|---------|---------|-----------|-------------|-----------|-------------|---------|
| REQ-SYS-001 | Platform Settings Management | BR-SYS-001, 005, 006, 012, 013 | Settings list, Settings edit | WF-1 (Setting Update) | — | PARTIAL (65%) | SystemConfigController has zero auth on all 7 methods; SettingController validates wrong table; store() returns raw $request; duplicate Setting model |
| REQ-SYS-002 | Navigation Menu Management | BR-SYS-002, 003, 004, 012 | Menu tree, Menu create, Menu edit, Trashed menus | — | — | PARTIAL (60%) | create(), destroy(), restore(), toggleStatus() are empty stubs; $request->all() mass-assign bug in update(); trashedMenu() wrong view notation |
| REQ-SYS-003 | Menu Translation Management | BR-SYS-017, 012 | Menu edit (translation sub-section) | — | — | PARTIAL (30%) | Translation create logic commented out in store(); hardcoded language ID=2; no standalone translation UI |
| REQ-SYS-004 | Dropdown Needs Registry | BR-SYS-014, 015, 012 | Dropdown needs list, Dropdown need create | — | — | PARTIAL (75%) | TenantDropdownNeedController + views exist post-V2; auth coverage unknown; no feature tests |
| REQ-SYS-005 | Dropdown Value Management | BR-SYS-007, 008, 009, 016, 019, 012 | Dropdown values list, Value create (2 paths), Value edit | WF-3 (Value Creation) | — | PARTIAL (75%) | TenantDropdownController + views exist post-V2; auth coverage unknown; ordinal/reference-check enforcement unknown |
| REQ-SYS-006 | Activity Log Viewer | BR-SYS-006, 012 | Activity log list | — | RPT-SYS-001 | PARTIAL (70%) | TenantActivityLogController + view exist; no filtering; no date range; no expandable detail panel confirmed |
| REQ-SYS-007 | Menu Synchronisation | BR-SYS-011, 012 | Sync trigger (button + confirmation) | WF-2 (Menu Sync) | — | PARTIAL (70%) | Auth check COMMENTED OUT — any authenticated user can trigger destructive truncate; 1,702-line controller violates SRP |
| REQ-SYS-008 | Platform Backup Management | BR-SYS-020, 012 | Backup create, Backup history, Schedule list, Schedule create/edit | WF-4 (Backup) | RPT-SYS-002 | PARTIAL (85%) | BackupController + BackupScheduleController + services + job + notifications implemented; auth coverage on backup routes unknown |
| REQ-SYS-009 | Location Reference Data Management | — | Country/State/City/District create+edit | — | — | PARTIAL (70%) [inferred] | TenantLocationController + 8 views exist; auth unknown; overlap with GlobalMaster module to be confirmed |
| REQ-SYS-010 | Media Asset Viewer | — | Media store list | — | — | PARTIAL (60%) [inferred] | TenantMediaStoreController + index view exist; auth unknown |

---

## Section 3 — Business Rules Register + Requirement Conditions Catalog + Validation & Edge-Case Catalog

### 3.1 Business Rules Register (standalone; IDs from FRD §4)

| BR-ID | Rule | Type | Trigger | Enforcement Point | Priority |
|-------|------|------|---------|-------------------|---------|
| BR-SYS-001 | Setting key is permanent — edit endpoint must strip it even if submitted | Validation | Setting update | Edit form (read-only) + update endpoint | P0 |
| BR-SYS-002 | Menu system identifier (code) is permanent — update endpoint must strip it | Validation | Menu update | Edit form (read-only) + update endpoint | P0 |
| BR-SYS-003 | Category heading menu item must have no parent; rejected at create, edit, and reorder | Validation | Menu create / edit / reorder | Form validation + reorder endpoint (HTTP 422) | P0 |
| BR-SYS-004 | On drag-drop reorder, all siblings at the same level are renumbered sequentially from 1 | Calculation | Menu reorder | Reorder endpoint post-save sibling loop | P1 |
| BR-SYS-005 | Settings with `is_public = false` are masked (bullets) in all list views and excluded from API responses | Permission | Settings list / API | Settings index view + every response serialiser | P0 |
| BR-SYS-006 | Keys containing "password", "api_key", "secret", "token" → value excluded from audit log; edit form uses password input type | Permission | Settings update | activityLog() helper | P0 |
| BR-SYS-007 | No Dropdown Value can be created without a matching Dropdown Need registered for that table-column pair | Validation | Dropdown value create | Value create endpoint — pre-check | P0 |
| BR-SYS-008 | Group key is always derived server-side as `tablename.columnname`; never accepted from request body | Validation | Dropdown value create / edit | Endpoint — derive from Need record, ignore input | P0 |
| BR-SYS-009 | Ordinal auto-assigned as MAX+1 within key group on create; must be unique within key group | Calculation / Validation | Dropdown value create / edit | Create: MAX+1 query; Edit: unique constraint check | P1 |
| BR-SYS-010 | Single Super Admin enforced by DB generated column + UNIQUE KEY + 2 DB triggers; cannot be bypassed | Validation / Concurrency | Super Admin management | Database layer | P0 |
| BR-SYS-011 | Menu Sync is Super Admin only; permission check must never be commented out | Permission | Sync trigger | Sync endpoint — explicit Gate::authorize before any logic | P0 |
| BR-SYS-012 | Every mutation on settings, menus, dropdown needs, values must produce an audit log entry with entity type, entity ID, user, event, IP, before+after JSON | Workflow | All mutation endpoints | activityLog() helper at every controller write method | P0 |
| BR-SYS-013 | Authoritative Setting model is Modules\SystemConfig\Models\Setting; duplicate in Prime module must be deleted | Workflow | Deployment | Code — delete duplicate; update imports | P0 |
| BR-SYS-014 | Dropdown Need combination of (database tier, table, column) must be unique in the registry | Validation | Need create | Create endpoint + DB UNIQUE constraint | P0 |
| BR-SYS-015 | System-protected Dropdown Needs cannot be edited or deleted; returns descriptive error | Permission | Need edit / delete | Edit/delete endpoint — check is_system flag | P1 |
| BR-SYS-016 | Dropdown Value deletion blocked if school data references it; deactivation always permitted | Validation | Value delete | Delete endpoint — reference check before delete | P1 |
| BR-SYS-017 | Translation create/update uses upsert (updateOrCreate) per menu item + language; no duplicates | Validation | Translation create / update | Endpoint (updateOrCreate pattern) | P1 |
| BR-SYS-018 | All SYS routes accessible only from central domain; RSP must use `['web', 'auth', 'verified']` only (per TEN-D-002) | Permission | Every HTTP request | RSP middleware configuration | P0 |
| BR-SYS-019 | School-admin path: group key is read-only (auto-derived); school admin cannot create Dropdown Needs | Permission | School-path dropdown create | School-path form — key field read-only; Need creation hidden | P1 |
| BR-SYS-020 | Backup runs are queued background jobs; Super Admin is not blocked; completion and failure each trigger a notification | Workflow | Backup create | BackupController::store() → dispatch RunBackupJob | P1 |

### 3.2 Requirement Conditions Catalog

> Also saved to: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/5-Requirement_Conditions/SYS_Conditions.md`

| Condition ID | Entity / Field | Condition (Business) | Type | Trigger | On-Violation Behaviour |
|--------------|---------------|---------------------|------|---------|----------------------|
| BR-SYS-001 | Platform Setting / Key | Key must not change after the setting is first saved | Validation | Setting update | Strip key from update payload; never return validation error — silently ignore |
| BR-SYS-002 | Menu Item / System Identifier | System identifier must not change after the menu item is first saved | Validation | Menu update | Strip code from update payload |
| BR-SYS-003 | Menu Item / Parent | A category heading item must have no parent | Validation | Menu create / edit / reorder | Return HTTP 422 with: "Category headings cannot have a parent item." |
| BR-SYS-003b | Menu Item / Category + Parent | A non-category item with `is_category = false` can have a parent | Validation | Menu create / edit | Allow; parent must exist in `glb_menus` |
| BR-SYS-004 | Menu Item / Sort Position | After reorder, all siblings at the moved item's level have sequential sort positions starting from 1 | Calculation | Menu reorder (drag-drop) | Post-save sibling loop; no user-visible error |
| BR-SYS-005 | Platform Setting / Value | If `is_public = false`, the value is shown as "••••••••" in every list view | Permission | Settings list render | Mask value in view; never expose in API unless caller is authenticated platform admin |
| BR-SYS-006a | Platform Setting / Value | If key contains "password", "api_key", "secret", or "token", the raw value is excluded from activity log entries | Permission | Setting update | Log "value updated (hidden for security)" instead of actual value |
| BR-SYS-006b | Platform Setting / Edit Form | If key contains "password", "api_key", "secret", or "token", the edit input renders as `type="password"` | Usability | Setting edit form render | Render password input type |
| BR-SYS-007 | Dropdown Value / Dropdown Need | A matching Dropdown Need must exist for the selected table-column before a value can be created | Validation | Dropdown value create | Error: "No dropdown requirement is configured for this field." |
| BR-SYS-008 | Dropdown Value / Group Key | Group key is always derived from the Dropdown Need (`tablename.columnname`); it cannot be supplied in the request | Validation | Dropdown value create / edit | Derive server-side; ignore any submitted `key` field |
| BR-SYS-009a | Dropdown Value / Display Order | On create, display order is auto-assigned as MAX(ordinal within key group) + 1 | Calculation | Dropdown value create | Auto-assign; no user input required or accepted |
| BR-SYS-009b | Dropdown Value / Display Order | Display order must be unique within the same group key | Validation | Dropdown value edit (ordinal change) | Reject with: "This display order is already in use within this pick-list group." |
| BR-SYS-009c | Dropdown Value / Display Text | Display text must be unique within the same group key | Validation | Dropdown value create / edit | Reject with: "This value already exists in this pick-list group." |
| BR-SYS-010 | Platform User / Super Admin | Only one Super Admin may exist; the second Super Admin cannot be created; the existing one cannot be demoted or deleted | Concurrency / Validation | User management | Database trigger: INSERT of second super-admin fails; UPDATE demoting is_super_admin to 0 fails; DELETE fails |
| BR-SYS-011 | Menu Sync / Permission | Only a Super Admin may trigger the sync | Permission | Sync trigger | Return 403 for any other actor |
| BR-SYS-012 | All Mutations / Audit | Every create/update/delete/restore/toggle/reorder on settings, menus, needs, values must be logged | Workflow | All mutation endpoints | If audit log write fails, the mutation itself should not be rolled back; log the logging failure separately |
| BR-SYS-013 | Setting Model / Canonical Source | Only `Modules\SystemConfig\Models\Setting` may reference `sys_settings` | Workflow | Code review / deployment | Remove `Modules\Prime\Models\Setting`; update all imports |
| BR-SYS-014 | Dropdown Need / (Tier, Table, Column) | Combination must be unique across the registry | Validation | Need create | Reject with: "A dropdown requirement for this table and column already exists." |
| BR-SYS-015 | Dropdown Need / is_system | If `is_system = true`, the record cannot be edited or deleted | Permission | Need edit / delete | Reject with: "This dropdown requirement is system-protected and cannot be changed." |
| BR-SYS-016 | Dropdown Value / Deletion | If the value is referenced by active school data, permanent deletion is blocked | Validation | Value delete | Show: "This value is referenced by {N} school record(s). Deactivate it instead of deleting." |
| BR-SYS-017 | Menu Translation / (Menu + Language) | Only one translation record per menu item + language combination | Validation | Translation create / update | Use updateOrCreate; never INSERT if record exists |
| BR-SYS-018 | SYS Routes / Middleware | RSP must use `['web', 'auth', 'verified']`; never include tenant middleware stack | Validation | RSP configuration | If tenant middleware is present, central domain returns 403 from `PreventAccessFromCentralDomains` |
| BR-SYS-019 | School-Path Create / Need | School admin may not create Dropdown Needs; may only add values where `tenant_creation_allowed = true` | Permission | School-path form | Hide "Create New Need" button; filter Need selector to `tenant_creation_allowed = 1` |
| BR-SYS-020 | Backup Run / Execution | Backup must be queued asynchronously; not executed synchronously in the HTTP request | Workflow | Backup create | Dispatch RunBackupJob; do not block HTTP response on completion |

### 3.3 Validation & Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty / Null | Concurrency Case | Expected Behaviour |
|---|---|---|---|---|---|---|
| Setting Key | `smtp_host` | `smtp host` (space) | 100 chars exactly | Empty → reject | Two admins create same key simultaneously | First succeeds; second gets unique-key violation |
| Setting Value (boolean) | `true` / `false` / `1` / `0` | `yes` / `no` (not castable) | — | Empty → reject (required) | — | Type validation fails for non-boolean string |
| Setting Value (JSON) | `{"key":"value"}` | `{invalid json` | — | Null → valid if type allows | — | JSON parse must succeed before save |
| Menu Code | `school_setup_class` | `school setup class` (spaces) | 60 chars | Empty → reject | Two managers create same code | Second gets UNIQUE constraint violation |
| Menu Sort Position | `5` | `-1` / `256` | `0` and `255` | 0 is valid (first position) | Two managers reorder simultaneously | Last write wins; sibling renumber runs after each save |
| Menu Category + Parent | Category item, parent=null | Category item, parent=3 | — | parent_id null is valid for categories and top-level non-categories | — | 422 if category heading has non-null parent |
| Dropdown Need (table, column) | `std_students`, `blood_group_id` | Duplicate of existing row | Max 150 chars each | Either empty → reject | Two admins create same need simultaneously | Second gets UNIQUE constraint violation |
| Dropdown Value Display Text | `A+` (12 chars) | `` (empty) or duplicate within key group | Max 100 chars | Empty → reject (required) | Two admins create same value in same key simultaneously | Second gets duplicate-text validation error |
| Dropdown Value Ordinal (create) | Auto-assigned | Manual submission ignored | MAX int within key group | — | Two admins create values in same key simultaneously | Both get MAX+1 from their respective SELECTs; DB UNIQUE constraint catches the collision on the second INSERT |
| Dropdown Value Delete | Value with no school references | Value referenced by 500 student records | — | — | Two admins simultaneously try to delete and use a value | Delete blocked; reference count shown |
| Backup Run (dispatch) | Valid connection list | Empty connection list | — | Empty list → reject | Two admins trigger backup simultaneously | Both queue independently; each gets its own Backup Run record |
| Translation (menu + language) | Menu 5, Language 2, title "परीक्षा" | Duplicate (menu 5, language 2 already has a record) | — | title empty → reject | Two managers update same translation simultaneously | updateOrCreate: last write wins |
| Menu Sync (permission) | Super Admin role | Platform Manager role | — | No auth → 401 | Two Super Admins trigger sync simultaneously | Both proceed independently; last write wins on each menu code |

---

## Section 4 — Process Flows + FSM Catalog

### 4.1 Process Flows
*(Full process flows are documented in FRD §6 — Workflows 1 through 4. This section adds the FSM catalog.)*

### 4.2 FSM Catalog

**Entity: Navigation Menu Item Status**

| From State | Event / Action | Guard | To State | Side-Effects |
|-----------|---------------|-------|----------|-------------|
| Active | Toggle status | Platform Manager or Super Admin + permission | Inactive | Audit log entry (event: Toggled); menu item no longer rendered in school sidebars |
| Inactive | Toggle status | Platform Manager or Super Admin + permission | Active | Audit log entry (event: Toggled); menu item appears in school sidebars again |
| Active | Soft delete | Super Admin / Platform Manager + no active children | Soft-Deleted | Audit log entry (event: Deleted); item removed from active listing |
| Inactive | Soft delete | Super Admin / Platform Manager + no active children | Soft-Deleted | Audit log entry (event: Deleted) |
| Soft-Deleted | Restore | Super Admin / Platform Manager | Active | Audit log entry (event: Restored); item returns to active listing |
| Soft-Deleted | Force delete | Super Admin only | (Removed) | Permanent removal from database; audit log entry (event: Force Deleted) |

Illegal transitions: Active → Force Delete (must soft-delete first); Force Delete → any (irreversible); Soft-Deleted with active children (children must be handled first).

Master driving this FSM: `is_active` (boolean on `glb_menus`) + `deleted_at` (SoftDeletes).

---

**Entity: Backup Run Status**

| From State | Event / Action | Guard | To State | Side-Effects |
|-----------|---------------|-------|----------|-------------|
| (none) | Super Admin submits backup form | BackupController::store() | Queued | BackupRun record created; RunBackupJob dispatched to queue |
| Queued | Queue worker picks up job | RunBackupJob::handle() | Running | BackupRun status updated to Running |
| Running | Job completes successfully | RunBackupJob | Completed | File stored; file_size_bytes, completed_at set; BackupSuccessNotification sent to Super Admin |
| Running | Job throws exception | RunBackupJob | Failed | Error detail stored; completed_at set; BackupFailedNotification sent to Super Admin |
| Completed | Super Admin deletes run | BackupController::destroy() | (Removed) | File deleted from disk; BackupRun record deleted |
| Failed | Super Admin deletes run | BackupController::destroy() | (Removed) | BackupRun record deleted; no file to clean up |

Terminal states: Completed (with download available), Failed, Removed.
Illegal transitions: Queued → Completed (must pass through Running); Completed → Queued (re-run creates a new BackupRun record, not a state transition on the existing one).

---

**Entity: Platform Setting Lifecycle**

| From State | Event / Action | Guard | To State | Side-Effects |
|-----------|---------------|-------|----------|-------------|
| (none) | Seeder / Super Admin create | Super Admin permission | Active | Audit log (event: Created) |
| Active | Super Admin updates value | Super Admin permission | Active | Audit log (event: Updated) with before/after |
| Active | Super Admin deletes | Super Admin permission | (Removed) | Audit log (event: Deleted); platform behaviour reverts to application default |

Note: `sys_settings` has no `deleted_at` column in the current DDL — deletion would be a hard delete. This is a known DDL gap (DDL-SYS-20). Until resolved, deletion should not be implemented in the application layer.

---

## Section 5 — Data Dictionary + Cross-Module Dependency Map

### 5.1 Data Dictionary

#### Platform Setting (sys_settings — prime_db)

| Business Field | Table.Column | Type | Required | FK / Cast | PII? |
|----------------|-------------|------|----------|-----------|------|
| Setting Key | sys_settings.key | VARCHAR(100) | Yes | UNIQUE; mutator: auto snake_case | No |
| Value | sys_settings.value | TEXT | Yes | — | Confidential if sensitive |
| Data Type | sys_settings.type | ENUM (string/int/boolean/json/date) | Yes | — | No |
| Description | sys_settings.description | VARCHAR(255) | No | — | No |
| Publicly Visible | sys_settings.is_public | TINYINT(1) | Yes | Default 0 | No |

Missing: `created_by`, `deleted_at`, `created_at`, `updated_at` — DDL gaps (DDL-SYS-20, DDL-SYS-25).

#### Navigation Menu Item (glb_menus — global_db)

| Business Field | Table.Column | Type | Required | FK / Cast | PII? |
|----------------|-------------|------|----------|-----------|------|
| System Identifier | glb_menus.code | VARCHAR(60) | Yes | UNIQUE | No |
| Title | glb_menus.title | VARCHAR(100) | Yes | UNIQUE | No |
| Description | glb_menus.description | VARCHAR(255) | No | — | No |
| Icon | glb_menus.icon | VARCHAR(150) | Yes | — | No |
| Route | glb_menus.route | VARCHAR(255) | Conditional | ValidCombinedRoute rule | No |
| Parent Item | glb_menus.parent_id | BIGINT UNSIGNED | No | FK → glb_menus.id (self-ref) | No |
| Category Heading | glb_menus.is_category | TINYINT(1) | Yes | Default 0 | No |
| Direct Link | glb_menus.is_direct_link | TINYINT(1) | Yes | Default 0 | No |
| Sort Position | glb_menus.sort_order | TINYINT UNSIGNED | Yes | 0–255 | No |
| Visible by Default | glb_menus.visible_by_default | TINYINT(1) | Yes | Default 1 | No |
| Status | glb_menus.is_active | TINYINT(1) | Yes | Default 1 | No |
| Target Scope | glb_menus.menu_for | VARCHAR(20) | Yes | 'tenant'/'prime' | No |
| Soft Delete Marker | glb_menus.deleted_at | TIMESTAMP | No | SoftDeletes | No |

#### Dropdown Need (sys_dropdown_needs — prime_db)

| Business Field | Table.Column | Type | Required | FK / Cast | PII? |
|----------------|-------------|------|----------|-----------|------|
| Database Tier | sys_dropdown_needs.db_type | VARCHAR(20) | Yes | 'Prime'/'Tenant'/'Global' | No |
| Table Name | sys_dropdown_needs.table_name | VARCHAR(150) | Yes | UNIQUE with column_name | No |
| Column Name | sys_dropdown_needs.column_name | VARCHAR(150) | Yes | UNIQUE with table_name | No |
| Menu Category | sys_dropdown_needs.menu_category | VARCHAR(150) | Conditional | | No |
| Main Menu | sys_dropdown_needs.main_menu | VARCHAR(150) | Conditional | | No |
| Sub Menu | sys_dropdown_needs.sub_menu | VARCHAR(150) | Conditional | | No |
| Tab Name | sys_dropdown_needs.tab_name | VARCHAR(100) | No | | No |
| Field Label | sys_dropdown_needs.field_name | VARCHAR(100) | Conditional | | No |
| System Protected | sys_dropdown_needs.is_system | TINYINT(1) | Yes | Default 1; note: DDL comment is misleading (DDL-SYS-21) — is_system=1 means platform-owned, NOT tenant-creatable | No |
| School Editable | sys_dropdown_needs.tenant_creation_allowed | TINYINT(1) | Yes | Default 0 | No |
| Mandatory | sys_dropdown_needs.compulsory | TINYINT(1) | Yes | Default 1 | No |
| Has Values | sys_dropdown_needs.dropdown_tabel_record_exist | TINYINT(1) | Auto | Note: typo in column name ("tabel") | No |

#### Dropdown Value (sys_dropdowns — prime_db)

| Business Field | Table.Column | Type | Required | FK / Cast | PII? |
|----------------|-------------|------|----------|-----------|------|
| Display Order | sys_dropdowns.ordinal | INT UNSIGNED | Auto | UNIQUE with key | No |
| Group Key | sys_dropdowns.key | VARCHAR(100) | Auto | UNIQUE with value; UNIQUE with ordinal | No |
| Display Text | sys_dropdowns.value | VARCHAR(100) | Yes | UNIQUE with key | No |
| Data Type | sys_dropdowns.type | ENUM(String/Integer/Decimal/Date/Datetime/Time/Boolean) | Yes | Note: D29 says avoid ENUM — this is a known DDL issue; app should treat as fixed set | No |
| Extra Information | sys_dropdowns.additional_info | JSON | No | | No |
| Status | sys_dropdowns.is_active | TINYINT(1) | Yes | Default 1 | No |

Missing: `deleted_at`, `created_by`, `created_at`, `updated_at` — DDL gaps (DDL-SYS-20, DDL-SYS-25).

#### Activity Log Entry (sys_activity_logs — prime_db)

| Business Field | Table.Column | Type | Required | FK / Cast | PII? |
|----------------|-------------|------|----------|-----------|------|
| Entity Type | sys_activity_logs.subject_type | VARCHAR | Yes | Polymorphic morph type | No |
| Entity Identifier | sys_activity_logs.subject_id | BIGINT UNSIGNED | Yes | Polymorphic morph id | No |
| Platform User | sys_activity_logs.user_id | BIGINT UNSIGNED | Yes | FK → sys_users.id ON DELETE CASCADE | No |
| Event | sys_activity_logs.event | VARCHAR | Yes | e.g. Created/Updated/Deleted | No |
| Change Detail | sys_activity_logs.properties | JSON | Conditional | Before/after; null for non-update events | No |
| IP Address | sys_activity_logs.ip_address | VARCHAR | Yes | IPv4/IPv6 | Confidential |
| Timestamp | sys_activity_logs.created_at | TIMESTAMP | Auto | Append-only | No |

#### Backup Run (sys_backup_runs — prime_db)

| Business Field | Table.Column | Type | Required | Notes |
|----------------|-------------|------|----------|-------|
| Status | sys_backup_runs.status | VARCHAR/ENUM | Auto | Queued/Running/Completed/Failed |
| File Size | sys_backup_runs.file_size_bytes | BIGINT UNSIGNED | Auto | Set on completion |
| File Location | sys_backup_runs.disk_path | VARCHAR | Auto | Confidential |
| Completed At | sys_backup_runs.completed_at | TIMESTAMP | Auto | |
| Initiated By | sys_backup_runs.created_by (inferred) | BIGINT UNSIGNED | Yes | FK → sys_users.id |

### 5.2 Cross-Module Dependency Map

#### SYS Consumes From

| Source Module | Source Entity | Why |
|---------------|---------------|-----|
| GlobalMaster (GLB) | Available Languages (`glb_languages`) | Language list for menu translation language selector (hardcoded ID=2 is the current broken workaround) |
| Auth / Spatie RBAC | `sys_roles`, `sys_permissions` | All SYS route permission checks resolve through Spatie roles/permissions |

#### SYS Provides To (Platform-Wide Impact)

| Consumer | Mechanism | What SYS Provides |
|----------|-----------|-------------------|
| All 40+ tenant modules | Read `sys_dropdowns` (in tenant DB, seeded from prime_db via DropdownsSeeder) | Every configurable dropdown field in every school form draws its options from SYS-managed dropdown values — the highest blast-radius dependency in the platform |
| All school applications | Read `glb_menus` on every page load | The entire sidebar navigation tree is rendered from SYS-managed menu records after MenuSync |
| Notification module (NTF) | Read `sys_settings` at runtime | SMTP host, port, username, password, encryption; SMS provider and API key |
| Auth system | Read `sys_settings` at runtime | Password minimum length, uppercase requirement, expiry days; OTP enabled, MFA required, OTP expiry minutes |
| All modules | Write `sys_activity_logs` via `activityLog()` helper | Platform-wide audit trail — SYS owns and defines the table; every module writes to it via the shared helper |
| SyllabusBooks (SLK) | Read `sys_media` | Book cover image storage (FK from books table to sys_media) |
| Prime (PRM) | Read `sys_settings` (via duplicate Setting model — must be resolved per BR-SYS-013) | Various platform configuration reads |

---

## Section 6 — NFR Catalog + Risk Register

### 6.1 NFR Catalog

| NFR-ID | Category | Requirement | Acceptance Threshold |
|--------|----------|-------------|---------------------|
| NFR-SYS-001 | Performance | Platform Settings list response time | < 200 ms at P95 |
| NFR-SYS-002 | Performance | Navigation Menu tree load time (up to 100 items) | < 500 ms at P95 |
| NFR-SYS-003 | Performance | Menu drag-drop reorder response (save + sibling renumber) | < 300 ms at P95 |
| NFR-SYS-004 | Performance | Menu Sync end-to-end time | < 30 s; execution time limit must be set |
| NFR-SYS-005 | Performance | Dropdown Values list (grouped, paginated, 20/page) | < 300 ms at P95 |
| NFR-SYS-006 | Performance | Activity Log list (50 rows, filtered) | < 500 ms at P95 |
| NFR-SYS-007 | Performance | Backup status poll endpoint (active runs only) | < 200 ms at P95 |
| NFR-SYS-008 | Security | Zero unauthorised access to any SYS route | 403 returned for every route when called without valid platform-admin authentication; verified by feature tests |
| NFR-SYS-009 | Security | Sensitive setting values never exposed in non-admin context | No test against the settings API or list view exposes unmasked value for `is_public = 0` settings |
| NFR-SYS-010 | Security | Menu Sync requires Super Admin role | Non-Super-Admin platform users receive 403; verified by feature test |
| NFR-SYS-011 | Security | All controller mutations use validated data only | Zero occurrences of `$request->all()` passed to Eloquent write methods in this module |
| NFR-SYS-012 | Security | CSRF protection on all write routes | All POST/PUT/PATCH/DELETE routes in the module's RSP are on the `web` middleware (includes CSRF) |
| NFR-SYS-013 | Security | Central-domain isolation | Zero SYS routes reachable from a school subdomain; confirmed by RSP middleware configuration |
| NFR-SYS-014 | Usability | Type-appropriate setting inputs | Every setting data type renders the correct input control (toggle, date picker, code editor, password field) |
| NFR-SYS-015 | Usability | Drag-and-drop menu reorder | Reorder interaction provides visual drag feedback; updates are reflected without full page reload |
| NFR-SYS-016 | Usability | Dropdown cascading selectors | Both DB-field and menu-navigation paths use progressive AJAX loading (each selector narrows the next) |
| NFR-SYS-017 | Availability | System-critical seeders | DropdownsSeeder + DropdownNeedsSeeder must be idempotent and included in the standard setup sequence — the entire platform's dropdown system depends on them |
| NFR-SYS-018 | Compliance | Audit log immutability | No UI or API path permits editing or deleting activity log entries |

### 6.2 Risk Register

| Risk-ID | Risk | Category | Likelihood | Impact | Mitigation | Owner | Early Warning |
|---------|------|----------|:---------:|:------:|-----------|-------|---------------|
| RISK-SYS-001 | All 7 SystemConfigController methods have zero auth — any authenticated user can view/mutate platform settings including SMTP passwords | Security | H | H | Add Gate::authorize() to all 7 methods before any feature work proceeds; add feature test SystemConfigAuthTest | Dev Lead | Any non-Super-Admin user accessing /system-config/* without 403 |
| RISK-SYS-002 | MenuSyncController auth is COMMENTED OUT — any authenticated user can trigger destructive menu truncate | Security | H | H | Uncomment and enforce Gate::authorize('system-config.menu.sync') immediately | Dev Lead | Unexpected menu structures appearing in schools after non-Super-Admin login |
| RISK-SYS-003 | DropdownsSeeder + DropdownNeedsSeeder failure cascades to every module's dropdown fields across the entire platform | Data Integrity | M | H | Idempotent seeders; run in CI; add smoke test that key dropdown needs exist post-seed | Platform Ops | Any school form reporting empty dropdown lists |
| RISK-SYS-004 | Duplicate Setting model (Prime vs SystemConfig) causes import ambiguity — wrong model used in other modules leads to queries against wrong connection | Architecture | M | M | Delete Prime's Setting model; audit all Prime module imports; add a Larastan rule to catch re-introduction | Dev Lead | `Class 'Modules\Prime\Models\Setting' not found` errors after deletion; or wrong connection errors |
| RISK-SYS-005 | SettingController::update() validates against non-existent table 'settings' — every setting update fails at validation | Broken Functionality | H | H | Create SettingRequest with correct table `sys_settings`; fix SettingController validation | Dev Lead | Every platform setting save attempt returning validation errors |
| RISK-SYS-006 | MenuSyncController is 1,702 lines — violates SRP; hard to test, high defect risk during future changes | Code Quality | M | M | Extract into MenuSyncService; controller becomes thin HTTP adapter (< 50 lines) | Dev Lead | Any change to sync logic causing unexpected regressions |
| RISK-SYS-007 | sys_settings, sys_dropdown_needs, sys_dropdowns lack soft-delete columns — violates project convention; Setting model has no SoftDeletes | Convention Compliance | L | L | Add DDL migration to add `deleted_at`, `created_by` to these tables; add SoftDeletes to Setting model | DB Architect | Unexpected hard-delete of platform settings |
| RISK-SYS-008 | Module routes/web.php is empty — all SYS routes registered in central application routes files; route-naming collisions between prime and tenant contexts | Architecture | M | M | Migrate all SYS routes into Modules/SystemConfig/routes/web.php under correct middleware group | Dev Lead | Route name collision errors; wrong controller called for a named route |
| RISK-SYS-009 | Zero HTTP/feature tests — the 22 existing tests only check class existence and model structure; no auth flows tested | Test Coverage | H | H | Priority: SystemConfigAuthTest (7 scenarios), MenuControllerAuthTest, MenuSyncAuthTest — these alone close the P0 security verification gap | QA Lead | A security regression merged without detection |
| RISK-SYS-010 | "Tenant" prefix on post-V2 controllers (TenantDropdownController, TenantActivityLogController) creates naming confusion — these serve central admin users, not tenant users | Naming / Maintainability | L | L | Rename controllers to reflect their actual scope once auth is confirmed; update route registrations | Dev Lead | New developers misunderstanding that these controllers serve tenant databases |

---

## Section 7 — Prioritization (MoSCoW) + Effort Estimation & Sprint Task Breakdown

### 7.1 Prioritization (MoSCoW)

| REQ-ID | Feature | MoSCoW | Rationale |
|--------|---------|:------:|-----------|
| REQ-SYS-001 | Platform Settings Management | Must | Platform-critical; SMTP, SMS, MFA credentials held here; currently broken (wrong table in validation) |
| REQ-SYS-002 | Navigation Menu Management | Must | All school sidebars rendered from these records; create/destroy/toggle/restore are empty stubs |
| REQ-SYS-004 | Dropdown Needs Registry | Must | Prerequisite for all dropdown values across every module; seeders are platform-critical |
| REQ-SYS-007 | Menu Synchronisation | Must | Required to apply any code-defined menu changes to the database; auth check must be restored |
| REQ-SYS-003 | Menu Translation Management | Should | Multi-language support; hardcoded language ID is a known defect |
| REQ-SYS-005 | Dropdown Value Management | Should | Partially implemented; P0 security gaps in related controllers must be resolved first |
| REQ-SYS-006 | Activity Log Viewer | Should | Compliance need; viewer partially implemented |
| REQ-SYS-008 | Platform Backup Management | Should | New post-V2 feature; substantially implemented; auth coverage to be confirmed |
| REQ-SYS-009 | Location Reference Data Management | Could | Inferred from filesystem; overlaps with GlobalMaster; low priority until scope confirmed |
| REQ-SYS-010 | Media Asset Viewer | Could | Read-only viewer; low priority; no blocking dependency |

### 7.2 Effort Estimation & Sprint Task Breakdown

**Sprint 1 — Security Hardening (P0 Fixes, ~8 h)**

| Task-ID | Task | Type | Effort (h) | Depends On | REQ Ref |
|---------|------|------|:----------:|-----------|---------|
| SYS-T01 | Add Gate::authorize('system-config.settings.<action>') to all 7 SystemConfigController methods | Backend | 1 | — | REQ-SYS-001 |
| SYS-T02 | Uncomment and enforce Super Admin auth check in MenuSyncController::sync() | Backend | 0.5 | — | REQ-SYS-007 |
| SYS-T03 | Add Gate::authorize() to MenuController::create(), destroy(), trashedMenu(), restore(), forceDelete() | Backend | 1 | — | REQ-SYS-002 |
| SYS-T04 | Change MenuController::update() line 127 from $request->all() to $request->validated(); strip 'code' key | Backend | 0.5 | — | REQ-SYS-002 |
| SYS-T05 | Delete Modules/Prime/app/Models/Setting.php; update all Prime module imports to use SystemConfig's Setting | Backend | 1.5 | — | REQ-SYS-001 |
| SYS-T06 | Create SettingRequest with correct table (sys_settings) and valid field list; fix SettingController validation and store() | Backend | 2 | — | REQ-SYS-001 |
| SYS-T07 | Write SystemConfigAuthTest (feature test: all 7 methods return 403 without auth or correct permission) | Testing | 1.5 | SYS-T01 | REQ-SYS-001 |
| SYS-T08 | Write MenuSyncAuthTest (non-Super-Admin returns 403) | Testing | 0.5 | SYS-T02 | REQ-SYS-007 |

**Sprint 2 — Broken Functionality Fix (~18 h)**

| Task-ID | Task | Type | Effort (h) | Depends On | REQ Ref |
|---------|------|------|:----------:|-----------|---------|
| SYS-T09 | Fix MenuPolicy: change all 7 permission prefixes from prime.menu.* to system-config.menu.* | Backend | 0.5 | — | REQ-SYS-002 |
| SYS-T10 | Implement MenuController::create(), store(), destroy(), restore(), toggleStatus() method bodies | Backend | 4 | SYS-T03 | REQ-SYS-002 |
| SYS-T11 | Fix MenuController::trashedMenu() view reference: systemconfig.menu.trash → systemconfig::menu.trash; add Gate check | Backend | 0.5 | SYS-T03 | REQ-SYS-002 |
| SYS-T12 | Replace hardcoded $languageId = 2 (lines 22, 105 of MenuController) with dynamic language resolution from settings | Backend | 1 | — | REQ-SYS-003 |
| SYS-T13 | Uncomment translation create logic in MenuController::store(); implement in update() | Backend | 1.5 | SYS-T12 | REQ-SYS-003 |
| SYS-T14 | Implement SystemConfigPolicy (5 methods with system-config.settings.* checks); register in AppServiceProvider | Backend | 1 | SYS-T01 | REQ-SYS-001 |
| SYS-T15 | Extract MenuSyncController 1,702-line logic into MenuSyncService class | Backend | 3 | SYS-T02 | REQ-SYS-007 |
| SYS-T16 | Move all SYS routes from central routes files into Modules/SystemConfig/routes/web.php under correct middleware | Backend | 2 | — | REQ-SYS-001–007 |
| SYS-T17 | Write MenuControllerTest (create, update validated(), soft delete, restore, force delete scenarios) | Testing | 2 | SYS-T10 | REQ-SYS-002 |
| SYS-T18 | Write MenuReorderTest (sibling renumbering; category cannot be re-parented; valid reorder JSON response) | Testing | 1.5 | SYS-T10 | REQ-SYS-002 |
| SYS-T19 | Write SettingControllerTest (index; edit; update saves; is_public=0 masked; sensitive key excluded from audit) | Testing | 1.5 | SYS-T06 | REQ-SYS-001 |

**Sprint 3 — Dropdown UI Completion (~12 h)**

| Task-ID | Task | Type | Effort (h) | Depends On | REQ Ref |
|---------|------|------|:----------:|-----------|---------|
| SYS-T20 | Audit TenantDropdownNeedController: confirm auth, implement missing methods, fix any $request->all() usage | Backend | 3 | — | REQ-SYS-004 |
| SYS-T21 | Audit TenantDropdownController: confirm auth, group key server-side derivation, ordinal auto-assign, reference check on delete | Backend | 3 | — | REQ-SYS-005 |
| SYS-T22 | Implement cascading AJAX selectors (DB-field path and menu-navigation path) for value create form | Frontend | 2 | SYS-T20 | REQ-SYS-005 |
| SYS-T23 | Implement school-admin path: filter Needs to tenant_creation_allowed=1; hide Need creation; key read-only | Frontend | 1.5 | SYS-T21 | REQ-SYS-005 |
| SYS-T24 | Write DropdownControllerTest (create without need = error; create with valid need = value + junction created; duplicate text rejected) | Testing | 2.5 | SYS-T21 | REQ-SYS-004/005 |

**Sprint 4 — Activity Log, Backup Audit, DDL Fixes (~8 h)**

| Task-ID | Task | Type | Effort (h) | Depends On | REQ Ref |
|---------|------|------|:----------:|-----------|---------|
| SYS-T25 | Audit TenantActivityLogController: confirm auth (Super Admin + Support only), add date/entity/user filters | Backend | 2 | — | REQ-SYS-006 |
| SYS-T26 | Audit BackupController + BackupScheduleController: confirm auth is Super Admin only on all routes | Backend | 1 | — | REQ-SYS-008 |
| SYS-T27 | DDL migration: fix FK constraint name typo fk_odelHasPermissions → fk_modelHasPermissions | Schema | 0.5 | — | — |
| SYS-T28 | DDL migration: add deleted_at and created_by to sys_settings, sys_dropdown_needs, sys_dropdowns | Schema | 1 | — | NFR-SYS-017 |
| SYS-T29 | Create SystemConfigPermissionSeeder: seed all system-config.* permissions; map to Super Admin / Platform Manager / Platform Support roles (idempotent) | Backend | 2 | — | All REQs |
| SYS-T30 | Write ActivityLogViewerTest (Super Admin sees logs; Platform Manager denied; entries not deletable) | Testing | 1.5 | SYS-T25 | REQ-SYS-006 |

**Effort Summary**

| Sprint | Hours | Focus |
|--------|------:|-------|
| Sprint 1 | 8 | Security hardening — all P0 auth gaps |
| Sprint 2 | 18 | Broken functionality fix + SRP + route migration |
| Sprint 3 | 12 | Dropdown UI completion |
| Sprint 4 | 8 | Activity log, backup audit, DDL fixes, permissions seeder |
| **Total** | **46** | 30 h backend/frontend + 11 h testing + 5 h schema/config |

---

## Section 8 — User Stories + Reporting & KPI Spec

### 8.1 User Stories (P0 and P1 REQs)

---

**US-SYS-001** | Priority: P0 | REQ: REQ-SYS-001

As a Super Admin, I want to update a Platform Setting value so that the platform's communication and authentication behaviour reflects the current operational configuration.

Acceptance Criteria:
```
Scenario: Update an SMTP setting
  Given I am authenticated as Super Admin
  When I navigate to Platform Settings and click Edit on "smtp_host"
  Then I see a text field pre-populated with the current value, and the key field is read-only

  When I change the value and submit
  Then the new value is saved
  And an audit log entry is created with the before and after values
  And I am redirected to the settings list with a success message

Scenario: Update a sensitive setting (password)
  Given I am authenticated as Super Admin
  When I edit "smtp_password"
  Then the edit form renders a password-type input
  When I save the new value
  Then the audit log entry says "value updated (hidden for security)" — not the actual password

Scenario: Platform Manager attempts to edit a setting
  Given I am authenticated as Platform Manager
  When I navigate to the settings edit route
  Then I receive a 403 response

Scenario: Setting key submitted in update payload
  Given I submit an update with a modified key in the request body
  Then the key field is silently stripped from the update — the key in the database does not change
```

Definition of Done: Gate check present on edit/update; SettingRequest validates against sys_settings; key stripped server-side; sensitive values masked in list; audit log entry written without raw sensitive values.

---

**US-SYS-002** | Priority: P0 | REQ: REQ-SYS-002

As a Platform Manager, I want to add and manage Navigation Menu items so that all school applications reflect the current intended navigation structure.

Acceptance Criteria:
```
Scenario: Create a new menu item
  Given I am authenticated as Platform Manager with menu.create permission
  When I submit the create form with a valid code, title, icon, and route
  Then a new menu item is created and appears in the menu tree
  And an audit log entry is created

Scenario: Attempt to create a category heading with a parent
  Given I submit a create form with is_category = true and a non-null parent_id
  Then I receive HTTP 422 with the message "Category headings cannot have a parent item."
  And no record is created

Scenario: Update a menu item — code must not change
  Given I am authenticated as Super Admin
  When I submit an update with a different code value in the request body
  Then the code in the database does not change (silently stripped)

Scenario: Unauthorised access
  Given I am authenticated as Platform Support
  When I attempt to access the menu create route
  Then I receive a 403 response
```

Definition of Done: All 12 menu controller methods have explicit permission checks; $request->validated() used throughout; code stripped on update; sibling renumber runs after reorder; audit logged.

---

**US-SYS-004** | Priority: P0 | REQ: REQ-SYS-004

As a Super Admin, I want to register Dropdown Needs so that platform administrators and, where permitted, school administrators can add configurable pick-list values to any form field.

Acceptance Criteria:
```
Scenario: Create a Dropdown Need
  Given I am authenticated as Super Admin
  When I create a need with db_type=Tenant, table=std_students, column=blood_group_id
  Then the need is saved with a unique (table, column) entry in the registry

Scenario: Duplicate need rejected
  Given a need for (Tenant, std_students, blood_group_id) already exists
  When I try to create another need for the same table and column
  Then I receive a validation error: "A dropdown requirement for this table and column already exists."

Scenario: System-protected need cannot be edited
  Given a need with is_system = true
  When I attempt to edit it
  Then I receive: "This dropdown requirement is system-protected and cannot be changed."

Scenario: Platform Manager cannot create Needs
  Given I am authenticated as Platform Manager
  When I attempt to access the Need creation form
  Then I receive a 403 response
```

Definition of Done: TenantDropdownNeedController has auth on all methods; (table, column) unique constraint enforced in validation and DB; is_system check on edit/delete; feature test covers all scenarios.

---

**US-SYS-005** | Priority: P0 | REQ: REQ-SYS-005

As a Platform Manager, I want to add Dropdown Values to a registered Dropdown Need so that school administrators see the correct options when filling in forms.

Acceptance Criteria:
```
Scenario: Create a dropdown value via DB-field path
  Given a Dropdown Need exists for (Tenant, std_students, blood_group_id)
  When I select Tenant → std_students → blood_group_id and enter "A+" as the display text
  Then a Dropdown Value is created with key="std_students.blood_group_id", value="A+"
  And the display order is auto-assigned
  And the junction record linking it to the Need is created

Scenario: Group key cannot be set via request
  Given I submit a create form with key="anything.injected"
  Then the saved record's key is derived from the Dropdown Need — not "anything.injected"

Scenario: Duplicate value rejected
  Given "A+" already exists for key "std_students.blood_group_id"
  When I try to create another value "A+" for the same key
  Then I receive: "This value already exists in this pick-list group."

Scenario: Value delete blocked if referenced
  Given "A+" is referenced by 250 student records
  When I attempt to permanently delete it
  Then I receive: "This value is referenced by 250 school record(s). Deactivate it instead of deleting."
```

Definition of Done: Group key derived server-side; ordinal auto-assigned (MAX+1); duplicate text and ordinal rejected; reference check before delete; junction record auto-created; audit logged.

---

**US-SYS-007** | Priority: P0 | REQ: REQ-SYS-007

As a Super Admin, I want to synchronise the navigation menus from code so that all school applications reflect the latest navigation structure after a platform update.

Acceptance Criteria:
```
Scenario: Successful sync as Super Admin
  Given I am authenticated as Super Admin
  When I click "Sync Menus" and confirm the prompt
  Then the database menu records are updated to match the code definitions
  And I see a summary: "Created: 5, Updated: 12, Removed: 2, Unchanged: 43"
  And an audit log entry is created with the Super Admin's identity and the summary counts

Scenario: Non-Super-Admin blocked
  Given I am authenticated as Platform Manager
  When I navigate to the sync route
  Then I receive a 403 response
  And no sync operation occurs

Scenario: Sync failure
  Given the database becomes unavailable mid-sync
  Then the system logs a failure event
  And shows a descriptive error message
  And the database is not left in a partially-synced state
```

Definition of Done: Gate::authorize() check is the first statement in sync(); auth check is never commented out; confirmation prompt displayed; summary shown on success; failure logged.

---

**US-SYS-003** | Priority: P1 | REQ: REQ-SYS-003

As a Platform Manager, I want to add a translated title for a menu item so that school applications configured for languages other than English display the correct navigation labels.

Acceptance Criteria:
```
Scenario: Add a translation
  Given a Menu Item with id=5 exists
  When I add a translation for it in Hindi (language_id=3)
  Then a translation record is created for (menu_id=5, language_id=3)

Scenario: Update existing translation (upsert)
  Given a translation already exists for (menu_id=5, language_id=3)
  When I submit an update with a new translated title
  Then the existing record is updated — no duplicate record is created

Scenario: Fallback to default title
  Given no translation exists for language_id=4 for menu_id=5
  When the school application renders its sidebar in language 4
  Then the menu item displays its default English title as fallback

Scenario: Language list is not hardcoded
  Given the platform has 5 registered available languages
  When I open the menu edit form translation section
  Then all 5 languages appear in the language selector (not just language_id=2)
```

Definition of Done: Language ID sourced dynamically; upsert used (no duplicate per menu+language); fallback to default title confirmed in sidebar render; translation create/edit logic no longer commented out.

---

**US-SYS-006** | Priority: P1 | REQ: REQ-SYS-006

As a Platform Support user, I want to view the Activity Log so that I can investigate what configuration changes were made and by whom.

Acceptance Criteria:
```
Scenario: View logs as Platform Support
  Given I am authenticated as Platform Support
  When I navigate to Activity Logs
  Then I see a list of log entries ordered newest-first with entity type, acting user, event, and timestamp

Scenario: Expand log entry detail
  When I click on a log entry
  Then the before-and-after change detail is shown
  And for sensitive settings, the detail shows "value updated (hidden for security)" not the actual value

Scenario: Platform Manager blocked
  Given I am authenticated as Platform Manager
  When I navigate to Activity Logs
  Then I receive a 403 response

Scenario: No edit or delete controls
  When I view any log entry
  Then there are no edit, delete, or modify buttons on the screen
```

Definition of Done: TenantActivityLogController has auth (Super Admin + Platform Support only); detail panel shows structured before/after; sensitive values excluded; date/entity/user filters functional.

---

**US-SYS-008** | Priority: P1 | REQ: REQ-SYS-008

As a Super Admin, I want to trigger and schedule database backups so that platform data is protected against loss.

Acceptance Criteria:
```
Scenario: Trigger a manual backup
  Given I am authenticated as Super Admin
  When I submit the backup form with selected connections
  Then a background job is queued
  And I am redirected to backup history with "Backup queued" confirmation
  And a Backup Run record appears with status "Queued"

Scenario: Backup completes
  When the background job finishes successfully
  Then the Backup Run status updates to "Completed" with file size and duration
  And I receive a success notification

Scenario: Backup fails
  When the background job encounters an error
  Then the Backup Run status updates to "Failed"
  And I receive a failure notification with the error description

Scenario: Download a completed backup
  Given a Backup Run with status "Completed"
  When I click "Download"
  Then the backup file is downloaded

Scenario: Non-Super-Admin blocked
  Given I am authenticated as Platform Manager
  When I navigate to any backup route
  Then I receive a 403 response
```

Definition of Done: BackupController + BackupScheduleController have Super Admin auth on all routes; job queued asynchronously; status polling works without page reload; success and failure notifications sent.

---

### 8.2 Reporting & KPI Spec

**RPT-SYS-001 — Platform Activity Audit Report**
- Purpose: Compliance and incident investigation view of all platform configuration changes
- Audience: Super Admin (read-write access level), Platform Support (read-only)
- Frequency: On-demand
- Contents: Entity type, entity identifier, acting user (name + ID), event type, IP address, timestamp, expandable before-and-after change record
- Filters: Entity type (Settings / Menu / Dropdown Need / Dropdown Value), event type, platform user, date range (from–to)
- Export: None in v1; CSV export is ENH-SYS-002 territory
- Rules: Sensitive setting values replaced with "value updated (hidden for security)" in all detail panels; log entries cannot be edited or deleted through any interface; entries ordered newest-first; 50 rows per page

**KPIs for RPT-SYS-001:**

| KPI | Formula | Source | Target |
|-----|---------|--------|--------|
| Settings change frequency | Count of Setting update events / week | sys_activity_logs | Baseline then alert on > 20/week |
| Menu sync frequency | Count of Synced events / month | sys_activity_logs | Expected 1–5/month; alert on unexpected spikes |
| Unauthorised access attempts | Count of 403 responses on SYS routes | Application log / Telescope | 0 after security hardening (RISK-SYS-001/002 resolved) |

---

**RPT-SYS-002 — Backup History Report**
- Purpose: Operational assurance — confirm backups are running, completing, and within expected file sizes
- Audience: Super Admin only
- Frequency: On-demand (recommend weekly review)
- Contents: Backup run timestamp, status (Queued / Running / Completed / Failed), connections and schools included, file size (bytes), duration (seconds), download link if Completed, error summary if Failed
- Filters: Status, date range
- Export: Individual files downloadable per completed run; no bulk export
- Rules: Only Completed runs have downloadable files; Failed runs show error summary; Queued/Running runs show real-time status update (poll endpoint)

**KPIs for RPT-SYS-002:**

| KPI | Formula | Source | Target |
|-----|---------|--------|--------|
| Backup success rate | Completed runs / (Completed + Failed runs) × 100 | sys_backup_runs | ≥ 95% |
| Average backup duration | AVG(completed_at - created_at) WHERE status = 'Completed' | sys_backup_runs | Baseline established after first 10 runs |
| Backup coverage | Count of tenant databases included per run | sys_backup_runs | All active tenant databases included in weekly full backup |

---

*End of SYS Complete Analysis Pack v1.0 — 2026-06-30*
*Consolidated file: `SYS_FRD_Complete_2026-06-30.md`*
*FRD: `SYS_FRD_2026-06-30.md`*
*Conditions Catalog: `5-Requirement_Conditions/SYS_Conditions.md`*
