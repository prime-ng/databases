# How to Run Web Application & Mobile App on Localhost
======================================================

IP : http://192.168.29.100:8000


## After Restart the Laptop below steps needs to be followed :
--------------------------------------------------------------

Open Terminal on folder "/Users/bkwork/Herd/prime_ai" and Run below command as required :
To start Terminal in VS Code on that Folder, Right Click on the folder and click on "Open in Integrated Terminal"

Only after taking Pull from Git we have to Run below command :
>> composer dump-autoload


>> php artisan optimize

>> php artisan serve



Open VS code on 'mobile_student' folder in "/Users/bkwork/Herd"
then start terminal in vs code and execute below command -
>>  npx expo start


#### Required Changes in App Config Files:
------------------------------------------
make below changes in  (/.env) file On Application Root:

Current value
-------------
APP_URL=http://localhost:8000
APP_DOMAIN=localhost
TENANCY_CENTRAL_DOMAINS=localhost

Should be replaced with
-----------------------
APP_URL=http://prime_ai.test
APP_DOMAIN=prime_ai
TENANCY_CENTRAL_DOMAINS=prime_ai

Current value
-------------
Change below in root/config/app.php
In Section - Application URL
'url' => env('APP_URL', 'http://localhost'),

Should be replaced with
-----------------------
'url' => env('APP_URL', 'http://prime_ai'),

At all above 4 places change localhost with prime_ai.test
------------------------------------------


### To Update Menu for Prime & Tanent App
=========================================

### To update Prime Menu
http://localhost:8000/system-config/sync-prime-menus

### To update Tenant Menu
http://localhost:8000/system-config/sync-menus



### Tenant App
--------------
test.localhost:8000
root@tenant.com / password@123

### Prime App
-------------
localhost:8000
superadmin@prime.com / password


### To Run Mobile Application
-----------------------------
Open Terminal on the Folder for the Mobile App (mobile_stundet / mobile_school) want to run on Mobile
Execute below command in the Terminal
```
npx expo start
```
If you have made some chnages and want to clear memory before start npx expo then use below command:



### Mobile App - Student
------------------------
esha.dutt68@yopmail.com / password

### Mobile App - School
-----------------------
root@tenant.com / password@123

