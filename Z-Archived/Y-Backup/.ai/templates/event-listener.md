# Template: Event & Listener

## Location
- Events: `Modules/{ModuleName}/app/Events/`
- Listeners: `Modules/{ModuleName}/app/Listeners/` (or subscribing module's `Listeners/`)

## Generate
```bash
php artisan module:make-event EntityCreated ModuleName
php artisan module:make-listener OnEntityCreated ModuleName
```

---

## Event Class

```php
<?php

namespace Modules\ModuleName\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use Modules\ModuleName\Models\Entity;

class EntityCreated
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public readonly Entity $entity,
        public readonly int    $tenantId,   // Always pass tenant ID for queued listeners
    ) {}
}
```

## Listener Class

```php
<?php

namespace Modules\OtherModule\Listeners;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Modules\ModuleName\Events\EntityCreated;

class NotifyOnEntityCreated implements ShouldQueue
{
    use InteractsWithQueue;

    public string $queue = 'notifications';

    public function handle(EntityCreated $event): void
    {
        // Initialize tenancy for queued listeners
        $tenant = \Modules\Prime\Models\Tenant::find($event->tenantId);
        tenancy()->initialize($tenant);

        try {
            // Do work — now in correct tenant DB context
            $entity = $event->entity;
            // ...
        } finally {
            tenancy()->end();
        }
    }

    public function failed(EntityCreated $event, \Throwable $exception): void
    {
        \Illuminate\Support\Facades\Log::error('EntityCreated listener failed', [
            'entity_id' => $event->entity->id,
            'error'     => $exception->getMessage(),
        ]);
    }
}
```

## Register in EventServiceProvider

```php
// app/Providers/EventServiceProvider.php (or module ServiceProvider)
protected $listen = [
    \Modules\ModuleName\Events\EntityCreated::class => [
        \Modules\OtherModule\Listeners\NotifyOnEntityCreated::class,
    ],
];
```

## Dispatch the Event

```php
// In a service method, after successful creation:
EntityCreated::dispatch($entity, tenant()->id);
```

## Notes
- **Queued listeners MUST re-initialize tenancy** — context is lost between jobs
- **Always pass `$tenantId`** as a plain scalar (int/string) — not the Tenant model (causes serialization issues)
- **Cross-module communication:** Prefer events over direct service calls between modules
- **`SerializesModels`:** Automatically re-fetches Eloquent models when the job runs — safe to pass models in events
- **Failed jobs:** Always implement `failed()` for observability
- **Queue:** Assign slow listeners (email, PDF) to specific queues (`notifications`, `reports`)
