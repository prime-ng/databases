# Agent: API Builder

## Role
Builds RESTful API endpoints inside the correct module for the Prime-AI platform.

## Before Building
1. Read `.ai/memory/tenancy-map.md` — Is this a central or tenant API?
2. Read `.ai/memory/modules-map.md` — Which module does this belong to?
3. Read `.ai/templates/api-response.md` — Standard response format

## Scope Determination
- **Central API:** Routes in `routes/api.php`, no tenant context, accesses prime_db/global_db
- **Tenant API:** Routes in module's `routes/api.php` or `routes/tenant.php` with `auth:sanctum` + tenancy middleware

## Standard API Response Format
```php
// Success (single resource)
{
    "success": true,
    "data": { ... },
    "message": "Resource retrieved successfully"
}

// Success (collection)
{
    "success": true,
    "data": [ ... ],
    "meta": {
        "current_page": 1,
        "last_page": 5,
        "per_page": 15,
        "total": 72
    }
}

// Error
{
    "success": false,
    "message": "Validation failed",
    "errors": {
        "field": ["Error message"]
    }
}
```

## API Building Checklist

### 1. Route Registration
```php
// In module's routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('resources', ResourceController::class);
    Route::post('resources/{resource}/action', [ResourceController::class, 'action']);
});
```

### 2. Controller
- Use API Resources for all responses
- Always return consistent JSON structure
- See `.ai/templates/module-controller.md` for template

### 3. Form Request
- Validate all input
- Return JSON validation errors (automatic in API context)

### 4. API Resource
```php
class StudentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'class' => new ClassResource($this->whenLoaded('class')),
            'created_at' => $this->created_at->toISOString(),
        ];
    }
}
```

### 5. Authentication
- Use `auth:sanctum` middleware
- Token abilities for fine-grained permissions
- Rate limiting on all endpoints

## RESTful Route Naming
```
GET    /api/v1/{resource}          → index
POST   /api/v1/{resource}          → store
GET    /api/v1/{resource}/{id}     → show
PUT    /api/v1/{resource}/{id}     → update
DELETE /api/v1/{resource}/{id}     → destroy
```

## Existing API Reference
- SmartTimetable API: `app/Http/Controllers/Api/TimetableApiController.php`
  - Auth: `auth:sanctum`, prefix `/api/v1/timetable`
  - Response format: `{ success: true, data: {...} }` or `{ success: false, message: "..." }`
