# Template: Central/System Migration

## Location
`database/migrations/`

## Command
```bash
php artisan make:migration create_table_name
```

## Boilerplate

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Central/system-level migration.
     * This runs against the central database (prime_db).
     */
    public function up(): void
    {
        Schema::create('prm_table_name', function (Blueprint $table) {
            $table->id();

            // For tenant reference
            $table->string('tenant_id')->nullable();
            $table->foreign('tenant_id')
                  ->references('id')
                  ->on('prm_tenant')
                  ->onDelete('cascade');

            // Data columns
            $table->string('name', 150);
            $table->text('description')->nullable();
            $table->decimal('amount', 12, 2)->default(0);

            // Standard columns
            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            // Indexes
            $table->index('tenant_id');
            $table->index('is_active');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('prm_table_name');
    }
};
```

## Notes
- Central tables use `prm_` prefix for Prime/SaaS management
- Central tables use `bil_` prefix for billing
- Central tables use `sys_` prefix for system config
- Central tables use `glb_` prefix for global reference data
- Tenant ID is a UUID string (`string('tenant_id')`)
- Central migrations run with `php artisan migrate`
