# Template: Central Controller (Non-Module)

## Location
`app/Http/Controllers/`

## Use Case
For central/system-level controllers that don't belong to a specific module. Rare — most controllers should be in modules.

## Boilerplate

```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreEntityRequest;
use App\Http\Requests\UpdateEntityRequest;
use App\Models\Entity;
use App\Services\EntityService;
use Illuminate\Http\Request;

class EntityController extends Controller
{
    public function __construct(
        private readonly EntityService $entityService
    ) {}

    public function index(Request $request)
    {
        $entities = $this->entityService->list($request->all());

        return view('entity.index', compact('entities'));
    }

    public function store(StoreEntityRequest $request)
    {
        $entity = $this->entityService->create($request->validated());

        return redirect()
            ->route('entity.index')
            ->with('success', 'Created successfully.');
    }

    public function update(UpdateEntityRequest $request, Entity $entity)
    {
        $this->entityService->update($entity, $request->validated());

        return redirect()
            ->route('entity.index')
            ->with('success', 'Updated successfully.');
    }

    public function destroy(Entity $entity)
    {
        $this->entityService->delete($entity);

        return redirect()
            ->route('entity.index')
            ->with('success', 'Deleted successfully.');
    }
}
```

## Note
Prefer creating controllers inside modules. Use this template only for truly central functionality (e.g., dashboard, system health, global settings).
