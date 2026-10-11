

## Commands to Create All the Tables 7 Rfresh Data from Seeder (New)
====================================================================

composer dump-autoload
php artisan optimize
php artisan migrate: fresh --seed ---> [reset prime , global + create tenant + create tenant migration ]
run server : php artisan serve
test.localhost:8000/seeder  --> run seeder 



php artisan db:seed

## Commands when you have to Create & Set Tenant from Prime App (Depricated)
============================================================================

run --> php artisan migrate:fresh --seed
run server : php artisan serve
url :   http://localhost:8000/system-config/sync-menus  
url :  http://localhost:8000/system-config/sync-prime-menus
Access Central app :  http://localhost:8000
run : php artisan queue:work 
Go to tenant :  http://localhost:8000/prime/tenant-management?tab=tenant#tenant 
After creating tenant :  assing the 'Developer Plan' to the teant and  put status to active.
Access :  http://test.localhost:8000/
Seed the DB : http://test.localhost:8000/seeder  --> hit Run All Sequentially. 
access tenant app :  http://test.localhost:8000/dashboard 

Run the app :  npx expo run --clear 
 
php artisan serve --host=192.168.29.100
 
start mobile app server : npx expo start 
 
use EXPO application on mobile phone and scan then QR
 
composer dump-autoload
 
