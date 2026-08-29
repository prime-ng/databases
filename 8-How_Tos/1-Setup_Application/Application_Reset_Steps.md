# Application Reset — Steps

Full reset of the central application, then creation of a fresh tenant with demo data.

**Run everything from `prime_ai/`. Keep two terminals open** — one for commands, one for the queue
worker (step 6). Tenant creation will not finish without the worker running.

| | URL | Email | Password |
|---|---|---|---|
| Central | http://localhost:8000/login | `superadmin@prime.com` | `password` |
| Tenant | http://test.localhost:8000/login | `root@tenant.com` | `password` |

---

## 1. Clear caches and rebuild the autoloader

```bash
composer dump-autoload
php artisan optimize:clear
php artisan tinker --execute='Cache::store("file")->flush();'
```

`optimize:clear` clears config, routes, views and the **default** cache store (`database`).
It does **not** clear the `file` store, where the menu trees are cached — hence the third command.
Skipping it is the usual cause of stale or broken menus after a reset.

## 2. Reset and reseed the central database

```bash
php artisan migrate:fresh --seed
```

Drops every table in `prime_db` and reseeds it. This removes tenant **records**, but **not** the
tenant databases themselves — drop those manually if you want them gone.

## 3. Log in to the central application

http://localhost:8000/login — `superadmin@prime.com` / `password`

## 4. Sync the menus

Both run on the central domain, in this order:

| Menus | URL |
|---|---|
| Central (Prime) | http://localhost:8000/system-config/sync-prime-menus |
| Tenant | http://localhost:8000/system-config/sync-menus |

Each returns a JSON report of created / updated / skipped rows.

## 5. Assign menus to the modules

http://localhost:8000/global-master/module/1/edit — module `1` is **STUDENT**.

Repeat for the other modules you need (`2` FINANCE, `3` LIBRARY, `4` ATTENDANCE, `5` EXAMS).
A tenant only gets the menus belonging to the modules in its plan.

## 6. Start the queue worker

In a second terminal, and leave it running:

```bash
php artisan queue:work
```

Tenant creation dispatches `SetupTenantDatabase` to the queue (`QUEUE_CONNECTION=database`).
Without a worker the new tenant stays stuck at "setup in progress".

## 7. Create the tenant

http://localhost:8000/prime/tenant/create

Watch the worker terminal until the setup job finishes.

## 8. Complete the tenant setup

http://localhost:8000/prime/tenant/{tenant-id}/complete-tenant-setup?tab=assign-plan#assign-plan

Take `{tenant-id}` from the tenant list. On this screen:

1. Assign a plan.
2. Set the tenant status to **Active**.

## 9. Log in to the tenant

http://test.localhost:8000/login — `root@tenant.com` / `password`

## 10. Seed the tenant data

http://test.localhost:8000/seeder

Run the seeders you need from that page. Individual seeders are also reachable directly, e.g.
`/seeder/school-setup`, `/seeder/students`, `/seeder/teachers`, `/seeder/fees`, `/seeder/timetable`.

---

## If something looks stale

| Symptom | Fix |
|---|---|
| Menus missing, wrong, or throwing | Re-run step 1, then step 4 |
| Menu cache only | http://localhost:8000/system-config/refresh-menu-cache (central) · http://test.localhost:8000/system-config/refresh-menu-cache (tenant) |
| Permission missing after a code change | http://localhost:8000/system-config/sync-permissions — dry run by default, add `?apply=1` to commit |
| Tenant stuck "setup in progress" | Check the `php artisan queue:work` terminal is running, then re-run the setup |
