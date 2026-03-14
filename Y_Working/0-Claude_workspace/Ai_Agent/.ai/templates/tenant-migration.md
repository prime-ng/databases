# Template: Tenant Migration

## Location
`database/migrations/tenant/` or via `php artisan module:make-migration migration_name ModuleName`

## Boilerplate

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('prefix_table_name', function (Blueprint $table) {
            // Primary key
            $table->id(); // INT UNSIGNED AUTO_INCREMENT

            // Foreign keys
            $table->unsignedInteger('parent_id');
            $table->foreign('parent_id')
                  ->references('id')
                  ->on('prefix_parent_table')
                  ->onDelete('cascade');

            // Data columns
            $table->string('name', 150);
            $table->string('code', 60)->nullable();
            $table->text('description')->nullable();
            $table->json('params_json')->nullable();
            $table->decimal('amount', 12, 2)->default(0);
            $table->boolean('is_compulsory')->default(false);
            $table->date('effective_from_date')->nullable();
            $table->date('effective_to_date')->nullable();

            // Standard columns (REQUIRED on every table)
            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('created_by')->nullable();
            $table->timestamps(); // created_at, updated_at
            $table->softDeletes(); // deleted_at

            // Indexes
            $table->index('is_active');
            $table->index('parent_id');
            $table->unique(['code']); // if code must be unique
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('prefix_table_name');
    }
};
```

## Table Prefix Guide
Use the prefix matching the module:
- `tt_` — Timetable
- `std_` — Student
- `sch_` — School Setup
- `slb_` — Syllabus
- `qns_` — Questions
- `fin_` — Finance/Fees
- `tpt_` — Transport
- `vnd_` — Vendor
- `cmp_` — Complaint
- `ntf_` — Notification
- `rec_` — Recommendation
- `hpc_` — HPC
- `bok_` — Books

## Junction Table Example
```php
Schema::create('prefix_entity1_entity2_jnt', function (Blueprint $table) {
    $table->id();
    $table->unsignedInteger('entity1_id');
    $table->unsignedInteger('entity2_id');
    $table->unsignedInteger('created_by')->nullable();
    $table->timestamps();

    $table->foreign('entity1_id')->references('id')->on('prefix_entity1s');
    $table->foreign('entity2_id')->references('id')->on('prefix_entity2s');
    $table->unique(['entity1_id', 'entity2_id']);
});
```
