# Artisan Commands Reference

## nwidart/laravel-modules v12 Commands

### Module Scaffold Commands

```bash
# Create a new module
php artisan module:make <ModuleName>
# Example: php artisan module:make Attendance

# Create controller inside a module
php artisan module:make-controller <ControllerName> <ModuleName>
# Example: php artisan module:make-controller AttendanceController Attendance
# Result: Modules/Attendance/app/Http/Controllers/AttendanceController.php

# Create model inside a module
php artisan module:make-model <ModelName> <ModuleName>
# Example: php artisan module:make-model Attendance Attendance
# Result: Modules/Attendance/app/Models/Attendance.php

# Create migration inside a module (for prime only)
php artisan module:make-migration <MigrationName> <ModuleName>
# Example: php artisan module:make-migration create_prm_boards_table Prime

# Create form request
php artisan module:make-request <RequestName> <ModuleName>
# Example: php artisan module:make-request StoreAttendanceRequest Attendance

# Create resource (API resource)
php artisan module:make-resource <ResourceName> <ModuleName>

# Create seeder
php artisan module:make-seeder <SeederName> <ModuleName>

# Create factory
php artisan module:make-factory <FactoryName> <ModuleName>

# Create policy
php artisan module:make-policy <PolicyName> <ModuleName>

# Create middleware
php artisan module:make-middleware <MiddlewareName> <ModuleName>

# Create command
php artisan module:make-command <CommandName> <ModuleName>

# Create event
php artisan module:make-event <EventName> <ModuleName>

# Create listener
php artisan module:make-listener <ListenerName> <ModuleName>

# Create job
php artisan module:make-job <JobName> <ModuleName>

# Create provider
php artisan module:make-provider <ProviderName> <ModuleName>

# Create test
php artisan module:make-test <TestName> <ModuleName>
```

### Module Management Commands

```bash
# List all modules with status
php artisan module:list

# Enable a module
php artisan module:enable <ModuleName>

# Disable a module
php artisan module:disable <ModuleName>
```

### Migration Commands

```bash
# Create tenant migration (MOST COMMON):
php artisan make:migration create_hpc_new_table_table --path=database/migrations/tenant

# Create central migration:
php artisan make:migration create_prm_new_table_table

# Run all central migrations:
php artisan migrate

# Run all tenant migrations (all schools):
php artisan tenants:migrate

# Run tenant migrations for specific school:
php artisan tenants:migrate --tenants=<tenant-uuid>

# Rollback tenant migrations:
php artisan tenants:migrate-rollback

# Seed tenant databases:
php artisan tenants:seed
php artisan tenants:seed --class="Modules\Hpc\Database\Seeders\HpcSeeder"
```

### Cache & Optimization Commands

```bash
php artisan optimize:clear          # Clear all caches
php artisan config:clear            # Clear config cache
php artisan route:clear             # Clear route cache
php artisan view:clear              # Clear compiled views
php artisan cache:clear             # Clear application cache
php artisan config:cache            # Cache config (production)
php artisan route:cache             # Cache routes (production)
```

### Testing Commands (Pest 4.x)

```bash
./vendor/bin/pest                           # All tests
./vendor/bin/pest tests/Unit/               # Unit tests only
./vendor/bin/pest --filter="keyword"        # Filter by keyword
./vendor/bin/pest Modules/Hpc/              # Module tests only
./vendor/bin/pest tests/Unit/SmartTimetable/ # Specific test folder
```

### Useful Debug Commands

```bash
php artisan route:list                      # List all routes
php artisan route:list --path=hpc           # Filter by path prefix
php artisan tinker                          # Laravel REPL
php artisan db:show                         # Show DB info
php artisan db:show --table=hpc_parameters  # Show table structure
```
