# Template: Authorization Policy

## Location
`app/Policies/` (central policies) or `Modules/{ModuleName}/app/Policies/`

## Generate
```bash
php artisan make:policy EntityPolicy --model=Modules\\ModuleName\\Models\\Entity
```

## Boilerplate

```php
<?php

namespace App\Policies;

use App\Models\User;
use Modules\ModuleName\Models\Entity;
use Illuminate\Auth\Access\HandlesAuthorization;

class EntityPolicy
{
    use HandlesAuthorization;

    /**
     * Admins and Principals can do anything.
     */
    public function before(User $user, string $ability): bool|null
    {
        if ($user->hasRole(['SchoolAdmin', 'Principal'])) {
            return true;
        }
        return null; // fall through to specific methods
    }

    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('view-any entity');
    }

    public function view(User $user, Entity $entity): bool
    {
        return $user->hasPermissionTo('view entity');
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('create entity');
    }

    public function update(User $user, Entity $entity): bool
    {
        return $user->hasPermissionTo('update entity');
    }

    public function delete(User $user, Entity $entity): bool
    {
        return $user->hasPermissionTo('delete entity');
    }

    public function restore(User $user, Entity $entity): bool
    {
        return $user->hasPermissionTo('restore entity');
    }

    public function forceDelete(User $user, Entity $entity): bool
    {
        return $user->hasRole('SchoolAdmin');
    }
}
```

## Register in AuthServiceProvider

```php
// app/Providers/AuthServiceProvider.php
protected $policies = [
    \Modules\ModuleName\Models\Entity::class => \App\Policies\EntityPolicy::class,
];
```

## Notes
- **Naming convention:** `{ModelName}Policy` in `app/Policies/`
- **`before()`:** Use for SuperAdmin / SchoolAdmin bypass — returns `true` to grant, `null` to continue
- **Permissions:** Use Spatie Permission `hasPermissionTo()` — permission names are kebab-case: `'create entity'`
- **Tenant context:** All permission checks are automatically scoped to the tenant DB when tenancy is initialized
- **In controllers:** `$this->authorize('create', Entity::class)` or `$request->user()->can('update', $entity)`
- **In Form Requests:** `$this->user()->can('create', Entity::class)` in `authorize()`
