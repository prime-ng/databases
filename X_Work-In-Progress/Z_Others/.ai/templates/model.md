# Template: Eloquent Model

## Location
`Modules/{ModuleName}/app/Models/`

## Tenant-Scoped Model (most common)

```php
<?php

namespace Modules\ModuleName\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;

class Entity extends Model implements HasMedia
{
    use HasFactory, SoftDeletes, InteractsWithMedia;

    protected $table = 'prefix_entities'; // e.g. sch_entities, std_entities

    protected $fillable = [
        'name',
        'description',
        'is_active',
        'created_by',
        // ...
    ];

    protected $casts = [
        'is_active'  => 'boolean',
        'meta'       => 'array',       // for JSON columns
        'starts_at'  => 'datetime',
        'ends_at'    => 'datetime',
    ];

    // ─── Relationships ────────────────────────────────────────────

    public function parent(): BelongsTo
    {
        return $this->belongsTo(ParentModel::class);
    }

    public function children(): HasMany
    {
        return $this->hasMany(ChildModel::class);
    }

    public function tags(): BelongsToMany
    {
        return $this->belongsToMany(Tag::class, 'prefix_entity_tag_jnt');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(\App\Models\User::class, 'created_by');
    }

    // ─── Scopes ──────────────────────────────────────────────────

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeForClass($query, int $classId)
    {
        return $query->where('class_id', $classId);
    }

    // ─── Media ───────────────────────────────────────────────────

    public function registerMediaCollections(): void
    {
        $this->addMediaCollection('documents')->singleFile();
        $this->addMediaCollection('images');
    }
}
```

## Central-Scoped Model (Prime/GlobalMaster modules)

```php
<?php

namespace Modules\Prime\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Entity extends Model
{
    use SoftDeletes;

    // Central models use prime_db or global_db — no tenant context
    protected $connection = 'prime'; // or 'global'
    protected $table      = 'prm_entities';

    protected $fillable = [
        'name',
        'is_active',
        'created_by',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];
}
```

## Notes
- Tenant models: **do NOT set `$connection`** — tenancy bootstrapper handles it automatically
- Central models: **always set `$connection`** explicitly (`prime` or `global`)
- All tables must have: `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
- Use `SoftDeletes` on every model (except pure junction/pivot tables)
- Use `InteractsWithMedia` only when the entity needs file attachments
- Table prefix must match the module prefix convention (see CLAUDE.md)
