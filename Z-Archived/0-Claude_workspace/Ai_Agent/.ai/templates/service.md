# Template: Central Service (Non-Module)

## Location
`app/Services/`

## Use Case
For shared services used across multiple modules. Most services should be in modules.

## Boilerplate

```php
<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SharedService
{
    /**
     * Perform a shared operation.
     */
    public function execute(array $data): mixed
    {
        try {
            DB::beginTransaction();

            // Business logic here

            DB::commit();

            return $result;
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('SharedService operation failed', [
                'error' => $e->getMessage(),
                'data' => $data,
            ]);
            throw $e;
        }
    }
}
```

## Note
Prefer creating services inside modules. Use this template only for truly shared functionality (e.g., notification dispatch, audit logging, file processing).
