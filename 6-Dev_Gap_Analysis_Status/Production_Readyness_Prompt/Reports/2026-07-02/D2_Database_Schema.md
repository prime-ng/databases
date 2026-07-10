# D2 — Database & Schema Integrity Audit (Production Readiness)

- **Date:** 2026-07-02
- **Auditor role:** DB Architect (read-only static analysis; no database was touched)
- **App repo:** `/Users/bkwork/Herd/prime_ai`
- **Masters:** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/0-DDL_Masters/{global_db_v4,prime_db_v4,tenant_db_v4}.sql`

## Domain Verdict: **NOT-READY**

A fresh tenant cannot be fully migrated (`tenants:migrate` aborts on the first FK to the
never-created `sys_roles` table, errno 150/1824), and even if it could, the tenant seeding
pipeline is (a) never invoked by the provisioning job and (b) fatally broken by 8 phantom
seeder class references. These are hard deploy blockers, independent of the substantial
schema-typing and index debt beneath them.

---

## 1. Scope & Inputs Verified

| Source | Count verified today |
|---|---|
| Central migrations `database/migrations/*.php` | 13 |
| Tenant migrations `database/migrations/tenant/*.php` | 713 (660 contain `Schema::create`, creating 664 distinct tables) |
| Module-level migrations `Modules/*/database/migrations/*.php` | 49 (Prime 27, GlobalMaster 17, Documentation 3, Scheduler 2) |
| Master DDL `tenant_db_v4.sql` | 711 lines, **32 tables only** |
| Seeders `database/seeders/` | 40 files |
| Explicit FK references scanned in tenant migrations | 1,539 |

---

## 2. Findings

| ID | Sev | Area | Description | Evidence | Remediation | Effort |
|---|---|---|---|---|---|---|
| GAP-D2-001 | **P0** | Tenant migrate | **`sys_roles` referenced by 17 tenant FKs but NO create migration exists anywhere** (tenant, central, or any module). `sys_roles` is only created on the CENTRAL DB by spatie's `Modules/Prime/database/migrations/2025_10_06_110647_create_permission_tables.php` (via `config/permission.php` `table_names.roles = 'sys_roles'`). MySQL cannot FK across databases → `tenants:migrate` fails errno 150/1824 at the first referencing file. Baseline (known-issues) = 17; **re-verified today = 17, unchanged, still open.** | First failing file: `database/migrations/tenant/2026_06_15_151417_create_lib_digital_resource_access_restrictions_table.php`; `grep "on('sys_roles')" database/migrations/tenant` → 17 hits; `Schema::create('sys_roles'` → 0 hits project-wide | Add `2026_06_15_1454xx_create_sys_roles_table.php` (+ `sys_permissions` and the 3 spatie junction tables per `tenant_db_v4.sql`) to `database/migrations/tenant/`, timestamped BEFORE 2026_06_15_1514xx | S |
| GAP-D2-002 | **P0** | Tenant provisioning | **Tenant seeding is never invoked.** `app/Jobs/SetupTenantDatabase.php` runs only `Artisan::call('tenants:migrate', …)` (line 206); zero occurrences of `seed` in the job. `config/tenancy.php:200-203` names `TenantDatabaseSeeder` as root seeder, but nothing in `app/` or `Modules/` calls `tenants:seed` (only 2 docblock comments in demo seeders). A fresh tenant boots with **no roles, no menus, no settings, no admin user, no dropdowns**. | `app/Jobs/SetupTenantDatabase.php:206`; `grep -rn "tenants:seed" app Modules` → docblocks only | Append `Artisan::call('tenants:seed', ['--tenants'=>[$tenant->id],'--force'=>true])` to the job after migrate (or `$tenant->run(fn() => Artisan::call('db:seed', …))`) | S |
| GAP-D2-003 | **P0** | Tenant seeding | **`TenantDatabaseSeeder` is fatally broken — 8 phantom class references.** 7 unimported bare names resolve to `Database\Seeders\*` and exist NOWHERE in the project: `SchoolDaySeeder`, `DayTypeSeeder`, `PeriodTypeSeeder`, `ShiftSeeder`, `TimetableTypeSeeder`, `PeriodConfigSeeder`, `PeriodSetSeeder`. Plus the import `Modules\SystemConfig\Database\Seeders\SettingSeeder` — only `SettingsSeeder.php` (plural) exists. First `$this->call()` reaching any of these throws class-not-found and aborts the whole tenant seed. | `database/seeders/TenantDatabaseSeeder.php` (calls at run()); `grep -rl "class SchoolDaySeeder"` etc. → NOT FOUND; `Modules/SystemConfig/database/seeders/` contains `SettingsSeeder.php` only | Remove/implement the 7 phantom seeders; fix `SettingSeeder` → `SettingsSeeder`; add a CI smoke test `tenants:seed` on a scratch tenant | M |
| GAP-D2-004 | **P0** | Tenant seeding | **`RolePermissionSeeder` in the tenant pipeline writes to a non-existent tenant table.** `TenantDatabaseSeeder` calls `Modules\Prime\...\RolePermissionSeeder` which does `Role::firstOrCreate(...)` (line 253) → spatie writes to `sys_roles`, which per GAP-D2-001 does not exist in tenant DBs. Even after fixing GAP-D2-002/003, seeding dies here. | `Modules/Prime/database/seeders/RolePermissionSeeder.php:253`; `config/permission.php:39` | Resolved automatically by GAP-D2-001 (create the 5 spatie tables in tenant migrations) | S (with 001) |
| GAP-D2-005 | P1 | Master DDL drift | **`tenant_db_v4.sql` covers only 32 foundational tables (711 lines) while tenant migrations create 664 tables** → 656 migration tables (98.8%) have no v4 master DDL, and 24 of the 32 DDL tables have no identically-named tenant migration. The v4 master is a foundational-core extract, not a schema master; any DDL-driven review or diff is blind to ~99% of the live schema. (Note: db-architect.md still cites v2 @ 368 tables/10,297 lines — also stale.) | `grep -c "CREATE TABLE" tenant_db_v4.sql` → 32; extracted migration tables → 664; comm diff in audit scratchpad | Regenerate `tenant_db_v4.sql` (or a v5) from the full migration set, or explicitly rename the file `tenant_db_core_v4.sql` and produce a complete master | L |
| GAP-D2-006 | P1 | DDL↔migration naming drift | Within the 32-table DDL core, systematic name drift vs migrations: `sys_dropdown_table`→`sys_dropdowns`, `sch_department`→`sch_departments`, `sch_config`→`sch_configs`, `sch_designation`→`sch_designations`, `sys_dropdown_need_table_jnt`→`sys_dropdown_need_dropdowns_jnt`, `sch_entity_groups_members`→(absent). `sch_categories`, `sch_disable_reasons` have no tenant migration at all. The 11 `glb_*` tables in the tenant DDL are created only centrally (GlobalMaster module) — the DDL implies tenant-local copies that don't exist. | comm output: 24 DDL tables without matching tenant migration; `database/migrations/tenant/2026_06_15_145406_create_sys_dropdown_table.php` creates `sys_dropdowns` | Decide canonical names, align DDL to migrations (migrations are the deployed truth), document glb_* as central-only in the DDL header | M |
| GAP-D2-007 | P1 | Migration architecture | **49 module-level migrations contradict the centralized convention but are NOT dead:** every module's ServiceProvider calls `loadMigrationsFrom(module_path(...,'database/migrations'))`, so they run on **central** `php artisan migrate`. `tenants:migrate` is unaffected (`config/tenancy.php:193` pins `--path` to `database/migrations/tenant`). Prime(27)/GlobalMaster(17) are central-by-design; Documentation(3) and Scheduler(2) create central tables for module features — verify intent. Zero basename overlap with `tenant/`. | `config/tenancy.php:191-193`; `grep loadMigrationsFrom Modules/*/app/Providers` → all modules | Document the split; move Documentation/Scheduler migrations to `database/migrations/` proper if central is intended, or to `tenant/` if not | M |
| GAP-D2-008 | P1 | Migration collision | **3 pairs of duplicate migration basenames with DIFFERENT contents** between `Modules/Prime/` and `Modules/GlobalMaster/`: `2025_10_06_112509_create_media_table.php`, `2025_10_21_091617_create_plans_table.php`, `2025_11_02_071024_create_activity_logs_table.php`. Laravel's migrator keys files by basename — one file silently shadows the other (last-scanned path wins), so which schema you get is load-order dependent and one version never runs. | `diff` → DIFFER on all 3 pairs; Illuminate `Migrator::getMigrationFiles()` keyed by name | Delete the shadowed copy of each pair (keep the one matching the live central schema); add a CI check for duplicate migration basenames | S |
| GAP-D2-009 | P1 | Reference data | **52 tenant FKs → `sys_dropdowns` re-verified (baseline 52, unchanged) — BUT the baseline "cross-DB/impossible" P0 classification is now a false positive:** tenant migration `2026_06_15_145406_create_sys_dropdown_table.php` DOES create `sys_dropdowns` inside the tenant DB, timestamped before all 52 referencing files (earliest ref: `2026_06_15_145408`). Residual P1: the tenant seeding pipeline contains **no dropdown seeder** (`DropdownsSeeder` runs only in central `DatabaseSeeder`), so tenant `sys_dropdowns` is empty → every NOT NULL dropdown FK insert fails at runtime and all dropdown-driven UIs are blank on a fresh tenant. | FK grep → 52; create-migration timestamp vs earliest ref; `TenantDatabaseSeeder` has zero `Dropdown*` calls | Add `DropdownNeedsSeeder`/`DropdownsSeeder`/`DropdownNeedDropdownsJntSeeder` (tenant-safe variants) to `TenantDatabaseSeeder` before all module seeders; downgrade the known-issues entry from P0 | S |
| GAP-D2-010 | P1 | PK typing | **`->increments('id')` signed INT(11) PKs: 429 of 660 create migrations (65%)** — re-verified today; baseline 428/658, effectively unchanged. Violates the platform rule (INT UNSIGNED) and mixes signed/unsigned FK typing across modules; 2.1B-row ceiling on log-type tables. | `grep -rl -F "->increments('id')" database/migrations/tenant` → 429; 195 files use `id()`/`bigIncrements` | Batch-rewrite to `$table->id()` pre-GA (tenant DBs are re-creatable now; post-GA this becomes an XL online-DDL project) | L |
| GAP-D2-011 | P1 | Model↔schema | `$fillable` columns missing from migrations — **baseline 66 models (D17) carried forward, not re-verified in this pass** (requires per-model column diff; out of D2 static scope today). Known concrete instances remain open in known-issues (e.g. `difficulty_band`, `doc_articles.sort_order`, `hst_mess_bills.total_amount`). Symptom: `SQLSTATE 42S22` on create/update paths. | `AI_Brain/lessons/known-issues.md:44` and module entries | Run the D17 model↔migration differ as a dedicated pass; add CI schema-vs-fillable assertion | M |
| GAP-D2-012 | P2 | Migration order | FK dependency ordering is otherwise CLEAN: of 1,539 explicit FK references (`->on('x')` / `constrained('x')`) across 713 tenant migrations, **0 reference a table created in a later-timestamped migration**. The only unresolved targets are the 17 `sys_roles` refs (GAP-D2-001). Implicit `constrained()` (name-derived) not exhaustively checked. | fk_scan script over sorted tenant migrations | None (keep the scan as a CI gate) | S |
| GAP-D2-013 | P2 | Indexes | **77 of 875 FK-named columns (8.8%) in the 10 largest modules' create migrations have neither an FK constraint nor an explicit index.** Worst: `tt_` 39, `lms_` 12, `slb_` 7, `sch_` 7, `hst_` 4, `tpt_` 4, `fee_` 3, `lib_` 1. Hot examples: `fee_transactions.receipt_id`, `hst_mess_bills.fee_demand_id`, `lms_quizzes.lesson_id`, `sch_class_group_subject_options_jnt.class_group_id`, `slb_syllabus_schedule.lesson_id`. (InnoDB auto-indexes constrained FKs, so only these 77 unconstrained `_id` columns lack indexes; regex-based, ±small error.) | idx_scan script; top-10 prefixes by table count (sch 52, lib 48, tt 45, hst 40, lms 36, slb 28, inv 28, acc 28, tpt 26, fee 24) | Single index-backfill migration per module; prioritize tt_ (39) and join-table columns | M |
| GAP-D2-014 | P2 | ENUM debt | `->enum()` in tenant migrations: **466 occurrences across 319 files** — re-verified today (baseline ~476; small drift down, e.g. tpt now 0 per known-issues correction). D29 violation: fixed value sets requiring migrations to extend; several FSM enums already mismatch code (e.g. `hpc_reports.status`, `adm_applications.status` — tracked in known-issues). | `grep -r -F -e "->enum(" database/migrations/tenant` → 466 | Convert dropdown-candidate enums to `sys_dropdowns` FKs module-by-module; keep genuine FSM enums but reconcile value casing with code | XL |
| GAP-D2-015 | P3 | Docs | `AI_Brain/agents/db-architect.md` "Existing Schema Stats" cites v2 counts (368 tenant tables / 10,297 lines) and instructs "use v2 DDLs" while the audit brief designates v4 masters; `known-issues.md` still lists the sys_dropdowns FK issue as P0 cross-DB (superseded by GAP-D2-009). | `AI_Brain/agents/db-architect.md:103-107`; `AI_Brain/lessons/known-issues.md:42` | Update both docs after this report is accepted | S |

---

## 3. Re-verified Systemic Counts (Task 2 summary)

| Known issue | Baseline | Today (2026-07-02) | Status |
|---|---|---|---|
| Tenant FKs → `sys_roles`, no create migration | 17 (P0) | **17 — no create migration exists; tenants:migrate still fails** | OPEN (GAP-D2-001) |
| Tenant FKs → `sys_dropdowns` "central-only" | 52 (P0) | **52 refs, but tenant migration creates the table first → not cross-DB; residual = unseeded data** | RECLASSIFIED P1 (GAP-D2-009) |
| `->increments('id')` signed PKs | 428/658 | **429/660** | OPEN (GAP-D2-010) |
| `->enum()` in tenant migrations | ~476 | **466 (319 files)** | OPEN (GAP-D2-014) |
| `$fillable` col missing from migration | 66 models | not re-verified this pass | CARRIED (GAP-D2-011) |

## 4. Counts

- **P0: 4** (GAP-D2-001, 002, 003, 004) — all on the fresh-tenant provisioning path
- **P1: 7** (GAP-D2-005 … 011)
- **P2: 3** (GAP-D2-012, 013, 014)
- **P3: 1** (GAP-D2-015)

## 5. Verdict Rationale

**NOT-READY.** The four P0s form a single fatal chain on tenant onboarding: migrations
abort at the first `sys_roles` FK; the provisioning job never seeds; the root tenant seeder
cannot execute end-to-end even if invoked; and its role seeder targets a table that does not
exist in tenant DBs. All four are S/M-effort fixes — the fastest path to READY-WITH-RISK is:
create the 5 spatie tables in `tenant/` (001/004), fix the 8 phantom seeder references (003),
wire `tenants:seed` into `SetupTenantDatabase` (002), and add tenant dropdown seeding (009),
then smoke-test one scratch tenant end-to-end.
