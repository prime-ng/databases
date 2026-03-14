# Template: Module Service

## Location
`Modules/{ModuleName}/app/Services/`

## Boilerplate

```php
<?php

namespace Modules\ModuleName\Services;

use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Modules\ModuleName\Models\Entity;

class EntityService
{
    /**
     * List entities with optional filtering and pagination.
     */
    public function list(array $filters = []): LengthAwarePaginator
    {
        return Entity::query()
            ->with(['relationship1', 'relationship2'])
            ->when($filters['search'] ?? null, function ($query, $search) {
                $query->where('name', 'like', "%{$search}%");
            })
            ->when($filters['is_active'] ?? null, function ($query, $isActive) {
                $query->where('is_active', $isActive);
            })
            ->orderBy('created_at', 'desc')
            ->paginate($filters['per_page'] ?? 15);
    }

    /**
     * Create a new entity.
     */
    public function create(array $data): Entity
    {
        try {
            DB::beginTransaction();

            $data['created_by'] = auth()->id();
            $entity = Entity::create($data);

            // Handle relationships if needed
            // $entity->relationship()->attach($data['related_ids']);

            DB::commit();

            return $entity->load(['relationship1']);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Failed to create entity', [
                'error' => $e->getMessage(),
                'data' => $data,
            ]);
            throw $e;
        }
    }

    /**
     * Update an existing entity.
     */
    public function update(Entity $entity, array $data): Entity
    {
        try {
            DB::beginTransaction();

            $entity->update($data);

            // Sync relationships if needed
            // $entity->relationship()->sync($data['related_ids'] ?? []);

            DB::commit();

            return $entity->fresh(['relationship1']);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Failed to update entity', [
                'error' => $e->getMessage(),
                'entity_id' => $entity->id,
            ]);
            throw $e;
        }
    }

    /**
     * Soft delete an entity.
     */
    public function delete(Entity $entity): bool
    {
        return $entity->delete();
    }

    /**
     * Toggle active status.
     */
    public function toggleStatus(Entity $entity): Entity
    {
        $entity->update(['is_active' => !$entity->is_active]);
        return $entity;
    }

    /**
     * Restore a soft-deleted entity.
     */
    public function restore(int $id): Entity
    {
        $entity = Entity::withTrashed()->findOrFail($id);
        $entity->restore();
        return $entity;
    }

    /**
     * Find entity by ID with relationships.
     */
    public function find(int $id): Entity
    {
        return Entity::with(['relationship1', 'relationship2'])->findOrFail($id);
    }
}
```

## Notes
- **Tenant context:** All queries automatically go to the tenant DB when tenancy is initialized (via middleware). No need to manually switch.
- **Transactions:** Always wrap multi-step operations in `DB::beginTransaction()` / `DB::commit()`.
- **Logging:** Log errors with context for debugging.
- **Auth:** Use `auth()->id()` for `created_by` — assumes user is authenticated.
