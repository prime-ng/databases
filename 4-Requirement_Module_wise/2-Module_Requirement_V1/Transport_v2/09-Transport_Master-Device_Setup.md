# Device Setup — Requirement Document

## 1. Screen Purpose & Overview

The Device Setup screen registers and manages companion mobile/tablet devices used by drivers and helpers. Rather than mapping devices directly to vehicles, the system links hardware UUIDs to specific personnel (`tpt_personnel`), ensuring that only authenticated staff members can transmit boarding scans, GPS coordinates, and arrival times.

---

## 2. Common Business Use Cases

1. **Registering a Driver's Smartphone:** The administrator registers the smartphone of a newly onboarded driver, logging the hardware UUID to allow app logins.
2. **Revoking Access on Lost Device:** If a tablet is lost, the administrator deactivates the device record, immediately blocking it from transmitting logs.
3. **App Version Auditing:** Checking the last-seen status and app version of active crew devices.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_attendance_device` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `user_id` (INT UNSIGNED): FK to `tpt_personnel`. Maps the device to a specific crew member.
* `device_uuid` (CHAR(36)): Unique hardware UUID identifier code.
* `device_type` (ENUM): Hardware classification: 'Mobile', 'Tablet', 'Laptop', 'Desktop'.
* `location` (VARCHAR(150)): Last reported location coordinates or neighborhood.
* `device_os` (INT): FK to `sys_dropdown_table` (representing 'android', 'ios', 'windows', 'linux', 'mac').
* `os_version` (VARCHAR(50)): Version status of the device operating system.
* `device_name` (VARCHAR(100)): Label name of the device.
* `device_model` (VARCHAR(100)): Hardware model string (e.g., 'iPhone 12 Pro').
* `pg_app_version` (VARCHAR(20)): Current app version installed on the device (e.g., '1.0.0').
* `pg_fcm_token` (TEXT): Firebase Cloud Messaging token for push notifications.
* `pg_first_registered_at` (TIMESTAMP): Time of first registration.
* `pg_last_seen_at` (TIMESTAMP): Last ping timestamp.
* `is_active` (TINYINT): 0 = Inactive/Suspended, 1 = Active.
* `created_at` (TIMESTAMP): Creation date-time.
* `updated_at` (TIMESTAMP): Update date-time.
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Crew Member** | Dropdown | Required. Matches list of active personnel (`tpt_personnel`). | `tpt_attendance_device.user_id` |
| **Device UUID** | Text Input | Required. Unique 36-character hardware code. | `tpt_attendance_device.device_uuid` |
| **Device Name** | Text Input | Required. Max 100 characters. | `tpt_attendance_device.device_name` |
| **Device Type** | Dropdown | Required. Options: `Mobile`, `Tablet`, `Laptop`. | `tpt_attendance_device.device_type` |
| **Device OS** | Dropdown | Required. Options: `Android`, `iOS`, `Windows`. | `tpt_attendance_device.device_os` |
| **OS Version** | Text Input | Optional. Max 50 characters. | `tpt_attendance_device.os_version` |
| **Device Model** | Text Input | Optional. Max 100 characters. | `tpt_attendance_device.device_model` |
| **App Version** | Text Input | Optional. Max 20 characters. | `tpt_attendance_device.pg_app_version` |
| **Active Status** | Toggle / Checkbox| Required. Default is 1 (Active). | `tpt_attendance_device.is_active` |

---

## 5. Business Logic & Validation Policies

### Unique Constraints
* The Device UUID must be globally unique inside the database (`uq_device`).
* A crew member can only have one active device mapped to them at any time, guarded by composite unique key `uq_user_device`.

### Security Token Invalidation
* API requests sent from the companion application check that:
  $$\text{tpt\_attendance\_device.is\_active} = 1$$
  * If `is_active = 0`, the endpoint returns a `403 Forbidden` response and invalidates the session token.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Register Device (Happy Path)
1. Go to `/transport/attendance-device` and click "+ Register Device".
2. Select Crew Member: `John Driver`.
3. Enter UUID: `f81d4fae-7dec-11d0-a765-00a0c91e6bf6`.
4. Enter Name: `John's Samsung S21`, Type: `Mobile`, OS: `Android`.
5. Click Save. Confirm device is registered successfully.

### Test Case 2: Duplicate UUID Block
1. Click "+ Register Device".
2. Select Crew Member: `Dave Helper`.
3. Enter the same UUID as Test Case 1 (`f81d4fae-7dec-11d0-a765-00a0c91e6bf6`).
4. Click Save.
5. Verify validation error: "Device UUID has already been registered."

### Test Case 3: Deactivation / Suspended Verification
1. Locate the device registered in Test Case 1.
2. Edit the record, toggle "Active Status" to **No**, and save.
3. Attempt to authenticate an API request from the companion application using this device's UUID.
4. Verify the server returns a `403 Forbidden` status with error payload "Device suspended".

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Device Tab**: `@device-setup-tab`
* **Register Device Button**: `@register-device-btn`
* **Crew Dropdown**: `select[name="user_id"]`
* **UUID Field**: `input[name="device_uuid"]`
* **Device Name Field**: `input[name="device_name"]`
* **Device Type Dropdown**: `select[name="device_type"]`
* **OS Dropdown**: `select[name="device_os"]`
* **Save Button**: `@save-device-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportDeviceSetupTest extends DuskTestCase
{
    public function testDeviceRegistrationAndDuplicationValidations()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/attendance-device')
                    ->click('@device-setup-tab')
                    ->click('@register-device-btn')
                    ->select('user_id', '1')
                    ->type('device_uuid', 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6')
                    ->type('device_name', 'Samsung Tablet Bus 1')
                    ->select('device_type', 'Tablet')
                    ->select('device_os', '1') // Android
                    ->click('@save-device-btn')
                    ->assertSee('saved successfully')
                    
                    // Attempting duplicate UUID
                    ->click('@register-device-btn')
                    ->select('user_id', '2')
                    ->type('device_uuid', 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6') // Duplicate
                    ->type('device_name', 'Helper Phone')
                    ->select('device_type', 'Mobile')
                    ->select('device_os', '1')
                    ->click('@save-device-btn')
                    ->assertSee('Device UUID has already been registered');
        });
    }
}
```
