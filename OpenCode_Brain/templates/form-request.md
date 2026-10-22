# Template: Form Request (Validation)

## Location
`Modules/{ModuleName}/app/Http/Requests/`

## Store Request

```php
<?php

namespace Modules\ModuleName\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreEntityRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', \Modules\ModuleName\Models\Entity::class);
    }

    public function rules(): array
    {
        return [
            'name'        => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:1000'],
            'class_id'    => ['required', 'integer', 'exists:sch_classes,id'],
            'is_active'   => ['boolean'],
            // For arrays:
            'tags'        => ['nullable', 'array'],
            'tags.*'      => ['integer', 'exists:prefix_tags,id'],
            // For file uploads:
            'document'    => ['nullable', 'file', 'mimes:pdf,doc,docx', 'max:5120'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required'   => 'Entity name is required.',
            'class_id.exists' => 'The selected class does not exist.',
        ];
    }
}
```

## Update Request

```php
<?php

namespace Modules\ModuleName\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateEntityRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('entity'));
    }

    public function rules(): array
    {
        $entityId = $this->route('entity')->id;

        return [
            'name'        => ['required', 'string', 'max:255',
                              Rule::unique('prefix_entities')->ignore($entityId)],
            'description' => ['nullable', 'string', 'max:1000'],
            'is_active'   => ['boolean'],
        ];
    }
}
```

## Notes
- **Naming convention:** `Store{ModelName}Request` / `Update{ModelName}Request`
- **`authorize()`:** Always use a Policy check — never return `true` blindly
- **`exists:` rule:** Use the actual table name with prefix (e.g., `sch_classes`, not `classes`)
- **Unique on update:** Always use `Rule::unique()->ignore($id)` to skip the current record
- **File validation:** Use `mimes:` not `mimetypes:` for user-friendly error messages
- Validated data is accessed via `$request->validated()` in the controller — never use `$request->all()`
