# Step by Step (End to End) Applicaiton Setup on Localhost
==========================================================



php artisan migrate:fresh --seed

php artisan tenants:test-migrate

php artisan queue:work

php artisan optimize

php artisan queue:work




## To Seed Data into Prime Menu
-------------------------------
http://localhost:8000/system-config/sync-prime-menus

## To Seed Data into Tenant Menu
-------------------------------
http://localhost:8000/system-config/sync-menus


## To Seed Data into tenant_db for all the Tables
-------------------------------------------------
http://test.localhost:8000/seeder

## Key for Encription
---------------------
# NEVER NEVER NEVER LOSE THIS
DATA_ENCRYPTION_KEY=39HQrzWQRAwpFvk0NPMDTmi4gEgOBvBK0VzBWWVWdd0=
DATA_ENCRYPTION_CIPHER=AES-256-CBC