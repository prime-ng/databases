# Template: Repository

## Location
`Modules/{ModuleName}/app/Repositories/` or `app/Repositories/`

## Use Case
Optional pattern for complex query logic. In this project, most data access is done directly through Eloquent in Services. Use repositories when query complexity warrants separation.

## Boilerplate

```php
<?php

namespace Modules\ModuleName\Repositories;

use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;
use Modules\ModuleName\Models\Entity;

class EntityRepository
{
    public function __construct(
        private readonly Entity $model
    ) {}

    /**
     * Get all active entities.
     */
    public function all(): Collection
    {
        return $this->model->where('is_active', true)->get();
    }

    /**
     * Find entity by ID.
     */
    public function find(int $id): ?Entity
    {
        return $this->model->find($id);
    }

    /**
     * Find entity by ID or fail.
     */
    public function findOrFail(int $id): Entity
    {
        return $this->model->findOrFail($id);
    }

    /**
     * Create a new entity.
     */
    public function create(array $data): Entity
    {
        return $this->model->create($data);
    }

    /**
     * Update an entity.
     */
    public function update(Entity $entity, array $data): Entity
    {
        $entity->update($data);
        return $entity->fresh();
    }

    /**
     * Soft delete an entity.
     */
    public function delete(Entity $entity): bool
    {
        return $entity->delete();
    }

    /**
     * Paginate with optional filters.
     */
    public function paginate(array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        return $this->model->query()
            ->when($filters['search'] ?? null, function ($q, $search) {
                $q->where('name', 'like', "%{$search}%");
            })
            ->when(isset($filters['is_active']), function ($q) use ($filters) {
                $q->where('is_active', $filters['is_active']);
            })
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);
    }

    /**
     * Find with relationships.
     */
    public function findWithRelations(int $id, array $relations): ?Entity
    {
        return $this->model->with($relations)->find($id);
    }
}
```

## Note
- Eloquent only — no raw SQL
- The model handles scopes and relationships
- The repository handles query composition
- The service handles business logic and transactions
