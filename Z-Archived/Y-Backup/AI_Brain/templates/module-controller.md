# Template: Module Controller

## Location
`Modules/{ModuleName}/app/Http/Controllers/`

## Boilerplate

```php
<?php

namespace Modules\ModuleName\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Modules\ModuleName\Http\Requests\StoreEntityRequest;
use Modules\ModuleName\Http\Requests\UpdateEntityRequest;
use Modules\ModuleName\Models\Entity;
use Modules\ModuleName\Services\EntityService;

class EntityController extends Controller
{
    public function __construct(
        private readonly EntityService $entityService
    ) {}

    /**
     * Display a listing of entities.
     */
    public function index(Request $request)
    {
        $entities = $this->entityService->list($request->all());

        return view('modulename::entity.index', compact('entities'));
    }

    /**
     * Show the form for creating a new entity.
     */
    public function create()
    {
        return view('modulename::entity.create');
    }

    /**
     * Store a newly created entity.
     */
    public function store(StoreEntityRequest $request)
    {
        $entity = $this->entityService->create($request->validated());

        return redirect()
            ->route('entity.index')
            ->with('success', 'Entity created successfully.');
    }

    /**
     * Display the specified entity.
     */
    public function show(Entity $entity)
    {
        $entity->load(['relationship1', 'relationship2']);

        return view('modulename::entity.show', compact('entity'));
    }

    /**
     * Show the form for editing the entity.
     */
    public function edit(Entity $entity)
    {
        return view('modulename::entity.edit', compact('entity'));
    }

    /**
     * Update the specified entity.
     */
    public function update(UpdateEntityRequest $request, Entity $entity)
    {
        $this->entityService->update($entity, $request->validated());

        return redirect()
            ->route('entity.index')
            ->with('success', 'Entity updated successfully.');
    }

    /**
     * Remove the specified entity (soft delete).
     */
    public function destroy(Entity $entity)
    {
        $this->entityService->delete($entity);

        return redirect()
            ->route('entity.index')
            ->with('success', 'Entity deleted successfully.');
    }

    /**
     * Toggle active status.
     */
    public function toggleStatus(Entity $entity)
    {
        $this->entityService->toggleStatus($entity);

        return back()->with('success', 'Status updated.');
    }

    /**
     * Restore a soft-deleted entity.
     */
    public function restore(int $id)
    {
        $this->entityService->restore($id);

        return back()->with('success', 'Entity restored.');
    }
}
```

## API Controller Variant

```php
/**
 * For JSON API endpoints (used with API Resources)
 */
public function index(Request $request)
{
    $entities = $this->entityService->list($request->all());

    return response()->json([
        'success' => true,
        'data' => EntityResource::collection($entities),
        'meta' => [
            'current_page' => $entities->currentPage(),
            'last_page' => $entities->lastPage(),
            'per_page' => $entities->perPage(),
            'total' => $entities->total(),
        ],
    ]);
}

public function store(StoreEntityRequest $request)
{
    $entity = $this->entityService->create($request->validated());

    return response()->json([
        'success' => true,
        'data' => new EntityResource($entity),
        'message' => 'Entity created successfully.',
    ], 201);
}
```
