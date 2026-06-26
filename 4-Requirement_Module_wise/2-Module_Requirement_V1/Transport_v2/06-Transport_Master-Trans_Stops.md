# Trans. Stops — Requirement Document

## 1. Screen Purpose & Overview

The Trans. Stops screen manages the master register of static physical pickup and drop-off stops. Each stop is registered with its code, name, shift linkage, GPS coordinates (latitude/longitude) stored in spatial POINT format, distance metrics, and stop type classifications. 

This ensures precise location tracking for companion mobile devices and student safety during trip execution.

---

## 2. Common Business Use Cases

1. **Onboarding a New Stop:** The manager adds a new pickup point at a local residential gate, linking it to the Morning Shift.
2. **Reviewing GPS Mapping:** Checking stop coordinate mappings to feed into navigation apps.
3. **Updating Stop Locations:** Editing a stop landmark due to road construction adjustments.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_pickup_points` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `shift_id` (INT UNSIGNED): FK to `tpt_shift`. Connects the stop to a primary shift context.
* `code` (VARCHAR(50)): Unique shorthand stop code (e.g., 'S-22').
* `name` (VARCHAR(200)): Unique descriptive stop name (e.g., 'Sector 22 Market').
* `latitude` (DECIMAL(10,7)): GPS Latitude coordinate.
* `longitude` (DECIMAL(10,7)): GPS Longitude coordinate.
* `location` (POINT SRID 4326): Spatial representation of the latitude and longitude.
* `total_distance` (DECIMAL(7,2)): Distance from school terminal in kilometers.
* `estimated_time` (INT): Estimated travel duration from start terminal in minutes.
* `stop_type` (ENUM): Specifies stop purpose: 'Pickup', 'Drop', or 'Both'. Defaults to 'Both'.
* `is_active` (TINYINT): 0 = Inactive, 1 = Active (Soft delete indicator).
* `created_at` (TIMESTAMP): Creation timestamp.
* `updated_at` (TIMESTAMP): Last update timestamp.
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Shift Association** | Dropdown | Required. Matches active shifts (`tpt_shift`). | `tpt_pickup_points.shift_id` |
| **Stop Code** | Text Input | Required. Max 50 characters. Must be unique. | `tpt_pickup_points.code` |
| **Stop Name** | Text Input | Required. Max 200 characters. Must be unique. | `tpt_pickup_points.name` |
| **Latitude** | Number Input | Required. Decimal between $-90.00$ and $90.00$. | `tpt_pickup_points.latitude` |
| **Longitude** | Number Input | Required. Decimal between $-180.00$ and $180.00$. | `tpt_pickup_points.longitude` |
| **Total Distance (KM)** | Number Input | Optional. Decimal $\ge 0$. | `tpt_pickup_points.total_distance` |
| **Est. Travel Time (Mins)**| Number Input | Optional. Positive integer. | `tpt_pickup_points.estimated_time` |
| **Stop Type** | Dropdown | Required. Options: `Pickup`, `Drop`, `Both`. | `tpt_pickup_points.stop_type` |
| **Active Status** | Toggle / Checkbox| Required. Default is 1 (Active). | `tpt_pickup_points.is_active` |

---

## 5. Business Logic & Validation Policies

### Unique Constraints
* Stop Code and Stop Name must be globally unique to ensure clarity in routing schedules (`uq_pickup_code`, `uq_pickup_name`).

### Spatial Point Geometry Conversion
* Upon saving, the input latitude and longitude are converted to a spatial POINT geometry object with coordinate system SRID 4326:
  $$\text{location} = \text{ST\_PointFromText}(\text{"POINT(longitude latitude)"}, 4326)$$

### Deactivation Rules
* A stop cannot be deactivated if it is linked to any active route in the stops-to-route mapping table (`tpt_pickup_points_route_jnt`).

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Create Stop (Happy Path)
1. Go to `/transport/pickup-point` and click "+ Add Stop".
2. Select Shift: Morning Shift.
3. Enter Code: `S22M`, Name: `Sector 22 Market Stop`.
4. Enter Latitude: `28.5355160`, Longitude: `77.3910290`.
5. Set Stop Type: `Both`.
6. Click Save. Confirm stop is registered successfully.

### Test Case 2: Out of Bounds Latitude Check
1. Click "+ Add Stop".
2. Fill standard fields. Enter Latitude: `95.0000000` (invalid latitude).
3. Click Save.
4. Verify validation error: "Latitude must be between -90 and 90."

### Test Case 3: Dependency Check on Deactivate
1. Locate a stop that is actively assigned to Route 10.
2. Edit the stop, toggle "Active Status" to **No**, and click Save.
3. Verify that the update fails with an error: "Cannot deactivate stop. It is assigned to active routes."

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Stops Tab**: `@stops-master-tab`
* **Add Stop Button**: `@add-new-stop-btn`
* **Shift Dropdown**: `select[name="shift_id"]`
* **Stop Code Field**: `input[name="code"]`
* **Stop Name Field**: `input[name="name"]`
* **Latitude Field**: `input[name="latitude"]`
* **Longitude Field**: `input[name="longitude"]`
* **Stop Type Dropdown**: `select[name="stop_type"]`
* **Save Button**: `@save-stop-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportStopsTest extends DuskTestCase
{
    public function testStopCreationAndCoordinateValidations()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/pickup-point')
                    ->click('@stops-master-tab')
                    ->click('@add-new-stop-btn')
                    ->select('shift_id', '1')
                    ->type('code', 'S22M')
                    ->type('name', 'Sector 22 Market Stop')
                    ->type('latitude', '95.123') // Invalid
                    ->type('longitude', '77.391')
                    ->select('stop_type', 'Both')
                    ->click('@save-stop-btn')
                    ->assertSee('Latitude must be between -90 and 90')
                    
                    // Correcting values
                    ->type('latitude', '28.535')
                    ->click('@save-stop-btn')
                    ->assertSee('saved successfully');
        });
    }
}
```
