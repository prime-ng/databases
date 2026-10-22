# Template: Central Feature Test

## Location
`tests/Feature/{Module}/{Feature}Test.php`

## When to Use
- Testing central routes: auth, tenant management, billing, global master CRUD
- Routes in `routes/web.php` (not `routes/tenant.php`)
- No tenant initialization needed

## Boilerplate

```php
<?php

use App\Models\User;
use Modules\GlobalMaster\Models\Board;

// Test: authenticated user can access resource
test('central admin can view boards list', function () {
    $user = User::factory()->create();
    actingAsCentralAdmin($user); // helper from Pest.php

    $response = $this->get(route('global-master.boards.index'));

    $response->assertStatus(200);
});

// Test: create resource (success)
test('central admin can create a board', function () {
    $user = User::factory()->create();
    $this->actingAs($user);

    $response = $this->post(route('global-master.boards.store'), [
        'name'       => 'CBSE',
        'short_name' => 'CBSE',
        'is_active'  => true,
    ]);

    $response->assertRedirect();
    $this->assertDatabaseHas('glb_boards', ['name' => 'CBSE']);
});

// Test: validation failure
test('board creation fails when name is missing', function () {
    $user = User::factory()->create();
    $this->actingAs($user);

    $response = $this->post(route('global-master.boards.store'), [
        'short_name' => 'CBSE',
    ]);

    $response->assertSessionHasErrors(['name']);
    $this->assertDatabaseMissing('glb_boards', ['short_name' => 'CBSE']);
});

// Test: authorization — unauthenticated redirect
test('unauthenticated user is redirected to login', function () {
    $response = $this->get(route('global-master.boards.index'));

    $response->assertRedirect(route('login'));
});

// Test: authorization — forbidden role
test('non-admin user cannot delete a board', function () {
    $user = User::factory()->create(); // no admin role
    $board = Board::factory()->create();
    $this->actingAs($user);

    $response = $this->delete(route('global-master.boards.destroy', $board));

    $response->assertForbidden();
    $this->assertDatabaseHas('glb_boards', ['id' => $board->id]);
});

// Test: API endpoint
test('API returns paginated boards list', function () {
    $user = User::factory()->create();
    $this->actingAs($user, 'sanctum');

    Board::factory()->count(5)->create();

    $response = $this->getJson(route('api.global-master.boards.index'));

    $response->assertStatus(200)
             ->assertJsonStructure([
                 'success',
                 'data' => [['id', 'name', 'short_name', 'is_active']],
                 'meta' => ['current_page', 'total'],
             ]);
});
```

## Notes
- Uses `RefreshDatabase` (configured in `tests/Pest.php`)
- Table names must include prefix: `glb_boards`, `prm_tenants`, etc.
- Test BOTH success path AND validation/auth failures
- Use `->actingAs($user, 'sanctum')` for API token-authenticated endpoints
