# Template: API Response Format

## Standard JSON Response Structure

### Success — Single Resource
```json
{
    "success": true,
    "data": {
        "id": 1,
        "name": "Example",
        "created_at": "2026-03-11T10:30:00.000000Z"
    },
    "message": "Resource retrieved successfully"
}
```

### Success — Collection (Paginated)
```json
{
    "success": true,
    "data": [
        { "id": 1, "name": "Item 1" },
        { "id": 2, "name": "Item 2" }
    ],
    "meta": {
        "current_page": 1,
        "last_page": 5,
        "per_page": 15,
        "total": 72
    }
}
```

### Success — Created
```json
{
    "success": true,
    "data": { "id": 3, "name": "New Item" },
    "message": "Resource created successfully"
}
```
HTTP Status: `201`

### Error — Validation
```json
{
    "success": false,
    "message": "The given data was invalid.",
    "errors": {
        "name": ["The name field is required."],
        "email": ["The email must be a valid email address."]
    }
}
```
HTTP Status: `422`

### Error — Not Found
```json
{
    "success": false,
    "message": "Resource not found"
}
```
HTTP Status: `404`

### Error — Unauthorized
```json
{
    "success": false,
    "message": "Unauthenticated"
}
```
HTTP Status: `401`

### Error — Forbidden
```json
{
    "success": false,
    "message": "You do not have permission to perform this action"
}
```
HTTP Status: `403`

### Error — Server Error
```json
{
    "success": false,
    "message": "An error occurred while processing your request"
}
```
HTTP Status: `500`

## Laravel Implementation

### Using API Resource
```php
// app/Http/Resources/StudentResource.php
class StudentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'class' => new ClassResource($this->whenLoaded('class')),
            'section' => new SectionResource($this->whenLoaded('section')),
            'is_active' => $this->is_active,
            'created_at' => $this->created_at->toISOString(),
        ];
    }
}
```

### Controller Response Helpers
```php
// Success
return response()->json([
    'success' => true,
    'data' => new StudentResource($student),
    'message' => 'Student retrieved successfully',
]);

// Paginated
$students = Student::with('class')->paginate(15);
return response()->json([
    'success' => true,
    'data' => StudentResource::collection($students),
    'meta' => [
        'current_page' => $students->currentPage(),
        'last_page' => $students->lastPage(),
        'per_page' => $students->perPage(),
        'total' => $students->total(),
    ],
]);

// Error
return response()->json([
    'success' => false,
    'message' => 'Operation failed',
], 422);
```

## Existing API Reference
The SmartTimetable API controller (`TimetableApiController.php`) uses this format:
```php
return response()->json(['success' => true, 'data' => $result]);
return response()->json(['success' => false, 'message' => $error], 422);
```

## Tenant Context Note
All API responses from tenant routes automatically return tenant-scoped data. The tenancy middleware ensures DB isolation. Never include `tenant_id` in API responses — it's implicit from the domain.
