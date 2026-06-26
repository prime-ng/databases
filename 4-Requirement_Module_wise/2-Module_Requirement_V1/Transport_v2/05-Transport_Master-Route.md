# Route Master — Requirement Document

## 1. Screen Purpose & Overview

The Route screen manages the travel paths designed for school transportation. It registers the route code, descriptive name, direction classification (Pickup or Drop), and links them to an operational Shift. 

A route acts as the core logical link connecting vehicles, drivers, pickup/drop stops, and student transport allocations. Geospatial routing paths are recorded in spatial format to enable future map visualizations and distance tracking.

---

## 2. Common Business Use Cases

1. **Onboarding a New Bus Route:** The administrator maps out Route R-10 (e.g., "Sector 15 to Main Campus - Pickup") and links it to the Morning Shift.
2. **Reviewing Route Active Status:** Setting route availability, temporarily deactivating routes undergoing road repairs.
3. **Route Direction Segregation:** Ensuring that a Pickup route is strictly mapped for student onboarding in the morning, and a separate Drop route is configured for afternoon dispersal.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_route` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `code` (VARCHAR(50)): Unique shorthand route code identifier (e.g., 'R-10').
* `name` (VARCHAR(200)): Unique descriptive route name (e.g., 'Route 10 - Sector 15').
* `description` (VARCHAR(500)): Detailed route overview notes.
* `pickup_drop` (ENUM): Specifies route service direction: 'Pickup' or 'Drop'. Defaults to 'Pickup'.
* `shift_id` (INT UNSIGNED): FK to `tpt_shift`. Links route to a master operational shift.
* `route_geometry` (LINESTRING SRID 4326): Geospatial coordinate geometry of the route path.
* `is_active` (TINYINT): 0 = Inactive, 1 = Active (Soft delete indicator).
* `created_at` (TIMESTAMP): Creation date-time.
* `updated_at` (TIMESTAMP): Last updated date-time.
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Route Code** | Text Input | Required. Max 50 characters. Must be unique. | `tpt_route.code` |
| **Route Name** | Text Input | Required. Max 200 characters. Must be unique. | `tpt_route.name` |
| **Description** | Text Area | Optional. Max 500 characters. | `tpt_route.description` |
| **Route Type** | Dropdown / Radio | Required. Options: `Pickup`, `Drop`. | `tpt_route.pickup_drop` |
| **Shift Assignment** | Dropdown | Required. Matches list of active shifts (`tpt_shift`). | `tpt_route.shift_id` |
| **Route Geometry** | Map / Text | Optional. Coordinates must form a valid LineString. | `tpt_route.route_geometry` |
| **Active Status** | Toggle / Checkbox| Required. Default is 1 (Active). | `tpt_route.is_active` |

---

## 5. Business Logic & Validation Policies

### Unique Constraints
* The Route Code and Route Name must be globally unique inside the database, guarded by `uq_route_code` and `uq_route_name`.

### Route Direction Locking
* A Route must be dedicated to either a `Pickup` or a `Drop` cycle. It cannot represent both. 
* Students can only allocate to a route if its type matches their usage need (e.g., student pickup stop must be mapped on a Pickup route).

### Calculations & Mathematical Formulas
* **Geospatial Geometry Check**: The system validates that the coordinates provided for `route_geometry` represent a valid open LineString shape under spatial reference SRID 4326:
  $$\text{ST\_IsValid}(\text{route\_geometry}) = 1$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Create a Route (Happy Path)
1. Go to `/transport/route` and click "+ Add Route".
2. Enter Code: `R-10P`, Name: `Route 10 - Sector 15 Pickup`.
3. Select Type: `Pickup`.
4. Select Shift: Select an active morning shift.
5. Click Save. Confirm that the route is created and shown in the grid.

### Test Case 2: Validate Dropdown Relations
1. Go to "+ Add Route".
2. Attempt to save the form leaving "Shift Assignment" empty.
3. Verify that validation error triggers: "The Shift field is required."

### Test Case 3: Duplicate Route Name Blocking
1. Go to "+ Add Route".
2. Enter Code: `R-11P`, Name: `Route 10 - Sector 15 Pickup` (duplicate name from Test Case 1).
3. Select Type: `Pickup`, choose a shift, and click Save.
4. Verify validation error: "Route Name must be unique".

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Route Master Tab**: `@route-master-tab`
* **Add Route Button**: `@add-new-route-btn`
* **Route Code Field**: `input[name="code"]`
* **Route Name Field**: `input[name="name"]`
* **Description Field**: `textarea[name="description"]`
* **Pickup/Drop Dropdown**: `select[name="pickup_drop"]`
* **Shift Dropdown**: `select[name="shift_id"]`
* **Save Button**: `@save-route-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportRouteTest extends DuskTestCase
{
    public function testRouteCreationAndUniqueChecks()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/route')
                    ->click('@route-master-tab')
                    ->click('@add-new-route-btn')
                    ->type('code', 'R-10P')
                    ->type('name', 'Route 10 - Sector 15 Pickup')
                    ->select('pickup_drop', 'Pickup')
                    ->select('shift_id', '1') // Select morning shift
                    ->click('@save-route-btn')
                    ->assertSee('saved successfully')
                    
                    // Attempting duplicate creation
                    ->click('@add-new-route-btn')
                    ->type('code', 'R-11P')
                    ->type('name', 'Route 10 - Sector 15 Pickup') // Duplicate Name
                    ->select('pickup_drop', 'Pickup')
                    ->select('shift_id', '1')
                    ->click('@save-route-btn')
                    ->assertSee('Route Name must be unique');
        });
    }
}
```
