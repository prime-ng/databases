# Running an isolated demo copy (`demo_from_main`)

Goal: run a second copy of prime_ai, with its own code and its own databases, on the
same PC and the same MySQL server as your normal copy. Running `migrate:fresh --seed`
(or anything else) in one copy must never touch the other copy's databases or files.

```
primeworkspace/
├── prime_ai/        branch: development   DBs: prime_db, global_master, xyz_school_…
└── prime_ai_demo/   branch: demo_from_main     DBs: demo_prime_db, demo_global_master, demo_xyz_school_…
```

---

## 1. What has to be separate

A copy is isolated only if **all three layers** are separate. Missing any one of them
is enough to damage the other copy.

| Layer | What it is | How it is separated |
|---|---|---|
| Code | the project folder | its own folder, on its own branch (`demo_from_main`) |
| Databases | **3 kinds:** central `prime_db`, `global_master`, and one DB **per tenant** | every name starts with `demo_` |
| Runtime | sessions, cache, queue, browser cookies, port | own `.env` values, own port, own queue worker |

### Why changing `DB_DATABASE` alone is not enough

`migrate:fresh` drops tables only in `DB_DATABASE`. But in this app:

1. **42 migrations write to `global_master`** (`GLOBAL_DB_DATABASE`). 17 GlobalMaster
   migrations run `dropIfExists('glb_…')` and then recreate the table. If both copies
   point at the same `global_master`, a reset in one copy drops the other copy's
   `glb_*` tables.
2. **Tenant DB names come from the tenant's data, not from config.**
   `Tenant::generateDatabaseName()` builds `{short_name}_{first 20 chars of uuid}_{session}`,
   for example `xyz_school_00000000000040008000_202526`. The seeders **pin** the UUIDs
   (`DevTenantSeeder` uses `…0001`, `DemoSchoolsSeeder` uses `…0002`–`…0005`), so both
   copies produce exactly the same names, and `DevTenantSeeder` **drops and recreates**
   that DB on every reset. A reset in the demo copy would therefore wipe your real
   dev tenant DB.

So a single prefix, `APP_DB_PREFIX=demo_`, has to reach **every** DB name: the two
central ones (set in `.env`) and every tenant one (set in code, step A).

---

## 2. Naming used by the demo copy

| Setting | Normal copy (`prime_ai`) | Demo copy (`prime_ai_demo`) |
|---|---|---|
| `APP_DB_PREFIX` | *(empty)* | `demo_` |
| `DB_DATABASE` | `prime_db` | `demo_prime_db` |
| `GLOBAL_DB_DATABASE` | `global_master` | `demo_global_master` |
| Tenant DBs | `xyz_school_…` | `demo_xyz_school_…` (automatic) |
| `DB_USERNAME` / `GLOBAL_DB_USERNAME` | your usual user | `prime_demo` (can only see `demo_%`) |
| `APP_NAME` | your current value | `PrimeDemo` |
| `SESSION_COOKIE` | default | `prime_demo_session` |
| `CACHE_PREFIX` / `REDIS_PREFIX` | default | `prime-demo-cache-` / `prime-demo-db-` |
| Dev tenant domain (`DEV_TENANT_DOMAIN`) | `test.localhost` | **`demo.localhost`** |
| Port | 8000 | **8001** |

> **Prefix length:** MySQL caps DB names at 64 characters. The generated tenant name is
> at most 58, so the prefix can be **at most 6 characters**. `demo_` is 5.

---

## Part A — Code changes on `demo_from_main` (done once, committed to the branch)

These are what make the prefix reach every DB name. Once they are committed, nobody
repeats them; teammates get them with `git pull`.

| # | File | Change |
|---|---|---|
| A1 | `Modules/Prime/app/Models/Tenant.php` | `generateDatabaseNameUsingSession()` puts `config('tenancy.database.copy_prefix')` in front of the name. This covers tenant create, `DevTenantSeeder`, `tenants:create-inspiration` and the session-rollover job. |
| A2 | `config/tenancy.php` | add `'copy_prefix' => env('APP_DB_PREFIX', '')`, and make the stancl fallback `'prefix'` start with it too. |
| A3 | `database/seeders/DemoSchoolsSeeder.php` | the 4 hard-coded `db_name` values (`mlzs_mhow_…`, `st_helen_s_kurseong_…`, `mhs_dehradun_…`, `gdgisn_…`) get the same prefix. |
| A3b | `database/seeders/DevTenantSeeder.php` + `config/tenancy.php` | the dev tenant's domain reads `config('tenancy.database.dev_tenant_domain')` (env `DEV_TENANT_DOMAIN`, default `test.localhost`) instead of a hard-coded `test.localhost`, so the demo copy can use `demo.localhost`. |
| A4 | `Modules/Maintenance/app/Services/BackupService.php` | `buildDatabaseName()` returns `'tenant_' . $id`, which is not the real name even today. Change it to read the tenant's real DB name. |
| A5 | `app/Providers/AppServiceProvider.php` | **safety guard:** if `APP_DB_PREFIX` is set but `DB_DATABASE` or `GLOBAL_DB_DATABASE` does not start with it, stop with a clear error before any command or request runs. This catches an `.env` copied from the normal copy. |
| A6 | `.env` (per PC, not committed) | built from `.env.example` with the section 2 values — see B3. |
| A7 | `docs/ISOLATED_DEMO_COPY.md` | this file. |

With an empty `APP_DB_PREFIX`, every change above behaves exactly as before, so the
normal copy is unaffected if these commits are ever merged.

---

## Part B — One-time setup on a PC

Run this **once per PC**. Tarun runs it on his PC; each teammate runs it on theirs (Part C).

### B1. Create the restricted MySQL user (needs MySQL root once)

This is the real safety net: the demo copy logs in as a user that **cannot see** any
database outside `demo_%`. If a config mistake points it at `prime_db`, MySQL returns
*access denied* instead of dropping tables.

```sql
-- sudo mysql   (or: mysql -u root -p)
CREATE USER 'prime_demo'@'localhost' IDENTIFIED BY 'choose-a-password';
GRANT ALL PRIVILEGES ON `demo\_%`.* TO 'prime_demo'@'localhost';
FLUSH PRIVILEGES;
```

The `\_` is required. A bare `_` is a single-character wildcard in MySQL grants.
The one grant covers `demo_prime_db`, `demo_global_master` and every `demo_…` tenant DB,
including tenant DBs created later.

```sql
CREATE DATABASE demo_prime_db      CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE demo_global_master CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### B2. Get the code into its own folder

To run the demo copy **next to** your normal copy, it needs its own folder: one folder can
only have one branch checked out, so it can only run one copy at a time.

```bash
cd ~/…/primeworkspace
git clone -b demo_from_main https://github.com/prime-ng/prime_ai.git prime_ai_demo
```

(If you only ever run one copy at a time, `git checkout demo_from_main` in your existing
folder also works, but you must then repeat B3 whenever you switch, because `vendor/`, `.env`
and `storage/` are shared by both branches in that folder.)

### B3. Install and configure

```bash
cd prime_ai_demo
composer install
npm ci && npm run build          # build once; don't run two `npm run dev` side by side
cp .env.example .env             # NEVER copy prime_ai/.env
# then set the section 2 values in .env:
#   APP_DB_PREFIX=demo_
#   DB_DATABASE=demo_prime_db          GLOBAL_DB_DATABASE=demo_global_master
#   DB_USERNAME / GLOBAL_DB_USERNAME = prime_demo, and both passwords from B1
#   SESSION_COOKIE=prime_demo_session  CACHE_PREFIX=prime-demo-cache-
#   REDIS_PREFIX=prime-demo-db-        APP_URL=http://localhost:8001
#   DEV_TENANT_DOMAIN=demo.localhost
# ⚠ .env.example lists DB_CONNECTION twice (sqlite, then mysql). Dotenv keeps the
#   FIRST one, so delete the sqlite line.
php artisan key:generate         # its own APP_KEY
php artisan storage:link
```

### B4. Check before the first destructive command

```bash
php artisan db:show                      # must say demo_prime_db, user prime_demo
php artisan tinker --execute="dump(config('database.connections.global_master_mysql.database'), config('tenancy.database.copy_prefix'));"
#   expected: "demo_global_master"  "demo_"
```

If either check prints a name without `demo_`, stop and fix `.env`.

### B5. Build the databases

```bash
php artisan migrate:fresh --seed
```

The tenant seeders create their DBs as `demo_xyz_school_…`. Confirm with:

```sql
SHOW DATABASES LIKE 'demo\_%';
```

### B6. Run it

```bash
php artisan serve --port=8001
php artisan queue:work            # from THIS folder: the demo jobs live in demo_prime_db
```

Open `http://demo.localhost:8001` (tenant) or `http://localhost:8001` (central).
The dev tenant gets `demo.localhost` (from `DEV_TENANT_DOMAIN`), so the two copies are told
apart by host as well as port. The four demo schools keep their own domains; each copy looks
a domain up in its own central DB, so a shared name never crosses copies.

---

## Part C — What a teammate does to get the same copy

Once Part A is pushed on `demo_from_main`, a teammate needs **no code changes**. They need to:

1. **Pull the branch:** clone with `-b demo_from_main` into a separate folder (B2).
2. **Create the `prime_demo` MySQL user and the two empty DBs** on their own MySQL (B1).
   Their MySQL is their own, so the user and DBs are created per PC. Nothing is shared
   between PCs.
3. **`composer install`, `npm ci && npm run build`** in the demo folder (B3).
4. **`cp .env.example .env`** and set the section 2 values listed in B3. They must not
   start from their normal `.env`; the A5 guard refuses to boot if they do and forget
   a name.
5. **`php artisan key:generate`** and **`php artisan storage:link`**.
6. **Run the B4 check**, then `php artisan migrate:fresh --seed` (B5).
7. **Serve on a free port** (8001) and run `queue:work` from the demo folder (B6).

Their normal copy keeps working unchanged next to it.

---

## Daily rules

- **Check which folder the terminal is in before running `artisan`.** Folder = copy.
  `pwd` takes one second; a reset in the wrong folder cannot be undone.
- Run each copy's **queue worker from its own folder**. A worker started in `prime_ai`
  never sees demo jobs, and vice versa. Restart the worker after pulling code.
- If you need a scheduler, use **one cron line per folder**
  (`cd …/prime_ai_demo && php artisan schedule:run`).
- Keep **different ports**. Browsers share cookies across ports on `localhost`; the
  separate `SESSION_COOKIE` name stops the two copies logging each other out.
- **Don't merge `development` into `demo_from_main`**, or the other way round, unless that's
  intended. The branch is its own version of the code. Bring changes over with
  `git cherry-pick` when needed.

## What is still shared (and why it is safe)

| Shared | Why it is safe |
|---|---|
| MySQL server | separate DB names plus the `prime_demo` user that can only see `demo_%` |
| Git remote | each clone has its own folder, `vendor/`, `.env` and `storage/`; only the code history is shared |
| Redis server (if used) | different `REDIS_PREFIX` / `CACHE_PREFIX` per copy |
| Browser | different port plus a different session cookie name |
