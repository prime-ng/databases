# Prime-AI Testing Application — Data Dictionary

**Document ID:** TSTAPP-DD-V7.2
**Version:** 1.0
**Date:** 2026-09-09
**Describes:** `testing_DDL_v7.2.sql` — 58 tables, 21 views
**Database:** `prime_testing` · MySQL 8.0.16+ · InnoDB · utf8mb4 / utf8mb4_unicode_ci

**Companion documents:** `TestingApp_BRD_v3.md` (what the business needs) · `Solution_Design_v3.md` (how it works)

---

## How to read this dictionary

Every table below has the same four parts:

| Part | What it tells you |
|---|---|
| **What it is for** | Plain-English purpose, in two or three sentences |
| **Example row** | Real-looking data, so the shape of the table is obvious at a glance |
| **Columns** | Every column: type, nullability, meaning, and an example value |
| **Keys & rules** | Unique keys, foreign keys, CHECK constraints, and any behaviour worth knowing |

### Notation used in the column tables

| Symbol | Meaning |
|---|---|
| **PK** | Primary key |
| **UK** | Part of a unique key |
| **FK** | Foreign key — the parent table is named |
| **GEN** | Generated column. The database calculates it; **you never write to it** |
| **DERIVED** | Maintained by a background job from recorded results. Never type into it |
| **[P2]** | Column exists in Phase 1 but stays NULL until Phase 2 is installed |
| ✔ / — | Column allows NULL / does not allow NULL |

### The audit columns — explained once, used everywhere

Almost every table carries the same six columns. They are described here once and **not repeated** in each table below.

| Column | Type | Null | Meaning | Example |
|---|---|---|---|---|
| `created_by` | VARCHAR(3) | — | Who created the row. FK → `tst_users.code` | `D02` |
| `updated_by` | VARCHAR(3) | — | Who last changed it. FK → `tst_users.code` | `T01` |
| `deleted_by` | VARCHAR(3) | ✔ | Who soft-deleted it. FK → `tst_users.code` | `A01` |
| `created_at` | TIMESTAMP | — | When the row was created. Defaults to now | `2026-09-09 10:14:22` |
| `updated_at` | TIMESTAMP | — | Auto-updated on every change | `2026-09-09 16:02:05` |
| `deleted_at` | TIMESTAMP | ✔ | **Soft delete.** NULL means the row is live. A date means it is hidden but retained | `NULL` |

> **Why soft delete everywhere.** Testing evidence must never disappear. If a test case were hard-deleted, every historical result that referenced it becomes unreadable. `deleted_at` hides a row from lists without destroying the history that points at it.

**Tables that deliberately have NO `deleted_at`** — because they are insert-only records of things that happened, and unsaying them would be dishonest:
`tst_test_case_versions_history` · `tst_duplicate_test_case` · `tst_test_run_result_steps` · `tst_run_result_artifacts` · `tst_failure_signatures` · `tst_test_case_runs_summary` · `tst_discovery_sync_logs` · `tst_known_issue_results` · `tst_bug_occurrences` · `tst_bug_status_history` · `tst_bug_links` · `tst_retest_cycles` · `tst_retest_cycle_bugs` · `tst_import_record_map` · `tst_import_conflicts` · `tst_ai_analyses` · `tst_ai_recommendations` · `tst_audit_logs` · `tst_app_requirement_test_cases` · `tst_test_suite_items` · `tst_test_suite_versions` · `tst_git_*`

---

## The coding system — read this first

Nearly every table in this database is joined by a **business code**, not by an integer id. If you understand the codes, you understand the schema.

### The five codes

```
   user_code       D02              role letter + 2 digits
        +
   machine_number  A                a single letter per machine that person owns
        ↓
   machine_code    D02A             GENERATED. "Tarun's first machine"

   module_code     SLB              a Prime-AI module
   cat_code        T01              a category inside it
   mm_code         T0104            a main menu    — starts with T01
   sm_code         T010401          a sub menu     — starts with T0104
   ts_code         T0104010200      a screen       — starts with T010401
        ↓
   tcr_code        D02A_T0104010200_0001   GENERATED. A PLANNED test  (TcList entry)
   test_case_code  D02A_T0104010200_001    GENERATED. An ACTUAL test
```

### Reading a test case code

```
   D02A _ T0104010200 _ 001
   ────   ───────────   ───
     │         │          └── the 1st test case written for this screen on this machine
     │         └───────────── screen T0104010200, which sits under sub menu T010401,
     │                        under main menu T0104, under category T01
     └─────────────────────── machine A of user D02 (Tarun)
```

**Everything you need to know is in the code.** No lookup required to know who wrote it, on which machine, and for which screen.

### Why the machine letter is in there

Two testers write a test for the same login screen on the same afternoon, without talking to each other:

| Who | Code they get |
|---|---|
| Tarun on his laptop | `D02A_T0104010200_001` |
| Sameer on his laptop | `T01A_T0104010200_001` |

**Different codes. No collision. No central number server.** Both import into the same central database side by side. Whether they are *the same test* is a separate human judgement, recorded in `tst_duplicate_test_case`.

### Three rules that follow from this

| # | Rule | Why |
|---|---|---|
| 1 | **A code can never be renamed.** Deactivate and create a new one instead | MySQL forbids `ON UPDATE CASCADE` on a column that feeds a generated column, so a rename physically cannot propagate |
| 2 | **A test case can never move to another screen** | Its code names its screen. A test of a different screen is a different test |
| 3 | **A retired user code or machine code is never reissued** | It is embedded in every test case that person wrote |

### Generated columns — never write to these

`tst_machines.machine_code`, `tst_tc_required_list.tcr_code` and `tst_test_cases.test_case_code` are **calculated by MySQL**. You insert the parts; the database builds the code.

```sql
-- CORRECT — insert the parts
INSERT INTO tst_test_cases (user_code, machine_code, ts_code, tc_seq_number, display_name, ...)
VALUES ('D02', 'D02A', 'T0104010200', 1, 'Login with valid credentials', ...);
-- test_case_code becomes 'D02A_T0104010200_001' automatically

-- WRONG — MySQL rejects this
INSERT INTO tst_test_cases (test_case_code, ...) VALUES ('D02A_T0104010200_001', ...);
```

---

## A worked example — one test, from plan to verified fix

This single story touches 18 tables. Follow it once and the rest of the dictionary will read easily.

| # | What happens | Table written | Key data |
|---|---|---|---|
| 1 | Admin registers Tarun | `tst_users` | `D02` |
| 2 | Admin registers Tarun's laptop | `tst_machines` | `D02A` (generated) |
| 3 | Admin loads the Fees module and its screens | `tst_modules` … `tst_tabs_screens` | `SLB` → `T01` → `T0104` → `T010401` → `T0104010200` |
| 4 | Tarun plans 12 tests needed for that screen | `tst_tc_required_list` | `D02A_T0104010200_0001` … `_0012` |
| 5 | He writes the first one as a Dusk test | `tst_test_cases` | `D02A_T0104010200_001` |
| 6 | He adds 4 manual steps to it | `tst_test_case_steps` | steps 1–4 |
| 7 | Sameer reviews it and Brijesh signs it off | `tst_test_case_review` | score 92, `Released` |
| 8 | A nightly schedule is set for Fees on `D02A` | `tst_schedules` + `tst_schedule_targets` | cron `0 2 * * *` |
| 9 | At 02:00 the run starts | `tst_test_runs` | run 5501, commit `a3f9c2…` |
| 10 | The environment is fingerprinted | `tst_environment_profiles` | Chrome 141 / Win 10 |
| 11 | 12 tests are selected into the run | `tst_test_run_items` | reason `Schedule` |
| 12 | Our test runs and **fails** | `tst_test_run_results` | attempt 1, `Failed` |
| 13 | A screenshot and console log are kept | `tst_run_result_artifacts` | 2 files |
| 14 | The failure is fingerprinted and grouped | `tst_failure_signatures` | 3 tests share it |
| 15 | Sameer triages it into a bug | `tst_bugs` | `BUG-000412`, `High` |
| 16 | The failure is linked to the bug | `tst_bug_occurrences` | occurrence 1 |
| 17 | Tarun fixes it and marks it Fixed | `tst_bug_status_history` | `In_Progress` → `Fixed` |
| 18 | A retest cycle fires automatically | `tst_retest_cycles` | cycle 1 |
| 19 | The retest passes | `tst_test_run_results` | run 5510, `Passed` |
| 20 | The bug is closed as **verified** | `tst_bugs` | `verified_result_id` set |
| 21 | Statistics are rebuilt | `tst_test_case_runs_summary` | pass rate, health |
| 22 | Tarun exports his evidence | `tst_data_exports` | bundle |
| 23 | Central imports it | `tst_data_imports` + `tst_import_record_map` | 1,204 rows created |

---

# PHASE 1 — RECORD AND DIAGNOSE

*44 tables. Everything needed to plan, write, review, schedule, run, evidence and defect-track a test.*

---

# Section 1 — Platform

## 1.1 `tst_app_settings` — Application Configuration

### What it is for

Every configurable value in the application, stored as a typed key/value pair with a description. Instead of scattering `config('testing.max_retest')` around the code, one table holds every setting, what it means, and who is allowed to change it.

### Example rows

| group_name | key | value | value_type | is_system | is_local_only | is_editable |
|---|---|---|---|:---:|:---:|:---:|
| Retest | `max_auto_retest_attempts` | `5` | INTEGER | 1 | 0 | 1 |
| Retention | `artifact_retention_days` | `180` | INTEGER | 1 | 0 | 1 |
| Paths | `prime_ai_repo_path` | `D:\work\prime-ai` | STRING | 1 | **1** | 1 |
| Platform | `schema_version` | `7.2.0` | STRING | 1 | 0 | **0** |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK.** Auto-increment | `14` |
| `group_name` | VARCHAR(50) | — | Screen grouping, so the settings page has sections | `Retention` |
| `ordinal` | SMALLINT UNSIGNED | — | Display order inside the group | `3` |
| `key` | VARCHAR(100) | — | **UK.** The setting name the code looks up | `bug_fix_sla_hours` |
| `value` | VARCHAR(1000) | — | The value, always stored as text | `48` |
| `value_type` | ENUM | — | How to cast it: `STRING`, `INTEGER`, `DECIMAL`, `BOOLEAN`, `DATE`, `TIME`, `DATETIME`, `JSON` | `INTEGER` |
| `description` | VARCHAR(500) | ✔ | What the setting does, in plain words | `Hours after assignment before a stale-bug alert` |
| `is_system` | TINYINT(1) | — | `1` = shipped with the app; a user may not delete it | `1` |
| `is_local_only` | TINYINT(1) | — | `1` = **never travels in a catalog bundle** | `1` for paths |
| `is_editable` | TINYINT(1) | — | `0` = read-only in the UI; changing it is a code change | `0` for `schema_version` |

### Keys & rules

- `UNIQUE (key)` — one row per setting name.
- **`is_local_only` is the important flag.** Exporting `prime_ai_repo_path` = `D:\work\prime-ai` to Sameer's Mac would point his installation at a directory that does not exist. Local paths, machine specifics and credentials stay where they belong.
- **`schema_version` lives here**, which is why there is no separate `tst_schema_version` table. Laravel's own `migrations` table already holds the applied history.

---

## 1.2 `tst_environment_profiles` — Machine Environment Profile

### What it is for

Records the exact software environment a test ran in, identified by a **fingerprint** rather than free text. This is the table that turns *"it fails on my machine"* into *"it fails on Chrome 141 and passes on Chrome 140"* — the first is an argument, the second is a fixable bug report.

### Example row

```
id                 : 7
env_fingerprint    : 9f2c1a...  (sha256 of the attributes below)
env_name           : "Tarun Local — Chrome 141"
env_type           : Local
os_name            : Windows 10        os_version      : 10.0.19045
php_version        : 8.2.4             laravel_version : 10.35.5
database_engine    : MySQL             database_version: 8.0.38
browser_name       : Chrome            browser_version : 141
driver_version     : ChromeDriver 141.0.5524.12
run_count          : 1,847
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `7` |
| `env_fingerprint` | CHAR(64) | — | **UK.** sha256 over the normalised attributes below. Identical environments produce identical fingerprints on any machine | `9f2c1a…` |
| `env_name` | VARCHAR(150) | ✔ | Friendly label, added by a person after the profile appears | `Tarun Local — Chrome 141` |
| `env_type` | ENUM | — | `Local`, `CI`, `Staging`, `Production_Like`, `Other` | `Local` |
| `os_name` / `os_version` | VARCHAR(80) / (120) | ✔ | Operating system | `Windows 10` / `10.0.19045` |
| `php_version` | VARCHAR(30) | ✔ | PHP running the app | `8.2.4` |
| `laravel_version` | VARCHAR(30) | ✔ | Framework version | `10.35.5` |
| `database_engine` / `database_version` | VARCHAR(50) | ✔ | Database under test | `MySQL` / `8.0.38` |
| `browser_name` / `browser_version` | VARCHAR(50) | ✔ | **The most common cause of "works on mine"** | `Chrome` / `141` |
| `driver_version` | VARCHAR(50) | ✔ | WebDriver version — a mismatch with the browser breaks Dusk | `ChromeDriver 141.0.5524.12` |
| `app_env` | ENUM | ✔ | `Local`, `Testing`, `Staging` | `Local` |
| `app_version` | VARCHAR(30) | ✔ | Prime-AI version under test | `2.4.1` |
| `config_profile` | VARCHAR(100) | ✔ | Named configuration set | `tenant-demo` |
| `attributes_json` | JSON | ✔ | Anything else captured that is **not** part of the fingerprint | `{"screen":"1920x1080"}` |
| `first_seen_at` / `last_seen_at` | DATETIME | ✔ | When this environment first and last appeared | `2026-08-01` |
| `run_count` | BIGINT UNSIGNED | — | How many runs used it | `1847` |

### Keys & rules

- `UNIQUE (env_fingerprint)` — a new fingerprint auto-creates a profile; a person names it later.
- **This table is never exported or imported.** A fingerprint recomputes identically anywhere, so importing profiles would only create duplicates that differ by `id`.
- **A regression comparison is only valid within one environment profile.** A pass on Chrome 140 and a fail on Chrome 141 is not a regression — it is an environment finding.

---

# Section 2 — Identity

## 2.1 `tst_users` — User Profile Management

### What it is for

Who is who. Every action in the entire database is attributable to a user code, and the user code is embedded in every machine code and therefore in every test case code.

### Example rows

| code | name | role | is_system | is_active |
|---|---|---|:---:|:---:|
| `S01` | Super User | System | 1 | 1 |
| `S02` | System | System | 1 | 1 |
| `A01` | Brijesh | Architect | 0 | 1 |
| `D02` | Tarun | Developer | 0 | 1 |
| `T01` | Sameer | Tester | 0 | 1 |

### The code format

```
   D  02
   │   └── a simple number, 01–99
   └────── first letter of the role
              A = Architect    Q = QA_Lead    T = Tester
              D = Developer    R = Reviewer   S = System
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `code` | VARCHAR(3) | — | **PK.** Role letter + 2 digits. Appears in every `*_by` column in the database | `D02` |
| `name` | VARCHAR(100) | — | Full name | `Tarun` |
| `email` | VARCHAR(150) | — | **UK.** Login identity | `tarun@prime-testing.local` |
| `password` | VARCHAR(512) | — | Bcrypt hash. Never plain text | `$2y$12$…` |
| `role` | ENUM | — | `Architect`, `QA_Lead`, `Tester`, `Developer`, `Reviewer`, `System`. **This single column replaces the four role/permission tables of v7.0** | `Developer` |
| `is_superuser` | TINYINT(1) | — | Full administrative access | `0` |
| `is_system` | TINYINT(1) | — | `1` = a robot, not a person: the scheduler, the importer, the retest engine. **So an automatic action still has a named actor** | `1` for `S02` |
| `is_active` | TINYINT(1) | — | `0` = deactivated. Never deleted | `1` |

Plus the standard audit columns. `created_by` / `updated_by` / `deleted_by` are **nullable here**, because the very first row (`S01`) has nobody to attribute itself to.

### Keys & rules

- `PRIMARY KEY (code)` · `UNIQUE (email)`
- Self-referencing FKs on `created_by`, `updated_by`, `deleted_by`.
- **A user code is never reissued to a different person.** If Tarun leaves and Rahul joins, Rahul gets `D04`, not Tarun's `D02` — because `D02` is baked into every test case Tarun wrote.
- Users are created centrally and distributed by seeder. A local user may change only their own password.

---

## 2.2 `tst_machines` — Machine Profile for every user

### What it is for

One row per installation of the Testing Application. This is what separates *"the application is broken"* from *"your machine is different"* — a test that fails on `D02A` and passes on `T01A` with a different browser is an environment finding, not a defect.

### Example rows

| id | owner_user_code | machine_number | machine_code (GEN) | machine_name | is_central |
|---:|---|:---:|---|---|:---:|
| 1 | `A01` | `A` | **`A01A`** | Central Consolidation Server | 1 |
| 11 | `D02` | `A` | **`D02A`** | Tarun Workstation | 0 |
| 12 | `D02` | `B` | **`D02B`** | Tarun Laptop | 0 |
| 13 | `T01` | `A` | **`T01A`** | Sameer Workstation | 0 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | SMALLINT UNSIGNED | — | **PK. Issued centrally, inserted EXPLICITLY.** `1` = the central installation; local machines start at `10` | `11` |
| `owner_user_code` | VARCHAR(3) | — | **FK → `tst_users.code`.** Who owns this machine | `D02` |
| `machine_number` | ENUM `A`–`Z` | — | Which of that person's machines this is | `A` |
| `machine_code` | VARCHAR(4) | — | **GEN + UK.** `owner_user_code ‖ machine_number`. The parent key of every `machine_code` reference | `D02A` |
| **— the 11 fields a local user may edit —** | | | | |
| `machine_name` | VARCHAR(150) | — | Friendly name | `Tarun Workstation` |
| `machine_model` | VARCHAR(150) | ✔ | Hardware model | `Dell XPS 15 9520` |
| `os_name` / `os_version` | VARCHAR(80) / (120) | ✔ | Operating system | `Windows 10` / `10.0.19045` |
| `architecture` | VARCHAR(30) | ✔ | CPU architecture | `x86_64` |
| `hostname` | VARCHAR(150) | ✔ | Network name | `TARUN-PC` |
| `hardware_serial` | VARCHAR(150) | ✔ | Serial number — helps detect a rebuilt machine | `5CG1234ABC` |
| `app_version` | VARCHAR(20) | ✔ | Testing App version installed here | `1.0.0` |
| `schema_version` | VARCHAR(20) | ✔ | Database schema version here | `7.2.0` |
| `prime_ai_repo_path` | VARCHAR(1000) | ✔ | Where the Prime-AI source lives on this machine | `D:\work\prime-ai` |
| `evidence_root_path` | VARCHAR(1000) | ✔ | Where screenshots and logs are stored | `D:\evidence` |
| **— administrator-controlled —** | | | | |
| `machine_fingerprint` | CHAR(64) | ✔ | sha256(hostname + os + serial + install path). **Re-checked at every boot**; a mismatch is reported, not silently accepted | `4b7e…` |
| `is_central` | TINYINT(1) | — | `1` on the one consolidation installation | `0` |
| `is_active` | TINYINT(1) | — | Currently in use | `1` |
| `registration_status` | ENUM | — | `Registered`, `Pending`, `Suspended`, `Retired` | `Registered` |
| `first_seen_at` / `last_seen_at` | DATETIME | ✔ | First and most recent contact | `2026-09-09 08:30:00` |
| `retired_at` | DATETIME | ✔ | When it was taken out of service | `NULL` |
| `registered_by` | VARCHAR(3) | — | FK → `tst_users.code`. The admin who registered it | `S01` |

### Keys & rules

- `UNIQUE (machine_code)` · `UNIQUE (owner_user_code, machine_number)`
- `owner_user_code` FK is **`ON DELETE RESTRICT` and cannot be anything else** — it feeds the generated `machine_code`, and MySQL forbids cascading actions on such a column.
- **Never let a local database auto-increment its own machine id.** Every machine would become `id = 1` and all consolidated evidence would collide. `AUTO_INCREMENT=10` is set as a guard, but ids must still be inserted explicitly.
- **A retired machine code is never reissued.** Two installations registered as `D02A` would silently merge two machines' evidence — which is why the importer flags a duplicate business code as a *blocking* conflict.
- A machine is never reassigned to another user. `D02A` means "Tarun's first machine" permanently; a new owner registers a new code.

---

# Section 3 — Catalog

The five catalog tables mirror the Prime-AI navigation menu. They exist so that every test case can be attached to a real, addressable screen.

```
tst_modules        SLB   Syllabus
  └── tst_categories      T01           Syllabus Setup
        └── tst_main_menus      T0104           Subject Mapping
              └── tst_sub_menus      T010401           Class-wise Mapping     ← optional
                    └── tst_tabs_screens   T0104010200         Assign Subjects tab
```

**Each code contains its parent's code as a prefix.** `T0104010200` is *provably* a screen under `T010401`, under `T0104`, under `T01`. This is enforced twice: by the prefix rule (readable by a human) and by composite foreign keys (enforced by the database). Neither alone is enough — a prefix can be typed wrong, and a composite key alone would happily accept `T0104` under category `T02`.

## 3.1 `tst_modules`

### What it is for
The top-level functional areas of Prime-AI: Fees, Examination, Syllabus, Student Profile.

### Example row
`SLB` · Syllabus · `Modules/Syllabus` · criticality `High` · owner `A01`

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `4` |
| `module_code` | VARCHAR(5) | — | **UK.** Short module identifier | `SLB` |
| `name` | VARCHAR(60) | — | Display name | `Syllabus` |
| `description` | VARCHAR(500) | ✔ | What the module does | `Curriculum and subject planning` |
| `folder_name` | VARCHAR(120) | ✔ | Where it lives in the Prime-AI source tree. **Used by Phase-2 path resolution** | `Modules/Syllabus` |
| `owner_user_code` | VARCHAR(3) | ✔ | FK → `tst_users.code`. Who is answerable for it | `A01` |
| `criticality` | ENUM | — | `Low`, `Medium`, `High`, `Critical`. Weights testing debt reports | `High` |
| `sort_order` | SMALLINT UNSIGNED | — | Menu display order | `4` |
| `version` | INT UNSIGNED | — | Module version counter | `3` |
| `is_active` | TINYINT(1) | — | In scope for testing | `1` |

### Keys & rules
`UNIQUE (module_code)`. Centrally governed and distributed by seeder — local users do not edit the catalog.

## 3.2 `tst_categories`

### What it is for
A grouping inside a module. `cat_code` is the **root of every code beneath it** — the first three characters of every main menu, sub menu and screen code in that branch.

### Example row
`SLB` · `T01` · Syllabus Setup

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `9` |
| `module_code` | VARCHAR(5) | — | **UK.** FK → `tst_modules.module_code` | `SLB` |
| `cat_code` | VARCHAR(3) | — | **UK.** The root of the code tree below | `T01` |
| `name` | VARCHAR(60) | — | Display name | `Syllabus Setup` |
| `description` | VARCHAR(500) | ✔ | Purpose | `Master configuration screens` |
| `sort_order` | SMALLINT UNSIGNED | — | Display order | `1` |
| `is_active` | TINYINT(1) | — | In scope | `1` |

### Keys & rules
`UNIQUE (cat_code)` · `UNIQUE (module_code, cat_code)` — the second is the **parent key of the composite FK from `tst_main_menus`** · `UNIQUE (module_code, name)`.

## 3.3 `tst_main_menus`

### What it is for
The main navigation entries under a category. `mm_code` = `cat_code` + 2 digits.

### Example row
`SLB` · `T01` · `T0104` · Subject Mapping · `/syllabus/subject-mapping`

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `31` |
| `module_code` | VARCHAR(5) | — | **UK.** Part of the composite parent link | `SLB` |
| `cat_code` | VARCHAR(3) | — | **UK.** Part of the composite parent link | `T01` |
| `mm_code` | VARCHAR(5) | — | **UK.** Prefix-nested: starts with `cat_code` | `T0104` |
| `name` | VARCHAR(60) | — | Menu label | `Subject Mapping` |
| `route_url` | VARCHAR(500) | ✔ | Laravel route this menu opens | `/syllabus/subject-mapping` |
| `sort_order` | SMALLINT UNSIGNED | — | Display order | `4` |
| `is_active` | TINYINT(1) | — | Visible in the menu | `1` |

### Keys & rules
`UNIQUE (mm_code)` · `UNIQUE (module_code, cat_code, mm_code)`.
**Composite FK** `(module_code, cat_code)` → `tst_categories`. This is what stops a main menu belonging to a category in a *different* module — a real bug in an earlier version that silently corrupted the hierarchy.

## 3.4 `tst_sub_menus`

### What it is for
An **optional** level between a main menu and a screen. `sm_code` = `mm_code` + 2 digits.

### Example row
`SLB` · `T01` · `T0104` · `T010401` · Class-wise Mapping

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `88` |
| `module_code` / `cat_code` / `mm_code` | VARCHAR(5)/(3)/(5) | — | **UK.** The composite parent link | `SLB` / `T01` / `T0104` |
| `sm_code` | VARCHAR(7) | — | **UK.** Starts with `mm_code` | `T010401` |
| `name` | VARCHAR(60) | — | Menu label | `Class-wise Mapping` |
| `route_url` | VARCHAR(500) | ✔ | Route | `/syllabus/subject-mapping/class` |
| `sort_order` | SMALLINT UNSIGNED | — | Display order | `1` |
| `is_active` | TINYINT(1) | — | Visible | `1` |

### Keys & rules
`UNIQUE (sm_code)` · `UNIQUE (module_code, cat_code, mm_code, sm_code)` · composite FK to `tst_main_menus`.

## 3.5 `tst_tabs_screens` — the anchor of the whole system

### What it is for

A **screen** is the smallest addressable, testable surface of Prime-AI, and `ts_code` is the middle segment of every test case code. This table also carries the **five status columns that make up the project-management view of testing** — you can list every screen whose development is finished and whose test list has not been written.

### Example row

```
ts_code            : T0104010200
name               : "Assign Subjects"
module/cat/mm/sm   : SLB / T01 / T0104 / T010401
criticality        : High
requir_doc_status  : Completed          requir_doc_md_path : docs/req/T0104010200.md
tc_list_status     : Approved           tc_list_md_path    : docs/tclist/T0104010200.md
dev_status         : Testing-Completed
tc_creation_status : In-Progress
test_run_status    : Partially-Run
finding_method     : Discovery          is_reviewed : 1
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `412` |
| `module_code` / `cat_code` / `mm_code` | VARCHAR(5)/(3)/(5) | — | The composite parent link to the main menu | `SLB` / `T01` / `T0104` |
| `sm_code` | VARCHAR(7) | ✔ | Sub menu — **nullable**, so a screen may hang directly off a main menu | `T010401` |
| `ts_code` | VARCHAR(11) | — | **UK.** The screen code. Appears in every test case code | `T0104010200` |
| `name` | VARCHAR(100) | — | Screen title | `Assign Subjects` |
| `description` | VARCHAR(1000) | ✔ | What the screen does | `Maps subjects to a class` |
| `route_url` | VARCHAR(500) | ✔ | Laravel route | `/syllabus/…/assign` |
| `folder_path` | VARCHAR(500) | ✔ | Source folder. **Used by Phase-2 path resolution** | `Modules/Syllabus/…` |
| `criticality` | ENUM | — | `View Only`, `View & Filter`, `Basic`, `Low`, `Medium`, `High`, `Critical`, `Duplicate`. The first two mark read-only screens that need lighter testing | `High` |
| `owner_user_code` | VARCHAR(3) | ✔ | Who owns this screen | `D02` |
| **— the authoring pipeline, one status per stage —** | | | | |
| `requir_doc_md_path` | VARCHAR(1000) | ✔ | Path to the requirement document | `docs/req/T0104010200.md` |
| `requir_doc_status` | ENUM | — | `Pending`, `In-Progress`, `In-Review`, `Completed`, `Error`, `Hold`, `Not-Required` | `Completed` |
| `tc_list_md_path` | VARCHAR(1000) | ✔ | Path to the test-list document | `docs/tclist/…md` |
| `tc_list_status` | ENUM | — | Same plus `Approved` | `Approved` |
| `dev_status` | ENUM | — | `Pending`, `Under-Development`, `In-Review`, `Ready-For-Testing`, `Testing-InProgress`, `Testing-Completed`, `Error`, `Hold`, `Not-Required` | `Ready-For-Testing` |
| `tc_creation_status` | ENUM | — | `Pending`, `In-Progress`, `Completed`, `Error`, `Hold`, `Not-Required` | `In-Progress` |
| `test_run_status` | ENUM | — | `Not-Run`, `Partially-Run`, `Fully-Run`, `Failing`, `Blocked` | `Partially-Run` |
| **— exclusion from testing scope —** | | | | |
| `is_excluded` | TINYINT(1) | — | `1` = out of testing scope. **Removed from the coverage denominator, never deleted** | `0` |
| `exclusion_reason` | VARCHAR(500) | ✔ | Why. Required in practice when excluding | `Legacy screen, retiring in Q4` |
| `excluded_by` / `excluded_at` | VARCHAR(3) / DATETIME | ✔ | Who decided, and when | `A01` / `2026-07-02` |
| **— provenance —** | | | | |
| `finding_method` | ENUM | — | `Manual`, `Discovery`, `Automated`. How this screen came to be catalogued | `Discovery` |
| `is_reviewed` | TINYINT(1) | — | A person has confirmed the screen belongs. **Discovery proposes; it does not decide** | `1` |
| `review_date` / `reviewed_by` / `review_comments` | DATETIME / VARCHAR(3) / VARCHAR(1000) | ✔ | The review record | `2026-08-14` / `A01` |
| `is_active` | TINYINT(1) | — | Screen still exists | `1` |

### Keys & rules

- `UNIQUE (ts_code)` — the parent key of every `ts_code` reference in the database.
- Composite FK `(module_code, cat_code, mm_code)` → `tst_main_menus`; separate nullable FK on `sm_code`.
- **A screen is excluded, never deleted.** Deleting it would orphan every historical result that referenced it.
- `FULLTEXT (name, description)` supports "find the screen about subject mapping".

**Why five status columns instead of one?** Because they answer five different questions, and a single "status" would hide four of them. `dev_status = Testing-Completed` with `tc_list_status = Pending` means development finished before anyone wrote down what to test — a gap you want visible.

---

# Section 4 — Authoring

## 4.1 `tst_tc_required_list` — the TcList

### What it is for

**What tests *should* exist for a screen, written before any of them are built.** This is the denominator of every coverage figure. Without it "Fees is about half tested" is a feeling; with it, "Fees has 214 required cases, 168 released, 31 in progress, 15 not started" is a number.

### Example rows

| tcr_code (GEN) | text_requir_detail | tc_creation_status |
|---|---|---|
| `D02A_T0104010200_0001` | Verify a subject can be assigned to a class | `Released` |
| `D02A_T0104010200_0002` | Verify duplicate subject assignment is rejected | `In-Progress` |
| `D02A_T0104010200_0003` | Verify assignment is blocked for an inactive class | `Planned` |
| `D02A_T0104010200_0004` | Verify the print button renders | `Not-Required` ← reason: *screen is view-only* |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `1180` |
| `user_code` | VARCHAR(3) | — | FK → `tst_users.code`. Who planned it | `D02` |
| `machine_code` | VARCHAR(4) | — | **FK → `tst_machines`. Feeds `tcr_code`, so RESTRICT only** | `D02A` |
| `ts_code` | VARCHAR(11) | — | **FK → `tst_tabs_screens`. Feeds `tcr_code`, so RESTRICT only** | `T0104010200` |
| `tc_list_number` | SMALLINT UNSIGNED | — | **UK.** Sequence within the screen for that machine | `1` |
| `tcr_code` | VARCHAR(21) | — | **GEN + UK.** `machine_code ‖ '_' ‖ ts_code ‖ '_' ‖ LPAD(tc_list_number, 4, '0')` | `D02A_T0104010200_0001` |
| `text_requir_detail` | VARCHAR(1000) | ✔ | What this test must verify, **in business language, before any code exists** | `Verify a subject can be assigned to a class` |
| `requir_steps_detail` | TEXT | ✔ | The required steps, in business language | `1. Open screen 2. Select class 3. …` |
| `tc_creation_status` | ENUM | — | `Planned`, `Pending`, `In-Progress`, `Ready`, `In_Review`, `Released`, `Error`, `Cancelled`, `Rolled_Back`, `Hold`, `Not-Required` | `Released` |
| `not_required_reason` | VARCHAR(500) | ✔ | **Mandatory when status is `Not-Required`.** Excludes the row from the coverage denominator | `Screen is view-only` |

### Keys & rules

- `UNIQUE (tcr_code)` · `UNIQUE (machine_code, ts_code, tc_list_number)`
- `CHECK` — `Not-Required` requires a reason. You cannot quietly shrink the denominator.
- **Coverage formula:** `released test cases ÷ required entries not marked Not-Required`.

> **Note on the sequence width.** `tc_list_number` is padded to **4** digits here (`_0001`) while `tc_seq_number` in `tst_test_cases` is padded to **3** (`_001`). Both columns are `VARCHAR(21)` and both work correctly, but the same conceptual position renders differently in the two codes. This is recorded as an open item in the BRD; align them if it causes confusion in practice.

## 4.2 `tst_test_cases` — the test case

### What it is for

The central table of the entire database. `test_case_code` is the **parent key of everything**: steps, reviews, version history, duplicate links, run items, results, bugs, dependencies, suite membership and path mappings all point at it.

### Example row

```
test_case_code       : D02A_T0104010200_001        ← GENERATED
tcr_code             : D02A_T0104010200_0001       ← the plan it satisfies
user_code / machine  : D02 / D02A
ts_code              : T0104010200
tc_seq_number        : 1
version_no           : 3
file_path            : tests/Browser/Syllabus/AssignSubjectTest.php
class_name           : AssignSubjectTest
method_name          : canAssignSubjectToClass
display_name         : "Assign a subject to a class"
test_method_code     : Automated       test_technology_code : Dusk
test_layer_code      : GUI             criticality          : High
creation_status_code : Released        test_execution_status: Fully-Run
definition_hash      : 7d41ba…
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK.** Internal only — never used as a cross-machine key | `2041` |
| `tcr_code` | VARCHAR(21) | ✔ | FK → `tst_tc_required_list.tcr_code`. **The planned entry this test satisfies.** Nullable, because a test discovered in the source may have no plan behind it | `D02A_T0104010200_0001` |
| `user_code` | VARCHAR(3) | — | FK → `tst_users`. The author | `D02` |
| `machine_code` | VARCHAR(4) | — | **Feeds `test_case_code` — RESTRICT only** | `D02A` |
| `ts_code` | VARCHAR(11) | — | **Feeds `test_case_code` — RESTRICT only** | `T0104010200` |
| `tc_seq_number` | SMALLINT UNSIGNED | — | **UK.** Allocated by `CodeFactory`; **never reused**, even after a soft delete | `1` |
| `test_case_code` | VARCHAR(21) | — | **GEN + UK.** `machine_code ‖ '_' ‖ ts_code ‖ '_' ‖ LPAD(tc_seq_number, 3, '0')` | `D02A_T0104010200_001` |
| `version_no` | TINYINT UNSIGNED | — | Increments when `definition_hash` changes | `3` |
| **— automation coordinates; NULL for a purely manual test —** | | | | |
| `file_path` | VARCHAR(500) | ✔ | Where the test lives in the source tree | `tests/Browser/…Test.php` |
| `namespace` | VARCHAR(255) | ✔ | PHP namespace | `Tests\Browser\Syllabus` |
| `class_name` | VARCHAR(150) | ✔ | PHP class | `AssignSubjectTest` |
| `method_name` | VARCHAR(150) | ✔ | The test method | `canAssignSubjectToClass` |
| **— definition —** | | | | |
| `display_name` | VARCHAR(255) | — | Human title shown everywhere | `Assign a subject to a class` |
| `description` | TEXT | ✔ | What it verifies and why | `Confirms the mapping persists…` |
| `preconditions` | TEXT | ✔ | What must be true before running | `A class and 3 subjects exist` |
| `test_data_note` | TEXT | ✔ | What data state it needs | `Uses tenant demo-01` |
| `test_case_type_code` | ENUM | ✔ | `Standard`, `Unit`, `Validation`, `Feature`, `Business_Condition` | `Feature` |
| `test_method_code` | ENUM | ✔ | `Manual`, `Automated`, `Hybrid` | `Automated` |
| `test_technology_code` | ENUM | ✔ | `Dusk`, `Laravel-Unit`, `Native` | `Dusk` |
| `test_layer_code` | ENUM | ✔ | `GUI`, `API`, `Unit`, `Integration`, `Performance`, `Security`, `Accessibility`, `Other` | `GUI` |
| `criticality` | ENUM | — | `Low`, `Medium`, `High`, `Critical`. Drives selection and alerting | `High` |
| `expected_duration_sec` | DECIMAL(10,2) | ✔ | Typical runtime — used to estimate a run | `12.50` |
| `definition_hash` | CHAR(64) | ✔ | sha256 over the normalised definition **including ordered steps**. Drives versioning and duplicate detection | `7d41ba…` |
| **— lifecycle —** | | | | |
| `creation_status_code` | ENUM | — | `Pending`, `In-Progress`, `Ready-For-Review`, `In-Review`, `Released`, `Cancelled`, `Rolled-Back`, `Hold`, `Not-Required` | `Released` |
| `test_execution_status` | ENUM | — | `Not-Run`, `Partially-Run`, `Fully-Run`, `Failing`, `Blocked` | `Fully-Run` |
| `is_orphaned` | TINYINT(1) | — | `1` = the implementation has vanished from the source tree. **Never deleted** | `0` |
| `orphaned_at` | DATETIME | ✔ | When it went missing | `NULL` |
| `last_seen_in_source_at` | DATETIME | ✔ | Last discovery scan that found the file | `2026-09-09 06:00` |
| `cloned_from_code` | VARCHAR(21) | ✔ | If copied from another test, its code | `T01A_T0104010200_004` |
| `is_active` | TINYINT(1) | — | `0` = **retired** | `1` |
| `retired_at` / `retired_by` / `retired_reason` | DATETIME / VARCHAR(3) / VARCHAR(500) | ✔ | The retirement record | `NULL` |

### Keys & rules

- `UNIQUE (test_case_code)` — **the parent key of the whole system.**
- `UNIQUE (machine_code, ts_code, tc_seq_number)` — the backstop if two concurrent inserts race for the same sequence.
- `CHECK` — retiring requires a reason (`is_active = 1 OR retired_reason IS NOT NULL`).
- **A test case cannot be moved to another screen.** Its code names its screen; testing a different screen is a different test case.
- **`definition_hash` does two jobs.** When it changes, the *previous* definition is snapshotted to `tst_test_case_versions_history` and `version_no` increments. Two test cases with the *same* hash are the same test written twice — `tst_duplicate_test_case` records the judgement.

## 4.3 `tst_test_case_steps`

### What it is for
The ordered steps a manual or hybrid test follows. **Holds only the current version** — historical steps live in the version snapshot.

### Example rows

| test_case_code | step_no | action | expected_result | is_optional |
|---|:---:|---|---|:---:|
| `D02A_T0104010200_001` | 1 | Log in as a school admin | Dashboard loads | 0 |
| `D02A_T0104010200_001` | 2 | Open Syllabus → Assign Subjects | Screen renders with the class dropdown | 0 |
| `D02A_T0104010200_001` | 3 | Select class "Grade 5" and subject "Maths", click Save | Success toast appears | 0 |
| `D02A_T0104010200_001` | 4 | Reload the page | "Maths" is listed against Grade 5 | 0 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `9912` |
| `test_case_code` | VARCHAR(21) | — | **UK.** FK → `tst_test_cases`. `ON DELETE CASCADE` | `D02A_T0104010200_001` |
| `step_no` | SMALLINT UNSIGNED | — | **UK.** Order, starting at 1 | `3` |
| `action` | TEXT | — | What the tester does | `Select class "Grade 5"…` |
| `expected_result` | TEXT | — | What must happen | `Success toast appears` |
| `test_data_note` | VARCHAR(1000) | ✔ | Data this step needs | `Grade 5 must exist` |
| `is_optional` | TINYINT(1) | — | A step that may be skipped without failing the test | `0` |

### Keys & rules
`UNIQUE (test_case_code, step_no)` · `CHECK (step_no >= 1)`.

**Why only the current version?** A manual tester replaying a historical run must see the steps *as they were*, and that comes from `steps_json` in the version history. Keeping every version here would force the grid query to filter on version on every load — on the table read most often during manual testing.

## 4.4 `tst_test_case_review` — review, readiness and sign-off

### What it is for

The record of a test case being reviewed, scored and released. **This table replaces the Release entity** of earlier versions: the unit of release here is the test case, not a named delivery.

### Example row

```
test_case_code       : D02A_T0104010200_001
version_no           : 3            ← the version that was reviewed
machine_code         : T01A         ← where the review was done
review_date          : 2026-09-05 11:00
status               : Released
readiness_score      : 92.00
readiness_assessment : "All 4 steps deterministic. No hard waits. Assertions cover both
                        the toast and the persisted row. No open bugs on this screen."
review_note          : "Suggest extracting the login into a helper. Not blocking."
reviewed_by          : T01 (Sameer)     reviewed_at   : 2026-09-05 11:40
sign_off_note        : "Approved for the nightly regression set."
signed_off_by        : A01 (Brijesh)    signed_off_at : 2026-09-05 14:10
bug_in_testcase      : 0    known_issues_in_scope : 0
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `310` |
| `test_case_code` | VARCHAR(21) | — | **UK.** FK → `tst_test_cases` | `D02A_T0104010200_001` |
| `version_no` | TINYINT UNSIGNED | — | **UK. Deliberately has NO foreign key** — see the note below | `3` |
| `machine_code` | VARCHAR(4) | — | **UK.** FK → `tst_machines`. Where the review happened | `T01A` |
| `review_date` | DATETIME | — | **UK.** The business date of the review | `2026-09-05 11:00` |
| `status` | ENUM | — | `Pending`, `In-Progress`, `Completed`, `Released`, `Error`, `Cancelled`, `Rolled-Back`, `Hold`, `Not-Required` | `Released` |
| `released_at` | DATETIME | ✔ | When it became released | `2026-09-05 14:10` |
| `readiness_score` | DECIMAL(5,2) | ✔ | 0–100. Metrics, completion checks, bug-free status | `92.00` |
| `readiness_assessment` | TEXT | ✔ | The reasoning behind the score | *see example above* |
| `review_note` | VARCHAR(1000) | ✔ | **Technical review:** step correctness, script logic, assertion accuracy, quality, suggestions | `Suggest extracting the login…` |
| `reviewed_by` / `reviewed_at` | VARCHAR(3) / DATETIME | ✔ | **Who reviewed the content** | `T01` |
| `sign_off_note` | TEXT | ✔ | **Sign-off:** authorisation, risk acceptance, release clearance | `Approved for the nightly set` |
| `signed_off_by` / `signed_off_at` | VARCHAR(3) / DATETIME | ✔ | **Who authorised the release** | `A01` |
| `bug_in_testcase` | TINYINT(1) | — | The test itself contains a defect | `0` |
| `known_issues_in_scope` | TINYINT(1) | — | This test knowingly covers an accepted known issue | `0` |

### Keys & rules

- `UNIQUE (test_case_code, version_no, machine_code, review_date)` — a test case may be reviewed repeatedly; each review is its own record.
- `CHECK` — `readiness_score` between 0 and 100.
- **Reviewer and approver are separate columns on purpose.** Putting them in one field makes "who signed this off?" unanswerable in the case that matters most: when somebody reviewed their own work. They may be the same person, and the record shows it.
- **A review is retained as issued.** Once `status = Completed`, the score and assessment are not edited. Later data never retrospectively improves a judgement made on what was known at the time.

> **Why `version_no` has no foreign key.** It records the version as it stood at review time. A foreign key to `tst_test_case_versions_history` would make reviewing version 1 *impossible*, because that table only holds **superseded** definitions — version 1's row does not exist until version 2 is written. This is intentional; do not "fix" it.

## 4.5 `tst_test_case_versions_history`

### What it is for
An **immutable snapshot of a previous definition**, written when `definition_hash` changes. It lets a result from six months ago be rendered as the test case stood when it ran.

### Example row
`D02A_T0104010200_001` version 2 · display name *"Assign subject"* · 3 steps in `steps_json` · change summary *"Added the reload-and-verify step"* · captured from commit `9c2e14a…`

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `4410` |
| `test_case_code` | VARCHAR(21) | — | **UK.** FK → `tst_test_cases`, `ON DELETE CASCADE` | `D02A_T0104010200_001` |
| `version_no` | TINYINT UNSIGNED | — | **UK.** The version being preserved | `2` |
| `definition_hash` | CHAR(64) | ✔ | The hash at that version | `3a91cd…` |
| `file_path` / `class_name` / `method_name` | VARCHAR(500)/(150)/(150) | ✔ | Automation coordinates as they then were | `…AssignSubjectTest.php` |
| `display_name` / `description` / `preconditions` | VARCHAR(255) / TEXT / TEXT | ✔ | The definition as it then was | `Assign subject` |
| `steps_json` | JSON | ✔ | **The ordered steps at that version** | `[{"no":1,"action":"…"}]` |
| `test_case_type_code` | VARCHAR(30) | ✔ | Type as it then was. **Stored as VARCHAR, not ENUM, so a later ENUM change never invalidates history** | `Feature` |
| `test_method_code` | VARCHAR(30) | ✔ | Method as it then was | `Automated` |
| `test_technology_code` | VARCHAR(30) | ✔ | Technology as it then was | `Dusk` |
| `test_layer_code` | VARCHAR(30) | ✔ | Layer as it then was | `GUI` |
| `criticality` | ENUM | ✔ | Criticality at that version | `Medium` |
| `change_summary` | VARCHAR(1000) | ✔ | What changed and why | `Added the reload-and-verify step` |
| `captured_from_commit_hash` | VARCHAR(40) | ✔ | The commit it was captured at. **40 chars — a Git SHA-1 is 40 hex characters** | `9c2e14a…` |
| `captured_by` | VARCHAR(3) | — | Who or what captured it | `S02` |

### Keys & rules
`UNIQUE (test_case_code, version_no)`. Insert-only — there is no update path and no `deleted_at`.

## 4.6 `tst_duplicate_test_case` — the equivalence judgement

### What it is for

Two people can legitimately write the same test on different machines and get two different codes. **This table records the human decision about whether they are actually the same test.** It replaced the whole "source test case" quarantine mechanism of earlier versions.

### Example rows

| test_case_code | linked_test_case_code | link_type | score | decided_by |
|---|---|---|---:|---|
| `D02A_T0104010200_001` | `T01A_T0104010200_003` | `Confirmed_Equivalent` | 0.940 | `A01` |
| `D02A_T0104010200_002` | `T01A_T0104010200_005` | `Confirmed_Different` | 0.810 | `A01` |
| `D02A_T0104010200_007` | `D02B_T0104010200_001` | `Proposed_Equivalent` | 0.880 | *(undecided)* |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `77` |
| `test_case_code` | VARCHAR(21) | — | FK → `tst_test_cases`, `ON DELETE CASCADE` | `D02A_T0104010200_001` |
| `linked_test_case_code` | VARCHAR(21) | — | FK → `tst_test_cases`, `ON DELETE CASCADE`. The other test | `T01A_T0104010200_003` |
| `link_type` | ENUM | — | `Proposed_Equivalent`, `Confirmed_Equivalent`, `Confirmed_Different`, `Duplicate_Of`, `Variant_Of`, `Supersedes` | `Confirmed_Equivalent` |
| `score` | DECIMAL(4,3) | ✔ | 0.000–1.000 — how strongly the system thinks they match | `0.940` |
| `evidence_json` | JSON | ✔ | **Why** the system proposed it: hash similarity, same screen, similar steps | `{"hash_distance":0.06}` |
| `proposed_by` | VARCHAR(3) | ✔ | A person, or the system user `S02` | `S02` |
| `decided_by` | VARCHAR(3) | ✔ | **QA Lead or Architect — never automatic** | `A01` |
| `decided_at` | DATETIME | ✔ | When the judgement was made | `2026-09-06 09:20` |
| `note` | VARCHAR(1000) | ✔ | The reasoning | `Same assertion, different data set` |
| `superseded_at` | DATETIME | ✔ | Set when a later row reverses this decision | `NULL` |

### Keys & rules

- `CHECK` — a test cannot link to itself; `score` between 0 and 1.
- **Insert-only.** A reversal writes a *new* row and stamps `superseded_at` on the old one, so the decision history survives.
- **`Confirmed_Different` is as valuable as `Confirmed_Equivalent`.** Without it, the system re-proposes the same rejected match forever.
- A confirmed duplicate is **not deleted**. Both test cases keep their evidence; reporting counts the primary one.

---

# Section 5 — Execution

```
tst_test_runs                one execution EVENT
  ├── tst_test_run_scopes    why the run exists
  └── tst_test_run_items     which test cases, and WHY each one
        └── tst_test_run_results     one row per ATTEMPT — insert-only
              ├── tst_test_run_result_steps   per-step outcomes (manual tests)
              └── tst_run_result_artifacts    screenshots, logs, video
tst_failure_signatures       distinct normalised failures
tst_test_case_runs_summary   DERIVED roll-up
```

## 5.1 `tst_test_runs` — one execution event

### What it is for

A **run** is one execution event covering many test cases: "the nightly Fees regression on Tarun's machine at 02:00 against commit a3f9c2". It records who, where, when, against which code, in which environment, and how it ended.

> **A run is not a test case.** The per-test-case link lives in `tst_test_run_items`.

### Example row

```
id 5501 · machine_id 11 · source_run_id 5501 · run_machine_code D02A · run_user_code D02
trigger_type    : Scheduled       schedule_id : 3
initiated_by    : D02 (Tarun set the schedule up)
executed_by     : S02 (the system ran it at 02:00)
repository_code : prime-ai        branch_name : develop
commit_hash     : a3f9c2e1b4…     working_tree_dirty : 0
environment_profile_id : 7
status          : Completed
started_at      : 2026-09-09 02:00:11   finished_at : 2026-09-09 02:07:48
total_tc_count 12 · passed 10 · failed 1 · blocked 1
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK.** Local auto-increment; **re-issued on the central database** | `5501` |
| `machine_id` | SMALLINT UNSIGNED | — | **UK.** FK → `tst_machines.id`. Which installation produced this row | `11` |
| `source_run_id` | BIGINT UNSIGNED | — | **UK.** Locally this equals `id`. On central it keeps the *source machine's* id | `5501` |
| `run_machine_code` | VARCHAR(4) | — | FK → `tst_machines.machine_code`. Readable in exports and logs | `D02A` |
| `run_user_code` | VARCHAR(3) | — | FK → `tst_users.code`. Whose machine it is | `D02` |
| `entry_type` | ENUM | — | `Local` (created here) or `Imported` (arrived in a bundle) | `Local` |
| `initiated_by` | VARCHAR(3) | ✔ | **Who asked for it** — a person, even for a scheduled run | `D02` |
| `executed_by` | VARCHAR(3) | ✔ | **Who ran it** — the system user for a scheduled run | `S02` |
| `trigger_type` | ENUM | — | `Manual`, `Scheduled`, `Rerun`, `Auto_Retest`, `Bug_Retest`, `Impact_Selected`, `Enhancement`, `Integration`, `Regression`, `Git_Merge`, `Release`, `CI` | `Scheduled` |
| `suite_id` **[P2]** | INT UNSIGNED | ✔ | Which suite produced this run. Stays NULL until Phase 2 | `NULL` |
| `suite_version_no` **[P2]** | INT UNSIGNED | ✔ | **The suite composition actually executed** — so a historical run is reproducible even after the suite changes | `NULL` |
| `impact_analysis_id` **[P2]** | BIGINT UNSIGNED | ✔ | Which impact analysis selected these tests | `NULL` |
| `schedule_id` | INT UNSIGNED | ✔ | FK → `tst_schedules.id` (added in Section 12 of the DDL) | `3` |
| `parent_run_id` | BIGINT UNSIGNED | ✔ | For a rerun or retest of an earlier run | `NULL` |
| `run_name` | VARCHAR(200) | ✔ | Friendly label | `Nightly Fees regression` |
| `reason` | VARCHAR(500) | ✔ | Why this run was started | `Scheduled nightly pass` |
| **— the code version under test —** | | | | |
| `repository_code` | VARCHAR(100) | ✔ | Which repository | `prime-ai` |
| `branch_name` | VARCHAR(200) | ✔ | Which branch | `develop` |
| `commit_hash` | VARCHAR(40) | ✔ | **The exact commit.** Without this a result cannot be interpreted historically | `a3f9c2e1b4…` |
| `merge_commit_hash` / `base_commit_hash` | VARCHAR(40) | ✔ | Merge context, when relevant | `NULL` |
| `working_tree_dirty` | TINYINT(1) | — | `1` = uncommitted changes were present. **A dirty run cannot be reproduced from the commit alone** | `0` |
| **— environment —** | | | | |
| `environment_profile_id` | INT UNSIGNED | ✔ | FK → `tst_environment_profiles` | `7` |
| `environment_json` | JSON | ✔ | The raw capture the fingerprint was built from | `{"os":"Windows 10",…}` |
| `command` | VARCHAR(2000) | ✔ | The exact command line executed | `php artisan dusk --group=fees` |
| **— lifecycle —** | | | | |
| `status` | ENUM | — | `Queued`, `Running`, `Completed`, `Failed`, `Cancelled`, `Interrupted`, `Timed_Out` | `Completed` |
| `queued_at` / `started_at` / `finished_at` | DATETIME | ✔ | Timeline | `2026-09-09 02:00:11` |
| `duration_seconds` | DECIMAL(12,3) | ✔ | Wall-clock duration | `457.220` |
| `exit_code` | SMALLINT | ✔ | Process exit code | `1` |
| `heartbeat_at` | DATETIME | ✔ | **Updated while running.** A watchdog moves a run whose heartbeat stops to `Interrupted`, keeping every result already recorded | `2026-09-09 02:07:40` |
| `lock_token` | CHAR(36) | ✔ | Prevents two processes claiming the same run | `9f1a…` |
| `cancelled_by` / `cancelled_at` / `cancel_reason` | VARCHAR(3) / DATETIME / VARCHAR(500) | ✔ | Who stopped it and why | `D02` / `Wrong branch` |
| **— roll-ups, RECOMPUTED from results over final attempts only —** | | | | |
| `total_tc_count` | MEDIUMINT UNSIGNED | — | Test cases in the run | `12` |
| `passed_tc_count` | MEDIUMINT UNSIGNED | — | Final attempts that passed | `10` |
| `failed_tc_count` | MEDIUMINT UNSIGNED | — | Final attempts that failed | `1` |
| `error_tc_count` | MEDIUMINT UNSIGNED | — | Final attempts that errored | `0` |
| `skipped_tc_count` | MEDIUMINT UNSIGNED | — | Final attempts skipped | `0` |
| `blocked_tc_count` | MEDIUMINT UNSIGNED | — | Blocked by a failed prerequisite | `1` |
| `not_executed_tc_count` | MEDIUMINT UNSIGNED | — | Selected but never reached | `0` |
| `total_assertion_count` | INT UNSIGNED | — | Assertions executed across the run | `184` |
| `passed_assertion_count` | INT UNSIGNED | — | Assertions that passed | `181` |
| `failed_assertion_count` | INT UNSIGNED | — | Assertions that failed | `3` |
| `raw_output_path` | VARCHAR(1000) | ✔ | The raw console output file | `D:\evidence\5501\out.log` |

### Keys & rules

- `UNIQUE (machine_id, source_run_id)` — **this is what makes a repeated import a no-op.** Import the same bundle twice and the second attempt matches instead of duplicating.
- **Roll-ups are recomputed, never incremented.** An incremental counter drifts; a recomputed one cannot disagree with the results underneath it.
- `INDEX (status, heartbeat_at)` serves the interruption watchdog.

**Why `initiated_by` and `executed_by` are separate.** A scheduled run at 2 a.m. was *asked for* by Tarun weeks ago and *executed by* the system user. Recording only one of them loses the distinction, and "who ran this?" becomes unanswerable in exactly the case where you need it.

## 5.2 `tst_test_run_scopes` — why the run exists

### What it is for
What the run was **asked to cover**. One run may have several scope rows: "the Fees module, plus these three screens, plus bug 412".

### Example rows

| run_id | scope_type | module_code | ts_code | test_case_code | bug_id | description |
|---:|---|---|---|---|---:|---|
| 5501 | `Module` | `SLB` | — | — | — | Nightly Syllabus pass |
| 5510 | `Bug` | — | — | — | 412 | Retest for BUG-000412 |
| 5511 | `Screen` | — | `T0104010200` | — | — | Ad-hoc check |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `8801` |
| `run_id` | BIGINT UNSIGNED | — | FK → `tst_test_runs`, `ON DELETE CASCADE` | `5501` |
| `scope_type` | ENUM | — | `Module`, `Screen`, `TestCase`, `Suite`, `Bug`, `Change_Request`, `Commit`, `Impact_Analysis`, `Release`, `Full`. **`Suite` and `Change_Request` are unreachable until Phase 2** | `Module` |
| `module_code` | VARCHAR(5) | ✔ | FK → `tst_modules` | `SLB` |
| `ts_code` | VARCHAR(11) | ✔ | FK → `tst_tabs_screens` | `T0104010200` |
| `test_case_code` | VARCHAR(21) | ✔ | FK → `tst_test_cases` | `D02A_T0104010200_001` |
| `bug_id` | BIGINT UNSIGNED | ✔ | FK → `tst_bugs` (added in Section 12) | `412` |
| `suite_id` **[P2]** | INT UNSIGNED | ✔ | FK added in Phase 2 | `NULL` |
| `change_request_id` **[P2]** | BIGINT UNSIGNED | ✔ | FK added in Phase 2 | `NULL` |
| `repository_code` / `commit_hash` | VARCHAR(100) / (40) | ✔ | For a commit-scoped run | `prime-ai` / `a3f9c2…` |
| `description` | VARCHAR(500) | ✔ | Free-text explanation | `Nightly Syllabus pass` |

## 5.3 `tst_test_run_items` — which test cases, and WHY

### What it is for

One row per test case selected into one run, **with the reason it was selected**. A month later, "why did we run these 40 tests?" is answerable from the data — which is what makes Phase-2 impact analysis explainable after the fact.

### Example row

```
run_id 5501 · test_case_code D02A_T0104010200_001
selection_reason      : Schedule
selection_source      : "schedule#3 target: module SLB"
sequence_no           : 4
test_case_version_no  : 3                                ← snapshot
display_name_snapshot : "Assign a subject to a class"    ← snapshot
file_path_snapshot    : tests/Browser/…AssignSubjectTest.php
criticality_snapshot  : High
attempt_count         : 1
final_status          : Failed
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `66102` |
| `run_id` | BIGINT UNSIGNED | — | **UK.** FK → `tst_test_runs`, `ON DELETE CASCADE` | `5501` |
| `test_case_code` | VARCHAR(21) | — | **UK.** FK → `tst_test_cases`, `ON DELETE RESTRICT` | `D02A_T0104010200_001` |
| `selection_reason` | ENUM | — | `Manual`, `Suite`, `Direct_Change`, `Dependency`, `Bug_Retest`, `Critical`, `Regression`, `Full_Regression`, `Historical_Correlation`, `Open_Bug`, `Schedule`, `Other`. **In Phase 1 the reachable values are Manual, Bug_Retest, Critical, Regression, Schedule and Open_Bug** | `Schedule` |
| `selection_source` | VARCHAR(255) | ✔ | The commit, rule or analysis that put it here | `schedule#3 target: module SLB` |
| `selection_confidence` | DECIMAL(4,3) | ✔ | How confident the selector was (Phase 2 mostly) | `NULL` |
| `sequence_no` | INT UNSIGNED | — | Execution order within the run | `4` |
| **— snapshots taken AT SELECTION TIME —** | | | | |
| `test_case_version_no` | INT UNSIGNED | ✔ | Which version was executed | `3` |
| `display_name_snapshot` | VARCHAR(255) | — | The name as it then was | `Assign a subject to a class` |
| `file_path_snapshot` | VARCHAR(500) | ✔ | The file path as it then was | `tests/Browser/…php` |
| `criticality_snapshot` | ENUM | ✔ | Criticality as it then was | `High` |
| **— blocking —** | | | | |
| `blocked_by_item_id` | BIGINT UNSIGNED | ✔ | Self-FK. The item whose failure blocked this one. **Phase-2 semantics** | `NULL` |
| `blocked_reason` | VARCHAR(500) | ✔ | Why it never ran | `Prerequisite login test failed` |
| `attempt_count` | SMALLINT UNSIGNED | — | How many attempts were made | `1` |
| `final_status` | ENUM | ✔ | `Passed`, `Failed`, `Error`, `Skipped`, `Blocked`, `Not_Executed`. The outcome of the **final** attempt | `Failed` |

### Keys & rules

- `UNIQUE (run_id, test_case_code)` — one item per test case per run.
- **Why the snapshots matter.** Rename a test case tomorrow and, without `display_name_snapshot`, every historical run silently re-labels itself. The snapshot means a six-month-old run renders as it was.

## 5.4 `tst_test_run_results` — ONE ROW PER ATTEMPT

### What it is for

**The single source of truth from which every statistic in the system is derived.** Insert-only: nothing in the application ever updates a status here. A re-execution is a *new* row with `attempt_no + 1`.

### Example rows

| id | run_item_id | attempt_no | is_final | status | error_message | triage_state |
|---:|---:|:---:|:---:|---|---|---|
| 91201 | 66102 | 1 | 0 | `Failed` | `Expected toast not found` | `New_Bug` |
| 91344 | 66102 | 2 | **1** | `Failed` | `Expected toast not found` | `Existing_Bug` |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `91344` |
| `run_id` | BIGINT UNSIGNED | — | FK → `tst_test_runs`, `ON DELETE CASCADE` | `5501` |
| `run_item_id` | BIGINT UNSIGNED | — | **UK.** FK → `tst_test_run_items`, `ON DELETE CASCADE` | `66102` |
| `test_case_code` | VARCHAR(21) | ✔ | **Denormalised** from the run item. Every history query starts from a test case, and this avoids a join across millions of rows | `D02A_T0104010200_001` |
| `machine_id` | SMALLINT UNSIGNED | — | FK → `tst_machines.id` | `11` |
| `run_machine_code` | VARCHAR(4) | ✔ | Denormalised code — readable in exports and logs | `D02A` |
| `environment_profile_id` | INT UNSIGNED | ✔ | FK → `tst_environment_profiles` | `7` |
| `attempt_no` | SMALLINT UNSIGNED | — | **UK.** 1, 2, 3 … | `2` |
| `is_final_attempt` | TINYINT(1) | — | Exactly one attempt per item is final. **All statistics count final attempts only** | `1` |
| `status` | ENUM | — | `Passed`, `Failed`, `Error`, `Skipped`, **`Blocked`**, **`Not_Executed`** | `Failed` |
| `executed_by` | VARCHAR(3) | ✔ | Who ran this attempt | `S02` |
| `started_at` / `finished_at` | DATETIME | ✔ | Attempt timeline | `02:03:11` / `02:03:24` |
| `duration_seconds` | DECIMAL(12,3) | ✔ | How long it took | `13.400` |
| `assertions` | INT UNSIGNED | — | Assertions executed | `7` |
| `display_name_snapshot` | VARCHAR(255) | — | The name at execution time | `Assign a subject to a class` |
| **— failure detail —** | | | | |
| `error_message` | TEXT | ✔ | The failure message | `Expected toast not found` |
| `error_trace` | MEDIUMTEXT | ✔ | Full stack trace | `#0 /var/www/…` |
| `exception_class` | VARCHAR(255) | ✔ | The exception type | `Facebook\WebDriver\…\TimeoutException` |
| `failure_fingerprint` | CHAR(64) | ✔ | **Normalised hash** — timestamps, ids, memory addresses and absolute paths stripped, so the same failure fingerprints identically everywhere | `c81b4d…` |
| `failure_signature_id` | BIGINT UNSIGNED | ✔ | FK → `tst_failure_signatures` (added in Section 12) | `18` |
| **— triage —** | | | | |
| `triage_state` | ENUM | — | `Untriaged`, `New_Bug`, `Existing_Bug`, `Known_Issue`, `Flaky`, `Environment`, `Test_Defect`, `Data_Issue`, `Expected`. **A failure is not automatically a bug** | `Existing_Bug` |
| `triaged_by` / `triaged_at` / `triage_note` | VARCHAR(3) / DATETIME / VARCHAR(1000) | ✔ | Who decided, when, and why | `T01` |
| `result_json` | JSON | ✔ | Raw adapter payload from Dusk/PHPUnit | `{"time":13.4,…}` |
| `consistency_note` | VARCHAR(1000) | ✔ | Explains a result that disagrees with its own step outcomes | `All steps passed but overall failed on teardown` |

### Keys & rules

- `UNIQUE (run_item_id, attempt_no)` — attempts are numbered, never overwritten.
- `INDEX (test_case_code, is_final_attempt, status, created_at)` — the index behind every history and pass-rate query.
- **`Blocked` and `Not_Executed` matter more than they look.** Recording a blocked test as `Failed` inflates defect counts and sends somebody to investigate a test that never executed. `Not_Executed` means it was selected but the run was interrupted before reaching it.

## 5.5 `tst_test_run_result_steps`

### What it is for
Per-step outcomes for a manual or hybrid test. The step text is **snapshotted**, not referenced, so a historical result shows the steps the tester actually followed.

### Example rows

| run_result_id | step_no | action_snapshot | status | actual_result |
|---:|:---:|---|---|---|
| 91344 | 1 | Log in as a school admin | `Passed` | Dashboard loaded |
| 91344 | 2 | Open Syllabus → Assign Subjects | `Passed` | Screen rendered |
| 91344 | 3 | Select Grade 5 + Maths, click Save | `Failed` | **No toast; page hung 30s** |
| 91344 | 4 | Reload the page | `Blocked` | Not attempted — step 3 failed |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `220331` |
| `run_result_id` | BIGINT UNSIGNED | — | **UK.** FK → `tst_test_run_results`, `ON DELETE CASCADE` | `91344` |
| `step_no` | SMALLINT UNSIGNED | — | **UK.** Step order | `3` |
| `action_snapshot` | TEXT | — | **The step as it was when executed** | `Select Grade 5 + Maths…` |
| `expected_snapshot` | TEXT | — | The expectation as it then was | `Success toast appears` |
| `status` | ENUM | — | `Passed`, `Failed`, `Blocked`, `Skipped`, `Not_Executed` | `Failed` |
| `actual_result` | TEXT | ✔ | What actually happened. **Mandatory in practice for any Failed or Blocked step** | `No toast; page hung 30s` |
| `note` | VARCHAR(1000) | ✔ | Tester's observation | `Reproduced 3 times` |
| `duration_seconds` | DECIMAL(10,2) | ✔ | Time on this step | `30.10` |

## 5.6 `tst_run_result_artifacts` — evidence

### What it is for
Screenshots, console logs, page source, video and any other file kept with a result. Replaces the three fixed path columns of earlier versions, which left video and per-step screenshots nowhere to go.

### Example rows

| run_result_id | step_no | artifact_type | file_path | is_available |
|---:|:---:|---|---|:---:|
| 91344 | 3 | `Screenshot` | `D:\evidence\5501\91344_step3.png` | 1 |
| 91344 | — | `Console_Log` | `D:\evidence\5501\91344_console.txt` | 1 |
| 91344 | — | `Video` | `D:\evidence\5501\91344.mp4` | **0** ← purged after 180 days |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `440912` |
| `run_result_id` | BIGINT UNSIGNED | — | FK → `tst_test_run_results`, `ON DELETE CASCADE` | `91344` |
| `step_no` | SMALLINT UNSIGNED | ✔ | Set when the artefact belongs to one manual step | `3` |
| `artifact_type` | ENUM | — | `Screenshot`, `Console_Log`, `Page_Source`, `Video`, `Network_Log`, `Raw_Output`, `Trace`, `Attachment`, `Other` | `Screenshot` |
| `file_path` | VARCHAR(1000) | — | Where the file lives on the evidence store | `D:\evidence\…png` |
| `file_sha256` | CHAR(64) | ✔ | Content hash — **identical artefacts are stored once and referenced many times** | `ab34f1…` |
| `bytes` | BIGINT UNSIGNED | ✔ | File size | `184320` |
| `mime_type` | VARCHAR(100) | ✔ | Content type | `image/png` |
| `caption` | VARCHAR(500) | ✔ | What the artefact shows | `Screen after clicking Save` |
| `is_available` | TINYINT(1) | — | **`0` = purged by retention. The row REMAINS.** The result then shows "evidence expired" rather than appearing never to have had any | `1` |
| `expires_at` / `purged_at` | DATETIME | ✔ | Retention dates | `2027-03-08` / `NULL` |

> **"Evidence expired" and "never had evidence" are different facts**, and the difference matters when somebody a year later is deciding whether an old conclusion can be re-examined.

## 5.7 `tst_failure_signatures` — turning forty failures into one problem

### What it is for

One row per **distinct normalised failure**. Without grouping, triage volume scales with test count instead of defect count, and the team stops triaging — which is how a real defect ends up buried under thirty-nine duplicates of itself.

### Example row

```
fingerprint         : c81b4d9e…
exception_class     : Facebook\WebDriver\Exception\TimeoutException
normalised_message  : "Waited 30 seconds for selector .toast-success"
top_frames          : "AssignSubjectTest::canAssignSubjectToClass; Browser::waitFor"
occurrence_count    : 41
distinct_test_cases : 3
distinct_machines   : 2
bug_id              : 412        ← triaged once; later matches attach automatically
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `18` |
| `fingerprint` | CHAR(64) | — | **UK.** The normalised hash | `c81b4d9e…` |
| `exception_class` | VARCHAR(255) | ✔ | Exception type | `…TimeoutException` |
| `normalised_message` | VARCHAR(1000) | ✔ | Message with variable parts stripped | `Waited 30 seconds for selector .toast-success` |
| `top_frames` | VARCHAR(1000) | ✔ | **Top application frames, vendor frames removed** — vendor frames are identical across unrelated failures | `AssignSubjectTest::…` |
| `sample_result_id` | BIGINT UNSIGNED | ✔ | One representative result to open when investigating | `91344` |
| `first_seen_at` / `last_seen_at` | DATETIME | ✔ | Lifespan of this failure | `2026-09-01` / `2026-09-09` |
| `occurrence_count` | BIGINT UNSIGNED | — | How many results share it | `41` |
| `distinct_test_cases` | INT UNSIGNED | — | **How many different tests hit it.** 3 tests × 1 cause = 1 bug, not 3 | `3` |
| `distinct_machines` | SMALLINT UNSIGNED | — | On how many machines. `1` hints at an environment problem | `2` |
| `bug_id` | BIGINT UNSIGNED | ✔ | Once triaged, matching failures attach here automatically | `412` |
| `known_issue_id` | BIGINT UNSIGNED | ✔ | Or to an accepted known issue | `NULL` |

## 5.8 `tst_test_case_runs_summary` — DERIVED statistics

### What it is for

A pre-computed picture of each test case's health, so dashboards do not aggregate millions of result rows. **Every column here must be reproducible from `tst_test_run_results` alone** — a nightly job compares the incremental values against a full rebuild and *reports* divergence rather than silently correcting it.

### Example row

```
test_case_code       : D02A_T0104010200_001
last_status          : Failed         last_run_at    : 2026-09-09 02:03
last_passed_at       : 2026-09-06 02:04
consecutive_failures : 3              consecutive_passes : 0
total_runs 88 · passed 71 · failed 14 · error 1 · skipped 1 · blocked 1
pass_rate_30d        : 62.50          pass_rate_all  : 80.68
avg_duration_seconds : 11.240         max : 30.100
distinct_machines 2 · distinct_environments 3
is_flaky_candidate 0 · is_flaky_confirmed 0
confidence_score     : 54.00
health_status        : Frequently_Failing
open_bug_count       : 1
last_rebuilt_at      : 2026-09-09 03:00      rebuild_source : Incremental
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `2041` |
| `test_case_code` | VARCHAR(21) | — | **UK.** FK → `tst_test_cases`, `ON DELETE CASCADE`. One row per test case | `D02A_T0104010200_001` |
| `first_run_at` | DATETIME | ✔ | First ever execution | `2026-06-14` |
| `last_run_id` / `last_run_result_id` | BIGINT UNSIGNED | ✔ | The most recent run and result | `5501` / `91344` |
| `last_status` | ENUM | ✔ | Outcome of the last final attempt | `Failed` |
| `last_run_at` / `last_passed_at` / `last_failed_at` | DATETIME | ✔ | **`last_passed_at` is what makes regression detection possible** | `2026-09-06 02:04` |
| `consecutive_failures` | INT UNSIGNED | — | Drives escalation | `3` |
| `consecutive_passes` | INT UNSIGNED | — | Confidence signal | `0` |
| `total_runs` | BIGINT UNSIGNED | — | Lifetime executions (final attempts) | `88` |
| `total_passed` | BIGINT UNSIGNED | — | Lifetime passes | `71` |
| `total_failed` | BIGINT UNSIGNED | — | Lifetime failures | `14` |
| `total_error` | BIGINT UNSIGNED | — | Lifetime errors | `1` |
| `total_skipped` | BIGINT UNSIGNED | — | Lifetime skips | `1` |
| `total_blocked` | BIGINT UNSIGNED | — | Lifetime blocks | `1` |
| `pass_rate_30d` / `pass_rate_all` | DECIMAL(5,2) | ✔ | Percentages | `62.50` / `80.68` |
| `avg_duration_seconds` / `max_duration_seconds` | DECIMAL(12,3) | ✔ | Runtime profile — a sudden jump often precedes a timeout failure | `11.240` / `30.100` |
| `distinct_machines` / `distinct_environments` | SMALLINT UNSIGNED | — | Breadth of evidence. **A green result seen on one machine is weaker than one seen on three** | `2` / `3` |
| **— flakiness —** | | | | |
| `flaky_score` | DECIMAL(4,3) | ✔ | Computed instability score | `0.180` |
| `is_flaky_candidate` | TINYINT(1) | — | The algorithm proposes it: 2+ outcome alternations in the last 10 runs, same environment, no intervening change | `0` |
| `is_flaky_confirmed` | TINYINT(1) | — | **A person agreed.** Confirmation is never automatic | `0` |
| `flaky_reason` | VARCHAR(500) | ✔ | Why it was flagged or cleared | `Insufficient history` |
| `flaky_evidence_json` | JSON | ✔ | **The outcome series, environment and change check** — so the conclusion can be re-argued a year later | `{"series":["P","F","P",…]}` |
| `flaky_confirmed_by` / `flaky_confirmed_at` | VARCHAR(3) / DATETIME | ✔ | Who confirmed it | `NULL` |
| **— derived indicators —** | | | | |
| `confidence_score` | DECIMAL(5,2) | ✔ | 0–100. **How much to trust this green tick** — combines pass rate, recency, evidence completeness, flakiness and open defects | `54.00` |
| `confidence_json` | JSON | ✔ | The inputs, so the score is explainable rather than magic | `{"recency":0.4,…}` |
| `health_status` | ENUM | — | `Healthy`, `Unstable`, `Frequently_Failing`, `Obsolete`, `Blocked`, `Insufficient_History`, `Under_Investigation`, `Orphaned` | `Frequently_Failing` |
| `open_bug_count` | SMALLINT UNSIGNED | — | Open defects referencing this test | `1` |
| `last_rebuilt_at` | DATETIME | ✔ | **Provenance** — a dashboard number whose freshness is unknown is a rumour | `2026-09-09 03:00` |
| `rebuild_source` | ENUM | — | `Incremental` or `Full_Rebuild` | `Incremental` |

> **This table is a convenience, never a source of truth.** If it ever disagrees with `tst_test_run_results`, the results win and this table is rebuilt.

---

# Section 6 — Scheduling

## 6.1 `tst_schedules` — when to run

### What it is for
A cron-driven execution schedule with an owner, a catch-up policy and a **missed count**. A schedule that did not fire is recorded as *missed*, not silently skipped — otherwise silence and success look identical until a release goes out untested.

### Example row

```
name             : "Nightly Syllabus + Fees"
owner_user_code  : D02
cron_expression  : "0 2 * * *"      timezone : Asia/Kolkata
catch_up_policy  : Skip
is_active 1 · is_suspended 0
next_run_at      : 2026-09-10 02:00
last_run_id 5501 · last_run_at 2026-09-09 02:00 · last_status Success
missed_count     : 2
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `3` |
| `name` | VARCHAR(150) | — | **UK.** Schedule name | `Nightly Syllabus + Fees` |
| `description` | VARCHAR(500) | ✔ | What it is for | `Full regression on the two busiest modules` |
| `owner_user_code` | VARCHAR(3) | — | FK → `tst_users`. **Answerable when it fails or is missed** | `D02` |
| `suite_id` **[P2]** | INT UNSIGNED | ✔ | Run a suite instead of explicit targets. NULL until Phase 2 | `NULL` |
| `cron_expression` | VARCHAR(100) | — | Standard 5-field cron | `0 2 * * *` |
| `timezone` | VARCHAR(64) | — | Cron is evaluated in this zone | `Asia/Kolkata` |
| `catch_up_policy` | ENUM | — | `Skip`, `Run_Once`, `Run_All` — what to do about firings missed while a machine was off | `Skip` |
| `is_active` | TINYINT(1) | — | Enabled | `1` |
| `is_suspended` | TINYINT(1) | — | **Temporarily held — different from deactivated** | `0` |
| `suspended_reason` | VARCHAR(500) | ✔ | **Mandatory when suspended** | `NULL` |
| `next_run_at` | DATETIME | ✔ | Next computed firing time | `2026-09-10 02:00` |
| `last_run_id` / `last_run_at` / `last_status` | BIGINT / DATETIME / ENUM | ✔ | The last firing. `last_status` ∈ `Success`, `Failed`, `Missed`, `Cancelled` | `5501` / `Success` |
| `missed_count` | INT UNSIGNED | — | **How many firings never happened.** A rising number is an operational signal | `2` |

### Keys & rules
`UNIQUE (name)` · `CHECK` — suspension requires a reason.

## 6.2 `tst_schedule_targets` — what to run, and on WHICH machine

### What it is for

**New in v7.2.** One `machine_id` column on the schedule cannot express *"run Syllabus on Tarun's machine and Examination on Sameer's, every night"*. This table can.

### Example rows

| schedule_id | target_type | module_code | ts_code | test_case_code | machine_code | seq |
|---:|---|---|---|---|---|---:|
| 3 | `Module` | `SLB` | — | — | **`D02A`** | 1 |
| 3 | `Module` | `EXM` | — | — | **`T01A`** | 2 |
| 3 | `Screen` | — | `T0104010200` | — | **`D02B`** | 3 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `27` |
| `schedule_id` | INT UNSIGNED | — | FK → `tst_schedules`, `ON DELETE CASCADE` | `3` |
| `target_type` | ENUM | — | `Module`, `Screen`, `TestCase` | `Module` |
| `module_code` | VARCHAR(5) | ✔ | Set when `target_type = Module` | `SLB` |
| `ts_code` | VARCHAR(11) | ✔ | Set when `target_type = Screen` | `NULL` |
| `test_case_code` | VARCHAR(21) | ✔ | Set when `target_type = TestCase` | `NULL` |
| `machine_code` | VARCHAR(4) | — | **FK → `tst_machines`. Which machine executes this target** | `D02A` |
| `sequence_no` | INT UNSIGNED | — | Order within the schedule | `1` |
| `is_active` | TINYINT(1) | — | Target enabled | `1` |

### Keys & rules

- `CHECK` — exactly the right reference must be present for the declared `target_type`. You cannot create a `Module` target that also names a screen.
- `INDEX (machine_code, schedule_id, is_active)` serves the dispatcher.
- **How dispatch works:** the job runs every minute on *every* machine, selects the targets whose `machine_code` matches the local machine and whose schedule is due, and creates one run per target group. A machine that is switched off produces a missed count on **its own** targets only — it does not block the others.

---

# Section 7 — Comments and Discovery

## 7.1 `tst_run_annotations` — Comments Management

### What it is for
Where a reviewer or developer records what they concluded about a run, or about one specific result inside it. These are evidence: they consolidate with the run they belong to.

### Example rows

| run_id | run_result_id | user_code | annotation_type | comment |
|---:|---:|---|---|---|
| 5501 | — | `T01` | `Review` | Nightly pass reviewed. 1 real failure, 1 blocked. |
| 5501 | 91344 | `D02` | `Investigation` | Toast selector changed in commit a3f9c2. Test needs updating. |
| 5501 | 91344 | `T01` | `Attribution` | Matches known issue KI-0007 → linked. |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `1502` |
| `run_id` | BIGINT UNSIGNED | — | FK → `tst_test_runs`, `ON DELETE CASCADE` | `5501` |
| `run_result_id` | BIGINT UNSIGNED | ✔ | FK → `tst_test_run_results`. **NULL when the note is about the run as a whole** | `91344` |
| `user_code` | VARCHAR(3) | — | FK → `tst_users`. Who wrote it | `D02` |
| `annotation_type` | ENUM | — | `Comment`, `Review`, `Investigation`, `Attribution`, `Decision` | `Investigation` |
| `comment` | VARCHAR(500) | — | The short version, shown in lists | `Toast selector changed…` |
| `note` | TEXT | ✔ | The long version | *(full analysis)* |
| `known_issue_id` | BIGINT UNSIGNED | ✔ | FK → `tst_known_issues` (added in Section 12). Attributes a failure to an accepted issue | `7` |

## 7.2 `tst_discovery_sync_logs` — Discovery

### What it is for

The log of each scan of the Prime-AI source tree. Discovery finds test files, reconciles them against the catalog, and reports drift: new tests, missing modules and screens, and orphaned test cases whose implementation has vanished.

> **Discovery never deletes and never writes catalog data.** It proposes; items wait for review. Otherwise a refactor that moves a directory silently retires two hundred test cases overnight.

### Example row

```
machine_id 11 · source_sync_id 340 · user_code D02
sync_mode        : Discover
repository_code  : prime-ai       commit_hash : a3f9c2e1b4…
folder_path      : D:\work\prime-ai\tests\Browser
started_at 2026-09-09 06:00:02 · finished_at 06:03:41 · duration 219.00s
status           : Success
modules_found 12 · screens_found 418
missing_modules 0 · missing_screens 6          ← code exists, catalog does not know
test_cases_found 1204 · added 7 · updated 3 · orphaned 2 · unchanged 1192
items_pending_review : 15                       ← proposals waiting for a human
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `340` |
| `machine_id` | SMALLINT UNSIGNED | — | **UK.** FK → `tst_machines.id`. Which machine scanned | `11` |
| `source_sync_id` | BIGINT UNSIGNED | — | **UK.** Distributed identity, so re-import is a no-op | `340` |
| `user_code` | VARCHAR(3) | — | FK → `tst_users`. Who ran the scan | `D02` |
| `sync_mode` | ENUM | — | `Discover` (scan source), `Import` (read a file), `Catalog_Bundle` (apply a catalog) | `Discover` |
| `import_format` | ENUM | ✔ | `CSV`, `Excel`, `JSON`, `NDJSON`, `Other` — only for import mode | `NULL` |
| `repository_code` / `commit_hash` | VARCHAR(100) / (40) | ✔ | **The code version that was scanned** | `prime-ai` / `a3f9c2…` |
| `folder_path` / `file_name` / `file_path` | VARCHAR(1000)/(500)/(1000) | ✔ | What was scanned | `…\tests\Browser` |
| `started_at` / `finished_at` / `duration_seconds` | DATETIME / DECIMAL(10,2) | ✔ | Timing | `06:00:02` / `219.00` |
| `status` | ENUM | — | `Running`, `Success`, `Partial`, `Failed` | `Success` |
| `modules_found` / `screens_found` | INT UNSIGNED | — | What the scan saw in the source | `12` / `418` |
| `missing_modules` / `missing_screens` | INT UNSIGNED | — | **Code that exists with no catalog entry** — a coverage blind spot | `0` / `6` |
| `test_cases_found` | INT UNSIGNED | — | Test methods detected | `1204` |
| `test_cases_added` | INT UNSIGNED | — | New ones proposed | `7` |
| `test_cases_updated` | INT UNSIGNED | — | Definitions that changed | `3` |
| `test_cases_orphaned` | INT UNSIGNED | — | **Catalog entries whose file has gone** | `2` |
| `test_cases_unchanged` | INT UNSIGNED | — | Untouched. A rescan of an unchanged tree changes nothing | `1192` |
| `items_pending_review` | INT UNSIGNED | — | **Proposals awaiting a human decision** | `15` |
| `details_json` | JSON | ✔ | Full per-item detail | `{"orphaned":["D02A_…_004"]}` |
| `error_message` | TEXT | ✔ | Why it failed or was partial | `NULL` |

### Keys & rules
`UNIQUE (machine_id, source_sync_id)` — idempotent re-import.

---

# Section 8 — Defects

Three concepts kept strictly apart:

| Concept | Table | Meaning |
|---|---|---|
| **Known Issue** | `tst_known_issues` | An **accepted** problem whose recurrence is expected. Not re-triaged every time |
| **Bug** | `tst_bugs` | **One problem** in Prime-AI |
| **Occurrence** | `tst_bug_occurrences` | **One observation** of that problem in one result. One bug → many occurrences |

Conflating bug and occurrence inflates defect counts and makes triage duplicate itself.

## 8.1 `tst_known_issues`

### What it is for
A documented problem the team has **decided not to fix yet**, so that its recurrence does not get re-triaged as new every week. The `rationale` column is the important one: without it, nobody in six months can re-judge the decision.

### Example row

```
issue_code          : KI-0007
title               : "Toast disappears before Dusk asserts on slow CI"
rationale           : "Root cause is a 300ms animation in a shared component. Fixing it
                       affects 40 screens. Deferred to the UI refresh in Q1."
category            : Deferred_Defect
module_code SLB · ts_code T0104010200
failure_fingerprint : c81b4d9e…      ← matching failures attach automatically
owner_user_code     : A01
status              : Active
review_due_at       : 2026-12-31     ← on expiry it reverts to normal defect treatment
occurrence_count    : 63
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `7` |
| `issue_code` | VARCHAR(40) | — | **UK.** Human reference | `KI-0007` |
| `title` | VARCHAR(255) | — | Short description | `Toast disappears before Dusk asserts` |
| `description` | TEXT | ✔ | Full description | *(detail)* |
| `rationale` | TEXT | ✔ | **WHY it is accepted rather than fixed.** Without this the decision cannot be re-judged | `Fixing it affects 40 screens…` |
| `category` | ENUM | — | `Product_Limitation`, `Environment`, `Third_Party`, `Test_Data`, `Deferred_Defect`, `Infrastructure`, `Other` | `Deferred_Defect` |
| `module_code` / `ts_code` | VARCHAR(5) / (11) | ✔ | Where it lives | `SLB` / `T0104010200` |
| `failure_fingerprint` | CHAR(64) | ✔ | **Auto-attributes matching failures**, so they are never re-triaged | `c81b4d9e…` |
| `owner_user_code` | VARCHAR(3) | — | FK → `tst_users`. Who is answerable | `A01` |
| `status` | ENUM | — | `Active`, `Expired`, `Promoted_To_Bug`, `Resolved`, `Withdrawn` | `Active` |
| `review_due_at` | DATE | ✔ | **On expiry it reverts to normal defect treatment and notifies the owner.** An accepted issue with no review date becomes permanent by neglect | `2026-12-31` |
| `expired_at` | DATETIME | ✔ | When it expired | `NULL` |
| `promoted_bug_id` | BIGINT UNSIGNED | ✔ | FK → `tst_bugs`. **Retains the occurrence history** when the team decides to fix it after all | `NULL` |
| `occurrence_count` | BIGINT UNSIGNED | — | How often it has recurred | `63` |
| `first_seen_at` / `last_seen_at` | DATETIME | ✔ | Lifespan | `2026-07-02` / `2026-09-09` |

## 8.2 `tst_known_issue_results`

### What it is for
The link table recording **every recurrence** of a known issue, so accepted problems stay countable rather than invisible.

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `known_issue_id` | BIGINT UNSIGNED | — | **PK.** FK → `tst_known_issues`, `ON DELETE CASCADE` | `7` |
| `run_result_id` | BIGINT UNSIGNED | — | **PK.** FK → `tst_test_run_results`, `ON DELETE CASCADE` | `91344` |
| `attributed_by` | VARCHAR(3) | ✔ | **NULL when attributed automatically by fingerprint** | `NULL` |
| `note` | VARCHAR(500) | ✔ | Any qualification | `Same symptom, different screen` |

### Keys & rules
Composite primary key — one attribution per issue per result.

## 8.3 `tst_bugs` — one problem in Prime-AI

### What it is for
A confirmed or suspected defect. **Fixed does not equal verified**: closing a bug properly requires a passing retest result in `verified_result_id`.

### Example row

```
id 412 · origin_machine_id 13 · source_bug_id 412 · bug_code BUG-000412
discovered_by   : T01
first_detected_run_id 5501 · first_detected_result_id 91344
module_code SLB · ts_code T0104010200 · test_case_code D02A_T0104010200_001
title           : "Subject assignment saves but no confirmation toast appears"
severity High · priority High · status Closed
resolution      : Fixed
root_cause_category : UI
environment_profile_id 7 · observed_commit_hash a3f9c2e1b4…
assigned_to D02 · assigned_at 2026-09-09 09:15 · sla_due_at 2026-09-11 09:15
fixed_by D02 · fixed_at 2026-09-09 16:40 · fixed_commit_hash 7e21b9c…
verified_by T01 · verified_at 2026-09-10 02:12 · verified_result_id 91502
verification_override 0
occurrence_count 41 · reopen_count 0 · retest_attempt_count 1
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `412` |
| `origin_machine_id` | SMALLINT UNSIGNED | — | **UK.** FK → `tst_machines.id`. Where the bug was raised | `13` |
| `source_bug_id` | BIGINT UNSIGNED | — | **UK.** Distributed identity — a bug can be raised on any machine and consolidate without collision | `412` |
| `bug_code` | VARCHAR(30) | ✔ | **UK.** Display code people quote in conversation | `BUG-000412` |
| `discovered_by` | VARCHAR(3) | ✔ | Who found it | `T01` |
| `first_detected_run_id` / `first_detected_result_id` | BIGINT UNSIGNED | ✔ | The exact run and result that first showed it | `5501` / `91344` |
| `module_code` | VARCHAR(5) | — | FK → `tst_modules` | `SLB` |
| `ts_code` | VARCHAR(11) | ✔ | FK → `tst_tabs_screens` | `T0104010200` |
| `test_case_code` | VARCHAR(21) | ✔ | FK → `tst_test_cases`. The test that detected it | `D02A_T0104010200_001` |
| `change_request_id` **[P2]** | BIGINT UNSIGNED | ✔ | Which change introduced it. NULL until Phase 2 | `NULL` |
| `failure_signature_id` | BIGINT UNSIGNED | ✔ | FK → `tst_failure_signatures`. **Later matching failures attach automatically** | `18` |
| `title` | VARCHAR(255) | — | Short statement of the problem | `Subject assignment saves but no toast` |
| `description` | TEXT | ✔ | Full description | *(detail)* |
| `steps_to_reproduce` | TEXT | ✔ | How to see it | `1. Open… 2. Select… 3. Save` |
| `expected_behaviour` / `actual_behaviour` | TEXT | ✔ | The two halves of any defect report | `Toast appears` / `Nothing appears` |
| `severity` | ENUM | — | `Low`, `Medium`, `High`, `Critical`. **How bad it is** | `High` |
| `priority` | ENUM | — | `Low`, `Medium`, `High`, `Critical`. **How soon we will fix it.** Deliberately separate from severity | `High` |
| `status` | ENUM | — | `Open`, `Assigned`, `In_Progress`, `Fixed`, `Retesting`, `Reopened`, `Closed`, `Escalated`, `Wont_Fix`, `Duplicate` | `Closed` |
| `resolution` | ENUM | ✔ | `Fixed`, `Not_A_Defect`, `Duplicate`, `Cannot_Reproduce`, `Wont_Fix`, `Known_Issue`, `Test_Defect`, `Environment` | `Fixed` |
| `root_cause_category` | ENUM | ✔ | `Logic`, `Validation`, `Data`, `Tenancy`, `Permission`, `Integration`, `UI`, `Performance`, `Configuration`, `Environment`, `Test_Defect`, `Other`. **Aggregating this tells you where your defects actually come from** | `UI` |
| `root_cause_note` | TEXT | ✔ | The explanation | `Animation removed the node before assert` |
| `environment_profile_id` | INT UNSIGNED | ✔ | Where it was observed | `7` |
| `observed_commit_hash` | VARCHAR(40) | ✔ | Which code version showed it | `a3f9c2e1b4…` |
| **— assignment and SLA —** | | | | |
| `assigned_to` / `assigned_by` / `assigned_at` | VARCHAR(3) / VARCHAR(3) / DATETIME | ✔ | Who owns the fix | `D02` / `T01` |
| `sla_due_at` | DATETIME | ✔ | Set on assignment from `bug_fix_sla_hours` | `2026-09-11 09:15` |
| `sla_breached` | TINYINT(1) | — | **Recorded, not merely alerted** — so breach rate is reportable | `0` |
| **— fix and verification —** | | | | |
| `fixed_by` / `fixed_at` | VARCHAR(3) / DATETIME | ✔ | Who declared it fixed | `D02` |
| `fixed_commit_hash` | VARCHAR(40) | ✔ | **The commit that fixed it** | `7e21b9c…` |
| `fix_notes` | TEXT | ✔ | What was changed | `Replaced animation with a persistent flag` |
| `verified_by` / `verified_at` | VARCHAR(3) / DATETIME | ✔ | Who confirmed the fix works | `T01` |
| `verified_result_id` | BIGINT UNSIGNED | ✔ | **Must be a PASSING retest result.** This is the difference between "he said he fixed it" and "we saw it pass" | `91502` |
| `verification_override` | TINYINT(1) | — | `1` = closed **without** a passing retest | `0` |
| `verification_override_reason` | VARCHAR(1000) | ✔ | **Mandatory when overriding.** Makes the exception visible and countable | `NULL` |
| `reopen_count` | SMALLINT UNSIGNED | — | How often it came back. **A high number means the fix never addressed the cause** | `0` |
| `occurrence_count` | INT UNSIGNED | — | Total observations | `41` |
| `retest_attempt_count` | SMALLINT UNSIGNED | — | Retest cycles so far; bounded by `max_auto_retest_attempts` | `1` |
| `escalated_at` / `escalation_reason` | DATETIME / VARCHAR(500) | ✔ | When automation gave up and asked a human | `NULL` |
| `duplicate_of_bug_id` | BIGINT UNSIGNED | ✔ | Self-FK. The primary bug when this is a duplicate | `NULL` |
| `known_issue_id` | BIGINT UNSIGNED | ✔ | FK → `tst_known_issues`, when triaged as accepted | `NULL` |
| `closed_by` / `closed_at` | VARCHAR(3) / DATETIME | ✔ | Who closed it | `T01` |

### Keys & rules

- `UNIQUE (origin_machine_id, source_bug_id)` · `UNIQUE (bug_code)`
- `CHECK` — `verification_override = 0 OR verification_override_reason IS NOT NULL`.
- **Severity and priority are separate on purpose.** A cosmetic typo on the login page can be Low severity and High priority.

## 8.4 `tst_bug_occurrences`

### What it is for
Every time the bug was **observed** in a result. One bug, many occurrences. This is what stops the same defect being counted forty-one times.

### Example rows

| bug_id | run_result_id | occurrence_type | matched_by | confirmed_by |
|---:|---:|---|---|---|
| 412 | 91344 | `First_Detected` | `Manual` | `T01` |
| 412 | 91389 | `Reproduced` | `Fingerprint` | *(auto)* |
| 412 | 91502 | `Retest_Passed` | `Manual` | `T01` |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `2210` |
| `bug_id` | BIGINT UNSIGNED | — | **UK.** FK → `tst_bugs`, `ON DELETE CASCADE` | `412` |
| `run_result_id` | BIGINT UNSIGNED | — | **UK.** FK → `tst_test_run_results`, `ON DELETE CASCADE` | `91344` |
| `occurrence_type` | ENUM | — | `First_Detected`, `Reproduced`, `Regression`, `Retest_Failed`, `Retest_Passed`, `Other` | `Reproduced` |
| `matched_by` | ENUM | — | `Manual`, `Fingerprint` (automatic), `AI_Proposal` | `Fingerprint` |
| `confirmed_by` | VARCHAR(3) | ✔ | NULL when matched automatically | `NULL` |
| `note` | VARCHAR(500) | ✔ | Anything worth adding | `Also seen on D02B` |

### Keys & rules
`UNIQUE (bug_id, run_result_id)` — one occurrence per bug per result.

## 8.5 `tst_bug_status_history`

### What it is for
Every status transition of every bug, insert-only. This is what makes "how long did this sit in Assigned?" answerable.

### Example rows

| bug_id | from_status | to_status | from_assignee | to_assignee | changed_by | is_system_action |
|---:|---|---|---|---|---|:---:|
| 412 | — | `Open` | — | — | `T01` | 0 |
| 412 | `Open` | `Assigned` | — | `D02` | `T01` | 0 |
| 412 | `Assigned` | `In_Progress` | `D02` | `D02` | `D02` | 0 |
| 412 | `In_Progress` | `Fixed` | `D02` | `D02` | `D02` | 0 |
| 412 | `Fixed` | `Retesting` | `D02` | `D02` | `S02` | **1** |
| 412 | `Retesting` | `Closed` | `D02` | — | `T01` | 0 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `9014` |
| `bug_id` | BIGINT UNSIGNED | — | FK → `tst_bugs`, `ON DELETE CASCADE` | `412` |
| `from_status` / `to_status` | VARCHAR(30) | ✔ / — | The transition. `from_status` is NULL on creation | `Fixed` → `Retesting` |
| `from_assignee` / `to_assignee` | VARCHAR(3) | ✔ | Ownership change, if any | `D02` |
| `changed_by` | VARCHAR(3) | ✔ | Who did it. **The system user `S02` for an automatic transition** | `S02` |
| `is_system_action` | TINYINT(1) | — | `1` = automation, not a person | `1` |
| `note` | TEXT | ✔ | Why | `Auto-retest triggered on Fixed` |

## 8.6 `tst_bug_comments`

### What it is for
Discussion attached to a bug.

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `3312` |
| `bug_id` | BIGINT UNSIGNED | — | FK → `tst_bugs`, `ON DELETE CASCADE` | `412` |
| `user_code` | VARCHAR(3) | — | FK → `tst_users`. Author | `D02` |
| `comment` | TEXT | — | The comment | `Reproduced on D02B too` |
| `is_internal` | TINYINT(1) | — | `1` = visible only to the team, not in a shared report | `0` |

## 8.7 `tst_bug_links`

### What it is for
Relationships between bugs — duplicates, blockers, causes. Insert-only, like the test-case equivalence table.

### Example rows

| bug_id | linked_bug_id | link_type | score | decided_by |
|---:|---:|---|---:|---|
| 412 | 388 | `Duplicate_Of` | 0.910 | `A01` |
| 415 | 412 | `Blocked_By` | — | `T01` |
| 431 | 412 | `Regression_Of` | 0.760 | `A01` |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `144` |
| `bug_id` / `linked_bug_id` | BIGINT UNSIGNED | — | FK → `tst_bugs`, both `ON DELETE CASCADE` | `412` / `388` |
| `link_type` | ENUM | — | `Proposed_Duplicate`, `Duplicate_Of`, `Related`, `Blocks`, `Blocked_By`, `Caused_By`, `Causes`, `Regression_Of` | `Duplicate_Of` |
| `score` | DECIMAL(4,3) | ✔ | How strongly the system thinks they match | `0.910` |
| `evidence_json` | JSON | ✔ | Why it was proposed | `{"same_fingerprint":true}` |
| `proposed_by` / `decided_by` / `decided_at` | VARCHAR(3) / VARCHAR(3) / DATETIME | ✔ | Proposed by system or person; **confirmed by a person** | `S02` / `A01` |
| `note` | VARCHAR(500) | ✔ | Reasoning | `Same signature, same screen` |
| `superseded_at` | DATETIME | ✔ | Set when a later row reverses this decision | `NULL` |

### Keys & rules
`CHECK` — a bug cannot link to itself. Insert-only; reversals supersede rather than delete.

## 8.8 `tst_retest_cycles`

### What it is for
One managed attempt to **verify a fix**. The retest never overwrites the original failure — it is a new run producing new results, so the evidence of what went wrong survives.

### Example row

```
bug_id 412 · cycle_number 1
trigger_source : Auto_On_Fixed      triggered_by : S02
triggered_at   : 2026-09-09 16:41   (one minute after the bug was marked Fixed)
run_id         : 5510
scope_policy   : Screen             ← the failing test plus others on the same screen
status         : Passed             completed_at : 2026-09-10 02:14
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `701` |
| `bug_id` | BIGINT UNSIGNED | — | **UK.** FK → `tst_bugs`, `ON DELETE CASCADE` | `412` |
| `cycle_number` | SMALLINT UNSIGNED | — | **UK.** 1, 2, 3 … **bounded by `max_auto_retest_attempts`**, after which the bug escalates | `1` |
| `trigger_source` | ENUM | — | `Auto_On_Fixed`, `Manual`, `Scheduled`, `Release_Gate` | `Auto_On_Fixed` |
| `triggered_by` | VARCHAR(3) | ✔ | Who or what triggered it | `S02` |
| `triggered_at` | DATETIME | — | When | `2026-09-09 16:41` |
| `run_id` | BIGINT UNSIGNED | ✔ | FK → `tst_test_runs`. The run that carried out the retest | `5510` |
| `scope_policy` | ENUM | — | `Test_Only`, `Screen`, `Screen_Plus_Dependencies`, `Module`, `Regression_Suite`. **`Screen_Plus_Dependencies` behaves as `Screen` until Phase 2 supplies the dependency graph** | `Screen` |
| `scope_json` | JSON | ✔ | The resolved scope | `{"ts_code":"T0104010200"}` |
| `status` | ENUM | — | `Pending`, `Running`, `Passed`, `Failed`, `Not_Covered`, `Cancelled`. **`Not_Covered` means no test exists to verify this fix** — an important and easily hidden situation | `Passed` |
| `completed_at` | DATETIME | ✔ | When it finished | `2026-09-10 02:14` |
| `note` | VARCHAR(1000) | ✔ | Anything worth recording | `Verified on D02A and T01A` |

### Keys & rules
`UNIQUE (bug_id, cycle_number)`. **Automation with no bound is how a broken fix generates four hundred runs overnight** — hence the cycle limit and the escalation.

## 8.9 `tst_retest_cycle_bugs`

### What it is for
One retest cycle may verify **several** bugs at once — a single Fees regression pass can confirm four fixes.

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `retest_cycle_id` | BIGINT UNSIGNED | — | **PK.** FK → `tst_retest_cycles`, `ON DELETE CASCADE` | `701` |
| `bug_id` | BIGINT UNSIGNED | — | **PK.** FK → `tst_bugs`, `ON DELETE CASCADE` | `412` |
| `outcome` | ENUM | — | `Pending`, `Passed`, `Failed`, `Not_Covered`, `Blocked` | `Passed` |
| `verifying_result_id` | BIGINT UNSIGNED | ✔ | FK → `tst_test_run_results`. **The specific passing result that verified this bug** | `91502` |
| `note` | VARCHAR(500) | ✔ | Qualification | `Verified by the reload assertion` |

---

# Section 9 — Export, Import and Consolidation

## 9.1 `tst_data_exports`

### What it is for
A bundle of data leaving this machine. Two directions with different rules: **catalog out** (central → local) and **evidence in** (local → central).

### Example row

```
machine_id 11 · source_export_id 88 · user_code D02
export_name    : "D02A evidence 2026-09-01 to 09-09"
export_type    : Incremental      direction : Evidence_Out
date_from 2026-09-01 · date_to 2026-09-09
app_version 1.0.0 · schema_version 7.2.0
file_path      : D:\exports\D02A_20260909.zip     file_bytes : 48,221,904
artifact_count : 3,412            includes_artifacts : 1
status         : Completed
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `88` |
| `machine_id` | SMALLINT UNSIGNED | — | **UK.** FK → `tst_machines.id`. Which machine produced it | `11` |
| `source_export_id` | BIGINT UNSIGNED | — | **UK.** Distributed identity | `88` |
| `user_code` | VARCHAR(3) | — | FK → `tst_users`. Who exported | `D02` |
| `export_name` | VARCHAR(200) | — | Friendly label | `D02A evidence 2026-09-01 to 09-09` |
| `export_type` | ENUM | — | `Full`, `Incremental`, `Selected`, `Catalog_Bundle` | `Incremental` |
| `direction` | ENUM | — | **`Evidence_Out`** (local → central) or **`Catalog_Out`** (central → local) | `Evidence_Out` |
| `date_from` / `date_to` | DATETIME | ✔ | The period covered | `2026-09-01` / `2026-09-09` |
| `modules_json` | JSON | ✔ | Which modules were included, if filtered | `["SLB","EXM"]` |
| `app_version` | VARCHAR(20) | — | App version that built the bundle | `1.0.0` |
| `schema_version` | VARCHAR(20) | — | **Read from `tst_app_settings`. The importer compares it before applying anything** | `7.2.0` |
| `file_path` / `file_bytes` | VARCHAR(1000) / BIGINT | ✔ | Where the bundle is and how big | `D:\exports\…zip` |
| `manifest_json` | JSON | ✔ | **Counts, per-file checksums, period, source identity.** The importer validates against this | `{"files":{…}}` |
| `record_counts_json` | JSON | ✔ | Rows per table | `{"tst_test_runs":14,…}` |
| `artifact_count` | INT UNSIGNED | — | Evidence files included | `3412` |
| `includes_artifacts` | TINYINT(1) | — | `0` = metadata only, for a small bundle over a slow link | `1` |
| `status` | ENUM | — | `Pending`, `In_Progress`, `Completed`, `Failed` | `Completed` |
| `error_message` | TEXT | ✔ | Why it failed | `NULL` |
| `exported_at` | DATETIME | ✔ | When the file was written | `2026-09-09 18:02` |

## 9.2 `tst_data_imports`

### What it is for
Applying a bundle. **Idempotent** — the same bundle applied twice creates nothing the second time. **Reversible** — every row it touched is recorded in the record map.

### Example row

```
source_machine_id 11 · source_export_id 88 · imported_by A01
source_app_version 1.0.0 · source_schema_version 7.2.0
version_decision  : Same_Version
status            : Completed
records_created 1204 · records_matched 318 · records_rejected 0
conflict_count 2 · open_conflict_count 1
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `55` |
| `source_machine_id` | SMALLINT UNSIGNED | — | **UK.** FK → `tst_machines.id`. Which machine sent it | `11` |
| `source_export_id` | BIGINT UNSIGNED | — | **UK.** The export id on that machine. **This pair is what makes a repeated import a no-op** | `88` |
| `imported_by` | VARCHAR(3) | — | FK → `tst_users`. Who applied it | `A01` |
| `file_name` | VARCHAR(500) | ✔ | The bundle file | `D02A_20260909.zip` |
| `source_app_version` / `source_schema_version` | VARCHAR(20) | ✔ | What the bundle was built with | `1.0.0` / `7.2.0` |
| `version_decision` | ENUM | ✔ | `Same_Version`, `Migrated_On_Read`, `Rejected_Incompatible`. **An incompatible bundle is refused with a stated reason, not partially applied** | `Same_Version` |
| `version_decision_note` | VARCHAR(500) | ✔ | The explanation | `NULL` |
| `status` | ENUM | — | `Received`, `Validating`, `Applying`, `Completed`, `Partial`, `Rejected`, `Reversed` | `Completed` |
| `started_at` / `finished_at` | DATETIME | ✔ | Timing | `18:20` / `18:31` |
| `records_created` | INT UNSIGNED | — | New rows | `1204` |
| `records_matched` | INT UNSIGNED | — | **Already present and skipped. A high number is idempotency working, not a problem** | `318` |
| `records_rejected` | INT UNSIGNED | — | Rows that could not be applied | `0` |
| `conflict_count` / `open_conflict_count` | INT UNSIGNED | — | Total and still-unresolved conflicts | `2` / `1` |
| `record_counts_json` / `manifest_json` | JSON | ✔ | What arrived and what was claimed | `{…}` |
| `error_message` | TEXT | ✔ | Failure detail | `NULL` |
| `reversed_by` / `reversed_at` / `reversal_reason` | VARCHAR(3) / DATETIME / VARCHAR(500) | ✔ | **Withdrawal record.** Reason is mandatory when reversed | `NULL` |

### Keys & rules
`UNIQUE (source_machine_id, source_export_id)` · `CHECK` — reversal requires a reason.

## 9.3 `tst_import_record_map`

### What it is for
**Every record an import created or matched**, with its source identity and the local id or code it was given. Without this table an import cannot be withdrawn, and a bad merge becomes permanent.

### Example rows

| import_id | entity_type | source_machine_id | source_id | source_code | local_id | local_code | action |
|---:|---|---:|---:|---|---:|---|---|
| 55 | `tst_test_cases` | 11 | 2041 | `D02A_T0104010200_001` | 8802 | `D02A_T0104010200_001` | `Created` |
| 55 | `tst_test_runs` | 11 | 5501 | — | 90114 | — | `Created` |
| 55 | `tst_test_cases` | 11 | 2042 | `D02A_T0104010200_002` | 8803 | `D02A_T0104010200_002` | `Matched` |

**Notice:** the `id` changed on import (2041 → 8802) but the **code did not**. That is the whole point of the coding system.

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `41120` |
| `import_id` | BIGINT UNSIGNED | — | FK → `tst_data_imports`, `ON DELETE CASCADE` | `55` |
| `entity_type` | VARCHAR(64) | — | **UK.** Which table | `tst_test_runs` |
| `source_machine_id` | SMALLINT UNSIGNED | — | **UK.** Which machine it came from | `11` |
| `source_id` | BIGINT UNSIGNED | ✔ | **UK.** The local id it had on the source machine | `5501` |
| `source_code` | VARCHAR(120) | ✔ | **UK.** Or its business code — **now the usual case** | `D02A_T0104010200_001` |
| `local_id` | BIGINT UNSIGNED | ✔ | The id it was given here | `90114` |
| `local_code` | VARCHAR(120) | ✔ | The code here — identical to `source_code` for coded entities | `D02A_T0104010200_001` |
| `action` | ENUM | — | `Created`, `Matched`, `Updated`, `Skipped` | `Created` |

## 9.4 `tst_import_conflicts`

### What it is for
When a bundle disagrees with what is already here, **both versions are kept in full and a person decides**. Nothing is resolved by a coin toss.

### Example rows

| conflict_type | entity_type | source_identity | severity | status |
|---|---|---|---|---|
| `Missing_Catalog_Reference` | `tst_test_cases` | `D02A_T0199990000_001` | `Blocking` | `Open` |
| `Definition_Divergence` | `tst_test_cases` | `D02A_T0104010200_001` | `Warning` | `Resolved_Accept_Incoming` |
| `Duplicate_Business_Code` | `tst_machines` | `D02A` | **`Blocking`** | `Open` |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `912` |
| `import_id` | BIGINT UNSIGNED | — | FK → `tst_data_imports`, `ON DELETE CASCADE` | `55` |
| `conflict_type` | ENUM | — | `Missing_Catalog_Reference`, `Definition_Divergence`, `Machine_Metadata_Mismatch`, `Duplicate_Business_Code`, `Version_Incompatible`, `Referential_Gap`, `Other` | `Definition_Divergence` |
| `entity_type` | VARCHAR(64) | — | Which table | `tst_test_cases` |
| `source_identity` | VARCHAR(255) | ✔ | **How the record identified itself in the bundle** | `D02A_T0104010200_001` |
| `local_record_id` / `local_record_code` | BIGINT / VARCHAR(120) | ✔ | The existing row it clashed with | `8802` / `D02A_…_001` |
| `severity` | ENUM | — | `Blocking` (those records are not applied) or `Warning` (applied, flagged) | `Blocking` |
| `description` | VARCHAR(1000) | — | What the disagreement is | `Incoming definition_hash differs` |
| `incoming_json` / `existing_json` | JSON | ✔ | **Both versions retained in full. Nothing is discarded** | `{…}` |
| `status` | ENUM | — | `Open`, `Resolved_Keep_Existing`, `Resolved_Accept_Incoming`, `Resolved_Manual`, `Ignored` | `Open` |
| `resolved_by` / `resolved_at` / `resolution_note` | VARCHAR(3) / DATETIME / VARCHAR(1000) | ✔ | The decision record | `A01` |

> **`Duplicate_Business_Code` means something specific now.** Under the old id-based scheme, two machines minting the same test number was routine. Under the coding system it can only mean **a machine code was reused** — two installations registered as `D02A`. That silently merges two machines' evidence, so it is classified `Blocking` and surfaced as an operational alert.

---

# Section 10 — AI Analysis

**AI assists; it does not decide.** Nothing here mutates record data. Every output is a proposal with evidence, a confidence score and a review state, accepted or rejected by a named person.

## 10.1 `tst_ai_analyses`

### What it is for
One AI analysis run, with full provenance so a conclusion can be reproduced or explained months later.

### Example row

```
machine_id 11 · source_analysis_id 22 · requested_by T01
analysis_type     : Failure_Cluster
scope_description : "All failures on SLB in the last 7 days"
provider claude · model claude-opus-5 · prompt_version v3
input_tokens 18,400 · output_tokens 2,100 · duration_ms 6,820
status            : Completed
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `22` |
| `machine_id` | SMALLINT UNSIGNED | — | **UK.** FK → `tst_machines.id` | `11` |
| `source_analysis_id` | BIGINT UNSIGNED | — | **UK.** Distributed identity | `22` |
| `analysis_type` | ENUM | — | `Duplicate_Test_Case`, `Duplicate_Bug`, `Failure_Cluster`, `Flaky_Assessment`, `Regression_Assessment`, `Failure_Reason`, `Consecutive_Failure_Diagnosis`, `Impact_Proposal`, `Coverage_Gap`, `Recommendation` | `Failure_Cluster` |
| `scope_description` | VARCHAR(500) | ✔ | What was analysed, in words | `All failures on SLB in 7 days` |
| `scope_json` | JSON | ✔ | The exact filter used | `{"module":"SLB","days":7}` |
| `provider` / `model` | VARCHAR(50) / (100) | ✔ | Which AI answered | `claude` / `claude-opus-5` |
| `prompt_version` | VARCHAR(30) | ✔ | **So a conclusion can be reproduced or explained.** A different prompt gives a different answer | `v3` |
| `input_tokens` / `output_tokens` / `duration_ms` | INT UNSIGNED | ✔ | Cost and latency | `18400` / `2100` / `6820` |
| `status` | ENUM | — | `Queued`, `Running`, `Completed`, `Failed` | `Completed` |
| `error_message` | TEXT | ✔ | Failure detail | `NULL` |
| `requested_by` | VARCHAR(3) | — | FK → `tst_users`. Who asked | `T01` |

## 10.2 `tst_ai_recommendations`

### What it is for
The individual proposals an analysis produced, each with evidence, a confidence score and a review state. **`outcome` is the column people skip and shouldn't** — recording whether an accepted recommendation turned out to be correct is what makes the AI's usefulness measurable rather than assumed.

### Example row

```
analysis_id 22
recommendation_type : Attribute_To_Known_Issue
target_entity_type  : tst_test_run_results     target_entity_id : 91389
related_entity_code : KI-0007
title               : "This failure matches known issue KI-0007"
confidence          : 0.910
evidence_json       : {"fingerprint_match":true,"same_screen":true,"prior_matches":62}
review_state        : Accepted        reviewed_by : T01
outcome             : Correct
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `510` |
| `analysis_id` | BIGINT UNSIGNED | — | FK → `tst_ai_analyses`, `ON DELETE CASCADE` | `22` |
| `recommendation_type` | ENUM | — | `Link_Test_Cases`, `Link_Bugs`, `Attribute_To_Bug`, `Attribute_To_Known_Issue`, `Mark_Flaky`, `Mark_Regression`, `Create_Test_Case`, `Retire_Test_Case`, `Select_For_Run`, `Investigate`, `Other` | `Attribute_To_Known_Issue` |
| `target_entity_type` | VARCHAR(64) | ✔ | Which table the proposal is about | `tst_test_run_results` |
| `target_entity_id` | BIGINT UNSIGNED | ✔ | Its id, for id-keyed tables | `91389` |
| `target_entity_code` | VARCHAR(120) | ✔ | **Its business code, for code-keyed tables** | `D02A_T0104010200_001` |
| `related_entity_id` / `related_entity_code` | BIGINT / VARCHAR(120) | ✔ | The other end, for a link proposal | `KI-0007` |
| `title` | VARCHAR(255) | — | One-line proposal | `This failure matches KI-0007` |
| `recommendation` | TEXT | — | The full reasoning | *(detail)* |
| `confidence` | DECIMAL(4,3) | — | 0.000–1.000 | `0.910` |
| `evidence_json` | JSON | ✔ | **The recorded facts relied upon. A recommendation without this is an opinion** | `{"fingerprint_match":true}` |
| `review_state` | ENUM | — | `Proposed`, `Accepted`, `Rejected`, `Superseded`, `Expired` | `Accepted` |
| `reviewed_by` / `reviewed_at` / `review_note` | VARCHAR(3) / DATETIME / VARCHAR(1000) | ✔ | Who decided and why | `T01` |
| `outcome` | ENUM | — | `Correct`, `Incorrect`, `Partially_Correct`, `Unknown`. **Recorded after the fact — this is how AI accuracy becomes a number** | `Correct` |

### Keys & rules
`CHECK` — confidence between 0 and 1.

---

# Section 11 — Notifications and Audit

## 11.1 `tst_notifications`

### What it is for
Telling people about things that need a decision — **and nothing else**. Deduplicated by key, so forty identical failures produce one notification that says forty. A system that sends forty is a system people mute.

### Example row

```
recipient_code  : D02
event_type      : New_Critical_Bug     severity : Critical
entity_type     : tst_bugs             entity_id : 412
title           : "BUG-000412 assigned to you — SLA 2026-09-11 09:15"
dedupe_key      : "bug:412:assigned"
occurrence_count: 1
first_event_at 2026-09-09 09:15 · last_event_at 2026-09-09 09:15
channel Email · delivered_at 09:15:04 · read_at 09:41:22
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `7781` |
| `recipient_code` | VARCHAR(3) | — | **UK.** FK → `tst_users`, `ON DELETE CASCADE` | `D02` |
| `event_type` | ENUM | — | `Critical_Test_Failure`, `New_Critical_Bug`, `Bug_Assigned`, `Bug_Ready_For_Retest`, `Retest_Failed`, `SLA_Breach`, `Schedule_Missed`, `Import_Conflict`, `Known_Issue_Expired`, `Discovery_Anomaly`, `Export_Ready`, `Review_Requested`, `Regression_Detected`, `Other` | `New_Critical_Bug` |
| `severity` | ENUM | — | `Info`, `Warning`, `Critical` | `Critical` |
| `entity_type` / `entity_id` / `entity_code` | VARCHAR(64) / BIGINT / VARCHAR(120) | ✔ | What it is about, by id or by code | `tst_bugs` / `412` |
| `title` | VARCHAR(255) | — | The headline | `BUG-000412 assigned to you` |
| `body` | TEXT | ✔ | Detail | *(detail)* |
| `action_url` | VARCHAR(500) | ✔ | Deep link into the app | `/bugs/412` |
| `dedupe_key` | VARCHAR(191) | — | **UK.** The grouping key. A repeat event bumps the count instead of creating a row | `bug:412:assigned` |
| `occurrence_count` | INT UNSIGNED | — | How many times this event fired | `1` |
| `first_event_at` / `last_event_at` | DATETIME | — | Span of the grouped events | `09:15` / `09:15` |
| `channel` | ENUM | — | `In_App`, `Email`, `Digest` | `Email` |
| `delivered_at` / `read_at` | DATETIME | ✔ | Delivery and read state | `09:15:04` / `09:41:22` |

### Keys & rules
`UNIQUE (recipient_code, dedupe_key)` — this is the deduplication mechanism.

## 11.2 `tst_audit_logs`

### What it is for
Every material change, insert-only. `record_key` carries the **business code** for code-keyed tables — an audit row saying "tst_test_cases id 41207 changed" is unreadable on a different machine, whereas `D02A_T0104010200_001` is readable everywhere.

### Example rows

| table_name | record_id | record_key | operation | user_code | is_system_action |
|---|---:|---|---|---|:---:|
| `tst_test_cases` | 2041 | `D02A_T0104010200_001` | `UPDATE` | `D02` | 0 |
| `tst_bugs` | 412 | `BUG-000412` | `UPDATE` | `S02` | **1** |
| `tst_data_exports` | 88 | — | `EXPORT` | `D02` | 0 |
| — | — | — | `PERMISSION_DENIED` | `T02` | 0 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `220441` |
| `machine_id` | SMALLINT UNSIGNED | — | **UK.** FK → `tst_machines.id`. Where the action happened | `11` |
| `source_audit_id` | BIGINT UNSIGNED | — | **UK.** Distributed identity, so audit consolidates without duplication | `220441` |
| `user_code` | VARCHAR(3) | ✔ | FK → `tst_users`. Who did it | `D02` |
| `is_system_action` | TINYINT(1) | — | **`1` = automation.** So "who did this?" never answers "the system" when it means "the retest engine acting on a rule somebody configured" | `0` |
| `table_name` | VARCHAR(100) | — | Which table | `tst_test_cases` |
| `record_id` | BIGINT UNSIGNED | ✔ | The row id | `2041` |
| `record_key` | VARCHAR(255) | ✔ | **The business code, for code-keyed tables.** Readable on any machine | `D02A_T0104010200_001` |
| `operation` | ENUM | — | `INSERT`, `UPDATE`, `DELETE`, `RESTORE`, `PURGE`, `LOGIN`, `PERMISSION_DENIED`, `EXPORT`, `IMPORT` | `UPDATE` |
| `old_values_json` / `new_values_json` | JSON | ✔ | Before and after — only the changed fields | `{"criticality":"Medium"}` |
| `context` | VARCHAR(255) | ✔ | **The service or command responsible** | `TestCaseService@save` |
| `ip_address` | VARCHAR(45) | ✔ | IPv4 or IPv6 | `192.168.1.42` |
| `user_agent` | VARCHAR(1000) | ✔ | Browser or CLI signature | `Mozilla/5.0 …` |

### Keys & rules
`UNIQUE (machine_id, source_audit_id)`. Insert-only — no update path, no soft delete. Retention defaults to three years and expiry is an explicit administrative action, never a silent purge.

---

# PHASE 2 — CORRELATE AND SELECT

*14 tables. Everything needed to answer: **given this change, which tests does it require?***

> Phase 2 **adds** tables and constraints. It never alters a Phase-1 column. The five Phase-1 columns marked **[P2]** above were declared from the start and left NULL; Section 30 of the DDL adds their foreign keys once these tables exist.

---

# Section 20 — Change Requests and the Work Backlog

Two different things, deliberately kept apart:

| Table | Is a statement about | Example |
|---|---|---|
| `tst_app_requirements` | **Prime-AI** | "Fees must support part payment" |
| `tst_test_case_requirements` | **the test suite** | "Write a test for part payment" |

Conflating them makes coverage uncountable, because a backlog item about *writing* a test would be counted as a requirement needing coverage.

## 20.1 `tst_app_requirements` — change requests

### Example row
`FIN-REQ-014` · module `FIN` · *"Allow part payment of a fee instalment"* · criticality `High` · status `Implemented`

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `140` |
| `req_code` | VARCHAR(40) | — | **UK.** Stable business code | `FIN-REQ-014` |
| `module_code` | VARCHAR(5) | — | FK → `tst_modules` | `FIN` |
| `ts_code` | VARCHAR(11) | ✔ | FK → `tst_tabs_screens`. Set when the change is screen-specific | `T0203010100` |
| `title` | VARCHAR(255) | — | What is being asked for | `Allow part payment` |
| `description` | TEXT | ✔ | Full statement | *(detail)* |
| `acceptance_criteria` | TEXT | ✔ | **How we will know it is done.** This is what tests are written against | `Given a ₹5000 instalment…` |
| `source_document` | VARCHAR(1000) | ✔ | The FRD or BRD it came from | `docs/FIN_FRD_v2.md#3.4` |
| `criticality` | ENUM | — | `Low`, `Medium`, `High`, `Critical` | `High` |
| `status` | ENUM | — | `Draft`, `Approved`, `Implemented`, `Changed`, `Retired` | `Implemented` |
| `version_no` | INT UNSIGNED | — | Requirement revision | `2` |
| `owner_user_code` | VARCHAR(3) | ✔ | Who is answerable | `A01` |
| `is_active` | TINYINT(1) | — | In scope | `1` |

`FULLTEXT (title, description)` supports free-text search.

## 20.2 `tst_app_requirement_test_cases` — coverage mapping

### What it is for
Which tests cover which change request, in **both directions**. Coverage is a two-way question: "what covers this change?" and "what does this test cover?"

### Example rows

| requirement_id | test_case_code | coverage_type | mapped_by |
|---:|---|---|---|
| 140 | `D02A_T0203010100_001` | `Full` | `T01` |
| 140 | `D02A_T0203010100_004` | `Boundary` | `T01` |
| 140 | `T01A_T0203010100_002` | `Negative` | `A01` |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `requirement_id` | BIGINT UNSIGNED | — | **PK.** FK → `tst_app_requirements`, `ON DELETE CASCADE` | `140` |
| `test_case_code` | VARCHAR(21) | — | **PK.** FK → `tst_test_cases`, `ON DELETE CASCADE` | `D02A_T0203010100_001` |
| `coverage_type` | ENUM | — | `Full`, `Partial`, `Negative`, `Boundary`, `Integration`. **A requirement covered only by `Negative` tests is not really covered** | `Full` |
| `mapped_by` | VARCHAR(3) | — | FK → `tst_users`. Who made the link | `T01` |
| `note` | VARCHAR(500) | ✔ | Qualification | `Covers the happy path only` |

## 20.3 `tst_test_case_requirements` — the test-case work backlog

### What it is for
"Create a test for X", "automate Y", "retire Z". Carries a distributed identity because it can be raised on any machine.

### Example row

```
machine_id 13 · source_requirement_id 61 · raised_by_user_code T01
request_type          : Create
module_code FIN · ts_code T0203010100
title                 : "Need a test for part payment rounding"
priority              : High
origin_type           : Change_Request     origin_requirement_id : 140
assigned_to D02 · assigned_at 2026-09-09
status                : Completed
target_test_case_code : D02A_T0203010100_004   ← the test this request produced
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `61` |
| `machine_id` | SMALLINT UNSIGNED | — | **UK.** FK → `tst_machines.id` | `13` |
| `source_requirement_id` | BIGINT UNSIGNED | — | **UK.** Distributed identity | `61` |
| `raised_by_user_code` | VARCHAR(3) | — | FK → `tst_users`. Who raised it | `T01` |
| `request_type` | ENUM | — | `Create`, `Modify`, `Automate`, `Retire`, `Investigate` | `Create` |
| `module_code` / `ts_code` | VARCHAR(5) / (11) | — / ✔ | Where the work belongs | `FIN` / `T0203010100` |
| `proposed_tab_name` / `proposed_folder_path` | VARCHAR(150) / (1000) | ✔ | For a screen that does not exist in the catalog yet | `Part Payment` |
| `title` | VARCHAR(255) | — | The request | `Need a test for part payment rounding` |
| `description` | TEXT | ✔ | Detail | *(detail)* |
| `priority` | ENUM | — | `Low`, `Medium`, `High`, `Critical` | `High` |
| `origin_type` | ENUM | — | **Where the request came from:** `Person`, `Change_Request`, `Coverage_Gap`, `Bug`, `Discovery`, `AI`. Aggregating this shows whether your backlog is driven by planning or by firefighting | `Change_Request` |
| `origin_requirement_id` | BIGINT UNSIGNED | ✔ | FK → `tst_app_requirements`, when the origin is a change | `140` |
| `requested_by` / `assigned_to` / `assigned_at` | VARCHAR(3) / VARCHAR(3) / DATETIME | ✔ | Ownership | `T01` / `D02` |
| `status` | ENUM | — | `Pending`, `In_Progress`, `Completed`, `Cancelled`, `Hold` | `Completed` |
| `target_test_case_code` | VARCHAR(21) | ✔ | FK → `tst_test_cases`. **The test case this request produced** — closes the loop from "we need a test" to "here it is" | `D02A_T0203010100_004` |
| `completed_by` / `completed_at` / `completion_note` | VARCHAR(3) / DATETIME / VARCHAR(1000) | ✔ | The completion record | `D02` |

---

# Section 21 — Dependencies

## 21.1 `tst_module_dependencies`

### What it is for
Which module depends on which, so a change's blast radius is computable. **`impact_weight` decays with depth** in the traversal — a second-order dependency is weaker evidence than a first-order one, and treating them equally is how an impact analysis ends up proposing the entire test suite.

### Example rows

| module_code | depends_on_module_code | dependency_type | impact_weight |
|---|---|---|---:|
| `FIN` | `STD` | `Data` | 9 |
| `FIN` | `SCH` | `Shared_Component` | 6 |
| `EXM` | `STD` | `Data` | 8 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `module_code` | VARCHAR(5) | — | **PK.** FK → `tst_modules`, `ON DELETE CASCADE`. The dependent module | `FIN` |
| `depends_on_module_code` | VARCHAR(5) | — | **PK.** FK → `tst_modules`, `ON DELETE CASCADE`. What it needs | `STD` |
| `dependency_type` | ENUM | — | `Functional`, `Data`, `Shared_Component`, `API`, `Integration`, `Navigation`, `Other` | `Data` |
| `impact_weight` | TINYINT UNSIGNED | — | **1 (weak) … 10 (strong). Decays with depth** | `9` |
| `note` | VARCHAR(500) | ✔ | Why the dependency exists | `Fees reads the student roster` |
| `is_active` | TINYINT(1) | — | Currently true | `1` |

### Keys & rules
Composite PK · `CHECK` — a module cannot depend on itself; weight between 1 and 10.

## 21.2 `tst_test_case_dependencies`

### What it is for
Which test needs which other test to have passed first. **`is_blocking` reaches back into Phase 1**: if the parent fails, the dependent test is recorded `Blocked`, not `Failed`. That is why `Blocked` exists as a result status from Phase 1 — the status has to be there before the mechanism that produces it.

### Example rows

| test_case_code | depends_on_test_case_code | dependency_type | is_blocking | impact_weight |
|---|---|---|:---:|---:|
| `D02A_T0203010100_004` | `D02A_T0203010100_001` | `Prerequisite` | **1** | 10 |
| `D02A_T0203010100_007` | `T01A_T0201010100_002` | `Data` | 0 | 6 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `test_case_code` | VARCHAR(21) | — | **PK.** FK → `tst_test_cases`, `ON DELETE CASCADE`. The dependent test | `D02A_T0203010100_004` |
| `depends_on_test_case_code` | VARCHAR(21) | — | **PK.** FK → `tst_test_cases`, `ON DELETE CASCADE`. The prerequisite | `D02A_T0203010100_001` |
| `dependency_type` | ENUM | — | `Prerequisite`, `Functional`, `Data`, `Navigation`, `API`, `Integration`, `Shared_Component`, `Regression`, `Other` | `Prerequisite` |
| `is_blocking` | TINYINT(1) | — | **`1` = if the parent fails, this test records `Blocked` rather than `Failed`.** Stops one broken login inflating the defect count by forty | `1` |
| `impact_weight` | TINYINT UNSIGNED | — | 1–10, decays with depth | `10` |
| `note` | VARCHAR(500) | ✔ | Why | `Needs the instalment created by _001` |
| `is_active` | TINYINT(1) | — | Currently true | `1` |

---

# Section 22 — Application Path Mapping

## 22.1 `tst_path_mappings`

### What it is for
How a **changed source file** resolves to a module, a screen or a test case. Without it, impact analysis would need somebody to hand-map thousands of files.

### Example rows (these are seeded)

| pattern | target_type | confidence | priority | note |
|---|---|---:|---:|---|
| `tests/Browser/**` | `TestCase` | 0.950 | 10 | A Dusk file maps to the test it implements |
| `Modules/*/database/migrations/**` | `Module` | 0.950 | 15 | Schema change — high impact |
| `Modules/*/app/Http/Controllers/**` | `Module` | 0.900 | 20 | Direct behaviour change |
| `Modules/*/resources/views/**` | `Module` | 0.750 | 35 | UI change |
| `app/**` | `Module` | 0.600 | 60 | Shared code — broad impact |
| `vendor/**` | **`Ignore`** | 1.000 | 1 | Third-party code |
| `*.lock` | **`Ignore`** | 1.000 | 5 | Lock files |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `4` |
| `pattern` | VARCHAR(500) | — | **UK.** A glob | `Modules/*/app/Services/**` |
| `target_type` | ENUM | — | `Module`, `Screen`, `TestCase`, **`Ignore`** | `Module` |
| `module_code` / `ts_code` / `test_case_code` | VARCHAR(5)/(11)/(21) | ✔ | What it resolves to. All NULL for `Ignore` | `FIN` |
| `confidence` | DECIMAL(4,3) | — | **How strongly a match implies impact.** Carries into the selection score | `0.900` |
| `priority` | SMALLINT UNSIGNED | — | **Lower wins — most specific rule first** | `22` |
| `note` | VARCHAR(500) | ✔ | Why the rule exists | `Service — business logic change` |
| `is_active` | TINYINT(1) | — | Rule enabled | `1` |

### Keys & rules

- `UNIQUE (pattern)` · `CHECK` — confidence between 0 and 1.
- **The `Ignore` rules matter as much as the resolving ones.** Without them, every `composer update` reads as a change to the entire application.
- **A path no rule matched is an unresolved file, and it is counted** in `tst_impact_analyses.unresolved_file_count`. An analysis that silently ignored 40% of a change is worse than no analysis, because it looks complete.

---

# Section 23 — Test Suites

## 23.1 `tst_test_suites`

### What it is for
A named, reusable collection of test cases: Smoke, Regression, Critical. Membership may be **explicit** (a listed set) or **rule-based** (everything matching a filter).

### Example row
`REG-FIN` · "Fees Regression" · type `Regression` · rule-based · `{"module":["FIN"],"criticality":["Critical","High"]}` · version 7

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `12` |
| `suite_code` | VARCHAR(40) | — | **UK.** Stable code | `REG-FIN` |
| `name` | VARCHAR(150) | — | Display name | `Fees Regression` |
| `suite_type` | ENUM | — | `Smoke`, `Regression`, `Integration`, `Critical`, `Full`, `Bug_Retest`, `Release`, `Custom` | `Regression` |
| `description` | TEXT | ✔ | Purpose | `Everything critical in Fees` |
| `is_rule_based` | TINYINT(1) | — | `1` = membership is computed from `rule_json`, not listed | `1` |
| `rule_json` | JSON | ✔ | The filter, when rule-based | `{"module":["FIN"],…}` |
| `version_no` | INT UNSIGNED | — | Increments whenever membership changes | `7` |
| `is_active` | TINYINT(1) | — | Suite enabled | `1` |

## 23.2 `tst_test_suite_items`

### What it is for
Explicit membership, by `test_case_code`.

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `suite_id` | INT UNSIGNED | — | **PK.** FK → `tst_test_suites`, `ON DELETE CASCADE` | `12` |
| `test_case_code` | VARCHAR(21) | — | **PK.** FK → `tst_test_cases`, `ON DELETE CASCADE` | `D02A_T0203010100_001` |
| `priority` | ENUM | — | `Low`, `Medium`, `High`, `Critical`. Priority *within this suite*, which may differ from the test's own | `Critical` |
| `sequence_no` | INT UNSIGNED | — | Execution order | `3` |
| `added_by` | VARCHAR(3) | — | FK → `tst_users` | `T01` |

## 23.3 `tst_test_suite_versions`

### What it is for
**A frozen snapshot of who was in the suite at each version.** A run records `suite_version_no`, so a historical run remains reproducible even after the suite changes. "The regression suite" today is not the set it was in March.

### Example row

```
suite_id 12 · version_no 7 · member_count 84
members_json   : ["D02A_T0203010100_001","D02A_T0203010100_004", …]
change_summary : "Added 6 part-payment tests; removed 2 retired ones"
captured_by    : T01
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `340` |
| `suite_id` | INT UNSIGNED | — | **UK.** FK → `tst_test_suites`, `ON DELETE CASCADE` | `12` |
| `version_no` | INT UNSIGNED | — | **UK.** The version being frozen | `7` |
| `member_count` | INT UNSIGNED | — | How many tests were in it | `84` |
| `members_json` | JSON | — | **The resolved membership as a list of test case codes** | `["D02A_T0203010100_001",…]` |
| `change_summary` | VARCHAR(1000) | ✔ | What changed since the previous version | `Added 6 part-payment tests` |
| `captured_by` | VARCHAR(3) | — | FK → `tst_users` | `T01` |

---

# Section 24 — Git Ingestion

## 24.1 `tst_git_repositories`

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `repository_code` | VARCHAR(100) | — | **PK.** Short repository identifier | `prime-ai` |
| `name` | VARCHAR(150) | — | Display name | `Prime-AI Main` |
| `local_path` | VARCHAR(1000) | ✔ | Where the clone lives on this machine | `D:\work\prime-ai` |
| `remote_url` | VARCHAR(500) | ✔ | Origin URL | `git@github.com:…` |
| `default_branch` | VARCHAR(200) | ✔ | Usually `main` or `develop` | `develop` |
| `last_ingested_commit` | VARCHAR(40) | ✔ | **Ingestion is incremental from here** | `a3f9c2e1b4…` |
| `last_ingested_at` | DATETIME | ✔ | When | `2026-09-09 06:10` |
| `is_active` | TINYINT(1) | — | Being ingested | `1` |

## 24.2 `tst_git_commits`

### Example row

```
repository_code prime-ai · commit_hash a3f9c2e1b4d7… · short_hash a3f9c2e
branch_name    : develop
author_user_code : D02      ← RESOLVED from the git email to a Testing App user
author_name Tarun · author_email tarun@company.com
commit_message : "fix(syllabus): keep toast until dismissed"
is_merge_commit 0 · files_changed 4 · lines_added 61 · lines_removed 12
committed_at   : 2026-09-09 16:38
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `88210` |
| `repository_code` | VARCHAR(100) | — | **UK.** FK → `tst_git_repositories`, `ON DELETE CASCADE` | `prime-ai` |
| `commit_hash` | VARCHAR(40) | — | **UK. Exactly 40 characters — a Git SHA-1 is 40 hex chars.** Stored as `CHAR(64)` it would be space-padded and a hash read from `git log` would never compare equal | `a3f9c2e1b4d7…` |
| `short_hash` | VARCHAR(12) | ✔ | The abbreviated form people quote | `a3f9c2e` |
| `branch_name` | VARCHAR(200) | ✔ | Branch it was seen on | `develop` |
| `parent_commit_hash` / `merge_commit_hash` | VARCHAR(40) | ✔ | Graph position | `7e21b9c…` |
| `author_user_code` | VARCHAR(3) | ✔ | FK → `tst_users`. **Resolved from the git email where possible, so "who changed this" and "who tested this" share one vocabulary** | `D02` |
| `author_name` / `author_email` | VARCHAR(150) / (200) | ✔ | As recorded in git | `Tarun` / `tarun@company.com` |
| `commit_message` | TEXT | ✔ | The message | `fix(syllabus): keep toast…` |
| `is_merge_commit` | TINYINT(1) | — | Merge commits usually need different impact treatment | `0` |
| `files_changed` / `lines_added` / `lines_removed` | INT UNSIGNED | — | Size of the change | `4` / `61` / `12` |
| `committed_at` | DATETIME | ✔ | Commit timestamp | `2026-09-09 16:38` |
| `ingested_at` | TIMESTAMP | — | When we read it | `2026-09-09 18:00` |

## 24.3 `tst_git_commit_files`

### What it is for
Each changed file, **its resolved target, and how the resolution was reached**. Recording the *how* is what lets the team improve the mapping rules: a high `Module_Convention` share means the explicit rules are thin.

### Example rows

| file_path | change_type | module_code | ts_code | test_case_code | resolution_source |
|---|---|---|---|---|---|
| `Modules/Syllabus/resources/views/assign.blade.php` | `Modified` | `SLB` | `T0104010200` | — | `Screen_Path` |
| `tests/Browser/…/AssignSubjectTest.php` | `Modified` | `SLB` | — | `D02A_T0104010200_001` | `Test_File` |
| `app/Support/ToastHelper.php` | `Modified` | — | — | — | **`Unresolved`** ← a blind spot |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | INT UNSIGNED | — | **PK** | `551029` |
| `commit_id` | BIGINT UNSIGNED | — | **UK.** FK → `tst_git_commits`, `ON DELETE CASCADE` | `88210` |
| `file_path` | VARCHAR(1000) | — | **UK** (first 500 chars). The changed file | `Modules/Syllabus/…blade.php` |
| `old_file_path` | VARCHAR(1000) | ✔ | Previous path, for a rename | `NULL` |
| `change_type` | ENUM | — | `Added`, `Modified`, `Deleted`, `Renamed`, `Copied`, `Unknown` | `Modified` |
| `lines_added` / `lines_removed` | INT UNSIGNED | — | Change size for this file | `18` / `4` |
| `module_code` / `ts_code` / `test_case_code` | VARCHAR(5)/(11)/(21) | ✔ | **What this file resolved to** | `SLB` / `T0104010200` |
| `resolution_source` | ENUM | — | **How it was resolved:** `Test_File`, `Screen_Path`, `Path_Mapping`, `Module_Convention`, `Manual`, **`Unresolved`** | `Screen_Path` |
| `path_mapping_id` | INT UNSIGNED | ✔ | FK → `tst_path_mappings`. Which rule matched | `4` |
| `impact_level` | ENUM | — | `Low`, `Medium`, `High`, `Critical`, `Unknown` | `Medium` |

---

# Section 25 — Impact Analysis

## 25.1 `tst_impact_analyses`

### What it is for
A **named, retained, reviewable proposal** of which tests a change requires — not a transient list. **A person approves before anything runs.**

### Example row

```
analysis_name  : "Impact of develop 7e21b9c…a3f9c2e"
source_type    : Commit_Range
repository_code prime-ai · from 7e21b9c… · to a3f9c2e…
requested_by D02 · status Approved · approved_by A01 · approved_at 2026-09-09 18:40
changed_file_count      : 34
unresolved_file_count   : 3      ← 8.8% of the change could not be interpreted
affected_module_count   : 2      affected_screen_count : 6
proposed_test_count 48 · included_test_count 41 · excluded_test_count 7
executed_run_id         : 5514
defects_found_in_scope 2 · defects_found_out_of_scope 0    ← measured afterwards
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `77` |
| `machine_id` | SMALLINT UNSIGNED | — | **UK.** FK → `tst_machines.id` | `11` |
| `source_analysis_id` | BIGINT UNSIGNED | — | **UK.** Distributed identity | `77` |
| `analysis_name` | VARCHAR(200) | — | What this analysis is called | `Impact of develop 7e21b9c…` |
| `source_type` | ENUM | — | `Commit_Range`, `Single_Commit`, `Bug_Fix`, `Manual`, `Change_Request` | `Commit_Range` |
| `repository_code` | VARCHAR(100) | ✔ | Which repository | `prime-ai` |
| `from_commit_hash` / `to_commit_hash` | VARCHAR(40) | ✔ | The range analysed | `7e21b9c…` / `a3f9c2e…` |
| `bug_id` | BIGINT UNSIGNED | ✔ | FK → `tst_bugs`, when the source is a bug fix | `NULL` |
| `change_request_id` | BIGINT UNSIGNED | ✔ | FK → `tst_app_requirements` | `NULL` |
| `requested_by` | VARCHAR(3) | — | FK → `tst_users`. Who asked for the analysis | `D02` |
| `status` | ENUM | — | `Draft`, `Proposed`, `Approved`, `Rejected`, `Executed`, `Superseded` | `Approved` |
| `approved_by` / `approved_at` | VARCHAR(3) / DATETIME | ✔ | **A person approves before anything runs** | `A01` |
| `executed_run_id` | BIGINT UNSIGNED | ✔ | FK → `tst_test_runs`. The run that carried out the proposal | `5514` |
| `changed_file_count` | INT UNSIGNED | — | Files in the change | `34` |
| `unresolved_file_count` | INT UNSIGNED | — | **Paths no rule matched. This is the analysis stating its own blind spot** | `3` |
| `affected_module_count` / `affected_screen_count` | INT UNSIGNED | — | Breadth of impact | `2` / `6` |
| `proposed_test_count` | INT UNSIGNED | — | Candidates found | `48` |
| `included_test_count` / `excluded_test_count` | INT UNSIGNED | — | The split, with reasons in the items table | `41` / `7` |
| `defects_found_in_scope` | INT UNSIGNED | — | **Measured after the fact.** Defects the proposal caught | `2` |
| `defects_found_out_of_scope` | INT UNSIGNED | — | **Defects it missed.** These two columns are how selection stops being a guess | `0` |
| `parameters_json` | JSON | ✔ | **The algorithm settings used, so the result is reproducible** | `{"max_depth":3,"decay":0.6}` |
| `summary` | TEXT | ✔ | The narrative | `2 modules, 6 screens affected…` |

## 25.2 `tst_impact_analysis_items`

### What it is for
One proposed test case, with its reason, confidence and evidence. **Excluded items are retained with their reason** — a proposal that shows only what it included is not reviewable; the interesting question is always what it left out.

### Example rows

| test_case_code | reason | is_included | confidence | dependency_depth |
|---|---|:---:|---:|---:|
| `D02A_T0104010200_001` | `Direct_Change` | 1 | 0.950 | 0 |
| `D02A_T0104010200_004` | `Dependency` | 1 | 0.570 | 2 |
| `T01A_T0104010300_002` | `Historical_Correlation` | 1 | 0.640 | 0 |
| `D02A_T0104010200_009` | **`Flaky_Excluded`** | **0** | — | 0 |
| `D02A_T0104019900_001` | **`Screen_Excluded`** | **0** | — | 0 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `9910` |
| `analysis_id` | BIGINT UNSIGNED | — | **UK.** FK → `tst_impact_analyses`, `ON DELETE CASCADE` | `77` |
| `test_case_code` | VARCHAR(21) | — | **UK.** FK → `tst_test_cases`, `ON DELETE CASCADE` | `D02A_T0104010200_001` |
| `reason` | ENUM | — | **Inclusions:** `Direct_Change`, `Dependency`, `Historical_Correlation`, `Open_Bug`, `Critical`, `Regression_Policy`, `Manual_Addition`. **Exclusions:** `Flaky_Excluded`, `Retired_Excluded`, `Orphaned_Excluded`, `Screen_Excluded`, `Manual_Removal` | `Direct_Change` |
| `is_included` | TINYINT(1) | — | `1` = will run. `0` = **deliberately excluded, and the reason column says why** | `1` |
| `confidence` | DECIMAL(4,3) | — | 0.000–1.000 | `0.950` |
| `dependency_depth` | TINYINT UNSIGNED | — | 0 = directly changed; 1, 2, 3 = reached through the dependency graph. **Confidence decays as this rises** | `0` |
| `evidence_json` | JSON | ✔ | **The changed files, commits and prior failures relied upon** | `{"files":["…blade.php"]}` |
| `decided_by` / `decided_at` / `decision_note` | VARCHAR(3) / DATETIME / VARCHAR(500) | ✔ | **Set when a person overrode the algorithm** | `A01` / `Add this too` |

### Keys & rules
`UNIQUE (analysis_id, test_case_code)` · `CHECK` — confidence between 0 and 1.

---

# Views

21 read-only views. Dashboards read the summary table and these views; **investigation screens read `tst_test_run_results` directly and always with a filter.** No screen aggregates the results table unfiltered.

## Phase 1 — 17 views

| View | Answers |
|---|---|
| `vw_test_case_catalog` | The main list: every test case with its full hierarchy, author, machine and current health |
| `vw_tc_list_coverage` | **How tested is this screen, actually?** Required vs written vs released vs signed off, with a percentage |
| `vw_review_status` | Review and sign-off state per test case, including `Review_Stale` and **`Self_Signed_Off`** |
| `vw_test_case_history` | Every attempt for a test case, with run, machine, environment and commit context |
| `vw_test_run_history` | Run-level history with roll-ups, pass rate and schedule name |
| `vw_flaky_tests` | Candidates and confirmations, with the retained evidence |
| `vw_regression_candidates` | Currently failing, previously passing within 30 days, not confirmed flaky |
| `vw_open_bugs` | Open defects with age in days, SLA state and occurrence count |
| `vw_bug_lifecycle` | Hours to assign, to fix, to verify, and total — per bug |
| `vw_screen_coverage` | Screen-level coverage with a `coverage_state` label |
| `vw_module_quality_summary` | Module roll-up: screens, tests, passing, failing, flaky, open bugs |
| `vw_machine_comparison` | **The same test on different machines** — the environment-difference detector |
| `vw_environment_impact` | Pass rate by environment profile — *"it fails only on Chrome 141"* |
| `vw_known_issue_occurrences` | Recurrence counts per known issue, plus `review_overdue` |
| `vw_testing_debt` | Screens with **no released test case**, weighted by criticality, with a `debt_type` |
| `vw_developer_activity_summary` | Per user: tests authored, TcList entries, reviews, sign-offs, runs, bugs raised and fixed |
| `vw_import_status` | Import outcomes with blocking-conflict counts |

## Phase 2 — 4 views

| View | Answers |
|---|---|
| `vw_change_request_coverage` | Which tests cover which change, and whether they currently pass |
| `vw_run_test_selection_analysis` | **Which selection reasons actually find defects** — the defect-find rate per reason |
| `vw_impact_analysis_effectiveness` | Hit rate: defects in scope vs out of scope, plus the unresolved-path percentage |
| `vw_suite_composition` | Current and versioned suite membership with health |

---

# Quick reference

## Where does each business question live?

| Question | Tables |
|---|---|
| Who is this person? | `tst_users` |
| Whose machine ran this? | `tst_machines`, `tst_test_runs.run_machine_code` |
| Which screen is this test for? | `tst_test_cases.ts_code` → `tst_tabs_screens` |
| **How much of this screen is tested?** | `tst_tc_required_list` (denominator) vs `tst_test_cases` (numerator) |
| Has this test been reviewed and released? | `tst_test_case_review` |
| What did this test look like six months ago? | `tst_test_case_versions_history` |
| Are these two tests the same? | `tst_duplicate_test_case` |
| What happened when it ran? | `tst_test_run_results` |
| Where is the screenshot? | `tst_run_result_artifacts` |
| Is this failure new? | `tst_failure_signatures` |
| Is this test reliable? | `tst_test_case_runs_summary` |
| Is this bug actually fixed? | `tst_bugs.verified_result_id` + `tst_retest_cycles` |
| Why did we run these 40 tests? | `tst_test_run_items.selection_reason` |
| Which machine should run this tonight? | `tst_schedule_targets.machine_code` |
| Did the import duplicate anything? | `tst_import_record_map`, `tst_import_conflicts` |
| **[P2]** Which tests does this commit need? | `tst_impact_analyses` + `tst_impact_analysis_items` |
| **[P2]** What could the analysis not interpret? | `tst_impact_analyses.unresolved_file_count` |

## Table count

| Phase | Group | Count |
|---|---|---:|
| 1 | Platform · Identity · Catalog | 9 |
| 1 | Authoring | 6 |
| 1 | Execution | 8 |
| 1 | Scheduling · Comments · Discovery | 4 |
| 1 | Defects | 9 |
| 1 | Sync · AI · Ops | 8 |
| | **Phase 1 total** | **44** |
| 2 | Change requests · Dependencies · Path mapping | 6 |
| 2 | Suites · Git · Impact | 8 |
| | **Phase 2 total** | **14** |
| | **Grand total** | **58 tables, 21 views** |

## Five things that are easy to get wrong

| # | Trap | The rule |
|---|---|---|
| 1 | Writing to `test_case_code`, `tcr_code` or `machine_code` | **They are GENERATED.** Insert the parts; MySQL builds the code |
| 2 | Updating a result status when a test is re-run | **Results are insert-only.** Insert a new attempt with `attempt_no + 1` |
| 3 | Trusting `tst_test_case_runs_summary` over the results | **The summary is derived.** If they disagree, rebuild the summary |
| 4 | Renaming a user, machine or screen code | **Impossible by design.** Deactivate and create a new one |
| 5 | Treating a `Blocked` result as a failure | **Blocked means it never ran.** Counting it as failed inflates the defect rate |

---

**End of `Dictionary_DDL_v7.2.md`**
