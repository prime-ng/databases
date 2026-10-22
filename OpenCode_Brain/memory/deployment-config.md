# Deployment Configuration Reference — Prime-AI
> Used by: Technical Auditor (Layer 5), DevOps agent
> Last Updated: 2026-06-25

---

## Queue Names and Workload Map

Prime-AI uses Laravel Horizon with named queues. Each queue has a defined workload:

| Queue Name | Intended Workload | Expected Volume | Max Time |
|------------|------------------|-----------------|----------|
| `default` | General jobs, notifications | Medium | 60s |
| `generation` | Timetable generation (FET solver) | Low, spiky | 300s |
| `reports` | PDF report generation (HPC, marksheets) | Medium | 120s |
| `emails` | Email dispatch (fees, notifications) | High | 30s |
| `imports` | CSV/Excel bulk import jobs | Low | 600s |
| `webhooks` | Razorpay webhook processing | Low | 30s |

### Horizon Configuration Checklist

```bash
# Verify Horizon has production environment config
grep -A 20 "'production'" config/horizon.php

# Confirm each named queue has supervisor entry
grep -A 5 "queue" config/horizon.php
```

**Required:** Every queue in the workload map above must have a named supervisor in `config/horizon.php` for the `production` environment. Missing supervisor = jobs silently queue forever.

**Critical:** `generation` queue must have `timeout` set to at least `300` and `tries` ≥ 3 with exponential backoff. FET solver jobs can take 4–5 minutes on large schools.

---

## Environment Variable Checklist

### Required Variables (must be set, never empty in production)

| Variable | Purpose | Risk if Missing |
|----------|---------|-----------------|
| `APP_KEY` | Encryption key | All sessions/cookies invalid |
| `APP_ENV` | Environment flag | Logic branches may use dev paths |
| `APP_DEBUG` | Stack trace exposure | **P0: must be `false` in production** |
| `APP_URL` | Base URL | Email links, asset URLs broken |
| `DB_CONNECTION` | Default DB | All queries fail |
| `DB_HOST`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD` | Prime DB | All central queries fail |
| `TENANT_DB_HOST` | Tenant DB host | All tenant queries fail |
| `QUEUE_CONNECTION` | Queue driver | Jobs run synchronously (bad) |
| `REDIS_HOST` | Redis host | Queue, cache, sessions broken |
| `MAIL_MAILER`, `MAIL_HOST` | Email config | All email silent-fails |

### Security Variables (must be rotated from test values)

| Variable | Known Leak Risk | Action |
|----------|----------------|--------|
| `OPENAI_API_KEY` | Hardcoded in QuestionBank (SEC-QNS-002) | Rotate immediately |
| `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` | Hardcoded in Payment copy.php (SEC-PAY-001) | Rotate immediately |
| `APP_DEBUG` | Must be `false` | Verify before every deploy |

### Stancl Tenancy Variables

| Variable | Required Value |
|----------|---------------|
| `TENANCY_BOOTSTRAPPER_QUEUE_CONNECTION` | Should match `QUEUE_CONNECTION` |
| `CENTRAL_DOMAINS` | Comma-separated list of central domains (must NOT include tenant domains) |

---

## Deployment Pre-flight Checklist

Run before every production deployment:

```bash
# 1. Check for pending migrations
php artisan migrate:status | grep "No\|Pending"

# 2. Verify route cache will work
php artisan route:list 2>&1 | grep -i "error\|exception"

# 3. Check for hardcoded API keys
grep -rn "sk-proj-\|AIzaSy\|rzp_test_\|rzp_live_" Modules/ --include="*.php" | grep -v ".env"

# 4. Debug mode check
grep "APP_DEBUG" .env

# 5. Config cache test
php artisan config:cache && php artisan config:clear

# 6. Verify storage symlink
ls -la public/storage

# 7. Check Horizon is configured for production
php artisan horizon:status 2>/dev/null || echo "Horizon not running"
```

---

## Known Deployment Risks (from known-issues.md)

| Code | Risk | Status |
|------|------|--------|
| SEC-QNS-002 | OpenAI + Gemini keys hardcoded in QuestionBank | OPEN — rotate immediately |
| SEC-PAY-001 | Razorpay test keys hardcoded in Payment copy.php | OPEN — rotate immediately |
| SEC-PLATFORM-002 | `env('APP_DOMAIN')` in routes/web.php — ALL central routes 404 after `config:cache` | OPEN — blocks deployment |
| SEC-NTF-006 | ALL Notification routes commented out in web.php | OPEN — module inaccessible |
| DEPLOY-CMP-01 | Complaint module: no migration files for any tables | OPEN — module not deployable |
| DEPLOY-CMP-02 | Complaint module: `RouteServiceProvider` imports cross-module models | OPEN — load error risk |
| DEPLOY-HRZ-01 | **Queue driver mismatch:** `config/queue.php:17` hardcodes `default=database` but `config/horizon.php:201` supervises `connection=redis`. Jobs without explicit connection land on DB queue Horizon never reads → silently stuck. | OPEN — P0 (confirmed 2026-06-27) |
| DEPLOY-HRZ-02 | Single supervisor / single `['default']` queue with `tries=1`, `timeout=60`. No isolated `generation`/`reports`/`emails` queues (contradicts the workload map above). Heavy PDF/timetable jobs >60s killed with no retry. | OPEN — P0/P1 |
| DEPLOY-ENV-02 | **`.env-original` committed to git** with live `APP_KEY=base64:…` (forge signed URLs / decrypt cookies & encrypted columns). Defaults also ship `APP_ENV=local`. | OPEN — P0, rotate APP_KEY |
| DEPLOY-MIG-01 | **Cross-DB / missing FK targets:** 17 tenant FKs → `sys_roles` (no create migration anywhere); 52 tenant FKs → `sys_dropdowns` (central-only table). `tenants:migrate` throws errno 150/1824 or silently drops constraints. | OPEN — P0 (confirmed 2026-06-27) |
| DEPLOY-RTG-01 | **SEC-RTG-001 still live:** ~45 seeder routes at `routes/tenant.php:318+` are OUTSIDE the `auth` group (closes :296); `SeederController` has zero env/guard checks → anonymous destructive seeding on any tenant. | OPEN — P0 |
| DEPLOY-CFG-01 | Route closures break `route:cache` (`routes/api.php:9`, `routes/tenant.php:306`, `routes/web.php:996`, `SmartTimetable/routes/web.php:52`). `env()` outside config (11 sites, incl. `QuestionBank/AIQuestionGeneratorController.php:531,578`) returns null after `config:cache`. | OPEN — P1 |

---

## Route Caching Safety Notes

`php artisan route:cache` will FAIL if:
1. Any route file references a class that doesn't exist (missing imports)
2. `env('APP_DOMAIN')` is used in route registration closures (SEC-PLATFORM-002)
3. Any module's `RouteServiceProvider` has a broken import

Before `route:cache`, always run:
```bash
php artisan route:list 2>&1 | grep -i "error\|exception\|not found"
```
Zero errors = safe to cache.

---

## Storage Configuration

```bash
# Create storage symlink (run once on new server)
php artisan storage:link

# Verify permissions
chmod -R 775 storage/
chmod -R 775 bootstrap/cache/
chown -R www-data:www-data storage/ bootstrap/cache/
```

Directories that must be writable:
- `storage/app/` — File uploads
- `storage/framework/cache/` — Application cache
- `storage/framework/sessions/` — Session files
- `storage/framework/views/` — Blade compiled views
- `storage/logs/` — Application logs
- `bootstrap/cache/` — Config/route/service caches

---

## Log Configuration

| Setting | Development | Production |
|---------|-------------|------------|
| `LOG_CHANNEL` | `single` | `daily` |
| `LOG_LEVEL` | `debug` | `error` |
| `LOG_DAYS` | — | `14` |

`LOG_LEVEL=debug` in production logs ALL queries, ALL auth events — high I/O, security risk.

---

## Minimum Server Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| PHP | 8.2 | 8.3 |
| MySQL | 8.0 | 8.0 |
| Redis | 6.0 | 7.0 |
| Memory | 1GB | 4GB |
| Storage | 20GB | 100GB |

Laravel Octane (Swoole/RoadRunner) is NOT currently configured. Standard PHP-FPM is assumed.
