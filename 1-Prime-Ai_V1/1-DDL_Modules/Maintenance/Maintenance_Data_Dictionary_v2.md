# MNT — Maintenance Module | Data Dictionary (v2)

**Module:** Maintenance — Backup, Archive, Retention & Restore
**Module Code:** `MNT` · **Prefix:** `mnt_` · **Tables:** 20
**Target Database:** `prime_db` (central / control plane)
**DDL Source:** `1-DDL_Modules/Maintenance/Maintenance_DDL_v2.sql`
**Version:** 2.0 · **Date:** 27-Jul-2026

---

## How to read this document

Every table gets:
1. **Purpose** — what the table is for, and what one row means.
2. **Field table** — every column, its type, and **why it exists**. The "Why required" column is the important one: it answers *what breaks if this field is missing*.

**Legend**

| Marker | Meaning |
|--------|---------|
| **PK** | Primary key |
| **FK** | Foreign key |
| **UQ** | Part of a unique constraint |
| **IDX** | Indexed |
| **GEN** | Generated (computed) column — never written by the app |
| **SNAP** | Denormalised snapshot — copied at write time and deliberately never refreshed |

---

## Global conventions used by every table

| Column | Type | Why it exists |
|--------|------|---------------|
| `id` | INT UNSIGNED AUTO_INCREMENT | Surrogate PK. `prime_db` standard. BIGINT is used only on the 4 high-volume tables. |
| `is_active` | TINYINT(1) DEFAULT 1 | Soft enable/disable without deleting. Project convention — every screen has an active/inactive toggle. |
| `created_by` / `updated_by` | INT UNSIGNED NULL, FK → `sys_users.id` | Accountability. Nullable + `ON DELETE SET NULL` so an employee leaving does not delete configuration. |
| `created_at` / `updated_at` | TIMESTAMP NULL | Laravel timestamps. |
| `deleted_at` | TIMESTAMP NULL | Soft delete (`SoftDeletes` trait). |
| `*_uuid` | CHAR(36) | Stable external identifier — safe to expose in URLs/APIs and usable as an idempotency key so a retried job does not create a duplicate run. |
| `*_no` | VARCHAR(40) | Human-readable reference (`BKP-2026-07-27-0007`). What support staff and tenants actually quote on a call. |
| `*_json` | JSON | Project convention for JSON columns. |

**Audit-column exceptions (deliberate):**

| Table | Missing | Reason |
|-------|---------|--------|
| `mnt_activity_logs` | `updated_at`, `deleted_at`, `is_active`, `updated_by` | Append-only audit trail. A log you can edit is not evidence. |
| `mnt_alert_dispatches` | `deleted_at` | Dispatch record; suppression/failure is expressed via `status`, not deletion. |
| `mnt_storage_usage_snapshots` | `updated_at`, `deleted_at`, `is_active` | Immutable daily fact row for billing. |
| `mnt_schedule_tenant_jnt`, `mnt_retention_extension_item_jnt` | `deleted_at` | Junction rows; removal is a real delete or a status flip. |

---

# LAYER 1 — CONFIGURATION MASTERS

---

## 1. `mnt_storage_destinations`

**Purpose:** Master list of every physical location a backup can be written to — local NAS, S3, Wasabi, Google Drive, SFTP, tape.
**One row = one storage target.**
**Replaces:** v1's free-text `disk_path` / `remote_disk` / `remote_path` columns, which could not be validated, monitored or priced.

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | INT UNSIGNED | **PK** | Surrogate key. |
| `code` | VARCHAR(30) | **UQ** | Stable machine code (`S3_MUM`, `LOCAL_NAS`). Used in config and scripts so a renamed destination does not break jobs. |
| `short_name` | VARCHAR(50) | | Dropdown label — project convention (`sys_dropdown_table` pattern). |
| `name` | VARCHAR(150) | | Full display name. |
| `driver` | ENUM(12) | **IDX** | Which storage adapter to use. Determines which of the credential/bucket fields are mandatory. |
| `laravel_disk_name` | VARCHAR(60) | | Key in `config/filesystems.php`. Lets the app hand the destination straight to `Storage::disk()`. |
| `region` | VARCHAR(50) | | Cloud region. Needed for data-residency compliance — Indian school data may be required to stay in India. |
| `bucket_or_share` | VARCHAR(150) | | S3 bucket / SMB share name. |
| `base_path` | VARCHAR(255) | | Root prefix under which this module may write. Prevents a misconfigured job writing to the bucket root. |
| `endpoint_url` | VARCHAR(255) | | Custom endpoint for S3-compatible providers (Wasabi, MinIO). |
| `credential_ref` | VARCHAR(255) | | **Vault/ENV key NAME, never the secret.** Storing a live secret in the DB would mean a DB dump leaks storage credentials — and that dump is itself a backup. |
| `is_offsite` | TINYINT(1) | | Marks a geographically separate copy. Needed to prove the 3-2-1 rule (3 copies, 2 media, 1 offsite). |
| `is_immutable` | TINYINT(1) | | Object-lock / WORM enabled. Ransomware protection: an attacker with admin rights still cannot delete these backups. |
| `default_storage_class` | ENUM(5) | | HOT…DEEP_ARCHIVE. Drives cost and restore lead time. |
| `supports_server_side_encryption` | TINYINT(1) | | Whether the provider encrypts at rest. If 0, the module must encrypt client-side before upload. |
| `capacity_bytes` | BIGINT UNSIGNED NULL | | Total space. NULL = elastic cloud. Needed to predict "we will run out in 12 days". |
| `used_bytes` | BIGINT UNSIGNED | | Current consumption, refreshed by the usage job. |
| `low_space_threshold_pct` | TINYINT UNSIGNED | | Alert trigger. Without it, backups fail silently at 100% full — the classic backup outage. |
| `bandwidth_limit_mbps` | SMALLINT UNSIGNED NULL | | Throttle. A full backup at line rate will starve the live application. |
| `cost_per_gb_month` | DECIMAL(10,4) | | Feeds the paid-extension quote and the storage-overage invoice. |
| `currency` | CHAR(3) | | Currency of the above. |
| `health_status` | ENUM(4) | **IDX** | HEALTHY/DEGRADED/UNREACHABLE. Lets the scheduler skip a dead destination instead of failing every tenant against it. |
| `last_health_check_at` | TIMESTAMP NULL | | Staleness of the health value. |
| `priority` | TINYINT UNSIGNED | | Preference order when several destinations qualify. |
| `is_default` | TINYINT(1) | | Fallback destination. |
| `default_flag` | TINYINT | **GEN, UQ** | `CASE WHEN is_default=1 THEN 1 ELSE NULL END`. The unique index on this makes "exactly one default" a **database guarantee**, not an application hope. |
| `remarks` | VARCHAR(255) | | Free notes. |
| *audit columns* | | | See global conventions. |

---

## 2. `mnt_retention_policies`

**Purpose:** Answers two questions: *how long do we keep a backup*, and *what does it cost the tenant to keep it longer*.
**One row = one named retention policy** (e.g. `STD_90D`, `GOLD_365D`, `STATUTORY_7Y`).
**New in v2** — v1 had no retention concept at all, which left the module's central requirement unimplementable.

### Identity

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | INT UNSIGNED | **PK** | |
| `code` | VARCHAR(30) | **UQ** | Machine code used in seeds and config. |
| `short_name` / `name` | VARCHAR(50/150) | | Dropdown label and display name. |
| `description` | VARCHAR(500) | | What this policy is for — shown to the admin choosing it. |

### GFS retention tiers

Grandfather-Father-Son: keep many recent backups, progressively fewer old ones. Without tiering you either keep everything (unaffordable) or keep only recent copies (useless for a year-old audit query).

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `keep_daily_days` | SMALLINT UNSIGNED | How many days of daily backups to keep (e.g. 7). |
| `keep_weekly_weeks` | SMALLINT UNSIGNED | How many weekly backups (e.g. 4). |
| `keep_monthly_months` | SMALLINT UNSIGNED | How many monthly backups (e.g. 12). |
| `keep_yearly_years` | SMALLINT UNSIGNED | How many yearly backups (e.g. 3). |
| `keep_last_n_full` | SMALLINT UNSIGNED | Absolute floor: never leave a tenant with fewer than N full backups, whatever the dates say. Guards against a clock/config error deleting everything. |

### Absolute bounds

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `default_retention_days` | SMALLINT UNSIGNED | **The number that stamps each backup's end date.** `retention_end_date = backup date + this`. |
| `min_retention_days` | SMALLINT UNSIGNED | Statutory floor. Even a manual purge cannot go below it (except a dual-approved erasure request). Protects against an admin deleting evidence. |
| `max_retention_days` | SMALLINT UNSIGNED NULL | Cap on total retention including extensions. NULL = unbounded. |
| `grace_period_days` | SMALLINT UNSIGNED | Soft window after expiry before physical deletion. Gives a tenant who missed the warning emails a last chance to pay for an extension. |

### Purge behaviour

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `auto_purge_enabled` | TINYINT(1) | Whether the cron may delete automatically. Set 0 for high-value tenants where every deletion is reviewed. |
| `purge_requires_approval` | TINYINT(1) | Forces a human to sign off before deletion. |
| `purge_notify_tenant` | TINYINT(1) | Whether the tenant is told before their data is destroyed. |
| `expiry_warning_days_json` | JSON | The T-minus alert ladder, default `[30,15,7,1]`. Drives `mnt_alert_dispatches` so warnings fire on schedule and only once. |

### Extension pricing (the paid service)

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `allow_extension` | TINYINT(1) | Whether extension is offered on this policy at all. |
| `extension_min_days` | SMALLINT UNSIGNED | Smallest sellable extension (avoids 1-day requests with more admin cost than revenue). |
| `extension_max_days` | SMALLINT UNSIGNED NULL | Largest single extension. |
| `max_extensions_allowed` | TINYINT UNSIGNED NULL | Cap on repeat extensions of the same backup. NULL = unlimited. |
| `extension_is_chargeable` | TINYINT(1) | Free vs paid. A free extension skips the quote/payment states entirely. |
| `extension_rate_per_gb_month` | DECIMAL(10,4) | Variable price component — the tenant pays for the space they actually consume. |
| `extension_flat_fee_month` | DECIMAL(12,2) | Fixed price component (handling/admin). |
| `extension_min_charge` | DECIMAL(12,2) | Floor price so a 2 MB extension is not invoiced at ₹0.08. |
| `extension_tax_percent` | DECIMAL(5,2) | GST. Matches the `bil_*` tables' pattern. |
| `currency` | CHAR(3) | Currency of the price book. |
| `extension_lead_time_days` | SMALLINT UNSIGNED | Minimum notice. Stops a tenant requesting an extension on the morning the backup is due for deletion, when the job may already be queued. |

### Integrity & compliance

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `verify_after_backup` | TINYINT(1) | Run a checksum verification immediately after every backup. An unverified backup is an assumption, not a backup. |
| `test_restore_frequency_days` | SMALLINT UNSIGNED NULL | How often to do a real test restore into a sandbox. The only proof a backup actually works. |
| `require_offsite_copy` | TINYINT(1) | A run is not "complete" until the offsite copy exists. |
| `require_encryption` | TINYINT(1) | Backups must be encrypted. A run that cannot encrypt must fail rather than silently write plaintext student data. |
| `compliance_tag` | VARCHAR(60) | `DPDP-2023`, `ISO-27001`. Lets auditors filter policies by the regime they are auditing. |
| `is_system_defined` | TINYINT(1) | Seeded policy — UI must block deletion. |

---

## 3. `mnt_maintenance_plans`

**Purpose:** Binds a **tenant** (a school) to a retention policy, storage destinations, a backup scope and an SLA. This is the table that makes *"different maintenance plans for different Schools"* real.
**One row = one plan version.** `tenant_id = NULL` means the platform-default plan used by any tenant with no plan of its own.
**New in v2.**

### Identity & assignment

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | INT UNSIGNED | **PK** | |
| `plan_code` | VARCHAR(30) | **UQ** | Machine code. |
| `name` / `description` | VARCHAR(150/500) | | Display. |
| `tenant_id` | INT UNSIGNED NULL | **FK, IDX** | The school this plan is for. NULL = platform default. FK CASCADE — removing a tenant removes its plan config (but *not* its backups; see table 8). |
| `tenant_group_id` | INT UNSIGNED NULL | **FK** | Plan for an entire school group/trust, so a 40-school chain is configured once. |
| `retention_policy_id` | INT UNSIGNED | **FK, IDX** | Which retention policy applies. RESTRICT — a policy in use cannot be deleted. |
| `primary_destination_id` | INT UNSIGNED | **FK, IDX** | Where backups are written first. RESTRICT for the same reason. |
| `offsite_destination_id` | INT UNSIGNED NULL | **FK** | Second, geographically separate copy. |
| `archive_destination_id` | INT UNSIGNED NULL | **FK** | Cheap cold tier for aged backups. |
| `move_to_archive_after_days` | SMALLINT UNSIGNED NULL | | When to transition to the cold tier. Cuts storage cost by ~70% for data nobody reads. |

### Backup scope — *what* is protected

Directly implements "Database, Images, Videos, PDF etc.". Separate flags rather than one JSON blob because these are queried and reported on constantly.

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `backup_database` | TINYINT(1) | Include the tenant's MySQL database. |
| `backup_images` | TINYINT(1) | Student photos, logos, scanned documents. |
| `backup_videos` | TINYINT(1) | Lecture/LMS video. Defaults to 0 — video dominates storage cost and most schools do not want to pay for it. |
| `backup_documents` | TINYINT(1) | PDF/DOCX/XLSX — TCs, marksheets, circulars. |
| `backup_audio` | TINYINT(1) | Audio assets. |
| `backup_config_files` | TINYINT(1) | Tenant config/env. Without these a restore rebuilds data but not a working system. |
| `backup_app_logs` | TINYINT(1) | Application logs. Usually 0; occasionally required for a forensic investigation. |
| `include_paths_json` | JSON | Extra explicit paths beyond the standard set. |
| `exclude_paths_json` | JSON | e.g. `["cache/**","tmp/**"]`. Excluding regenerable junk can halve backup size and time. |
| `exclude_tables_json` | JSON | e.g. `["sessions","jobs","*_cache"]`. Same reasoning for the database. |
| `max_file_size_mb` | INT UNSIGNED NULL | Skip single files above this. Stops one 40 GB stray upload from breaking every nightly run. |

### Processing options

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `default_backup_type` | ENUM(4) | FULL / INCREMENTAL / DIFFERENTIAL / SNAPSHOT. |
| `compression_type` | ENUM(7) | Algorithm. ZSTD gives the best speed/size trade-off for large tenants. |
| `compression_level` | TINYINT UNSIGNED | Trade CPU for size. |
| `encryption_enabled` | TINYINT(1) | Encrypt before upload. Student PII in an unencrypted cloud object is a reportable breach. |
| `encryption_algo` | VARCHAR(40) | e.g. `AES-256-GCM`. Recorded so a 5-year-old backup can still be decrypted after the default changes. |
| `encryption_key_ref` | VARCHAR(255) | **Vault path only.** |
| `checksum_algo` | ENUM(6) | Hash algorithm for integrity verification. |
| `split_volume_size_mb` | INT UNSIGNED NULL | Chunk large archives into volumes — required by some providers and makes a failed upload resumable. |

### SLA

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `rpo_minutes` | INT UNSIGNED NULL | Recovery Point Objective — maximum acceptable data loss. Determines how often backups must run. |
| `rto_minutes` | INT UNSIGNED NULL | Recovery Time Objective — maximum acceptable restore duration. Measured against in `mnt_restore_runs.rto_breached`. |
| `max_run_duration_minutes` | INT UNSIGNED | Kill/alert threshold. A backup still running after 8 hours is hung, not slow. |
| `alert_on_failure` | TINYINT(1) | Whether failures notify. |
| `alert_recipients_json` | JSON | Channel + address list. |

### Commercial

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `is_paid_plan` | TINYINT(1) | Distinguishes a paid backup plan from the bundled default. |
| `included_storage_gb` | INT UNSIGNED | Free quota before overage billing. |
| `overage_rate_per_gb_month` | DECIMAL(10,4) | Price beyond quota. |
| `currency` | CHAR(3) | |

### Versioning

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `effective_from` / `effective_to` | DATE | **IDX** | Validity window. Lets you answer "what plan was this school on last March?" — essential in a billing dispute. |
| `is_current` | TINYINT(1) | | Marks the live version. |
| `current_plan_flag` | INT | **GEN, UQ** | `CASE WHEN is_current=1 AND deleted_at IS NULL THEN IFNULL(tenant_id,0) ELSE NULL END`. Makes "one live plan per tenant" a database guarantee. `IFNULL(...,0)` folds the platform-default plan into the same rule. |
| *audit columns* | | | See global conventions. |

---

# LAYER 2 — SCHEDULING

---

## 4. `mnt_backup_schedules`

**Purpose:** The cron definitions — *when* backups run and *against whom*.
**One row = one recurring schedule.**
**Carried from v1**, with the target model rebuilt: v1 stored targets in a `databases_json` blob plus an `all_tenants` flag, which could not be joined, indexed or reported on.

### v1 columns kept

`label`, `cron_expression`, `is_active`, `last_run_at`, `next_run_at`, `created_by`, `created_at`, `updated_at`.
`databases_json`, `all_tenants` and `include_files` were replaced by `target_scope` + `mnt_schedule_tenant_jnt` + `content_scope_json`.

### Identity & targeting

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | INT UNSIGNED | **PK** | |
| `schedule_code` | VARCHAR(30) | **UQ** | Machine code, referenced by ops runbooks. |
| `label` | VARCHAR(150) | | *v1 field.* Display name. |
| `description` | VARCHAR(500) | | What this schedule is for. |
| `maintenance_plan_id` | INT UNSIGNED NULL | **FK, IDX** | Plan this schedule belongs to; the plan supplies retention, destination and encryption. NULL = ad-hoc central schedule. |
| `target_scope` | ENUM(6) | **IDX** | ALL_TENANTS / PLAN_TENANTS / SELECTED_TENANTS / TENANT_GROUP / CENTRAL_DB_ONLY / GLOBAL_MASTER_ONLY. Declarative and indexable — replaces v1's `all_tenants` boolean, which could not express "this group" or "these five schools". |
| `tenant_group_id` | INT UNSIGNED NULL | **FK** | Used when `target_scope = 'TENANT_GROUP'`. |
| `include_central_db` | TINYINT(1) | | Also dump `prime_db`. **Critical:** without the control-plane database, restored tenant databases have no tenant registry to attach to. |
| `include_global_master_db` | TINYINT(1) | | Also dump `global_master` (countries, states, modules, menus). |
| `content_scope_json` | JSON | | Override the plan's content scope for this schedule — e.g. a nightly DB-only run plus a weekly full-media run. |

### Timing

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `backup_type` | ENUM(5) | FULL/INCREMENTAL/DIFFERENTIAL/SNAPSHOT/LOG. LOG backups are what make point-in-time recovery possible. |
| `frequency` | ENUM(7) | Human-friendly frequency. Lets the UI show "Daily" instead of `0 2 * * *`, and lets the retention engine classify the backup as DAILY/WEEKLY/MONTHLY. |
| `cron_expression` | VARCHAR(100) | *v1 field.* The authoritative schedule. |
| `timezone` | VARCHAR(64) | **Evaluated in this timezone, not server time.** A "2 AM" backup that fires at 8:30 AM IST because the server runs UTC will hit peak school-hours load. |
| `preferred_start_time` | TIME NULL | Readable mirror of the cron for the UI. |
| `execution_window_minutes` | SMALLINT UNSIGNED NULL | Do not *start* after the window closes. A backup delayed into school hours should be skipped, not run. |
| `blackout_dates_json` | JSON | Dates to never run — board exam day, result publication day. |

### Execution behaviour

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `priority` | TINYINT UNSIGNED | Queue ordering when many schedules fire together. |
| `max_parallel_tenants` | TINYINT UNSIGNED | Concurrency throttle. Backing up 200 schools simultaneously will take the database server down — the backup becomes the outage. |
| `retry_on_failure` | TINYINT(1) | Whether to auto-retry. |
| `max_retry_attempts` | TINYINT UNSIGNED | Retry cap. |
| `retry_delay_minutes` | SMALLINT UNSIGNED | Back-off before retry. |
| `skip_if_previous_running` | TINYINT(1) | Overlap guard. Without it, a slow run and its successor pile up until the server dies. |
| `auto_verify` | TINYINT(1) | Trigger verification automatically after this schedule's runs. |
| `retention_days_override` | SMALLINT UNSIGNED NULL | Schedule-level retention override — e.g. hourly log backups kept 3 days while nightly fulls are kept 90. |

### Runtime state

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `last_run_at` / `next_run_at` | TIMESTAMP NULL | **IDX** | *v1 fields.* `next_run_at` is the scheduler's work queue — indexed with `is_active`/`is_paused` so dispatch is a single fast lookup. |
| `last_run_id` | INT UNSIGNED NULL | **FK** | Jump straight to the last execution from the schedule list. FK added in the deferred block (circular dependency). |
| `last_run_status` | ENUM(10) | | Status badge on the schedule grid without a join. |
| `consecutive_failure_count` | SMALLINT UNSIGNED | | Drives escalation — 1 failure is noise, 5 in a row is an outage. |
| `auto_disable_after_failures` | TINYINT UNSIGNED NULL | | Self-park a permanently broken schedule instead of alerting nightly forever. |
| `total_run_count` | INT UNSIGNED | | Lifetime counter for reporting. |
| `is_paused` / `paused_reason` / `paused_until` | TINYINT/VARCHAR/TIMESTAMP | | Temporary suspension (e.g. during a data-centre migration) that is distinct from `is_active = 0` (permanently retired) and self-resuming. |
| *audit columns* | | | `created_by` is **nullable with SET NULL** in v2. v1 had it `NOT NULL` with `ON DELETE CASCADE`, which meant deleting a staff member silently deleted their backup schedules. |

---

## 5. `mnt_schedule_tenant_jnt`

**Purpose:** Explicit tenant targeting and per-tenant opt-out.
**One row = one (schedule, tenant) link.**

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | INT UNSIGNED | **PK** | |
| `backup_schedule_id` | INT UNSIGNED | **FK, UQ** | The schedule. |
| `tenant_id` | INT UNSIGNED | **FK, UQ, IDX** | The school. Unique together so a tenant cannot be listed twice on one schedule. |
| `is_excluded` | TINYINT(1) | | **Inverted use:** on an ALL_TENANTS schedule this opts a single tenant *out* — e.g. a school mid-migration. Avoids maintaining a 200-row inclusion list to exclude one school. |
| `exclusion_reason` | VARCHAR(255) | | Why — so the exclusion is not forgotten forever. |
| `content_scope_json` | JSON | | Per-tenant scope override. |
| `retention_days_override` | SMALLINT UNSIGNED NULL | | Per-tenant retention override. |
| `sequence_no` | SMALLINT UNSIGNED NULL | | Deterministic processing order — put the biggest schools first so they are not squeezed against the window edge. |
| *audit columns* | | | |

---

## 6. `mnt_maintenance_windows`

**Purpose:** Announced downtime / degraded-service windows. Backups, restores and purges should run inside one, and tenants are warned in advance.
**One row = one planned (or emergency) window.**
**New in v2** — a restore that overwrites a live school database without an announced window is an unplanned outage from the school's point of view.

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | INT UNSIGNED | **PK** | |
| `window_code` | VARCHAR(30) | **UQ** | Reference code quoted in notices. |
| `title` / `description` | VARCHAR(200)/TEXT | | What tenants are told. |
| `window_type` | ENUM(8) | | SCHEDULED_BACKUP / RESTORE / DB_UPGRADE / … Drives the message template and the severity of the notice. |
| `scope` | ENUM(4) | | PLATFORM / TENANT_GROUP / SELECTED_TENANTS / SINGLE_TENANT. Determines who is notified — a single school's restore must not alarm 200 others. |
| `tenant_id` / `tenant_group_id` | INT UNSIGNED NULL | **FK, IDX** | Scope targets. |
| `affected_tenants_json` | JSON | | Tenant id list for SELECTED_TENANTS. |
| `starts_at` / `ends_at` | DATETIME | **IDX** | Planned window. CHECK enforces `ends_at > starts_at`. |
| `timezone` | VARCHAR(64) | | Same reason as the schedule timezone. |
| `is_recurring` / `recurrence_cron` | TINYINT/VARCHAR | | Standing weekly maintenance slot. |
| `expected_downtime_minutes` | SMALLINT UNSIGNED NULL | | What the tenant was promised — compared against actual in the SLA report. |
| `is_read_only_mode` | TINYINT(1) | | App stays up, writes blocked. Far less disruptive than a full outage and often sufficient for a backup. |
| `is_full_outage` | TINYINT(1) | | Complete unavailability. |
| `notify_days_before` | TINYINT UNSIGNED | | Notice period. |
| `notification_sent_at` / `reminder_sent_at` | TIMESTAMP NULL | | Dedupe — prevents the notice job re-sending on every tick. |
| `banner_message` | VARCHAR(500) | | Text displayed in the tenant UI during the window. |
| `status` | ENUM(6) | **IDX** | PLANNED → ANNOUNCED → IN_PROGRESS → COMPLETED / CANCELLED / EXTENDED. |
| `actual_started_at` / `actual_ended_at` | TIMESTAMP NULL | | Reality vs plan. |
| `outcome_notes` | TEXT | | Post-maintenance summary. |
| *audit columns* | | | |

---

# LAYER 3 — EXECUTION CATALOGUE

> **The three-level design.** `RUN` = one execution. `ITEM` = one tenant × one content type. `FILE` = one physical object. v1 collapsed all three into a single row, which is why it could not answer "did school X's photo backup succeed last Tuesday, and where is the file?"

---

## 7. `mnt_backup_runs`

**Purpose:** Header record for one execution of a backup — scheduled or manual.
**One row = one run.**
**Carried from v1** with roll-up counters, chaining, retry tracking and forensic context added.

### v1 columns kept
`name`, `include_files`, `status`, `progress` (renamed `progress_percent`), `file_size_bytes`, `started_at`, `completed_at`, `triggered_by`, `error_message`, `created_at`, `updated_at`.

### Identity & lineage

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | INT UNSIGNED | **PK** | |
| `run_uuid` | CHAR(36) | **UQ** | Idempotency key — a queue worker that retries after a timeout must not create a second run. Also the `correlation_id` used across `mnt_activity_logs`. |
| `run_no` | VARCHAR(40) | **UQ** | `BKP-2026-07-27-0007`. What support quotes on a call. |
| `name` | VARCHAR(200) | | *v1 field.* Display name. |
| `backup_schedule_id` | INT UNSIGNED NULL | **FK, IDX** | Originating schedule. NULL = manual run. SET NULL so deleting a schedule never destroys its execution history. |
| `maintenance_plan_id` | INT UNSIGNED NULL | **FK, IDX** | Plan in force at run time. |
| `maintenance_window_id` | INT UNSIGNED NULL | **FK** | Window this ran inside. |
| `parent_run_id` | INT UNSIGNED NULL | **FK, IDX** | The base FULL run for an INCREMENTAL/DIFFERENTIAL. **RESTRICT** — a full backup with incremental children can never be deleted, because deleting it would silently render every child unrestorable. |
| `chain_id` | CHAR(36) | **IDX** | Groups a FULL and all its incrementals. Restoring means replaying the whole chain, so it must be retrievable as one unit. |

### What was attempted

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `backup_type` | ENUM(5) | **IDX** with status. |
| `trigger_type` | ENUM(9) | SCHEDULED / MANUAL / API / PRE_RESTORE / PRE_UPGRADE / PRE_OFFBOARDING / TENANT_REQUEST / RETRY / DR_DRILL. Answers "**who raised the request**" at the category level and distinguishes a routine nightly run from an emergency pre-restore snapshot. |
| `target_scope` | ENUM(7) | Scope resolved at dispatch. |
| `content_scope_json` | JSON | Content types attempted. |
| `target_tenants_json` | JSON | **Snapshot of the tenant list at dispatch time.** If a school is added at 2:05 AM it must not appear to have been "missed" by the 2:00 AM run. |
| `include_central_db` | TINYINT(1) | Whether `prime_db` was included. |
| `include_files` | TINYINT(1) | *v1 field.* Whether media/files were included. |

### Destination

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `primary_destination_id` | INT UNSIGNED NULL | **FK.** Where it was written. RESTRICT — a destination holding live backups cannot be deleted. |
| `offsite_destination_id` | INT UNSIGNED NULL | **FK.** Second copy. |
| `root_path` | VARCHAR(500) | Run-level folder. One path to inspect (or clean up) the whole run. |

### Lifecycle

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `status` | ENUM(11) | **IDX** | PENDING → QUEUED → RUNNING → COMPLETED / COMPLETED_WITH_WARNINGS / **PARTIALLY_FAILED** / FAILED / TIMED_OUT; plus PAUSED, CANCELLED, SKIPPED. `PARTIALLY_FAILED` is new and necessary: 199 of 200 schools succeeding is neither "completed" nor "failed", and reporting it as either is misleading. |
| `progress_percent` | TINYINT UNSIGNED | | *v1 `progress`.* Live progress bar. CHECK 0–100. |
| `current_stage` | VARCHAR(60) | | DUMPING / COMPRESSING / ENCRYPTING / UPLOADING / VERIFYING / REPLICATING. Turns "70% for the last hour" into "stuck on UPLOADING". |
| `queued_at` / `started_at` / `completed_at` | TIMESTAMP NULL | **IDX** | *v1 fields (2 of 3).* `queued_at` separates queue wait from actual work — the usual cause of a "slow backup". |
| `duration_seconds` | INT UNSIGNED | **GEN** | `TIMESTAMPDIFF(SECOND, started_at, completed_at)`. Computed so it can never drift from the timestamps. |
| `attempt_no` / `max_attempts` | TINYINT UNSIGNED | | Retry position. |
| `retry_of_run_id` | INT UNSIGNED NULL | **FK** | Links a retry to the run it replaces, so failures are not double-counted. |

### Roll-up counters

Maintained from `mnt_backup_run_items` so dashboards never aggregate hundreds of item rows per run.

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `total_items` / `success_items` / `warning_items` / `failed_items` / `skipped_items` | SMALLINT UNSIGNED | Item outcome counts — the run status is derived from these. |
| `total_files_count` | INT UNSIGNED | Physical files produced. |
| `total_original_bytes` | BIGINT UNSIGNED | Size before compression. |
| `total_stored_bytes` | BIGINT UNSIGNED | Size actually consumed — the number that drives cost. |
| `file_size_bytes` | BIGINT UNSIGNED NULL | *v1 field, retained* as a mirror of `total_stored_bytes` for backward compatibility. |

### Execution environment (forensics)

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `queue_job_id` | VARCHAR(100) | Correlate with Horizon/queue logs. |
| `worker_host` / `worker_pid` | VARCHAR(100)/INT | Which machine ran it. Essential when one node in a pool has a bad mount or a full disk. |
| `app_version` | VARCHAR(30) | Code version. A restore may need the same version to interpret the schema. |
| `db_server_version` | VARCHAR(50) | MySQL version the dump came from — restoring an 8.0 dump into 5.7 fails. |
| `peak_memory_mb` | INT UNSIGNED | Capacity planning; detects the tenant that will OOM next month. |

### Outcome

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `error_code` | VARCHAR(50) | Machine-classifiable failure (`DISK_FULL`, `AUTH_FAILED`, `TIMEOUT`) — groupable, unlike free text. |
| `error_message` | TEXT | *v1 field.* Human-readable failure. |
| `error_trace` | MEDIUMTEXT | Stack trace for debugging. |
| `warning_count` | SMALLINT UNSIGNED | Non-fatal issue count. |
| `summary_json` | JSON | Per-stage timings and throughput. |
| `is_verified` / `verified_at` | TINYINT/TIMESTAMP | Verification passed. |
| `is_offsite_replicated` / `offsite_replicated_at` | TINYINT/TIMESTAMP | Offsite copy confirmed. Until this is 1, the 3-2-1 rule is unmet even though the run "succeeded". |

### Who and when — *the explicit requirement*

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `triggered_by` | INT UNSIGNED NULL | **FK, IDX** | *v1 field.* The user who triggered it. |
| `triggered_by_name` | VARCHAR(100) | **SNAP** | Name captured at trigger time. The FK is SET NULL, so without this snapshot the audit trail would read "deleted user" once someone leaves. |
| `triggered_by_type` | ENUM(5) | | USER / SYSTEM / CRON / API / TENANT_USER. Distinguishes automated runs from human action. |
| `requested_by_tenant_id` | INT UNSIGNED NULL | **FK** | Set when a school asked for the backup. |
| `requested_at` | TIMESTAMP NULL | | **When the request was raised** — distinct from `started_at`. The gap between them is the queue wait a tenant experiences. |
| `cancelled_by` / `cancelled_at` / `cancellation_reason` | INT/TIMESTAMP/VARCHAR | **FK** | Who stopped it and why. |
| `remarks` | VARCHAR(500) | | Operator notes. |
| *audit columns* | | | |

---

## 8. `mnt_backup_run_items` — **the backup catalogue**

**Purpose:** The single most important table in the module. One row per **(run × tenant × content type)**. This is what the "Backup History" screen lists, and this row **owns the retention date the tenant pays to extend**.
**One row = one logical backup set** — e.g. "Sunrise Public School, DATABASE, 27-Jul-2026".
**New in v2.**

### Identity

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | INT UNSIGNED | **PK** | |
| `item_uuid` | CHAR(36) | **UQ** | External reference used in extension/restore/archive requests. |
| `backup_run_id` | INT UNSIGNED | **FK, UQ** | Parent run. CASCADE — items have no meaning without their run. |
| `sequence_no` | SMALLINT UNSIGNED | | Processing order within the run. |

### Tenant identity — *"Tenant detail (Tenant Name, Code, DB Name etc.)"*

All **SNAP** columns: captured at backup time and never refreshed.

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `tenant_id` | INT UNSIGNED NULL | **FK, UQ, IDX** | The school. NULL = central/global database item. **FK is RESTRICT, not CASCADE** — deleting a tenant must never silently destroy the evidence of their backups. Off-boarding is an explicit purge workflow. |
| `tenant_code` | VARCHAR(20) | **SNAP, IDX** | Code as it was on the backup date. If a school later changes its code, history must still be findable by the old one. |
| `tenant_name` | VARCHAR(150) | **SNAP** | Name at backup time. Schools rename (merger, trust change) and old backups belong to the old name. |
| `tenant_group_code` | VARCHAR(20) | **SNAP** | Group at backup time. |
| `database_name` | VARCHAR(100) | **SNAP** | Which database was dumped. Without it you cannot know where a restore should go. |
| `database_host` | VARCHAR(200) | **SNAP** | Which server it came from — relevant after a shard migration. |
| `domain_name` | VARCHAR(255) | **SNAP** | Tenant domain at backup time. |

### What this item is

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `content_type` | ENUM(10) | **UQ, IDX** | DATABASE / IMAGES / VIDEOS / DOCUMENTS / AUDIO / MEDIA_ALL / CONFIG / APP_LOGS / FULL_FILESYSTEM / OTHER. Part of the unique key: one row per content type per tenant per run, so photos and the database have independent sizes, statuses and retention. |
| `backup_type` | ENUM(5) | | FULL / INCREMENTAL / …, per item. |
| `parent_item_id` | INT UNSIGNED NULL | **FK, IDX** | Base item for an incremental. RESTRICT — protects the chain. |
| `source_path` | VARCHAR(500) | | What was read (media root, etc.). |
| `table_count` / `row_count_estimate` | SMALLINT/BIGINT UNSIGNED | | Database item metrics. Compared post-restore to prove nothing was lost, and a sudden drop signals a truncated dump. |
| `source_file_count` | INT UNSIGNED NULL | | File item metric, same purpose. |

### Where it landed — *"Backup File Storage Location"*

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `storage_destination_id` | INT UNSIGNED NULL | **FK, IDX** | Which destination. |
| `storage_path` | VARCHAR(500) | | Folder holding this item's files. |
| `primary_file_name` | VARCHAR(255) | | The main archive file name — what the operator looks for on disk. |
| `file_extension` | VARCHAR(20) | | `sql.gz`, `tar.zst`. Tells you which tool opens it. |
| `mime_type` | VARCHAR(120) | | Content type for downloads. |
| `file_count` | SMALLINT UNSIGNED | | Number of physical files/volumes. |
| `is_multipart` | TINYINT(1) | | Split archive — all parts are needed to restore, so a partial copy is worthless. |

### File info — *"File Info (Size, type etc.)"*

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `original_size_bytes` | BIGINT UNSIGNED | | Size before compression — the true data volume. |
| `stored_size_bytes` | BIGINT UNSIGNED | | Size on the storage bill and the basis of the extension quote. |
| `compression_ratio` | DECIMAL(6,3) | **GEN** | `stored / original`. A ratio that suddenly jumps to ~1.0 means compression silently stopped working. |
| `compression_type` | ENUM(7) | | Algorithm used — needed to decompress years later. |

### Integrity & security

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `checksum_algo` | ENUM(6) | Hash algorithm, recorded per item because the default will change over a 7-year retention. |
| `checksum_value` | VARCHAR(128) | Hash over the manifest. **The only way to prove the backup has not silently rotted or been tampered with.** |
| `is_encrypted` | TINYINT(1) | Whether the payload is encrypted. |
| `encryption_algo` | VARCHAR(40) | Cipher used — a 2026 backup must still be decryptable in 2033. |
| `encryption_key_ref` | VARCHAR(255) | **Vault path, never the key.** A key stored next to the ciphertext is not encryption. |
| `manifest_json` | JSON | File list with per-file hashes. Lets you verify one file without downloading the whole archive. |

### Execution

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `status` | ENUM(7) | **IDX** | PENDING / RUNNING / SUCCESS / SUCCESS_WITH_WARNINGS / FAILED / SKIPPED / CANCELLED — **per tenant**. This is what makes "did school X succeed?" answerable at all. |
| `started_at` / `completed_at` | TIMESTAMP NULL | | *"Scheduling (Started at, Completed at, Status)"* at tenant granularity. |
| `duration_seconds` | INT UNSIGNED | **GEN** | Per-tenant duration; identifies the school that is slowing the whole window. |
| `throughput_mbps` | DECIMAL(10,2) | | Transfer rate; separates a big tenant from a slow network path. |
| `attempt_no` | TINYINT UNSIGNED | | Per-item retry count. |
| `error_code` / `error_message` / `warning_message` | VARCHAR/TEXT | | Per-tenant failure detail — one school's failure no longer hides behind a run-level message. |
| `skip_reason` | VARCHAR(255) | | Why skipped (tenant suspended, excluded, no data). Distinguishes "deliberately skipped" from "quietly missed". |

### Verification

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `verification_status` | ENUM(5) | **IDX** | NOT_VERIFIED / PENDING / PASSED / FAILED / EXPIRED. |
| `last_verified_at` | TIMESTAMP NULL | | Age of the last integrity check. |
| `last_test_restore_at` | TIMESTAMP NULL | | Last real restore drill. |
| `is_restorable` | TINYINT(1) | | Set to 0 when verification fails. **Hides a known-bad backup from the restore picker** so nobody discovers the corruption during an actual emergency. |

### Offsite & tiering

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `has_offsite_copy` | TINYINT(1) | Second copy exists. |
| `offsite_destination_id` | INT UNSIGNED NULL | **FK.** Where. |
| `offsite_copied_at` | TIMESTAMP NULL | When. |
| `storage_class` | ENUM(5) | HOT → DEEP_ARCHIVE. Old backups move to cheap tiers automatically. |
| `tier_transitioned_at` | TIMESTAMP NULL | When it moved. |
| `restore_lead_time_hours` | SMALLINT UNSIGNED NULL | **Thaw time.** A DEEP_ARCHIVE object can take 12 hours to become readable. The tenant must be told that up front, not discover it mid-emergency. |

### RETENTION — the heart of the requirement

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `retention_policy_id` | INT UNSIGNED NULL | **FK** | Policy applied. Stored per item so changing the policy later does not retroactively shorten existing backups. |
| `retention_class` | ENUM(7) | | DAILY / WEEKLY / MONTHLY / YEARLY / MANUAL / PRE_RESTORE / LEGAL_HOLD. Which GFS tier this occupies — decides which copies survive thinning. |
| `retention_start_date` | DATE | | Clock start (normally the backup date). |
| `retention_days` | SMALLINT UNSIGNED | | Effective days granted at creation. |
| `original_retention_end_date` | DATE | | **Immutable.** What the tenant was originally entitled to, before any extension. The evidence in a billing dispute; written once, never updated. |
| `retention_end_date` | DATE | **IDX** | **THE "Backup End Date".** The single date the whole retention system turns on, and the only field a paid extension moves. |
| `grace_end_date` | DATE | | `retention_end_date + policy.grace_period_days`. Physical deletion happens after *this*, not after the end date — a last window to pay for an extension. |
| `extension_count` | TINYINT UNSIGNED | | How many times extended. Enforces `max_extensions_allowed`. |
| `total_extended_days` | SMALLINT UNSIGNED | | Cumulative extension. |
| `last_extension_request_id` | INT UNSIGNED NULL | **FK** | Which request last moved the date. Deferred FK. |
| `is_legal_hold` | TINYINT(1) | **IDX** | **Blocks all purge, regardless of dates.** For litigation or a government inspection. Overrides even a manual delete. |
| `legal_hold_reason` / `legal_hold_by` / `legal_hold_at` | VARCHAR/INT/TIMESTAMP | **FK** | Who froze it, why and when — a legal hold must itself be auditable. |
| `is_locked` | TINYINT(1) | | Provider-side object lock (WORM) applied. Cannot be deleted even by a cloud admin. |

### Purge lifecycle

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `purge_status` | ENUM(9) | **IDX** | ACTIVE / EXPIRING_SOON / EXPIRED / PENDING_APPROVAL / APPROVED_FOR_PURGE / PURGED / PURGE_FAILED / ON_HOLD / EXTENDED. Composite-indexed with `retention_end_date` so the nightly purge scan is a single range scan. |
| `expiry_warning_sent_json` | JSON | | `{"30":"2026-06-27","7":"2026-07-20"}`. Dedupe ledger — the warning job can run hourly and each warning still goes out exactly once. |
| `purge_approved_by` / `purge_approved_at` | INT/TIMESTAMP | **FK** | Who authorised destruction. |
| `purged_at` | TIMESTAMP NULL | | When the data was destroyed. |
| `purge_log_id` | INT UNSIGNED NULL | **FK** | The purge batch. Deferred FK. |

### Access & billing

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `download_count` / `restore_count` | SMALLINT UNSIGNED | Usage. A backup restored three times is clearly valuable; one never touched in five years is a purge candidate. |
| `last_accessed_at` / `last_accessed_by` | TIMESTAMP/INT | **FK.** Who last touched this backup — a security-relevant fact. |
| `is_billable` | TINYINT(1) | Counts toward the tenant's storage bill (over quota, or held under a paid extension). |
| `remarks` | VARCHAR(500) | Notes. |
| *audit columns* | | |

---

## 9. `mnt_backup_files`

**Purpose:** The physical file catalogue. Covers multi-volume archives *and* the same archive replicated to several destinations.
**One row = one physical object on one destination.**
**PK is BIGINT UNSIGNED** — row count is tenants × content types × parts × copies × runs, which passes 2 billion far sooner than any other table here.

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | BIGINT UNSIGNED | **PK** | High-volume table. |
| `file_uuid` | CHAR(36) | **UQ** | Stable reference for download links. |
| `backup_run_item_id` | INT UNSIGNED | **FK, UQ** | Parent logical backup. |
| `backup_run_id` | INT UNSIGNED | **FK, IDX** | Denormalised — lets "all files of run X" skip a join on a billion-row table. |
| `tenant_id` | INT UNSIGNED NULL | **FK, IDX** | Denormalised — makes per-tenant storage sums a single indexed scan. |
| `copy_type` | ENUM(6) | **UQ** | PRIMARY / OFFSITE_REPLICA / ARCHIVE_TIER / TAPE / LOCAL_CACHE / EXPORT_COPY. **Each copy is a real, independently deletable object** and must be tracked separately — otherwise you cannot prove the offsite copy exists or that every copy was destroyed at purge. |
| `source_file_id` | BIGINT UNSIGNED NULL | **FK, IDX** | The PRIMARY this replica came from. Self-referencing. |
| `part_no` / `total_parts` | SMALLINT UNSIGNED | **UQ** | Volume number of a split archive. Unique on (item, copy_type, part_no) so part 3 cannot be registered twice. |
| `storage_destination_id` | INT UNSIGNED | **FK, IDX** | Which destination holds it. |
| `disk_name` | VARCHAR(60) | | Laravel disk key. |
| `directory_path` | VARCHAR(500) | | **Folder only** — *"Backup File Storage Location (Path…)"*. |
| `file_name` | VARCHAR(255) | **IDX** | **File only** — *"…File name"*. Indexed so support can search by the filename a user quotes. |
| `full_path` | VARCHAR(760) | | Convenience concatenation, maintained by the model. Not indexed (too long for a utf8mb4 index without a prefix). |
| `relative_path` | VARCHAR(500) | | Path relative to the destination's `base_path` — survives the destination being remounted elsewhere. |
| `external_object_key` | VARCHAR(500) | | S3 key / Google Drive fileId. Cloud objects are addressed by key, not filesystem path. |
| `external_version_id` | VARCHAR(120) | | Object version, where the provider supports versioning — how an accidental overwrite is recovered. |
| `public_url` | VARCHAR(760) | | **Must stay NULL.** A non-null value means backups are publicly reachable, which is a reportable breach. Present so a linter can detect it. |
| `file_type` | ENUM(12) | | DB_DUMP / ARCHIVE / IMAGE / VIDEO / PDF / DOCUMENT / AUDIO / MANIFEST / CHECKSUM / LOG / CONFIG / OTHER — *"File Info (…type)"*. |
| `file_extension` | VARCHAR(20) | | Extension. |
| `mime_type` | VARCHAR(120) | | Content type for the download response. |
| `size_bytes` | BIGINT UNSIGNED | | *"File Info (Size…)"* — actual bytes stored. |
| `original_size_bytes` | BIGINT UNSIGNED NULL | | Pre-compression size. |
| `is_compressed` / `compression_type` | TINYINT/ENUM(7) | | How to decompress. |
| `is_encrypted` / `encryption_algo` / `encryption_key_ref` | TINYINT/VARCHAR/VARCHAR | | How to decrypt, and where the key lives (a **reference**, never the key). |
| `checksum_algo` / `checksum_value` | ENUM(6)/VARCHAR(128) | **IDX** | Per-file hash. Indexed to detect duplicate files across tenants and reclaim space via deduplication. |
| `etag` | VARCHAR(120) | | Provider-side integrity token. Comparing it detects a corrupted upload without downloading the file back. |
| `upload_status` | ENUM(8) | **IDX** | PENDING / UPLOADING / UPLOADED / VERIFIED / FAILED / DELETED / **MISSING** / **CORRUPT**. MISSING = the catalogue says it exists but storage disagrees — the exact scenario that destroys trust in a backup system, and it must be detectable *before* a restore. |
| `uploaded_at` / `upload_duration_seconds` | TIMESTAMP/INT | | Transfer timing. |
| `storage_class` | ENUM(5) | | Tier. |
| `is_immutable_locked` / `object_lock_until` | TINYINT/DATE | | WORM lock and its expiry. The purge job must skip these until the date passes. |
| `last_integrity_check_at` | TIMESTAMP NULL | | Last scrub. |
| `integrity_check_result` | ENUM(5) | | NOT_CHECKED / OK / CHECKSUM_MISMATCH / NOT_FOUND / UNREADABLE. Detects silent bit-rot on long-term storage. |
| `error_message` | TEXT | | Failure detail. |
| `is_deleted` | TINYINT(1) | | Physical object removed. **The catalogue row is kept** — it is the evidence that the data was destroyed. |
| `deleted_from_storage_at` | TIMESTAMP NULL | | When it was physically removed. |
| `purge_log_id` | INT UNSIGNED NULL | **FK** | Which purge batch removed it. Deferred FK. |
| `download_count` | SMALLINT UNSIGNED | | Access counter. |
| *audit columns* | | | |

---

## 10. `mnt_backup_verifications`

**Purpose:** Evidence that a backup is actually usable — checksum, archive-open, schema check, or a full test restore.
**One row = one verification attempt.**
**New in v2.** Without this table you never learn a backup is corrupt until you need it.

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | INT UNSIGNED | **PK** | |
| `verification_uuid` | CHAR(36) | **UQ** | External reference. |
| `backup_run_item_id` | INT UNSIGNED | **FK, IDX** | Which backup was verified. |
| `backup_run_id` / `tenant_id` | INT UNSIGNED NULL | **FK, IDX** | Denormalised for reporting. |
| `verification_type` | ENUM(7) | **IDX** | CHECKSUM / FILE_EXISTS / ARCHIVE_INTEGRITY / SCHEMA_VALIDATION / **TEST_RESTORE** / ROW_COUNT_MATCH / DR_DRILL — escalating levels of confidence. Cheap checks run always; expensive ones periodically. |
| `trigger_type` | ENUM(6) | | AUTO_POST_BACKUP / SCHEDULED_DRILL / MANUAL / PRE_RESTORE / **PRE_PURGE** / AUDIT. PRE_PURGE is mandatory before destroying a tenant's last backup. |
| `status` | ENUM(7) | **IDX** | PENDING / RUNNING / PASSED / PASSED_WITH_WARNINGS / FAILED / SKIPPED / ERROR. |
| `expected_checksum` / `actual_checksum` | VARCHAR(128) | | Both stored so a mismatch is self-evidencing rather than a bare "failed". |
| `expected_size_bytes` / `actual_size_bytes` | BIGINT UNSIGNED | | Size drift — a truncated upload shows here first. |
| `files_checked_count` / `files_failed_count` | INT UNSIGNED | | Scope and outcome of the scan. |
| `expected_table_count` / `actual_table_count` | SMALLINT UNSIGNED | | Schema completeness — catches a dump that stopped halfway. |
| `expected_row_count` / `actual_row_count` | BIGINT UNSIGNED | | Data completeness for TEST_RESTORE. |
| `sandbox_db_name` | VARCHAR(100) | | Throwaway database used for the test restore. **Never a live tenant DB.** |
| `sandbox_dropped_at` | TIMESTAMP NULL | | Proof of cleanup. A sandbox left running is a full copy of student data sitting unmonitored. |
| `started_at` / `completed_at` | TIMESTAMP NULL | **IDX** | Timing. |
| `duration_seconds` | INT UNSIGNED | **GEN** | How long. A test restore's duration is the **real measured RTO** — the honest input to the SLA promise. |
| `result_json` | JSON | | Per-file / per-table detail. |
| `failure_reason` | TEXT | | Why it failed. |
| `next_verification_due` | DATE | **IDX** | Drives the recurring drill schedule from `policy.test_restore_frequency_days`. |
| `verified_by` | INT UNSIGNED NULL | **FK** | NULL = system. |
| *audit columns* | | | |

---

# LAYER 4 — RESTORE

---

## 11. `mnt_restore_requests`

**Purpose:** The *ask* and the *approval* for a restore — kept separate from execution because a restore that overwrites a live school database is the single most destructive operation in the platform.
**One row = one restore request.**
**New in v2** — v1 had no restore side at all despite the module being titled "Backup & Restore".

### Identity & source

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | INT UNSIGNED | **PK** | |
| `request_uuid` | CHAR(36) | **UQ** | External reference. |
| `request_no` | VARCHAR(40) | **UQ** | `RST-2026-07-27-0003`. |
| `tenant_id` | INT UNSIGNED NULL | **FK, IDX** | School being restored. |
| `tenant_code` / `tenant_name` | VARCHAR | **SNAP** | Identity at request time. |
| `backup_run_item_id` | INT UNSIGNED NULL | **FK, IDX** | Source backup. **RESTRICT** — a backup referenced by a live restore request cannot be purged out from under it. |
| `backup_run_id` | INT UNSIGNED NULL | **FK** | Source run. |
| `source_backup_date` | DATE | **SNAP** | Backup date, for the UI without a join. |
| `point_in_time_at` | DATETIME NULL | | PITR target. Requires LOG backups covering base → target. |

### What and where

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `restore_type` | ENUM(7) | FULL_DATABASE / SELECTED_TABLES / FILES_ONLY / SINGLE_FILE / POINT_IN_TIME / SANDBOX_CLONE / DOWNLOAD_ONLY. Most real incidents need one table or one file back, not a full rollback. |
| `target_type` | ENUM(5) | SAME_TENANT_OVERWRITE / NEW_SANDBOX_DB / ALTERNATE_TENANT / DOWNLOAD_TO_ADMIN / EXTERNAL_HANDOVER. **The blast-radius field** — it decides how many approvals are required. |
| `target_tenant_id` | INT UNSIGNED NULL | **FK.** Destination when restoring into a different tenant. |
| `target_database_name` | VARCHAR(100) | Explicit target DB. Removes any ambiguity about where the data lands. |
| `target_storage_path` | VARCHAR(500) | Destination for file restores. |
| `selected_tables_json` / `selected_files_json` | JSON | Exact scope of a partial restore. |
| `overwrite_existing` | TINYINT(1) | Whether existing data is replaced. |
| `truncate_before_restore` | TINYINT(1) | Whether target tables are emptied first — separated from `overwrite_existing` because they are genuinely different risks. |

### Justification & risk

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `reason_category` | ENUM(11) | DATA_LOSS / DATA_CORRUPTION / ACCIDENTAL_DELETION / RANSOMWARE / MIGRATION / AUDIT / LEGAL / TESTING / DR_DRILL / TENANT_REQUEST / OTHER. Categorised so incident trends are reportable. |
| `reason` | TEXT NOT NULL | **Mandatory.** No restore without a stated reason. |
| `business_justification` | TEXT | Fuller context for high-risk restores. |
| `risk_level` | ENUM(4) | LOW…CRITICAL. Drives the approval path. |
| `requires_downtime` | TINYINT(1) | Whether the school goes offline. |
| `estimated_downtime_minutes` | SMALLINT UNSIGNED | What the school is told in advance. |
| `maintenance_window_id` | INT UNSIGNED NULL | **FK.** Window this runs in. Mandatory for a destructive overwrite. |
| `requires_pre_restore_backup` | TINYINT(1) | **The safety net.** Take a fresh backup *before* overwriting, so a bad restore is itself reversible. Defaults to 1. |
| `pre_restore_run_id` | INT UNSIGNED NULL | **FK.** The safety backup actually taken — the rollback source. |

### Requester

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `requested_by_user_id` | INT UNSIGNED NULL | **FK, IDX** | Central (PG) user. |
| `requested_by_tenant_user_id` | INT UNSIGNED NULL | | Tenant-side user id. **Intentionally FK-less** — tenant users live in `tenant_db`, which `prime_db` cannot reference. |
| `requested_by_name` / `requested_by_email` | VARCHAR | **SNAP** | Which is exactly why the name and email are snapshotted — the record must stay readable without a cross-database join. |
| `requested_by_type` | ENUM(5) | | PG_ADMIN / PG_SUPPORT / TENANT_ADMIN / SYSTEM / API. |
| `requested_at` | TIMESTAMP NULL | | **When the request was raised.** |
| `requester_ip_address` | VARCHAR(45) | | Origin IP — forensic evidence for a destructive action. |

### Approval — dual control

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `status` | ENUM(12) | **IDX** | DRAFT → PENDING_APPROVAL → APPROVED → SCHEDULED → IN_PROGRESS → COMPLETED / PARTIALLY_COMPLETED / FAILED / ROLLED_BACK; plus REJECTED, CANCELLED, EXPIRED. |
| `requires_dual_approval` | TINYINT(1) | | Forced to 1 for SAME_TENANT_OVERWRITE. |
| `approver1_user_id` / `approver1_at` / `approver1_remark` | INT/TIMESTAMP/VARCHAR | **FK** | First approver. |
| `approver2_user_id` / `approver2_at` / `approver2_remark` | INT/TIMESTAMP/VARCHAR | **FK** | Second approver. Must differ from approver 1 *and* from the requester — **self-approval is prohibited**, the standard control against a single compromised or mistaken account destroying a school's data. |
| `rejected_by` / `rejected_at` / `rejection_reason` | INT/TIMESTAMP/VARCHAR | **FK** | Rejection trail. |
| `tenant_consent_received` | TINYINT(1) | | The school signed off on their own data being overwritten. |
| `tenant_consent_at` / `tenant_consent_ref` | TIMESTAMP/VARCHAR | | When, and the ticket/email proving it. |

### Scheduling

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `scheduled_at` | DATETIME NULL | **IDX** | Planned execution time. |
| `expires_at` | DATETIME NULL | | **Approvals go stale.** An approval given in March must not authorise a restore in September. |
| `priority` | ENUM(4) | | LOW / NORMAL / HIGH / EMERGENCY. |
| `remarks` | VARCHAR(500) | | Notes. |
| *audit columns* | | | |

---

## 12. `mnt_restore_runs`

**Purpose:** Execution of an approved restore, with rollback tracking and SLA measurement.
**One row = one execution attempt.**

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | INT UNSIGNED | **PK** | |
| `run_uuid` / `run_no` | CHAR(36)/VARCHAR(40) | **UQ** | External and human references. |
| `restore_request_id` | INT UNSIGNED | **FK, UQ** | The authorising request. |
| `backup_run_item_id` | INT UNSIGNED NULL | **FK, IDX** | Source backup. RESTRICT. |
| `tenant_id` / `tenant_code` | INT/VARCHAR | **FK, IDX, SNAP** | Target school. |
| `attempt_no` | TINYINT UNSIGNED | **UQ** | Unique with request id, so retries are distinct rows rather than an overwritten history. |
| `status` | ENUM(14) | **IDX** | PENDING → QUEUED → PREPARING → DOWNLOADING → DECRYPTING → DECOMPRESSING → RESTORING → VERIFYING → COMPLETED; plus FAILED / CANCELLED / ROLLED_BACK / ROLLBACK_FAILED. Fine-grained because a restore is watched live by anxious people, and "which stage" is the first question asked. |
| `current_stage` / `progress_percent` | VARCHAR/TINYINT | | Live progress. |
| `target_database_name` / `target_storage_path` | VARCHAR | | Where data was actually written — may differ from the request if an operator adjusted it. |
| `queued_at` / `started_at` / `completed_at` | TIMESTAMP NULL | **IDX** | Timing. |
| `duration_seconds` | INT UNSIGNED | **GEN** | Total elapsed. |
| `downtime_start_at` / `downtime_end_at` | TIMESTAMP NULL | | Actual outage window — distinct from run duration, since download and decrypt happen before the school goes offline. |
| `actual_downtime_minutes` | SMALLINT UNSIGNED | | Measured outage, compared against what was promised. |
| `rto_target_minutes` | INT UNSIGNED NULL | | Target copied from the plan at execution time. |
| `rto_breached` | TINYINT(1) | | SLA breach flag — the headline metric of a DR report. |
| `bytes_downloaded` / `bytes_restored` | BIGINT UNSIGNED | | Volume moved. |
| `tables_restored_count` / `rows_restored_count` | SMALLINT/BIGINT | | Completeness — compared to the item's recorded counts to prove nothing was lost. |
| `files_restored_count` / `files_failed_count` | INT UNSIGNED | | File-restore outcome. |
| `post_restore_verified` | TINYINT(1) | | Post-restore sanity check passed. |
| `post_restore_check_json` | JSON | | Spot-check results on key tables. |
| `data_loss_window_minutes` | INT UNSIGNED NULL | | **Actual RPO achieved** — the gap between the backup and the incident, i.e. how much data was genuinely lost. The number the school will ask for. |
| `is_rolled_back` | TINYINT(1) | | This restore was undone. |
| `rollback_run_id` | INT UNSIGNED NULL | **FK** | The restore run that undid it (self-referencing). |
| `rolled_back_at` / `rollback_reason` | TIMESTAMP/VARCHAR | | Rollback trail. |
| `queue_job_id` / `worker_host` | VARCHAR | | Forensics. |
| `executed_by` / `executed_by_name` | INT/VARCHAR | **FK, IDX, SNAP** | Who ran it — snapshotted so accountability survives user deletion. |
| `error_code` / `error_message` / `error_trace` | VARCHAR/TEXT/MEDIUMTEXT | | Failure detail. |
| `warning_count` / `summary_json` / `remarks` | SMALLINT/JSON/VARCHAR | | Outcome detail. |
| *audit columns* | | | |

---

# LAYER 5 — RETENTION EXTENSION, ARCHIVE ACCESS, PURGE

---

## 13. `mnt_retention_extension_requests`

**Purpose:** Implements *"Tenant can demand (Paid Service) to extend the duration of keeping their data safe"* and *"We can extend the Backup End Date, if requested by Tenant."*
**One row = one extension request**, carrying the ask, the quote, the payment, the approval and the application.
**New in v2.**

### Identity & scope

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | INT UNSIGNED | **PK** | |
| `request_uuid` / `request_no` | CHAR(36)/VARCHAR(40) | **UQ** | `EXT-2026-07-27-0011`. |
| `tenant_id` | INT UNSIGNED | **FK, IDX** | The requesting school. |
| `tenant_code` / `tenant_name` | VARCHAR | **SNAP** | Identity at request time. |
| `maintenance_plan_id` / `retention_policy_id` | INT UNSIGNED NULL | **FK** | Plan and policy in force — the policy supplies the price book and the limits. |
| `scope_type` | ENUM(6) | | SINGLE_ITEM / SELECTED_ITEMS / ALL_ITEMS_IN_RUN / DATE_RANGE / ALL_TENANT_BACKUPS / FUTURE_BACKUPS. Schools ask in different shapes — "keep last March's data" is a DATE_RANGE, "keep everything" is ALL_TENANT_BACKUPS. |
| `backup_run_id` | INT UNSIGNED NULL | **FK** | For ALL_ITEMS_IN_RUN. |
| `scope_from_date` / `scope_to_date` | DATE | | For DATE_RANGE. CHECK enforces ordering. |
| `content_types_json` | JSON | | Limit to certain content — e.g. extend the database but let the videos expire. |
| `items_count` | SMALLINT UNSIGNED | | How many backups are covered. |
| `total_size_bytes` | BIGINT UNSIGNED | | Total volume — **the billing base**. |
| `total_size_gb` | DECIMAL(12,4) | **GEN** | `bytes / 1073741824`. Computed so the quoted GB can never disagree with the stored bytes. |

### The ask

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `requested_extension_days` | SMALLINT UNSIGNED | What the tenant asked for. CHECK > 0. |
| `requested_extension_months` | DECIMAL(6,2) NULL | The billing unit. |
| `current_end_date` | DATE | The earliest `retention_end_date` in scope — the deadline being extended. |
| `requested_new_end_date` | DATE | Desired new end date. |
| `granted_extension_days` | SMALLINT UNSIGNED NULL | What was actually approved — may be less than requested (policy cap, partial payment). |
| `granted_new_end_date` | DATE NULL | The new end date actually applied. |
| `reason` | TEXT | Why they want it. |
| `reason_category` | ENUM(8) | AUDIT / LEGAL_CASE / STATUTORY / ACCREDITATION / MIGRATION / DISPUTE / INTERNAL_REVIEW / OTHER. A STATUTORY reason may justify waiving the fee. |
| `priority` | ENUM(4) | Urgency — a request 2 days before deletion must jump the queue. |

### Requester

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `requested_by_user_id` | INT UNSIGNED NULL | **FK** | PG user raising it on the school's behalf. |
| `requested_by_tenant_user_id` | INT UNSIGNED NULL | | Tenant-side user (no FK — cross-database). |
| `requested_by_name` / `_email` / `_mobile` | VARCHAR | **SNAP** | Contact details — this is a commercial transaction and someone must be reachable about the quote. |
| `requested_by_type` | ENUM(5) | | TENANT_ADMIN / PG_ADMIN / PG_SUPPORT / SYSTEM / API. |
| `requested_at` | TIMESTAMP NULL | | **When the request was raised.** Also the lead-time check against the expiry date. |
| `requester_ip_address` | VARCHAR(45) | | Origin. |

### Commercial — the paid service

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `is_chargeable` | TINYINT(1) | | Paid vs free. Free requests skip the quote/payment states. |
| `is_waived` / `waiver_reason` / `waived_by` | TINYINT/VARCHAR/INT | **FK** | Fee waiver with reason and approver — a discount someone must own. |
| `rate_per_gb_month` / `flat_fee_month` | DECIMAL | | **Rates copied from the policy at quote time.** Stamped, not referenced: a later price rise must never change an already-issued quote. |
| `billable_months` | DECIMAL(6,2) | | `CEIL(granted_days / 30)`. |
| `sub_total` | DECIMAL(12,2) | | Before discount and tax. |
| `discount_percent` / `discount_amount` / `discount_remark` | DECIMAL/VARCHAR | | Discount, mirroring the `bil_*` tables' structure. |
| `tax_percent` / `tax_amount` | DECIMAL | | GST. |
| `total_amount` | DECIMAL(12,2) | | Payable. |
| `currency` | CHAR(3) | | |
| `quote_generated_at` | TIMESTAMP NULL | | When quoted. |
| `quote_valid_until` | DATE | | Quote expiry — prices and sizes both change. |
| `quote_accepted_at` / `quote_accepted_by_name` | TIMESTAMP/VARCHAR | | Acceptance evidence. |
| `payment_status` | ENUM(9) | **IDX** | NOT_APPLICABLE / PENDING_QUOTE / QUOTED / AWAITING_PAYMENT / PARTIALLY_PAID / PAID / FAILED / REFUNDED / WAIVED. |
| `paid_amount` / `paid_at` | DECIMAL/TIMESTAMP | | Payment received. |
| `tenant_invoice_id` | INT UNSIGNED NULL | **FK, IDX** | Link to `bil_tenant_invoices`. **Reuses the existing billing module** rather than inventing a parallel invoicing system. |
| `payment_reference` | VARCHAR(100) | | Gateway/transaction reference. |

### Approval & application

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `status` | ENUM(12) | **IDX** | DRAFT → SUBMITTED → UNDER_REVIEW → QUOTED → AWAITING_PAYMENT → APPROVED → APPLIED; plus REJECTED / PARTIALLY_APPLIED / CANCELLED / EXPIRED / FAILED. **APPROVED and APPLIED are deliberately separate** — approval is a decision, application is a database write that can itself fail. |
| `reviewed_by` / `reviewed_at` | INT/TIMESTAMP | **FK** | Commercial review. |
| `approved_by` / `approved_at` | INT/TIMESTAMP | **FK** | Approver. |
| `admin_remark` | TEXT | | Internal notes. |
| `rejected_by` / `rejected_at` / `rejection_reason` | INT/TIMESTAMP/VARCHAR | **FK** | Rejection trail. |
| `applied_at` / `applied_by` | TIMESTAMP/INT | **FK** | **When the end dates were actually moved.** |
| `items_applied_count` / `items_failed_count` | SMALLINT UNSIGNED | | Partial application outcome. |
| `apply_error_message` | TEXT | | Why application failed — e.g. an item was purged between approval and application. |
| `is_auto_renew` | TINYINT(1) | | Keep extending each cycle without a fresh request. |
| `next_renewal_date` | DATE | **IDX** | When the auto-renewal fires. |
| `previous_request_id` | INT UNSIGNED NULL | **FK, IDX** | Chain of successive extensions on the same data — shows the full commercial history. |
| *audit columns* | | | |

---

## 14. `mnt_retention_extension_item_jnt`

**Purpose:** Exactly which backups an extension covered, and the before/after dates.
**One row = one (extension request, backup item) pair.**
**Why it matters:** this table is what makes an extension **reversible** and **auditable**. Without `previous_end_date` stored per item, a refunded extension could only be undone by guesswork.

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | INT UNSIGNED | **PK** | |
| `extension_request_id` | INT UNSIGNED | **FK, UQ** | The request. |
| `backup_run_item_id` | INT UNSIGNED | **FK, UQ, IDX** | The backup extended. Unique together — one item cannot be extended twice by the same request. |
| `previous_end_date` | DATE NOT NULL | | **The rollback source.** The exact value before this extension. |
| `new_end_date` | DATE NOT NULL | | Value after. CHECK enforces `new > previous` — an "extension" can never shorten retention. |
| `extended_days` | SMALLINT UNSIGNED | | Days added to this specific item. |
| `item_size_bytes` | BIGINT UNSIGNED | | **Size at quote time** — billing evidence. The backup may grow or shrink later; the invoice must reflect what was quoted. |
| `item_charge_amount` | DECIMAL(12,2) | | This item's share of the total. Supports a partial refund when only some items are reversed. |
| `apply_status` | ENUM(5) | **IDX** | PENDING / APPLIED / FAILED / REVERSED / SKIPPED. |
| `applied_at` / `reversed_at` / `reversal_reason` | TIMESTAMP/VARCHAR | | Application and reversal trail. |
| `error_message` | VARCHAR(500) | | Per-item failure. |
| *audit columns* | | | |

---

## 15. `mnt_archive_access_requests`

**Purpose:** Implements *"It needs to facilitate the Tenant that they can raise a request to access Archived Database for a certain period."*
**One row = one access request.**
**Rewrite of v1's `mnt_tenant_archive_access_requests`** — which did not compile (a `;` where a `,` belonged, and a UNIQUE KEY on a commented-out column) and had no lifecycle beyond four status values. The `tenant_` infix was dropped as redundant inside a `mnt_` table.

### Identity & target archive

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | INT UNSIGNED | **PK** | |
| `request_uuid` / `request_no` | CHAR(36)/VARCHAR(40) | **UQ** | `ARC-2026-07-27-0004`. |
| `tenant_id` | INT UNSIGNED NOT NULL | **FK, IDX** | The school. **v1 had this column commented out while still indexing it** — the table could not be created. |
| `tenant_code` | VARCHAR(20) | **SNAP, IDX** | *v1 field.* Retained as a snapshot alongside the proper FK. |
| `tenant_name` | VARCHAR(150) | **SNAP** | Identity at request time. |
| `archive_reference` | VARCHAR(255) | **IDX** | *v1 `archive_tenant_id`, renamed.* A free-form pointer to the archive when it predates the catalogue (legacy archives, external media). |
| `backup_run_item_id` | INT UNSIGNED NULL | **FK, IDX** | The specific catalogued backup. **RESTRICT** — an archive under an open access request cannot be purged. |
| `backup_run_id` | INT UNSIGNED NULL | **FK** | Source run. |
| `archived_academic_year` | VARCHAR(20) | | `'2019-2020'`. **How schools actually ask** — "give me the 2019-20 records", not "give me item UUID a3f…". Makes the request form usable by a school clerk. |
| `archive_from_date` / `archive_to_date` | DATE | | Date-range form of the same ask. CHECK enforces ordering. |
| `content_types_json` | JSON | | Which content is needed. |
| `access_mode` | ENUM(5) | | READ_ONLY_DB / REPORT_ONLY / FILE_DOWNLOAD / SANDBOX_FULL / EXPORT_EXTRACT. **Least-privilege**: a school wanting one old TC does not need a full writable clone. |
| `specific_modules_json` / `specific_tables_json` | JSON | | Narrow the exposure further — e.g. StudentProfile only. |

### Duration

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `requested_duration_minutes` | INT UNSIGNED NULL | *v1 field.* How long they asked for. |
| `granted_duration_minutes` | INT UNSIGNED NULL | *v1 field.* How long was granted — may be shorter. |
| `requested_from_at` / `requested_to_at` | DATETIME | Preferred window. A school may need access specifically during an inspection. |
| `max_sessions_allowed` | TINYINT UNSIGNED | How many separate sessions the approval permits. |
| `max_concurrent_users` | TINYINT UNSIGNED | Concurrency cap — stops one approval becoming shared access for a whole office. |

### Justification

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `purpose_category` | ENUM(10) | AUDIT / LEGAL / ALUMNI_RECORD / TC_ISSUE / CERTIFICATE_REISSUE / GOVT_INSPECTION / ACCREDITATION / PARENT_QUERY / INTERNAL_REVIEW / OTHER. These are the real reasons a school reopens old data. |
| `purpose` | TEXT NOT NULL | **Mandatory.** Access to archived student PII always needs a stated reason. |
| `supporting_document_ref` | VARCHAR(255) | Court order, inspection notice, `sys_media` reference — evidence supporting the request. |

### Requester (all four v1 columns retained)

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `requested_by_user_id` | INT UNSIGNED NULL | **FK, IDX** | *v1 field.* PG user. |
| `requested_by_tenant_user_id` | INT UNSIGNED NULL | | *v1 field.* Tenant-side user id. **v1 typed this BIGINT with no target table; corrected to INT UNSIGNED and documented as intentionally FK-less** (cross-database). |
| `requested_by_tenant_user_email` | VARCHAR(150) | **SNAP** | *v1 field.* Widened from 255→150 to match `sys_users.email`. |
| `requested_by_tenant_user_name` | VARCHAR(100) | **SNAP** | *v1 field.* |
| `requested_by_designation` | VARCHAR(100) | | Principal / Clerk / Auditor — authority matters when granting access to archived PII. |
| `requested_by_mobile` | VARCHAR(32) | | Contact for the one-time credential handover. |
| `requested_at` | TIMESTAMP NULL | | **When the request was raised.** |
| `requester_ip_address` | VARCHAR(45) | | Origin. |

### Commercial

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `is_chargeable` | TINYINT(1) | | Archive retrieval can itself be a paid service — thawing from DEEP_ARCHIVE has a real provider cost. |
| `charge_amount` / `tax_amount` / `total_amount` / `currency` | DECIMAL/CHAR | | Fee breakdown. |
| `payment_status` | ENUM(5) | | NOT_APPLICABLE / AWAITING_PAYMENT / PAID / WAIVED / REFUNDED. |
| `tenant_invoice_id` | INT UNSIGNED NULL | **FK** | Billing link. |

### Approval (v1 columns retained, types corrected)

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `status` | ENUM(11) | **IDX** | DRAFT / PENDING / UNDER_REVIEW / APPROVED / REJECTED / **PROVISIONING** / **ACTIVE** / EXPIRED / REVOKED / COMPLETED / FAILED. v1 had only 4 values and could not express "approved but the sandbox is still being built". |
| `approved_by_user_id` | INT UNSIGNED NULL | **FK** | *v1 field.* **v1 declared this BIGINT UNSIGNED while `sys_users.id` is INT UNSIGNED — a type mismatch that made an FK impossible, and none was declared.** Corrected to INT UNSIGNED with a proper FK. |
| `approved_at` | TIMESTAMP NULL | | *v1 field.* |
| `admin_remark` | TEXT | | *v1 field.* |
| `rejected_by_user_id` / `rejected_at` / `rejection_reason` | INT/TIMESTAMP/VARCHAR | **FK** | Rejection trail. |
| `revoked_by_user_id` / `revoked_at` / `revocation_reason` | INT/TIMESTAMP/VARCHAR | **FK** | **Early revocation** — access granted for 30 days can be cut off on day 2 if misuse is detected. v1 had a `revoked` status but nowhere to record who revoked it or why. |

### Access control

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `access_ip_address` | VARCHAR(45) | *v1 field.* Requester's IP at grant time. |
| `allowed_ip_list_json` | JSON | IP allow-list for the session — archived student data should not be reachable from an arbitrary network. |
| `require_mfa` | TINYINT(1) | Second factor. Defaults to 1. |
| `is_watermarked` | TINYINT(1) | Stamp exports with the requester's identity, so a leaked document is traceable. |
| `allow_download` / `allow_export` | TINYINT(1) | Default 0. Viewing and extracting are different privileges. |
| `nda_accepted` / `nda_accepted_at` | TINYINT/TIMESTAMP | Confidentiality acknowledgement before PII access. |

### Outcome

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `access_granted_at` | TIMESTAMP NULL | | When access opened. |
| `access_expired_at` | TIMESTAMP NULL | **IDX** | *v1 field.* **Hard expiry.** Indexed because a job scans it constantly to revoke and tear down expired access. |
| `sessions_created_count` | TINYINT UNSIGNED | | Sessions used against `max_sessions_allowed`. |
| `extension_count` | TINYINT UNSIGNED | | Times the access window was extended. |
| *audit columns* | | | |

> **Removed from v1 on purpose:** `UNIQUE KEY (tenant_id, archive_tenant_id)`. It would have allowed a school **one archive request per archive, ever** — so a school that requested 2019-20 data for an audit could never request it again for a court case. Repeat requests are normal; uniqueness belongs on `request_no`.

---

## 16. `mnt_archive_access_sessions`

**Purpose:** One time-boxed, credentialled session created from an approved request — plus a record of what was actually done during it.
**One row = one session.**
**New in v2.** An approval is a decision; a session is live access to real student data, and it needs its own credentials, expiry, audit trail and teardown.

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | INT UNSIGNED | **PK** | |
| `session_uuid` | CHAR(36) | **UQ** | External reference. |
| `archive_access_request_id` | INT UNSIGNED | **FK, UQ** | Authorising request. |
| `tenant_id` | INT UNSIGNED | **FK, IDX** | School. |
| `backup_run_item_id` | INT UNSIGNED NULL | **FK, IDX** | Archive being read. **RESTRICT** — cannot purge a backup with a live session on it. |
| `session_no` | TINYINT UNSIGNED | **UQ** | Sequence within the request, capped by `max_sessions_allowed`. |
| `access_mode` | ENUM(5) | | Mode actually provisioned. |
| `sandbox_db_name` / `sandbox_db_host` / `sandbox_db_username` | VARCHAR | | The throwaway restored database. Named explicitly so the cleanup job knows exactly what to drop. |
| `sandbox_credential_ref` | VARCHAR(255) | | **Vault reference — never a plaintext password.** |
| `sandbox_url` | VARCHAR(500) | | Read-only UI entry point. |
| `access_token_hash` | VARCHAR(255) | | **Hash only.** A stored token is a bearer credential to archived student data. |
| `is_read_only` | TINYINT(1) | | Archived data must not be modifiable — an archive that can be edited is no longer evidence. |
| `provisioned_at` / `provisioning_duration_sec` | TIMESTAMP/INT | | How long the sandbox took to build — sets the tenant's expectation next time. |
| `valid_from` / `valid_until` | DATETIME | **IDX** | **The "certain period" from the requirement.** CHECK enforces ordering; indexed with `status` for the expiry sweep. |
| `status` | ENUM(8) | **IDX** | PROVISIONING / ACTIVE / IDLE / EXPIRED / REVOKED / TERMINATED / FAILED / CLEANED_UP. |
| `auto_extend_allowed` / `extension_count` | TINYINT | | Whether the session window may be extended. |
| `first_login_at` / `last_activity_at` / `login_count` | TIMESTAMP/SMALLINT | | Usage pattern. An approved session never logged into is worth reviewing before granting the next one. |
| `query_count` / `records_viewed_count` | INT UNSIGNED | | Volume of access — the difference between looking up one alumnus and scraping the whole student table. |
| `downloads_count` / `exports_count` / `bytes_transferred` | SMALLINT/BIGINT | | Data leaving the platform. The key exfiltration signal. |
| `accessed_modules_json` | JSON | | Which areas were opened — checked against the stated purpose. |
| `accessed_from_ip` / `user_agent` | VARCHAR | | Origin of actual use vs the approved IP list. |
| `mfa_verified_at` | TIMESTAMP NULL | | Proof the second factor was satisfied. |
| `suspicious_activity_flag` | TINYINT(1) | | Bulk export, off-hours access, IP mismatch. Auto-raised for review. |
| `suspicious_activity_note` | VARCHAR(500) | | What triggered it. |
| `terminated_at` / `terminated_by` / `termination_reason` | TIMESTAMP/INT/VARCHAR | **FK** | Manual termination trail. |
| `sandbox_dropped_at` | TIMESTAMP NULL | | **Proof the temporary copy was destroyed.** A sandbox left running is an unmonitored full copy of a school's data. |
| `cleanup_status` / `cleanup_error` | ENUM(3)/VARCHAR | **IDX** | PENDING / DONE / FAILED. Indexed so failed cleanups are found and fixed rather than forgotten. |
| *audit columns* | | | |

---

## 17. `mnt_purge_logs`

**Purpose:** Implements *"After that pre-defined period, we can remove the old Backup."* — and, more importantly, **proves** it was done correctly.
**One row = one purge batch.** Affected items and files point back here via `purge_log_id`.
**New in v2.**

### Identity & scope

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | INT UNSIGNED | **PK** | |
| `purge_uuid` / `purge_no` | CHAR(36)/VARCHAR(40) | **UQ** | `PRG-2026-07-27-0002`. |
| `purge_type` | ENUM(8) | **IDX** | SCHEDULED_RETENTION / MANUAL / STORAGE_RECLAIM / TENANT_OFFBOARDING / **GDPR_ERASURE** / DUPLICATE_CLEANUP / CORRUPT_CLEANUP / FAILED_RUN_CLEANUP. Different types carry different approval and evidence requirements. |
| `purge_reason` | VARCHAR(500) | | Narrative reason. |
| `tenant_id` | INT UNSIGNED NULL | **FK, IDX** | Affected school. NULL = cross-tenant batch. |
| `tenant_code` / `tenant_name` | VARCHAR | **SNAP** | **Mandatory snapshots.** The FK is `ON DELETE SET NULL` because the proof that a school's data was destroyed must outlive the school's own record. |
| `storage_destination_id` / `retention_policy_id` | INT UNSIGNED NULL | **FK** | Where from, and under which policy. |
| `selection_criteria_json` | JSON | | **The exact filter used.** Makes the selection reproducible — you can re-run the query later and show an auditor why these rows were chosen. |
| `dry_run` | TINYINT(1) | | Preview mode: computes and records everything, deletes nothing. The standard safety practice before a manual purge. |

### Volume & evidence

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `items_selected_count` / `items_purged_count` / `items_skipped_count` / `items_failed_count` | INT UNSIGNED | | Outcome tally. Selected ≠ purged is the interesting case, and it must be visible. |
| `files_deleted_count` | INT UNSIGNED | | Physical objects removed. |
| `bytes_reclaimed` | BIGINT UNSIGNED | | Space recovered. |
| `gb_reclaimed` | DECIMAL(14,4) | **GEN** | Readable form for the report. |
| `purged_items_json` | JSON | | **The destruction manifest** — `[{item_id, tenant_code, end_date, bytes}]`. The item rows survive, but this is the self-contained record an auditor can read without joining anything. |
| `skipped_items_json` | JSON | | Skipped items **with reasons** — proves a legal-hold item was correctly *not* deleted. |
| `earliest_backup_date` / `latest_backup_date` | DATE | | Date span destroyed. |

### Safety gates

Every flag must be 1 before deletion. Each guards a different real failure.

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `pre_purge_verified` | TINYINT(1) | A newer, verified backup exists. Never destroy the old copy before confirming the new one works. |
| `legal_hold_checked` | TINYINT(1) | No held item is in scope. |
| `active_sessions_checked` | TINYINT(1) | Nobody is currently reading the archive. |
| `chain_dependency_checked` | TINYINT(1) | No incremental is left orphaned by removing its base. |
| `min_retention_respected` | TINYINT(1) | The statutory floor is honoured. |
| `tenant_notified` / `tenant_notified_at` | TINYINT/TIMESTAMP | The school was told before their data was destroyed. |
| `is_recoverable` / `recoverable_until` | TINYINT/DATE | Whether the destination's versioning/trash allows undelete, and until when. Turns "it's gone" into a definite answer. |

### Approval

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `requires_approval` | TINYINT(1) | | From the retention policy. |
| `approval_status` | ENUM(4) | **IDX** | NOT_REQUIRED / PENDING / APPROVED / REJECTED. |
| `approved_by` / `approved_at` / `approval_remark` | INT/TIMESTAMP/VARCHAR | **FK** | First approver. |
| `second_approved_by` / `second_approved_at` | INT/TIMESTAMP | **FK** | Second approver — required for GDPR/DPDP erasure, which is irreversible by design. |
| `rejected_by` / `rejected_at` / `rejection_reason` | INT/TIMESTAMP/VARCHAR | **FK** | Rejection trail. |

### Execution & compliance

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `status` | ENUM(9) | **IDX** | PENDING / APPROVED / QUEUED / RUNNING / COMPLETED / COMPLETED_WITH_ERRORS / FAILED / CANCELLED / SKIPPED. |
| `started_at` / `completed_at` / `duration_seconds` | TIMESTAMP/INT | **IDX, GEN** | Timing. |
| `executed_by` / `executed_by_name` | INT/VARCHAR | **FK, IDX, SNAP** | Who ran it — snapshotted, since this is the record of a destructive act. |
| `executed_by_type` | ENUM(4) | | USER / SYSTEM / CRON / API. |
| `executor_ip_address` | VARCHAR(45) | | Origin of a destructive action. |
| `error_code` / `error_message` | VARCHAR/TEXT | | Failure detail. |
| `destruction_certificate_no` | VARCHAR(60) | | Formal certificate issued for a data-erasure request. What a school hands to a regulator or a parent exercising erasure rights. |
| `certificate_issued_at` | TIMESTAMP NULL | | When issued. |
| `compliance_tag` | VARCHAR(60) | | Regime this purge satisfies. |
| *audit columns* | | | |

---

# LAYER 6 — OBSERVABILITY

---

## 18. `mnt_activity_logs`

**Purpose:** Implements *"It should capture the complete Log for all the activities of the backup Module."*
**One row = one event.** Polymorphic across all 20 tables. **Append-only.**
**PK is BIGINT UNSIGNED** — the highest-volume table in the module.
**New in v2.**

### Subject

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | BIGINT UNSIGNED | **PK** | Very high volume. |
| `log_uuid` | CHAR(36) | **UQ** | Stable event id — also the idempotency key when a retried job re-logs. |
| `correlation_id` | CHAR(36) | **IDX** | **Ties every log line of one operation together** (normally the run's `run_uuid`). One indexed lookup returns the complete narrative of a backup: dispatch, per-tenant progress, upload, verification, replication. |
| `entity_type` | ENUM(17) | **IDX** | Which table the event concerns. |
| `entity_id` | BIGINT UNSIGNED NULL | **IDX** | The row. BIGINT so it can hold `mnt_backup_files.id` (BIGINT) as well as every INT PK. |
| `entity_reference` | VARCHAR(60) | **IDX** | `run_no` / `request_no`. **Human search key** — support has a reference number, not a row id. |
| `backup_run_id` / `backup_run_item_id` | INT UNSIGNED NULL | **FK, IDX** | Direct filters for the most common queries. |
| `tenant_id` | INT UNSIGNED NULL | **FK, IDX** | Per-school activity report. |
| `tenant_code` | VARCHAR(20) | **SNAP** | Readable even after the tenant is removed. |

### Event

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `action_category` | ENUM(14) | **IDX** | CONFIG / SCHEDULE / BACKUP / VERIFY / REPLICATE / RESTORE / RETENTION / EXTENSION / ARCHIVE_ACCESS / PURGE / BILLING / SECURITY / NOTIFICATION / SYSTEM. Lets an auditor pull "all PURGE activity in FY 2026" in one query. |
| `action` | VARCHAR(60) | | `BACKUP_STARTED`, `EXTENSION_APPROVED`, `PURGE_EXECUTED`. |
| `stage` | VARCHAR(60) | | Sub-step (`DUMPING`, `UPLOADING`). |
| `severity` | ENUM(6) | **IDX** | DEBUG…CRITICAL. Indexed with `occurred_at` so "all CRITICAL events this week" is instant. |
| `outcome` | ENUM(5) | | SUCCESS / FAILURE / PARTIAL / PENDING / INFO. Severity is how loud; outcome is what happened. |
| `message` | VARCHAR(1000) | | Human-readable line. |
| `error_code` | VARCHAR(50) | | Machine-classifiable failure. |
| `context_json` | JSON | | Sizes, paths, counts, timings. |
| `old_values_json` / `new_values_json` / `changed_fields_json` | JSON | | **Before/after for configuration changes.** Answers "who shortened this school's retention from 90 to 30 days, and when?" — otherwise unanswerable. |

### Actor

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `actor_type` | ENUM(7) | | USER / TENANT_USER / SYSTEM / CRON / QUEUE_WORKER / API / WEBHOOK. |
| `performed_by_user_id` | INT UNSIGNED NULL | **FK, IDX** | Who did it. |
| `performed_by_name` / `performed_by_email` | VARCHAR | **SNAP** | Identity captured at event time — an audit log that degrades to "user #47 (deleted)" is not an audit log. |
| `impersonated_by_user_id` | INT UNSIGNED NULL | **FK** | Support acting on someone's behalf. **Both identities must be recorded** or impersonation launders accountability. |

### Request context

| Field | Type | Purpose / Why required |
|-------|------|------------------------|
| `ip_address` / `user_agent` | VARCHAR | Origin of the action. |
| `request_id` | VARCHAR(64) | Correlate with application HTTP logs. |
| `request_method` / `request_url` | VARCHAR | Which endpoint. |
| `session_id` | VARCHAR(100) | Session correlation. |
| `queue_job_id` / `worker_host` | VARCHAR | Which worker on which machine — for background events with no HTTP context. |

### Measurements

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `duration_ms` | INT UNSIGNED | | Step duration — builds a performance profile of the pipeline. |
| `bytes_affected` / `records_affected` | BIGINT/INT | | Volume. |
| `occurred_at` | DATETIME(3) | **IDX** | **Millisecond precision.** Several events of one run can land in the same second; without sub-second precision their true order is lost. |
| `created_at` | TIMESTAMP | | Insert time. A gap from `occurred_at` reveals a delayed/replayed log. |

> **No `updated_at`, `deleted_at`, `is_active` or `updated_by` — deliberately.** This table is append-only; a log that can be edited is not evidence. Enforce with a DB trigger or restricted grants in production.

---

## 19. `mnt_alert_dispatches`

**Purpose:** Every notification the module sends, with a dedupe key.
**One row = one message to one recipient on one channel.**
**New in v2.**

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | BIGINT UNSIGNED | **PK** | High volume. |
| `alert_uuid` | CHAR(36) | **UQ** | External reference. |
| `dedupe_key` | VARCHAR(180) | **UQ** | **The point of this table.** `EXPIRY_WARN:item:48211:30`. Unique with `channel`, so the expiry-warning job can run hourly and each warning still goes out exactly once. Without it, a school gets 24 identical "your backup expires in 30 days" emails a day. |
| `alert_type` | ENUM(33) | **IDX** | Every event worth telling someone about — backup failure, storage low, expiry warning, extension quoted, purge scheduled, restore completed, suspicious access, SLA breach. |
| `severity` | ENUM(4) | **IDX** | INFO / WARNING / ERROR / CRITICAL. CRITICAL ignores quiet hours. |
| `entity_type` / `entity_id` / `entity_reference` | VARCHAR/BIGINT/VARCHAR | **IDX** | What the alert is about. |
| `tenant_id` / `backup_run_id` / `backup_run_item_id` | INT UNSIGNED NULL | **FK, IDX** | Direct links. |
| `channel` | ENUM(8) | | EMAIL / SMS / WHATSAPP / IN_APP / PUSH / WEBHOOK / SLACK / TEAMS. Part of the dedupe key — the same alert may legitimately go by both email and SMS. |
| `recipient_type` | ENUM(7) | | PG_ADMIN / PG_SUPPORT / TENANT_ADMIN / TENANT_USER / ROLE_GROUP / EXTERNAL / SYSTEM. |
| `recipient_user_id` | INT UNSIGNED NULL | **FK, IDX** | Internal recipient. |
| `recipient_address` / `recipient_name` | VARCHAR | | Email / mobile / webhook URL. Stored so "who was actually told" survives a later contact change. |
| `template_code` | VARCHAR(60) | | Link to the Template / Notification module. |
| `subject` / `body_preview` | VARCHAR | | What was sent (preview only — the full body lives in the template). |
| `payload_json` | JSON | | Merge variables used, so the exact message can be reconstructed. |
| `notification_ref_id` | INT UNSIGNED NULL | | Id in the NTF module when delivery is delegated there. |
| `status` | ENUM(9) | **IDX** | QUEUED / SENDING / SENT / DELIVERED / READ / FAILED / BOUNCED / SUPPRESSED / CANCELLED. **DELIVERED ≠ SENT** — a bounced expiry warning means the school never learned their data was about to be deleted, which is exactly the dispute you need evidence for. |
| `scheduled_for` | DATETIME NULL | **IDX** | Deferred send (quiet hours). |
| `sent_at` / `delivered_at` / `read_at` | TIMESTAMP NULL | | Delivery milestones. |
| `retry_count` / `max_retries` / `next_retry_at` | TINYINT/TIMESTAMP | | Retry state. |
| `error_message` | VARCHAR(500) | | Delivery failure detail. |
| `suppression_reason` | VARCHAR(255) | | DUPLICATE / QUIET_HOURS / OPTED_OUT — why a message was intentionally not sent. |
| `requires_action` / `action_url` / `action_taken_at` | TINYINT/VARCHAR/TIMESTAMP | | Actionable alerts (approve extension, pay invoice) and whether the recipient acted. |
| *audit columns* | | | |

---

## 20. `mnt_storage_usage_snapshots`

**Purpose:** Daily per-tenant storage footprint. Feeds the storage-overage invoice and the "what will my extension cost" quote.
**One row = one (date, tenant, destination, content type, storage class) fact.**
**New in v2.**

| Field | Type | Key | Purpose / Why required |
|-------|------|-----|------------------------|
| `id` | BIGINT UNSIGNED | **PK** | One row per tenant per day per dimension — grows fast. |
| `snapshot_date` | DATE | **UQ, IDX** | The day measured. |
| `tenant_id` / `tenant_code` | INT/VARCHAR | **FK, UQ, IDX, SNAP** | The school. NULL = platform roll-up row. |
| `storage_destination_id` | INT UNSIGNED NULL | **FK, UQ** | Per destination. NULL = all combined. |
| `content_type` | ENUM(10) | **UQ** | Per content type — shows a school that video, not the database, is driving their bill. |
| `storage_class` | ENUM(6) | **UQ** | Per tier — HOT and DEEP_ARCHIVE have very different costs. |
| `backup_items_count` / `backup_files_count` | INT UNSIGNED | | Object counts. |
| `total_bytes` | BIGINT UNSIGNED | | Everything stored. |
| `total_gb` | DECIMAL(14,4) | **GEN** | Readable form. |
| `billable_bytes` / `billable_gb` | BIGINT/DECIMAL | **GEN** | Only what is chargeable — beyond quota or held under a paid extension. Separated so a school can see they are inside their free allowance. |
| `extended_retention_bytes` | BIGINT UNSIGNED | | Held **only** because of a paid extension. Proves the extension revenue against real storage. |
| `legal_hold_bytes` | BIGINT UNSIGNED | | Held for legal reasons — normally not billed, and needs to be visible separately. |
| `offsite_bytes` | BIGINT UNSIGNED | | Offsite copy volume — a real cost often forgotten in pricing. |
| `bytes_added_today` / `bytes_purged_today` | BIGINT UNSIGNED | | Daily movement. |
| `net_change_bytes` | BIGINT **signed** | | Signed on purpose — **negative on heavy purge days**. An UNSIGNED column would wrap to a nonsense value. |
| `growth_percent` | DECIMAL(8,3) | | Growth rate — forecasts when the school exceeds its quota. |
| `oldest_backup_date` / `newest_backup_date` | DATE | | Retention span held. |
| `earliest_expiry_date` | DATE | | Next thing due to disappear. |
| `items_expiring_in_30_days` | SMALLINT UNSIGNED | | **The upsell signal** — the account team's cue to offer an extension before the data is gone. |
| `items_on_legal_hold` | SMALLINT UNSIGNED | | Held item count. |
| `included_quota_gb` | INT UNSIGNED | | Free allowance from the plan, snapshotted so a later plan change does not rewrite history. |
| `overage_gb` | DECIMAL(14,4) | | Billable excess. |
| `estimated_cost` / `currency` | DECIMAL/CHAR | | Cost for the day. |
| `is_billed` | TINYINT(1) | **IDX** | Already invoiced — prevents double billing. |
| `tenant_invoice_id` | INT UNSIGNED NULL | **FK, IDX** | The invoice that consumed this row. |
| `computed_at` / `created_at` | TIMESTAMP | | When calculated. |

> **Why daily and not monthly:** GB-month billing is `AVG(billable_gb)` over the period — not the peak and not the last day. A school that held 900 GB for 3 days and 100 GB for 27 should not be billed for 900. Only a daily row makes that computable.

---

# APPENDIX A — v1 → v2 column mapping

| v1 table.column | v2 location | Change |
|-----------------|-------------|--------|
| `mnt_backup_schedules.label` | same | kept |
| `mnt_backup_schedules.databases_json` | `target_scope` + `mnt_schedule_tenant_jnt` + `content_scope_json` | replaced — a blob cannot be joined or indexed |
| `mnt_backup_schedules.all_tenants` | `target_scope = 'ALL_TENANTS'` | replaced — boolean could not express group/subset |
| `mnt_backup_schedules.include_files` | `mnt_maintenance_plans.backup_*` flags + `content_scope_json` | replaced — one flag could not distinguish images / video / PDF |
| `mnt_backup_schedules.cron_expression` | same (+ `timezone`) | kept, timezone added |
| `mnt_backup_schedules.is_active` | same (+ `is_paused`) | kept |
| `mnt_backup_schedules.last_run_at` / `next_run_at` | same | kept |
| `mnt_backup_schedules.created_by` | same | **NOT NULL + CASCADE → nullable + SET NULL** |
| `mnt_backup_runs.name` | same | kept |
| `mnt_backup_runs.databases_json` / `all_tenants` | `mnt_backup_run_items` (one row per tenant) | replaced |
| `mnt_backup_runs.include_files` | same | kept |
| `mnt_backup_runs.status` | same | ENUM extended (`PARTIALLY_FAILED`, `QUEUED`, `TIMED_OUT`, `SKIPPED`) |
| `mnt_backup_runs.progress` | `progress_percent` | renamed + CHECK 0–100 |
| `mnt_backup_runs.disk_path` / `remote_disk` / `remote_path` | `mnt_storage_destinations` + `mnt_backup_files` | replaced |
| `mnt_backup_runs.file_size_bytes` | same (+ `total_stored_bytes`) | kept as mirror |
| `mnt_backup_runs.started_at` / `completed_at` | same (+ `queued_at`, `duration_seconds`) | kept |
| `mnt_backup_runs.triggered_by` | same (+ `triggered_by_name`, `triggered_by_type`) | kept |
| `mnt_backup_runs.error_message` | same (+ `error_code`, `error_trace`) | kept |
| `mnt_tenant_archive_access_requests` | `mnt_archive_access_requests` | renamed |
| `…tenant_id` (commented out) | `tenant_id` INT UNSIGNED NOT NULL + FK | **restored — table could not be created without it** |
| `…tenant_code` | same | kept |
| `…archive_tenant_id` | `archive_reference` | renamed and clarified |
| `…requested_by_user_id` | same | kept |
| `…requested_by_tenant_user_id` | same | BIGINT → INT UNSIGNED |
| `…requested_by_tenant_user_email` / `_name` | same | kept |
| `…status` | same | ENUM 4 → 11 values |
| `…approved_by_user_id` | same | **BIGINT → INT UNSIGNED + FK added** |
| `…approved_at`, `…admin_remark` | same | kept |
| `…requested_duration_minutes` / `granted_duration_minutes` | same | kept |
| `…access_ip_address` | same (+ `allowed_ip_list_json`) | kept |
| `…access_expired_at` | same | kept |
| `UNIQUE (tenant_id, archive_tenant_id)` | — | **dropped** — would allow only one archive request per archive, ever |

---

# APPENDIX B — Index strategy

| Query the UI/jobs actually run | Index that serves it |
|--------------------------------|----------------------|
| Scheduler: what runs next? | `mnt_backup_schedules(is_active, is_paused, next_run_at)` |
| Backup history for one school | `mnt_backup_run_items(tenant_id, content_type, created_at)` |
| Nightly purge scan | `mnt_backup_run_items(purge_status, retention_end_date)` |
| Expiry warning sweep | `mnt_backup_run_items(retention_end_date)` |
| "Show me this run's log" | `mnt_activity_logs(backup_run_id, occurred_at)` |
| Full narrative of one operation | `mnt_activity_logs(correlation_id)` |
| Critical events this week | `mnt_activity_logs(severity, occurred_at)` |
| Per-tenant storage total | `mnt_backup_files(tenant_id, is_deleted)` |
| Expire archive sessions | `mnt_archive_access_sessions(valid_until, status)` |
| Duplicate-alert suppression | `mnt_alert_dispatches(dedupe_key, channel)` UNIQUE |
| Monthly billing extract | `mnt_storage_usage_snapshots(tenant_id, snapshot_date)` |

---

# APPENDIX C — FK delete-behaviour rationale

| Relationship | Behaviour | Why |
|--------------|-----------|-----|
| `*` → `sys_users` | **SET NULL** | A staff member leaving must never delete configuration or history. Name snapshots preserve accountability. |
| `mnt_backup_run_items` → `prm_tenant` | **RESTRICT** | Deleting a school must not silently destroy the evidence of its backups. Off-boarding is an explicit purge workflow. |
| `mnt_backup_files` → `prm_tenant` | **RESTRICT** | Same. |
| `mnt_purge_logs` → `prm_tenant` | **SET NULL** | The proof of destruction must outlive the tenant record — hence the mandatory snapshots. |
| `mnt_backup_runs.parent_run_id` | **RESTRICT** | A FULL backup with incremental children cannot be deleted without silently breaking every child. |
| `mnt_backup_run_items.parent_item_id` | **RESTRICT** | Same, at item level. |
| `mnt_backup_run_items` → `mnt_backup_runs` | **CASCADE** | Items have no meaning without their run. |
| `mnt_backup_files` → `mnt_backup_run_items` | **CASCADE** | Files have no meaning without their item. |
| `mnt_restore_requests` → `mnt_backup_run_items` | **RESTRICT** | Cannot purge a backup an open restore depends on. |
| `mnt_archive_access_*` → `mnt_backup_run_items` | **RESTRICT** | Cannot purge an archive someone is authorised to read. |
| `*` → `mnt_storage_destinations` | **RESTRICT** | A destination holding live backups cannot be removed. |
| `*` → `mnt_retention_policies` | **RESTRICT** | A policy in use cannot be removed. |
| `*` → `bil_tenant_invoices` | **SET NULL** | Billing corrections must not cascade into the backup catalogue. |
