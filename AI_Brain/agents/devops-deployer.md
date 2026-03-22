# Agent: DevOps & Deployment Engineer

## Role
Infrastructure, CI/CD, and deployment specialist for the Prime-AI multi-tenant SaaS platform. Handles server provisioning, pipeline configuration, containerization, cloud deployment, SSL, domain management, and production operations for a stancl/tenancy Laravel application.

## When to Use This Agent
- Setting up **CI/CD pipelines** (GitHub Actions, GitLab CI, Bitbucket Pipelines)
- **Deploying** to cloud providers (AWS, DigitalOcean, Hetzner, Railway, Forge)
- Configuring **Docker/Docker Compose** for local dev and production
- Setting up **production server** (Nginx, PHP-FPM, MySQL, Redis, Supervisor)
- Configuring **SSL certificates** and **wildcard domains** for multi-tenancy
- Setting up **queue workers** (Supervisor for Laravel queues)
- Configuring **cron/scheduler** for Laravel scheduled tasks
- Setting up **backup automation** (Spatie Laravel Backup)
- Configuring **monitoring/alerting** (Laravel Telescope, Sentry, UptimeRobot)
- Managing **environment variables** and secrets across environments
- **Database operations** — tenant migration rollout, backup/restore, scaling

## Before Starting Any DevOps Work

1. Read `{PROJECT_DOCS}/01-project-overview.md` — Tech stack, 3-layer DB architecture
2. Read `{PROJECT_DOCS}/04-migration-guide.md` — Central vs tenant migration commands
3. Read `AI_Brain/memory/tenancy-map.md` — stancl/tenancy config, bootstrappers
4. Read `AI_Brain/memory/project-context.md` — External services (Razorpay, DomPDF, etc.)

## Critical Multi-Tenancy Deployment Rules

### 1. Wildcard DNS + SSL (MOST IMPORTANT)

stancl/tenancy uses domain-based tenant identification. Each school = one subdomain.

```
# DNS: Wildcard A record required
*.primeai.in  →  A  →  SERVER_IP

# SSL: Wildcard certificate required (Let's Encrypt or purchased)
# Certbot with wildcard:
sudo certbot certonly --manual --preferred-challenges=dns -d "*.primeai.in" -d "primeai.in"

# OR use Cloudflare (recommended for auto-SSL):
# Cloudflare handles wildcard SSL automatically on their proxy
```

### 2. Nginx Configuration (Multi-Tenant)

```nginx
server {
    listen 443 ssl http2;
    server_name primeai.in *.primeai.in;

    ssl_certificate /etc/letsencrypt/live/primeai.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/primeai.in/privkey.pem;

    root /var/www/prime-ai/public;
    index index.php;

    # Handle all subdomains — Laravel + stancl/tenancy handles routing
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;  # Timetable generation can take up to 120s
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    # File upload limit (for documents, photos)
    client_max_body_size 50M;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name primeai.in *.primeai.in;
    return 301 https://$host$request_uri;
}
```

### 3. Environment Variables (.env)

```bash
# Application
APP_NAME="Prime-AI"
APP_ENV=production
APP_DEBUG=false
APP_URL=https://primeai.in
APP_DOMAIN=primeai.in           # CRITICAL — used in routes/web.php for central routes

# Database — Central (prime_db + global_db)
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=prime_db
DB_USERNAME=primeai_user
DB_PASSWORD=<strong-password>

# Tenant databases are created automatically by stancl/tenancy
# Format: tenant_{uuid}
# MySQL user needs CREATE DATABASE permission

# Cache & Queue — Use Redis in production
CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379

# Mail
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=<email>
MAIL_PASSWORD=<app-password>
MAIL_ENCRYPTION=tls

# Razorpay
RAZORPAY_KEY=<key>
RAZORPAY_SECRET=<secret>
RAZORPAY_WEBHOOK_SECRET=<webhook-secret>

# Storage
FILESYSTEM_DISK=local
# Tenant storage: storage/tenant_{uuid}/

# Backup (Spatie)
BACKUP_DISK=s3
AWS_ACCESS_KEY_ID=<key>
AWS_SECRET_ACCESS_KEY=<secret>
AWS_DEFAULT_REGION=ap-south-1
AWS_BUCKET=primeai-backups
```

## CI/CD Pipeline Templates

### GitHub Actions — Complete Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy Prime-AI

on:
  push:
    branches: [main, staging]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: password
          MYSQL_DATABASE: testing
        ports: ['3306:3306']
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          extensions: mbstring, pdo_mysql, gd, zip, bcmath
          coverage: none

      - name: Install Composer Dependencies
        run: composer install --no-interaction --prefer-dist --optimize-autoloader

      - name: Copy .env
        run: cp .env.testing .env

      - name: Generate Key
        run: php artisan key:generate

      - name: Run Migrations
        run: php artisan migrate --force
        env:
          DB_CONNECTION: mysql
          DB_HOST: 127.0.0.1
          DB_PORT: 3306
          DB_DATABASE: testing
          DB_USERNAME: root
          DB_PASSWORD: password

      - name: Run Tests
        run: ./vendor/bin/pest --ci
        env:
          DB_CONNECTION: mysql
          DB_HOST: 127.0.0.1
          DB_PORT: 3306
          DB_DATABASE: testing
          DB_USERNAME: root
          DB_PASSWORD: password

  deploy-staging:
    needs: test
    if: github.ref == 'refs/heads/staging'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Staging
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.STAGING_HOST }}
          username: ${{ secrets.STAGING_USER }}
          key: ${{ secrets.STAGING_SSH_KEY }}
          script: |
            cd /var/www/prime-ai-staging
            git pull origin staging
            composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev
            php artisan migrate --force
            php artisan tenants:migrate --force
            php artisan config:cache
            php artisan route:cache
            php artisan view:cache
            php artisan queue:restart
            sudo supervisorctl restart prime-ai-worker:*

  deploy-production:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Production
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.PRODUCTION_HOST }}
          username: ${{ secrets.PRODUCTION_USER }}
          key: ${{ secrets.PRODUCTION_SSH_KEY }}
          script: |
            cd /var/www/prime-ai
            php artisan down --retry=60
            git pull origin main
            composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev
            php artisan migrate --force
            php artisan tenants:migrate --force
            php artisan config:cache
            php artisan route:cache
            php artisan view:cache
            php artisan queue:restart
            sudo supervisorctl restart prime-ai-worker:*
            php artisan up
```

### Zero-Downtime Deploy Script (Manual/Forge)

```bash
#!/bin/bash
# deploy.sh — Run on production server
set -e

APP_DIR="/var/www/prime-ai"
RELEASE_DIR="/var/www/releases/$(date +%Y%m%d%H%M%S)"

echo "=== Prime-AI Deployment ==="

# 1. Clone/copy to new release directory
mkdir -p $RELEASE_DIR
rsync -a --exclude='.git' --exclude='node_modules' --exclude='storage' $APP_DIR/ $RELEASE_DIR/

# 2. Pull latest code
cd $RELEASE_DIR
git pull origin main

# 3. Install dependencies
composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev

# 4. Link shared storage
ln -nfs /var/www/shared/storage $RELEASE_DIR/storage
ln -nfs /var/www/shared/.env $RELEASE_DIR/.env

# 5. Run migrations
php artisan migrate --force
php artisan tenants:migrate --force

# 6. Cache
php artisan config:cache
php artisan route:cache
php artisan view:cache

# 7. Swap symlink (zero downtime)
ln -nfs $RELEASE_DIR /var/www/prime-ai-current

# 8. Restart workers
sudo supervisorctl restart prime-ai-worker:*
php artisan queue:restart

echo "=== Deployed successfully ==="
```

## Server Setup — Complete Checklist

### Ubuntu 22.04 LTS + PHP 8.2 + MySQL 8 + Nginx + Redis

```bash
# 1. System
sudo apt update && sudo apt upgrade -y
sudo apt install -y software-properties-common curl git unzip supervisor

# 2. PHP 8.2
sudo add-apt-repository ppa:ondrej/php -y
sudo apt install -y php8.2-fpm php8.2-cli php8.2-mysql php8.2-mbstring php8.2-xml \
  php8.2-curl php8.2-zip php8.2-gd php8.2-bcmath php8.2-intl php8.2-redis

# 3. Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# 4. MySQL 8
sudo apt install -y mysql-server
sudo mysql_secure_installation
# Create databases + user:
# CREATE DATABASE prime_db;
# CREATE DATABASE global_db;
# CREATE USER 'primeai_user'@'localhost' IDENTIFIED BY '<password>';
# GRANT ALL PRIVILEGES ON *.* TO 'primeai_user'@'localhost' WITH GRANT OPTION;
# (WITH GRANT OPTION needed for stancl/tenancy to CREATE DATABASE per tenant)

# 5. Redis
sudo apt install -y redis-server
sudo systemctl enable redis-server

# 6. Nginx
sudo apt install -y nginx
# Copy nginx config from above

# 7. SSL (Certbot)
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d primeai.in -d "*.primeai.in"

# 8. Node.js (for Vite build)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

### Supervisor Config (Queue Workers)

```ini
# /etc/supervisor/conf.d/prime-ai-worker.conf
[program:prime-ai-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/prime-ai/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/prime-ai/storage/logs/worker.log
stopwaitsecs=3600
```

### Laravel Scheduler (Cron)

```bash
# Add to crontab (crontab -e):
* * * * * cd /var/www/prime-ai && php artisan schedule:run >> /dev/null 2>&1
```

## Docker Compose (Local Development)

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: primeai-app
    volumes:
      - .:/var/www/html
    ports:
      - "8000:8000"
    depends_on:
      - mysql
      - redis
    environment:
      - APP_ENV=local
      - DB_HOST=mysql
      - REDIS_HOST=redis

  mysql:
    image: mysql:8.0
    container_name: primeai-mysql
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: prime_db
    ports:
      - "3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql

  redis:
    image: redis:7-alpine
    container_name: primeai-redis
    ports:
      - "6379:6379"

  mailpit:
    image: axllent/mailpit
    container_name: primeai-mail
    ports:
      - "1025:1025"
      - "8025:8025"

volumes:
  mysql-data:
```

### Dockerfile

```dockerfile
FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    git curl zip unzip libpng-dev libjpeg-dev libfreetype6-dev \
    libonig-dev libxml2-dev libzip-dev libpq-dev \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

EXPOSE 8000
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
```

## Backup Strategy

```bash
# Spatie Laravel Backup config (config/backup.php)
# Central backup: runs daily, backs up prime_db + global_db + files
php artisan backup:run

# Tenant backup: iterate over all tenants
php artisan tenants:run backup:run

# Recommended schedule (in app/Console/Kernel.php):
$schedule->command('backup:run')->dailyAt('02:00');
$schedule->command('backup:clean')->dailyAt('03:00');

# Manual tenant DB backup:
mysqldump -u root -p tenant_<uuid> > backup_tenant_<uuid>_$(date +%Y%m%d).sql
```

## Monitoring & Health Checks

```bash
# Laravel Telescope (already installed)
# Access: https://primeai.in/telescope
# Only enable for admin users in production

# Health check endpoint (add to routes/web.php):
Route::get('/health', function () {
    try {
        DB::connection()->getPdo();
        Cache::store('redis')->get('health-check');
        return response()->json(['status' => 'ok', 'timestamp' => now()]);
    } catch (\Exception $e) {
        return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
    }
});

# External monitoring:
# - UptimeRobot: Monitor https://primeai.in/health every 5 minutes
# - Sentry: Install sentry/sentry-laravel for error tracking
# - Laravel Pulse: For real-time application metrics
```

## Cloud Provider Quick Setup

### AWS (Recommended for Scale)
```
EC2 (t3.medium+) + RDS (MySQL 8) + ElastiCache (Redis) + S3 (backups) + CloudFront (CDN)
Route53 for DNS with wildcard subdomain support
ACM for free wildcard SSL certificates
```

### DigitalOcean (Budget-Friendly)
```
Droplet ($24/mo 4GB) + Managed MySQL ($15/mo) + Redis ($15/mo)
Spaces for backup storage
Cloudflare for DNS + SSL (free tier)
```

### Laravel Forge (Easiest)
```
Forge handles: server provisioning, Nginx config, SSL, deployments, queue workers
Connect GitHub repo → auto-deploy on push
$12/mo for unlimited servers
Best option if you don't want to manage infrastructure manually
```

## Production Readiness Checklist

- [ ] `APP_ENV=production`, `APP_DEBUG=false`
- [ ] `CACHE_DRIVER=redis`, `QUEUE_CONNECTION=redis`, `SESSION_DRIVER=redis`
- [ ] `env('APP_DOMAIN')` replaced with `config('app.domain')` in routes/web.php
- [ ] Wildcard DNS configured (`*.primeai.in`)
- [ ] Wildcard SSL certificate installed
- [ ] MySQL user has CREATE DATABASE privilege (for tenant DB creation)
- [ ] Supervisor running queue workers (2+ processes)
- [ ] Cron configured for Laravel scheduler
- [ ] `php artisan config:cache` + `route:cache` + `view:cache` run
- [ ] Backups configured (daily, stored off-server)
- [ ] Health check endpoint responding
- [ ] Error monitoring (Sentry/Telescope) configured
- [ ] No `dd()`, hardcoded API keys, or debug routes in codebase
- [ ] Razorpay webhook route OUTSIDE auth middleware
- [ ] `is_super_admin` removed from User `$fillable`
- [ ] File upload limit set in Nginx (`client_max_body_size 50M`)
- [ ] PHP `max_execution_time` set to 300 (for timetable generation)
