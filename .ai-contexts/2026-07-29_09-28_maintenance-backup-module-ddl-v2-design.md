# Context: Maintenance (MNT) Backup/Archive/Retention/Restore Module — DDL v1 evaluation and full v2 redesign (3 → 20 tables) with Data Dictionary and Process Flow
# Saved: 2026-07-29 09:28
# Session Duration: Single working session (started 2026-07-27, saved 2026-07-29)
# Project: PrimeAI

---

## 1. SESSION OBJECTIVE

The user asked to build a complete **Maintenance Management Module** for backing up the Prime-AI application's database AND media files (images, videos, PDFs), keeping them for a defined period, then either purging them or extending the retention period on request (as a **paid service**).

Specifically requested:
1. Read and **evaluate** the existing DDL at `2-DDL_Tenant_Enhanced/Maintenance_DDL_v1.sql`
2. **Enhance** it and save as `1-DDL_Modules/Maintenance/Maintenance_DDL_v2.sql`
3. Create a **Data Dictionary** — explain EVERY field of EVERY table: what it is used for and why it is required
4. Create a **Process Flow** document capturing the complete process flow of the module

Functional requirements the user listed:
- Schedule different maintenance plans for different Schools (Tenants)
- Capture detail of all Maintenance activities (Backup & Restore)
- Capture information about all Backups performed historically
- Backup info: storage location (path, file name), file info (size, type), scheduling (started at, completed at, status), who raised the request and when, tenant detail (tenant name, code, DB name)
- Capture the complete Log for all activities of the backup Module
- Facilitate Tenants raising requests to access Archived Database for a certain period
- Backups kept for a certain period; Tenant can demand (Paid Service) to extend duration
- Ability to extend the Backup End Date if requested by Tenant
- **"Include any other point which I may have missed"** ← user explicitly invited scope expansion

Original prompt file: `7-CLAUDE_Prompts/Z-Temp_Prompts/Prompt_2026Jul27.md` (lines 5–25 selected in IDE).

---

## 2. SUMMARY OF WORK DONE

- Read and analysed v1 DDL (3 tables, 94 lines) at `2-DDL_Tenant_Enhanced/Maintenance_DDL_v1.sql`
- Read `AI_Brain/memory/conventions.md` for naming/prefix/audit-column conventions
- Read `0-DDL_Masters/prime_db_v4.sql` to establish exact FK anchor types: `sys_users.id` = INT UNSIGNED, `prm_tenant.id` = INT UNSIGNED, `prm_tenant_groups.id` = INT UNSIGNED, `prm_tenant_domains` (holds `db_name`, `db_host`), `bil_tenant_invoices.id` = INT UNSIGNED
- Discovered a **prefix collision**: `1-DDL_Modules/_Maintenance/Claude_Plan/MNT_DDL_v1.sql` is a COMPLETELY DIFFERENT module (physical asset/ticket/AMC maintenance, 11 tables, `tenant_db`) also using `mnt_` prefix
- Confirmed from `0-Prime_Ai_Detail/module_list.md`: Maintenance = code MNT, prefix `mnt_`, assigned to **Tarun**
- Found **4 hard SQL syntax errors** in v1 that mean it could never have been executed
- Found ~10 convention violations and ~12 major functional gaps
- Designed and wrote **v2 DDL: 20 tables across 6 layers** (1,990 lines)
- Wrote **Data Dictionary** (1,377 lines) — every field of every table with a "why required" justification, plus 3 appendices
- Wrote **Process Flow** (975 lines) — 12 end-to-end flows with Mermaid diagrams, state machines, cron schedule, permission matrix, 28 business rules
- Ran structural validation via a Python script: 20 balanced `CREATE TABLE` statements, no duplicate constraint names, all FK targets resolve
- Confirmed no MySQL binary available locally → flagged that validation is **structural only**, not parser-verified

---

## 3. FILES TOUCHED

### Created:
- `1-DDL_Modules/Maintenance/Maintenance_DDL_v2.sql` (1,990 lines / 146 KB) — Full v2 DDL. Contains an inline EVALUATION section (categories A/B/C/D) documenting every v1 defect, a 20-table inventory, all CREATE TABLEs, deferred FK ALTERs, 2 reporting views, seed data for 4 retention policies, and a change log.
- `1-DDL_Modules/Maintenance/Maintenance_Data_Dictionary_v2.md` (1,377 lines / 102 KB) — Field-by-field dictionary. Every column carries a "Purpose / Why required" answering *what breaks if this field is missing*. Includes Appendix A (v1→v2 column mapping), Appendix B (index strategy vs actual queries), Appendix C (FK delete-behaviour rationale).
- `1-DDL_Modules/Maintenance/Maintenance_Process_Flow_v2.md` (975 lines / 50 KB) — 12 process flows with Mermaid diagrams, 6 state machines, 17 scheduled jobs, permission matrix, 28 business rules (BR-MNT-01..28), 22 implied screens, requirement-coverage traceability table, 8-phase implementation sequence, 6 open decisions.

### Discussed/Reviewed (not modified):
- `2-DDL_Tenant_Enhanced/Maintenance_DDL_v1.sql` — the source being evaluated. **Left untouched** (user asked to save the enhanced version to a new path).
- `AI_Brain/memory/conventions.md` — module prefix table, DB conventions, naming rules.
- `0-DDL_Masters/prime_db_v4.sql` — FK anchor types and existing table patterns (`sys_users`, `prm_tenant`, `prm_tenant_domains`, `prm_tenant_groups`, `prm_plans`, `bil_tenant_invoices`, `bil_tenant_invoicing_payments`, `bil_tenant_invoicing_audit_logs`).
- `0-Prime_Ai_Detail/module_list.md` — confirmed MNT/`mnt_` registration and Tarun's ownership.
- `1-DDL_Modules/_Maintenance/Claude_Plan/MNT_TableSummary.md` + `Readme.md` — the OTHER (asset) maintenance module; source of the prefix-collision finding.

---

## 4. KEY DECISIONS & RATIONALE

- **Decision:** Target `prime_db`, NOT `global_db` (which v1 declared) and NOT `tenant_db`.
  **Why:** This is a control-plane module that backs up every tenant DB. Its catalogue cannot live inside a tenant database — a corrupt/dropped tenant DB would take its own backup catalogue with it (worst possible failure mode). All FK anchors it needs (`prm_tenant`, `prm_tenant_domains`, `sys_users`, `bil_tenant_invoices`) already live in `prime_db`.
  **Alternatives Considered:** `global_db` per v1 header — rejected because the anchors aren't there.

- **Decision:** Keep the `mnt_` prefix but formally flag the collision and RECOMMEND renaming to `bkp_`.
  **Why:** `module_list.md` registers MNT/`mnt_`, so changing unilaterally would desync the master reference. The other `mnt_` module lives in `tenant_db`, so there is no hard schema collision today — but the ambiguity will cost debugging time. Recorded as Open Decision #1.
  **Alternatives Considered:** Rename immediately to `bkp_` — deferred to the user's call.

- **Decision:** Three-level execution catalogue — RUN → ITEM → FILE.
  **Why:** v1 collapsed all three into one row, which is exactly why it could not answer "did school X's photo backup succeed last Tuesday, and where is the file?" RUN = one execution; ITEM = one tenant × one content type; FILE = one physical object (also covers multi-volume splits AND primary/offsite/archive copies as separate deletable objects).

- **Decision:** `mnt_backup_run_items` owns retention, with BOTH `original_retention_end_date` (immutable) and `retention_end_date` (mutable).
  **Why:** `retention_end_date` is the "Backup End Date" the tenant pays to extend. `original_retention_end_date` is written once and never updated — it is the evidence of the original entitlement in a billing dispute. Enforced by CHECK `chk_mntRunItems_extensionOnly` so an "extension" can never shorten retention.

- **Decision:** Snapshot tenant identity onto `mnt_backup_run_items` (`tenant_code`, `tenant_name`, `tenant_group_code`, `database_name`, `database_host`, `domain_name`) rather than relying on joins.
  **Why:** Directly satisfies the "Tenant detail (Tenant Name, Code, DB Name etc.)" requirement, AND a school that renames/merges must still be findable in history under the name it had on the backup date.

- **Decision:** `mnt_backup_run_items` → `prm_tenant` FK is **RESTRICT**, not CASCADE.
  **Why:** Deleting a tenant must never silently destroy the evidence of their backups. Off-boarding is an explicit purge workflow (`purge_type = 'TENANT_OFFBOARDING'`).

- **Decision:** `mnt_purge_logs` → `prm_tenant` FK is **SET NULL** (opposite of the above).
  **Why:** The proof that a school's data was destroyed must OUTLIVE the school's record. Hence `tenant_code`/`tenant_name` snapshots are mandatory on that table specifically.

- **Decision:** Extension pricing is **stamped into the request row** at quote time, not referenced from the policy.
  **Why:** A price rise next month must never retroactively change an already-issued quote.

- **Decision:** Separate `APPROVED` and `APPLIED` states on extension requests, with a junction table storing `previous_end_date` per item.
  **Why:** Approval is a decision; application is a DB write that can itself fail (e.g. an item got purged in between). And `previous_end_date` makes a refund/reversal exact rather than guesswork.

- **Decision:** Reuse `bil_tenant_invoices` for extension billing rather than inventing parallel invoicing.
  **Why:** The Billing module already exists in `prime_db` with tax/discount/payment structure. FK is SET NULL so billing corrections never cascade into the backup catalogue.

- **Decision:** PKs are INT UNSIGNED (matching `prime_db`) except BIGINT UNSIGNED on 4 high-volume tables: `mnt_backup_files`, `mnt_activity_logs`, `mnt_alert_dispatches`, `mnt_storage_usage_snapshots`.
  **Why:** v1 used BIGINT everywhere, violating the `prime_db` standard and breaking FK compatibility with `sys_users.id` (INT UNSIGNED). But file/log row counts genuinely exceed 2^31.

- **Decision:** Status values as ENUM, not `sys_dropdown_table`.
  **Why:** These are state machines with code branching on each value, not user-configurable lists. Recorded as Open Decision #2.

- **Decision:** `mnt_activity_logs` is append-only — no `updated_at`, `deleted_at`, `is_active`, `updated_by`.
  **Why:** A log that can be edited is not evidence. Documented as a deliberate audit-column exception.

- **Decision:** Encryption fields store a **key REFERENCE** (`encryption_key_ref` = vault path), never the key.
  **Why:** A key stored next to the ciphertext is not encryption — and the ciphertext here IS a database dump.

- **Decision:** Deliberately DROPPED v1's `UNIQUE KEY (tenant_id, archive_tenant_id)` on the archive access table.
  **Why:** It would have allowed a school exactly ONE archive request per archive, forever. A school that requested 2019-20 data for an audit could never request it again for a court case. Uniqueness moved to `request_no`.

- **Decision:** Purge deletes OFFSITE/ARCHIVE copies FIRST, PRIMARY last.
  **Why:** If deletion is interrupted halfway, the surviving copy is the primary — fastest to restore and the one the catalogue points at. Deleting primary first would leave a cold-tier copy with a 12-hour thaw.

---

## 5. TECHNICAL DETAILS & PATTERNS

### Six-layer architecture
- **Layer 1 — Config masters:** `mnt_storage_destinations`, `mnt_retention_policies`, `mnt_maintenance_plans`
- **Layer 2 — Scheduling:** `mnt_backup_schedules`, `mnt_schedule_tenant_jnt`, `mnt_maintenance_windows`
- **Layer 3 — Execution catalogue:** `mnt_backup_runs`, `mnt_backup_run_items`, `mnt_backup_files`, `mnt_backup_verifications`
- **Layer 4 — Restore:** `mnt_restore_requests`, `mnt_restore_runs`
- **Layer 5 — Retention/Archive/Purge:** `mnt_retention_extension_requests`, `mnt_retention_extension_item_jnt`, `mnt_archive_access_requests`, `mnt_archive_access_sessions`, `mnt_purge_logs`
- **Layer 6 — Observability:** `mnt_activity_logs`, `mnt_alert_dispatches`, `mnt_storage_usage_snapshots`

### Naming conventions followed (matching prime_db_v4.sql style)
- Indexes: `idx_<abbrevTable>_<camelCaseCols>` e.g. `idx_mntRunItems_purgeStatus_retentionEnd`
- Unique: `uq_<abbrevTable>_<cols>` e.g. `uq_mntBackupRuns_runNo`
- FKs: `fk_<abbrevTable>_<col>` e.g. `fk_mntRunItems_tenantId`
- Checks: `chk_<abbrevTable>_<rule>` e.g. `chk_mntRunItems_extensionOnly`
- Junction tables suffixed `_jnt`
- JSON columns suffixed `_json`
- ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci on every table

### Generated-column pattern for conditional uniqueness (borrowed from prime_db_v4.sql's `super_admin_flag` / `current_flag`)
- `mnt_storage_destinations.default_flag` = `CASE WHEN is_default=1 THEN 1 ELSE NULL END` STORED + UNIQUE → guarantees exactly ONE default destination at DB level
- `mnt_maintenance_plans.current_plan_flag` = `CASE WHEN (is_current=1 AND deleted_at IS NULL) THEN IFNULL(tenant_id,0) ELSE NULL END` STORED + UNIQUE → guarantees ONE live plan per tenant; `IFNULL(...,0)` folds the platform-default (tenant_id NULL) plan into the same rule

### Other generated columns used
- `duration_seconds` = `TIMESTAMPDIFF(SECOND, started_at, completed_at)` STORED — on runs, items, verifications, restore runs, purge logs
- `compression_ratio` = `stored_size_bytes / original_size_bytes` STORED
- `total_size_gb` / `gb_reclaimed` / `total_gb` / `billable_gb` = `bytes / 1073741824` STORED

### Retention stamping formula (executed ONCE at item creation)
```
retention_start_date        = DATE(completed_at)
retention_days              = COALESCE(schedule_tenant.retention_days_override,
                                       schedule.retention_days_override,
                                       policy.default_retention_days)
original_retention_end_date = retention_start_date + retention_days   -- IMMUTABLE
retention_end_date          = original_retention_end_date             -- extensions move THIS only
grace_end_date              = retention_end_date + policy.grace_period_days
retention_class             = derived from schedule.frequency
purge_status                = 'ACTIVE'
```

### Extension pricing formula (stamped at quote time)
```
total_size_gb   = total_size_bytes / 1073741824
billable_months = CEIL(granted_extension_days / 30)
sub_total       = MAX(policy.extension_min_charge,
                      (policy.extension_flat_fee_month
                       + policy.extension_rate_per_gb_month * total_size_gb) * billable_months)
discount_amount = sub_total * discount_percent / 100
tax_amount      = (sub_total - discount_amount) * tax_percent / 100
total_amount    = sub_total - discount_amount + tax_amount
```
Worked example in the docs: 12 GB, 180 days, ₹4.00/GB/month, 18% GST → sub_total ₹288.00, tax ₹51.84, total ₹339.84

### Five purge safety gates (ALL must be 1 before deletion)
1. `pre_purge_verified` — a newer verified backup exists
2. `legal_hold_checked` — no `is_legal_hold = 1` in scope
3. `active_sessions_checked` — no archive session in PROVISIONING/ACTIVE/IDLE
4. `chain_dependency_checked` — no child item with `parent_item_id = this.id`
5. `min_retention_respected` — statutory floor honoured
Plus: `is_locked = 0` and `object_lock_until` in the past.

### Restore approval matrix
| target_type | Approvals | Pre-restore backup | Window | Tenant consent |
|---|---|---|---|---|
| NEW_SANDBOX_DB | 1 | no | no | no |
| DOWNLOAD_TO_ADMIN | 1 | no | no | no |
| ALTERNATE_TENANT | 2 | recommended | no | yes |
| SAME_TENANT_OVERWRITE | 2 | MANDATORY | MANDATORY | MANDATORY |
| EXTERNAL_HANDOVER | 2 + legal | no | no | yes |
Hard rule: `approver1 ≠ approver2 ≠ requester` — self-approval prohibited.

### Reporting views created
- `v_mnt_backup_history` — joins runs + items; the main "Backup History" grid source; includes `days_to_expiry = DATEDIFF(retention_end_date, CURDATE())`
- `v_mnt_purge_candidates` — encapsulates the eligibility logic including NOT EXISTS subqueries for chain children and active archive sessions

### Deferred FK block (avoids circular CREATE order)
```sql
ALTER TABLE mnt_backup_schedules  ADD fk_mntSchedule_lastRunId      -> mnt_backup_runs
ALTER TABLE mnt_backup_run_items  ADD fk_mntRunItems_lastExtReqId   -> mnt_retention_extension_requests
ALTER TABLE mnt_backup_run_items  ADD fk_mntRunItems_purgeLogId     -> mnt_purge_logs
ALTER TABLE mnt_backup_files      ADD fk_mntBackupFiles_purgeLogId  -> mnt_purge_logs
```

### Seed data included
4 retention policies: `TRIAL_30D` (30d), `STD_90D` (90d, ₹4/GB/mo), `GOLD_365D` (365d, ₹3/GB/mo), `STATUTORY_7Y` (2555d, free extension)

---

## 6. DATABASE CHANGES

**20 new tables in `prime_db`** (DDL written, NOT executed against any server):

| # | Table | Purpose |
|---|---|---|
| 1 | `mnt_storage_destinations` | Physical storage targets (local/S3/Wasabi/GDrive/SFTP/tape) |
| 2 | `mnt_retention_policies` | GFS tiers + retention bounds + extension price book |
| 3 | `mnt_maintenance_plans` | Per-tenant plan: policy + destinations + scope + SLA + quota |
| 4 | `mnt_backup_schedules` | Cron definitions (ENHANCED from v1) |
| 5 | `mnt_schedule_tenant_jnt` | Explicit tenant targeting / per-tenant opt-out |
| 6 | `mnt_maintenance_windows` | Announced downtime windows |
| 7 | `mnt_backup_runs` | Run header (ENHANCED from v1) |
| 8 | `mnt_backup_run_items` | **THE CATALOGUE** — one per tenant × content type; owns retention |
| 9 | `mnt_backup_files` | Physical files (BIGINT PK); multi-volume + multi-copy |
| 10 | `mnt_backup_verifications` | Checksum / archive / schema / test-restore evidence |
| 11 | `mnt_restore_requests` | Restore ask + dual approval |
| 12 | `mnt_restore_runs` | Restore execution + rollback + RTO measurement |
| 13 | `mnt_retention_extension_requests` | **PAID EXTENSION** — ask, quote, payment, approval, apply |
| 14 | `mnt_retention_extension_item_jnt` | Per-item before/after dates (makes reversal exact) |
| 15 | `mnt_archive_access_requests` | REWRITE of v1's `mnt_tenant_archive_access_requests` |
| 16 | `mnt_archive_access_sessions` | Time-boxed credentialled session + usage audit + teardown |
| 17 | `mnt_purge_logs` | Deletion evidence + safety gates + destruction certificates |
| 18 | `mnt_activity_logs` | Append-only full module trail (BIGINT PK) |
| 19 | `mnt_alert_dispatches` | Notifications with `dedupe_key` UNIQUE (BIGINT PK) |
| 20 | `mnt_storage_usage_snapshots` | Daily per-tenant GB facts for billing (BIGINT PK) |

**Views:** `v_mnt_backup_history`, `v_mnt_purge_candidates`
**Seeds:** 4 rows in `mnt_retention_policies`
**Migration file:** NOT written this session.
**v1 file:** left untouched at `2-DDL_Tenant_Enhanced/Maintenance_DDL_v1.sql`.

---

## 7. PROBLEMS ENCOUNTERED & SOLUTIONS

- **Problem:** v1 DDL contains a `;` instead of a `,` after the `INDEX idx_mnt_taar_archiveTenantId_status (...)` line in `mnt_tenant_archive_access_requests`.
  **Cause:** Typo — terminates the CREATE TABLE statement mid-definition.
  **Solution:** Rewrote the table entirely as `mnt_archive_access_requests`. Documented as EVALUATION item A1.

- **Problem:** v1's `UNIQUE KEY uq_mnt_taar_tenantId_archiveTenantId (tenant_id, archive_tenant_id)` references `tenant_id`, but that column is commented out on the line above.
  **Cause:** Column was commented out during editing but the index referencing it was left in place.
  **Solution:** Restored `tenant_id` as INT UNSIGNED NOT NULL with a proper FK to `prm_tenant`. Documented as A2.

- **Problem:** v1's `approved_by_user_id` declared BIGINT UNSIGNED while `sys_users.id` is INT UNSIGNED — an FK is impossible, and none was declared.
  **Cause:** Type assumption not checked against `prime_db_v4.sql`.
  **Solution:** Changed to INT UNSIGNED and added `fk_mntArcReq_approvedBy ... ON DELETE SET NULL`. Documented as A3.

- **Problem:** v1's `mnt_backup_schedules.created_by` was `NOT NULL` with `ON DELETE CASCADE` to `sys_users`.
  **Cause:** Copy-paste of a CASCADE pattern to a column where it is semantically wrong.
  **Solution:** Made nullable with `ON DELETE SET NULL` — deleting a staff member must not delete their backup schedules. Documented as B3.

- **Problem:** No MySQL/mysqld/docker binary available in the environment to parse-verify the DDL.
  **Cause:** Local machine has no MySQL client installed.
  **Solution:** Wrote a Python validation script instead — stripped comments, split on `;`, verified 20 balanced `CREATE TABLE` statements, checked paren balance per statement, verified all `REFERENCES` targets resolve to known tables, and checked for duplicate constraint names (none). **Explicitly told the user validation is structural only** and recommended running `mysql --execute` against a scratch schema before committing.

- **Problem:** zsh glob error on `grep -rln "..." --include=*.sql .` — "no matches found".
  **Cause:** zsh expands `*.sql` before grep sees it.
  **Solution:** Quoted the pattern: `--include="*.sql"`.

- **Problem:** Circular FK dependencies (schedule→run, run_items→extension_requests, run_items→purge_logs, files→purge_logs).
  **Cause:** Legitimate bidirectional relationships across creation order.
  **Solution:** Declared those columns without inline FKs and added a DEFERRED FOREIGN KEYS block of `ALTER TABLE` statements after all 20 CREATE TABLEs.

---

## 8. CURRENT STATE OF WORK

### Completed:
- v1 evaluation — 4 hard SQL errors (A1–A4), 4 convention violations (B1–B4), 10 functional gaps (C1–C10), 12 unlisted-but-needed points (D1–D12). All documented INSIDE the v2 DDL header.
- `Maintenance_DDL_v2.sql` — complete, 20 tables, 2 views, seeds, deferred FKs, change log. 1,990 lines.
- `Maintenance_Data_Dictionary_v2.md` — complete, every field of every table documented with "why required". 1,377 lines. Appendices A (v1→v2 mapping), B (index strategy), C (FK delete rationale).
- `Maintenance_Process_Flow_v2.md` — complete. 975 lines. Flows A–L, 6 state machines, 17 cron jobs, permission matrix, BR-MNT-01..28, 22 screens, requirement coverage table, 8-phase implementation plan, 6 open decisions.
- Structural validation passed (balanced statements, no duplicate constraint names, all FK targets resolve).
- User was told about the prefix collision and the structural-only validation caveat.

### In Progress:
- Nothing mid-edit. All three deliverables are written to disk and complete.

### Not Yet Started:
- Laravel migration file (`MNT_Migration.php` equivalent) — not requested this session
- Seeder classes beyond the inline retention-policy INSERT
- Eloquent models / relationships
- Live parse verification against a real MySQL 8 server
- Update to `0-Prime_Ai_Detail/module_list.md` (DDL_FILE_NAME column still shows `Maintenance_DDL_` with no version)
- Module-knowledge file at `AI_Brain/module-knowledge/MNT_Maintenance.md` — does not exist
- No git commit made this session

---

## 9. OPEN QUESTIONS & TODOS

- [ ] Run the DDL against a scratch MySQL 8 schema to parse-verify (no MySQL binary locally; validation so far is structural only)
- [ ] **DECISION NEEDED:** rename prefix `mnt_` → `bkp_` to resolve the collision with the asset-maintenance module in `tenant_db`? Kept `mnt_` for now to stay aligned with `module_list.md`
- [ ] Write the Laravel migration for `prime_db` (INT UNSIGNED PKs, generated columns need raw `DB::statement` or `storedAs()`)
- [ ] Write seeders for `mnt_storage_destinations` (at least one with `is_offsite = 1` or the module raises a config warning)
- [ ] Decide the KMS/vault product for `encryption_key_ref` — must be settled before Phase 2 implementation
- [ ] Update `0-Prime_Ai_Detail/module_list.md` DDL_FILE_NAME for Maintenance
- [ ] Consider seeding `AI_Brain/module-knowledge/MNT_Maintenance.md`
- [?] Should this module be coordinated with **Tarun**, who owns Maintenance per `module_list.md`?
- [?] Open Decision #3: partition `mnt_activity_logs` by month? Recommendation was to DEFER until ~50M rows (partitioning requires dropping FKs)
- [?] Open Decision #4: tenants must never see other tenants' run status — needs a global scope on tenant-facing queries
- [?] Open Decision #6: retain `mnt_activity_logs` 24 months hot then cold archive — confirm with the user

---

## 10. IMPORTANT CONTEXT FOR FUTURE SESSIONS

### Critical facts to not re-derive
- `sys_users.id` = **INT UNSIGNED** (not BIGINT). Every FK to it must be INT UNSIGNED.
- `prm_tenant.id` = INT UNSIGNED. `prm_tenant.code` = VARCHAR(20). `prm_tenant.name` = VARCHAR(150).
- `prm_tenant_domains` holds `db_name` VARCHAR(100), `db_host` VARCHAR(200), `db_username`, `db_password` — this is where tenant DB connection info lives.
- `prm_tenant_groups.id` = INT UNSIGNED, `code` VARCHAR(20).
- `bil_tenant_invoices.id` = INT UNSIGNED — the billing anchor for paid extensions.
- `prime_db` uses `CREATE TABLE IF NOT EXISTS` and views over `global_master.*` for `glb_*` tables.
- There are TWO different "Maintenance" modules in this repo. `1-DDL_Modules/_Maintenance/` = physical asset/ticket/AMC (tenant_db). `1-DDL_Modules/Maintenance/` = backup/archive (prime_db, this work).

### The single most important table
`mnt_backup_run_items` — it IS the backup catalogue. It owns:
- `retention_end_date` = the "Backup End Date" the tenant pays to extend (forward-only, CHECK-enforced)
- `original_retention_end_date` = immutable evidence of the original entitlement
- `grace_end_date` = when physical deletion actually becomes possible
- All tenant identity snapshots
- `purge_status` (9-value state machine)
- `is_legal_hold` (blocks ALL purge paths)

### User preferences observed this session
- Wants comprehensive, not minimal — explicitly said *"Include any other point which I may have missed"*
- Wants the **"why"** explained, not just the "what" — the Data Dictionary was asked for as "what is the use of it and why it is required"
- Uses inline `-- Conditions:` comment blocks after tables in existing DDLs; v2 follows that convention
- Prefers evaluation findings documented IN the artefact, not just in chat

### Where the artefacts live
All three at `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Modules/Maintenance/`

---

## 11. DEPENDENCIES & CROSS-MODULE REFERENCES

- **Prime (PRM)** — `prm_tenant`, `prm_tenant_groups`, `prm_tenant_domains`. Source of tenant identity and tenant DB connection details.
- **SystemConfig (SYS)** — `sys_users` (all `created_by`/`approved_by`/`triggered_by` FKs), `sys_media` (supporting-document refs), `sys_activity_logs` (may mirror cross-module summary events).
- **Billing (BIL)** — `bil_tenant_invoices`. Paid retention extensions and storage-overage billing invoice through this. FK is SET NULL so billing corrections never cascade into the backup catalogue.
- **Notification (NTF)** — `mnt_alert_dispatches.notification_ref_id` links out when delivery is delegated to the NTF module.
- **Template (TMP)** — `mnt_alert_dispatches.template_code`.
- **Laravel/infra** — `config/filesystems.php` disks (`mnt_storage_destinations.laravel_disk_name`), queue/Horizon (`queue_job_id`), a KMS/vault for `encryption_key_ref` (not yet chosen).
- **stancl/tenancy** — the module operates across the tenancy boundary by design; it reads tenant DB connection info from `prm_tenant_domains` rather than using tenant context.

---

## 12. CONVERSATION HIGHLIGHTS — RAW NOTES

### v1's actual broken lines (from `2-DDL_Tenant_Enhanced/Maintenance_DDL_v1.sql`)
```sql
  INDEX `idx_mnt_taar_archiveTenantId_status` (`archive_tenant_id`,`status`);   -- <-- SEMICOLON, should be comma
  UNIQUE KEY `uq_mnt_taar_tenantId_archiveTenantId` (`tenant_id`,`archive_tenant_id`),  -- <-- tenant_id is commented out above
```
```sql
  -- `tenant_id` varchar(255) NOT NULL,        -- <-- commented out but still indexed
  `approved_by_user_id` bigint UNSIGNED DEFAULT NULL,   -- <-- BIGINT vs sys_users.id INT UNSIGNED
```
```sql
  `created_by` int UNSIGNED NOT NULL,
  CONSTRAINT `mnt_backup_schedules_created_by_foreign` FOREIGN KEY (`created_by`)
    REFERENCES `sys_users` (`id`) ON DELETE CASCADE     -- <-- deleting a user deletes the schedule
```

### The validation script used
```python
import re
src=open('Maintenance_DDL_v2.sql').read()
clean="\n".join(re.sub(r'--.*$','',l) for l in src.split("\n"))
stmts=[s.strip() for s in clean.split(';') if s.strip()]
ct=[s for s in stmts if s.upper().startswith('CREATE TABLE')]
# -> 20 CREATE TABLE stmts, 0 unbalanced parens, 0 dup constraint names, all FK targets known
```

### Key CHECK constraint that enforces the core business rule
```sql
CONSTRAINT `chk_mntRunItems_extensionOnly`
  CHECK (`original_retention_end_date` IS NULL
      OR `retention_end_date` IS NULL
      OR `retention_end_date` >= `original_retention_end_date`)
```
An "extension" can never shorten retention — enforced at the database level, not just in the service layer.

### The extension APPLY transaction (from the Process Flow doc)
```sql
INSERT INTO mnt_retention_extension_item_jnt
  (extension_request_id, backup_run_item_id, previous_end_date, new_end_date,
   extended_days, item_size_bytes, item_charge_amount, apply_status)
VALUES (:req, :item, :old_end, :old_end + :days, :days, :bytes, :share, 'PENDING');

UPDATE mnt_backup_run_items
   SET retention_end_date        = retention_end_date + INTERVAL :days DAY,
       grace_end_date            = retention_end_date + INTERVAL :grace DAY,
       extension_count           = extension_count + 1,
       total_extended_days       = total_extended_days + :days,
       last_extension_request_id = :req,
       purge_status              = 'EXTENDED',
       is_billable               = 1
 WHERE id = :item;
-- original_retention_end_date is NEVER touched
```

### Job ordering constraint that matters
`PurgeExpiredBackupsJob` (04:00) MUST run before `StorageUsageSnapshotJob` (05:00) — otherwise the daily usage figure counts data that was deleted an hour earlier, and the tenant is over-billed.

### Billing nuance captured in the docs
Storage billing uses `AVG(billable_gb)` over the period — NOT the peak and NOT the last day. A school holding 900 GB for 3 days and 100 GB for 27 should not be billed for 900. This is the entire reason `mnt_storage_usage_snapshots` writes a DAILY row rather than a monthly one.

### Final summary given to the user
- v1 would not have run — 4 hard errors
- v1 covered roughly 20% of the stated requirement; retention was entirely absent
- v2 = 20 tables in 6 layers
- Two caveats flagged: the `mnt_` prefix collision (recommend `bkp_`), and that validation is structural only (no MySQL binary available)

---
*End of Context Save*
