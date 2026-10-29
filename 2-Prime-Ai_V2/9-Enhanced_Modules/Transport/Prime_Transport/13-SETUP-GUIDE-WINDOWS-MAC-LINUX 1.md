# PrimeTransport — Setup Guide for Windows, Mac and Linux (2026-10-25)

> **Updated 2026-10-29:** the road map is now **Haldwani** (central zone), matching the test
> tenant. It used to be Surat (western zone). Shortcut for a teammate: copy the prepared map
> `haldwani-osrm-v5.27.1.zip` (14 MB) instead of doing 5.2-5.4 — see
> `18-TEAMMATE-ROAD-SERVER-SETUP.md`.

Follow this guide to make the PrimeTransport module (Route Planner, What-if, Approvals, plan map) work on any machine exactly as it works on Tarun's PC:

- a developer laptop running Windows, macOS or Linux;
- the Linux VPS (production).

**Do every step in order. Do not skip one.** Each step ends with a **Check**. When a check fails, stop and fix it before going on (section 11 lists the usual causes).

Commands are given per OS where they differ:

- **Linux / Mac** commands run in Terminal.
- **Windows** commands run in **PowerShell**, not `cmd`.

---

## 0. What PrimeTransport needs (the 7 pieces)

| # | Piece | What it does | Without it |
|---|---|---|---|
| 1 | Laravel app (`prime_ai`, branch `development`) | Pages, data, planning requests | Nothing works |
| 2 | MySQL **8.x** | Tenant tables `ptr_*` (23 migrations). Road paths are stored as spatial `LINESTRING` columns | Migrations fail |
| 3 | **Python 3** + a venv with **OR-Tools** | The route engine (`Modules/PrimeTransport/python/solve_routes.py`) that builds the routes | "Generate plan" fails: *The route engine's Python interpreter was not found* |
| 4 | **Queue worker** (`php artisan queue:work`) | Runs "Generate plan" in the background (`GeneratePlanJob`) | The plan stays **Queued** forever |
| 5 | **Scheduler** (`schedule:run` every minute) | Publishes plans that were given a scheduled publish date (hourly, at :05) | Scheduled plans never go live |
| 6 | **Docker + OSRM road server** (`prime-osrm` container, port 5000) | Draws plan routes along real roads, and gives real road distances when chosen | The map draws **straight lines** between stops |
| 7 | Internet in the browser (dev only) | The map library (MapLibre from unpkg.com) and the map tiles (tile.openstreetmap.org) | The map area stays blank |

Pieces 1–5 are **required**. Piece 6 is required for road-traced lines. Without it everything else still works, but the lines are straight.

How the pieces talk to each other:

```
Browser ──► Laravel ──► MySQL (tenant DB: ptr_* tables)
               │
               ├──► queue worker ──► Python venv (OR-Tools) ──► plan routes
               │
               └──► OSRM docker  http://127.0.0.1:5000   (road paths + road distances)
```

---

## 1. Install the base software

### 1.1 Windows 10/11

1. **Docker Desktop**
   1. Download it from https://www.docker.com/products/docker-desktop/ and install it.
   2. When the installer asks, keep **"Use WSL 2 instead of Hyper-V"** ticked.
   3. If Windows asks you to install or update WSL, run `wsl --install` (or `wsl --update`) in an *Administrator* PowerShell, then restart the PC.
   4. Open Docker Desktop and go to **Settings → General**. Tick **"Start Docker Desktop when you sign in to your computer"**, so the road server comes back after every reboot.
2. **Python 3**
   1. Download it from https://www.python.org/downloads/windows/ (3.12 recommended).
   2. In the installer, tick **"Add python.exe to PATH"**.
   3. Keep **"py launcher"** ticked.
3. **PHP 8.2+, Composer, MySQL 8**: use the same setup you already run prime_ai with (Laragon / XAMPP / manual).
4. **Git**: https://git-scm.com/download/win

**Check** (in a new PowerShell window):
```powershell
docker --version
docker run --rm hello-world
py --version
php -v
mysql --version
```
`hello-world` must print "Hello from Docker!".

### 1.2 macOS (Intel or Apple Silicon M1/M2/M3/M4)

1. **Homebrew** (if missing):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
2. **Docker Desktop**
   1. Download it from https://www.docker.com/products/docker-desktop/. Pick **Apple chip** or **Intel chip** to match your Mac.
   2. Open it once.
   3. Go to **Settings → General** and tick **"Start Docker Desktop when you sign in"**.
   4. The two images we use (`ghcr.io/project-osrm/osrm-backend:v5.27.1` and `iboates/osmium:latest`) ship native **arm64** builds, so Apple Silicon needs no `--platform` flag.
3. **Python 3**:
   ```bash
   brew install python@3.12
   ```
4. **PHP / Composer / MySQL 8**: your existing setup (Herd / Valet / brew).

**Check:**
```bash
docker --version
docker run --rm hello-world
python3 --version
php -v
mysql --version
```

### 1.3 Linux (Ubuntu / Debian — also the production VPS)

1. **Docker Engine**:
   ```bash
   curl -fsSL https://get.docker.com | sudo sh
   sudo systemctl enable --now docker          # start now AND on every boot
   sudo usermod -aG docker $USER               # run docker without sudo
   ```
   **Log out and log back in** (or reboot) so the `docker` group takes effect.
2. **Python 3 with venv + pip**:
   ```bash
   sudo apt update
   sudo apt install -y python3 python3-venv python3-pip curl
   ```
3. **PHP 8.2+, Composer, MySQL 8**: your existing setup.

**Check:**
```bash
docker --version
docker run --rm hello-world
systemctl is-enabled docker        # must print: enabled
python3 --version
python3 -m venv --help >/dev/null && echo "venv OK"
php -v
mysql --version
```

---

## 2. Get the latest code

Run this in the `prime_ai` folder. It is the same on all three OSes.

```bash
git checkout development
git pull
composer install
php artisan config:clear
php artisan cache:clear
```

Never skip `config:clear`. A cached config freezes the list of module migration folders. That is exactly why `ptr_settings`, `ptr_safety_rules` and `ptr_rule_settings` were missing on teammates' machines.

**Check:**
```bash
git log --oneline -1          # must be the same commit as origin/development
ls Modules/PrimeTransport/database/migrations/tenant | wc -l      # Linux/Mac: 23
```
```powershell
(Get-ChildItem Modules\PrimeTransport\database\migrations\tenant).Count   # Windows: 23
```

---

## 3. Create the PrimeTransport tables

```bash
php artisan tenants:migrate
```

This runs the migrations for every tenant, including the 23 `ptr_*` migrations in `Modules/PrimeTransport/database/migrations/tenant/` and the Transport GPS tables.

**Check:** open the tenant database in your MySQL client. These tables must exist:

- `ptr_settings`
- `ptr_safety_rules`
- `ptr_rule_settings`
- `ptr_plans`
- `ptr_plan_routes`
- `ptr_student_geo`

If they don't, see section 11, row "Tables missing".

---

## 4. Build the Python route engine (venv + OR-Tools)

The venv lives inside the module at `Modules/PrimeTransport/python/.venv`. It is **git-ignored**, so **every machine builds its own**. Never copy a venv from another PC or another OS; it will not work.

The packages come from `Modules/PrimeTransport/python/requirements.txt`:

```
ortools==9.15.6755
numpy==2.5.4
pytest
```

### Linux / Mac
```bash
cd Modules/PrimeTransport/python
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt
cd ../../..
```
Laravel finds this interpreter automatically, at its default path `Modules/PrimeTransport/python/.venv/bin/python`. You do not need an `.env` line.

### Windows (PowerShell)
```powershell
cd Modules\PrimeTransport\python
py -3.12 -m venv .venv
.venv\Scripts\python.exe -m pip install --upgrade pip
.venv\Scripts\python.exe -m pip install -r requirements.txt
cd ..\..\..
```
**Windows MUST also set the interpreter path in `.env`.** On Windows the venv puts Python in `Scripts\python.exe`, not `bin/python`, so the default path does not exist. Use forward slashes and your real path:
```
PRIME_TRANSPORT_PYTHON_BINARY="C:/path/to/prime_ai/Modules/PrimeTransport/python/.venv/Scripts/python.exe"
```

**About the Python version:**

- Tarun's PC runs Python 3.14.4.
- If `pip install` says *"No matching distribution found for ortools==9.15.6755"*, your Python version has no OR-Tools build. Install Python 3.12, delete the `.venv` folder, and repeat this step.

**Check:**
```bash
# Linux / Mac
Modules/PrimeTransport/python/.venv/bin/python -c "import ortools, numpy; print('ortools', ortools.__version__, 'numpy', numpy.__version__)"
```
```powershell
# Windows
Modules\PrimeTransport\python\.venv\Scripts\python.exe -c "import ortools, numpy; print('ortools', ortools.__version__, 'numpy', numpy.__version__)"
```
It must print `ortools 9.15.6755 numpy 2.5.4`.

**Production server:** build the venv **as the same user that runs the queue worker** (usually `www-data` or the deploy user), so that user can execute it:
```bash
sudo -u www-data bash -c 'cd /var/www/prime_ai/Modules/PrimeTransport/python && python3 -m venv .venv && .venv/bin/python -m pip install -r requirements.txt'
```
Replace `/var/www/prime_ai` with the real app path on the server.

---

## 5. Build and start the OSRM road server (Docker)

OSRM is an open-source road-routing server. It runs in Docker on our own machine, so no outside service ever sees the school's stop locations. It needs a road map of the area, which takes 4 one-time preparation steps (5.2 – 5.4) and then runs as a container (5.5).

Disk: about **0.6 GB** (the 221 MB download plus the prepared files). The running server uses about **120 MB** of RAM.

### 5.1 Make a data folder

| OS | Command |
|---|---|
| Linux / Mac | `mkdir -p ~/osrm-data && cd ~/osrm-data` |
| Windows | `mkdir C:\osrm-data; cd C:\osrm-data` |

Run **all of 5.2 – 5.6 from inside this folder.**

### 5.2 Download the road map (OpenStreetMap, from Geofabrik)

Our test school (test.localhost, Inspiration identity) is in **Haldwani, Uttarakhand**, which falls in India's **central zone** (Uttarakhand, Uttar Pradesh, Madhya Pradesh, Chhattisgarh):

| OS | Command |
|---|---|
| Linux / Mac | `curl -L -o central-zone-latest.osm.pbf https://download.geofabrik.de/asia/india/central-zone-latest.osm.pbf` |
| Windows | `curl.exe -L -o central-zone-latest.osm.pbf https://download.geofabrik.de/asia/india/central-zone-latest.osm.pbf` |

**On Windows, type `curl.exe`, not `curl`.** In PowerShell, plain `curl` is a different command.

Other Indian zones are listed on https://download.geofabrik.de/asia/india.html: central, eastern, north-eastern, northern, southern, western. Pick the zone that contains the school.

**Check:** the file `central-zone-latest.osm.pbf` is about **350 MB**.

### 5.3 Cut out just the city (keeps memory low)

Preparing the whole central zone needs a lot of RAM. We cut out a box around the city first.

The box is given as `minLongitude,minLatitude,maxLongitude,maxLatitude`. For **Haldwani** it is `79.2,28.9,79.9,29.5`. That covers the city, Kathgodam and Lalkuan with room to spare; every bus stop on the test tenant lies inside lat 29.20-29.29, lng 79.49-79.56.

| OS | Command |
|---|---|
| Linux / Mac | `docker run --rm -v "$PWD:/data" iboates/osmium:latest extract -b 79.2,28.9,79.9,29.5 /data/central-zone-latest.osm.pbf -o /data/haldwani.osm.pbf --overwrite` |
| Windows | `docker run --rm -v "${PWD}:/data" iboates/osmium:latest extract -b 79.2,28.9,79.9,29.5 /data/central-zone-latest.osm.pbf -o /data/haldwani.osm.pbf --overwrite` |

**For a school in another city**, take the school's latitude and longitude (from `sch_organizations`) and make a box about 0.6° each side. For example, a school at lat 23.03, lng 72.58 (Ahmedabad) gives the box `71.98,22.43,73.18,23.63`. You can also draw a box on https://boundingbox.klokantech.com and copy it in "CSV" format.

Any stop **outside** the box cannot be routed, and that route is drawn as a straight line.

**Check:** `haldwani.osm.pbf` exists and is about **3.4 MB** (measured 2026-10-29 with the box above).

### 5.4 Prepare the routing data (3 commands, run in this order)

Linux / Mac:
```bash
docker run --rm -v "$PWD:/data" ghcr.io/project-osrm/osrm-backend:v5.27.1 osrm-extract -p /opt/car.lua /data/haldwani.osm.pbf
docker run --rm -v "$PWD:/data" ghcr.io/project-osrm/osrm-backend:v5.27.1 osrm-partition /data/haldwani.osrm
docker run --rm -v "$PWD:/data" ghcr.io/project-osrm/osrm-backend:v5.27.1 osrm-customize /data/haldwani.osrm
```
Windows (PowerShell):
```powershell
docker run --rm -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend:v5.27.1 osrm-extract -p /opt/car.lua /data/haldwani.osm.pbf
docker run --rm -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend:v5.27.1 osrm-partition /data/haldwani.osrm
docker run --rm -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend:v5.27.1 osrm-customize /data/haldwani.osrm
```
Each command ends with a line containing `finished`. The first one takes the longest (about a minute).

**Check:** the folder now holds about 26 files named `haldwani.osrm.*`, for example `haldwani.osrm.mldgr`, `haldwani.osrm.partition` and `haldwani.osrm.cells`.

### 5.5 Start the server (once; it then restarts by itself)

Linux / Mac:
```bash
docker rm -f prime-osrm 2>/dev/null
docker run -d --name prime-osrm --restart unless-stopped -p 127.0.0.1:5000:5000 -v "$PWD:/data" ghcr.io/project-osrm/osrm-backend:v5.27.1 osrm-routed --algorithm mld /data/haldwani.osrm
```
Windows (PowerShell):
```powershell
docker rm -f prime-osrm 2>$null
docker run -d --name prime-osrm --restart unless-stopped -p 127.0.0.1:5000:5000 -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend:v5.27.1 osrm-routed --algorithm mld /data/haldwani.osrm
```

What the options mean:

- `--restart unless-stopped`: the container starts again whenever Docker starts. On Windows and Mac that needs Docker Desktop set to start at sign-in (step 1.1 / 1.2). On Linux it needs `systemctl enable docker` (step 1.3).
- `-p 127.0.0.1:5000:5000`: the server is reachable **only from this machine**. **On the production server, keep `127.0.0.1`.** Never publish port 5000 to the internet.
- The container name **must** be `prime-osrm`.
- The last argument must match the file name from 5.4 (`/data/haldwani.osrm`).

### 5.6 Check the road server

| OS | Command |
|---|---|
| Linux / Mac | `curl "http://127.0.0.1:5000/route/v1/driving/79.5130,29.2183;79.5300,29.2400?overview=false"` |
| Windows | `curl.exe "http://127.0.0.1:5000/route/v1/driving/79.5130,29.2183;79.5300,29.2400?overview=false"` |

The answer must start with `{"code":"Ok"` and contain `"distance":3782.8` (about 3.78 km — measured 2026-10-29). Also run `docker ps`: it must list `prime-osrm` as **Up**.

For a city other than Haldwani, use two points inside your own box for this test.

---

## 6. Set the `.env` values

Add these lines to `prime_ai/.env`. `.env.example` already lists `PRIME_TRANSPORT_OSRM_URL`.

```dotenv
# Road server from step 5. This is the DEFAULT for Settings → Maps & Distances → OSRM server URL,
# so a DB reset + reseed keeps it. Leave empty only if you have no OSRM server (straight lines).
PRIME_TRANSPORT_OSRM_URL=http://127.0.0.1:5000

# Windows ONLY (see step 4). Linux/Mac: leave this line out.
# PRIME_TRANSPORT_PYTHON_BINARY="C:/path/to/prime_ai/Modules/PrimeTransport/python/.venv/Scripts/python.exe"

# Production server ONLY: must be more than the longest plan solve (see step 8.3).
# DB_QUEUE_RETRY_AFTER=700
```

These keys are optional. Leave them out unless you need to change the default:

| Key | Default | Meaning |
|---|---|---|
| `PRIME_TRANSPORT_ENGINE_TIMEOUT` | `600` | Hard stop for one Python solve, in seconds |
| `PRIME_TRANSPORT_ENGINE_QUEUE` | `default` | Queue name `GeneratePlanJob` is sent to |
| `PRIME_TRANSPORT_OSRM_TIMEOUT` | `20` | Seconds allowed for an OSRM distance-table call |
| `PRIME_TRANSPORT_MAP_STYLE_URL` | empty | Self-hosted MapLibre style. Wins over the tiles below (production, later) |
| `PRIME_TRANSPORT_MAP_TILES` | `https://tile.openstreetmap.org/{z}/{x}/{y}.png` | Raster map tiles (public OSM is OK for development only) |
| `PRIME_TRANSPORT_MAP_ATTRIBUTION` | `&copy; OpenStreetMap contributors` | Map credit text |

**If Laravel itself runs inside Docker** (Sail, Laradock, or a docker-compose stack), `127.0.0.1` inside the PHP container means *that container*, not your PC. Use one of these instead:

- **Windows / Mac:** `PRIME_TRANSPORT_OSRM_URL=http://host.docker.internal:5000`
- **Linux:** add `extra_hosts: ["host.docker.internal:host-gateway"]` to the PHP service and use the same URL.
- **Any OS:** put `prime-osrm` on the same docker network as PHP and use `http://prime-osrm:5000`.

After editing `.env`, always run:
```bash
php artisan config:clear
php artisan cache:clear
```

---

## 7. Seed PrimeTransport

Pick **one** of these:

- **A full reset:** run the `/seeder` page as usual. It includes the Prime Transport module registration (foundation group) and the **Prime Transport Masters** group.
- **PrimeTransport only:** open `http://<your-tenant>.localhost:8000/seeder/prime-transport` in the browser. It runs:
  1. `PtrSettingsSeeder`: every setting with its default. **The OSRM URL default comes from `PRIME_TRANSPORT_OSRM_URL`.**
  2. `PtrSafetyRuleSeeder`: the 15 system safety rules.
  3. `PtrRuleSettingSeeder`: starter Smart Advisor rules.
  4. `PtrStudentGeoDemoSeeder`: **DEMO** home locations for students, generated around the school's own location (Haldwani on the test tenant).

All four seeders are insert-only and safe to run again. A value a school changed on the Settings tab is never overwritten.

**Check:**

1. Go to **Prime Transport → Masters → Settings**, section **Maps & Distances**. **OSRM server URL** must show `http://127.0.0.1:5000`, or your URL from step 6.
2. If the field is empty, `.env` was not re-read. Run `php artisan config:clear` and `php artisan cache:clear`, then reload the page.

**Distance source** (same section):

- `Straight line × road factor` (the default): the planner estimates distances. This is fast and needs no server.
- `OSRM road routing`: the planner uses real road distances from the server in step 5.

Road-traced **map lines** need only the OSRM URL; they work with either distance source.

---

## 8. Run the queue worker (required for "Generate plan")

### 8.1 Development (all OSes)
Keep this running in its own terminal while you use the app:
```bash
php artisan queue:work
```
After **every** `git pull`, code change or `.env` change, restart the worker. Otherwise it keeps running the old code:
```bash
php artisan queue:restart
```
Then start `queue:work` again if it does not restart by itself. On a dev PC it stops after `queue:restart`.

### 8.2 Production (Linux VPS) — Supervisor
The server may already run a worker for other modules. If so, **check its settings against this block** instead of adding a second one.

```bash
sudo apt install -y supervisor
sudo nano /etc/supervisor/conf.d/prime-queue.conf
```
```ini
[program:prime-queue]
command=php /var/www/prime_ai/artisan queue:work database --queue=default --sleep=3 --tries=1 --timeout=700
directory=/var/www/prime_ai
user=www-data
numprocs=1
autostart=true
autorestart=true
stopwaitsecs=720
redirect_stderr=true
stdout_logfile=/var/www/prime_ai/storage/logs/queue-worker.log
```
```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl status prime-queue      # must show RUNNING
```
After every deploy: `php artisan queue:restart`. Supervisor starts the worker again with the new code.

### 8.3 Why `DB_QUEUE_RETRY_AFTER=700` on the server
- `QUEUE_CONNECTION=database` re-releases a job after `retry_after` seconds. The default is **90**.
- A plan solve can be set to search for up to 300 seconds (setting *Route planner search time*), and the job allows up to 660 seconds.
- With 90, a long solve is handed out a second time while it is still running, and then marked failed.
- Set `DB_QUEUE_RETRY_AFTER=700` in the server `.env`, then run `php artisan config:clear` and `php artisan queue:restart`.
- On a dev PC with the default 30-second search this is not needed.

**Check:** generate a plan (Route Planner → Generate). Its status moves **Queued → Running → Done** within about a minute.

---

## 9. Run the scheduler (required for scheduled publishing)

The command `tenant:prime-transport:publish-scheduled` runs hourly at :05 from `routes/console.php`. The scheduler itself must be triggered **every minute**:

| Where | How |
|---|---|
| Dev PC (any OS) | Keep `php artisan schedule:work` running in a terminal when you test scheduled publishing |
| Linux server | `sudo crontab -u www-data -e` and add: `* * * * * cd /var/www/prime_ai && php artisan schedule:run >> /dev/null 2>&1` |
| Windows server (if ever) | Task Scheduler → a task every 1 minute running `php C:\path\to\prime_ai\artisan schedule:run` |

**Check:**
```bash
php artisan schedule:list
```
It must list `tenant:prime-transport:publish-scheduled`.

---

## 10. Final end-to-end check (do all 6)

1. `docker ps` shows `prime-osrm` **Up**, and step 5.6 returns `"code":"Ok"`.
2. The step 4 check prints the OR-Tools version.
3. Settings → Maps & Distances shows the OSRM URL.
4. `queue:work` is running (dev) or `supervisorctl status prime-queue` shows **RUNNING** (server).
5. Route Planner → **Generate** finishes with status **Done**.
6. Open the plan. The map lines **follow the roads** (curved, along streets), not straight lines from stop to stop.

The first time a plan is opened, each route's road path is fetched once and saved in `ptr_plan_routes.route_geometry`. Later views read the saved path. Plans made before OSRM was set up also turn road-traced the next time they are opened; you don't need to regenerate them.

---

## 11. Troubleshooting

| What you see | Cause | Fix |
|---|---|---|
| Map shows **straight lines** | (a) the `prime-osrm` container is not running | `docker start prime-osrm`. Then check `docker ps` and step 5.6. On Windows/Mac, make sure Docker Desktop is open and set to start at sign-in |
| | (b) the OSRM URL setting is empty | Set `PRIME_TRANSPORT_OSRM_URL` (step 6), run `config:clear` + `cache:clear`, or type the URL on Settings → Maps & Distances |
| | (c) Laravel runs in Docker and uses `127.0.0.1` | Use `host.docker.internal` or the docker network name (step 6) |
| | (d) the stops are outside the extracted box | Make a bigger box in step 5.3 and redo 5.3 – 5.5 |
| Straight lines **again after a DB reset** | Fixed on 2026-10-25 (commit `0cb2336e8`): the setting now defaults from `.env` | `git pull`, and make sure `.env` has `PRIME_TRANSPORT_OSRM_URL` |
| Plan stays **Queued** | No queue worker running | Step 8 |
| Plan **Failed**: *Python interpreter was not found* | No venv, or Windows without `PRIME_TRANSPORT_PYTHON_BINARY` | Step 4, then `config:clear` + `queue:restart` |
| Plan **Failed**: *ModuleNotFoundError: ortools* | The venv was built but `pip install` did not finish | Re-run the `pip install -r requirements.txt` line from step 4 |
| Plan fails after about 90 s on the server | `retry_after` is shorter than the solve | Step 8.3 |
| Pages error: table `ptr_settings` / `ptr_safety_rules` / `ptr_rule_settings` **doesn't exist** | Migrations not run, or a cached config hid the module's migration folder | `git pull`, `php artisan config:clear`, `php artisan tenants:migrate` |
| `/seeder` #284 *PtrStudentGeoDemoSeeder: Too few arguments* | Old code | `git pull` (fixed 2026-10-25) |
| Changed code or `.env` but nothing is different | The queue worker still runs the old code | `php artisan queue:restart` |
| **Map area is blank** (no streets at all) | The browser cannot reach unpkg.com or tile.openstreetmap.org | Check internet / firewall / ad-blocker. Self-hosted tiles for production are a pending item (see 07-PRIMETRANSPORT-PLAN.md) |
| `docker run ... osrm-extract` stops with *Killed* or exit 137 | Not enough RAM for the area | Use a smaller box in 5.3. On Windows/Mac, give Docker more memory: Docker Desktop → Settings → Resources |
| Windows: `docker: invalid reference format` or the mount is empty | Wrong folder syntax | Use **PowerShell** and `"${PWD}:/data"` exactly as written. In `cmd` it would be `"%cd%:/data"` |
| Port 5000 already in use (often on **Mac**: AirPlay Receiver) | Another program holds 5000 | Turn off System Settings → General → AirDrop & Handoff → **AirPlay Receiver**. Or use `-p 127.0.0.1:5001:5000` and set the URL to `http://127.0.0.1:5001` |

---

## 12. Several schools in different cities (server)

The OSRM URL is a **per-school** setting (each tenant's Settings → Maps & Distances). So:

- **Schools in the same zone:** one box (step 5.3) that covers all of them, and one container.
- **Schools far apart:** one container per region, each with its own folder, file name and port. For example, `prime-osrm-haldwani` on `127.0.0.1:5000` and `prime-osrm-surat` on `127.0.0.1:5001`. Then set each school's OSRM URL on its own Settings tab. The `.env` value is only the default for new or reset tenants.

---

## 13. Keeping the road map fresh (optional, every few months)

New roads appear in OpenStreetMap over time. To refresh, repeat steps **5.2 → 5.5** in the same folder. 5.5 removes and recreates the container. Saved road paths of old plans are not changed. New plans use the new map.
