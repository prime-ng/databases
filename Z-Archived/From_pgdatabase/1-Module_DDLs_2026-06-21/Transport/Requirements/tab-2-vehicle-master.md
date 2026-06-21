# Transport Tab 2: Vehicle Master

This screen manages the complete vehicle registry for the institution's fleet. Every bus, van, or car used for student transport is registered here with its legal documents, ownership details, and operational status.

---

## How It Works

The administrator sees a searchable, filterable table listing all registered vehicles. Each row shows the registration number, vehicle number (VIN/chassis), model, manufacturer, vehicle type, fuel type, seating capacity, ownership type, vendor name, and availability status. The administrator can add a new vehicle using the Add Vehicle button, which opens a form with all required fields.

For each vehicle, the administrator can upload scanned copies of the registration certificate, fitness certificate, insurance certificate, pollution certificate, vehicle emission certificate, fire extinguisher certificate, and GPS device certificate. Each document has a separate upload tracking flag so the administrator knows what is still missing.

The form also tracks key validity dates: fitness, insurance, pollution, and fire extinguisher. The system will alert the dashboard when any of these are within 30 days of expiry.

---

## Important Business Rules

- Registration number and vehicle number together must be unique across all vehicles — no duplicate pair is allowed.
- Vehicle type is selected from a system dropdown (values: BUS, VAN, CAR).
- Fuel type is selected from a system dropdown (values: Diesel, Petrol, CNG, Electric).
- Ownership type is selected from a system dropdown (values: Owned, Leased, Rented).
- Vehicle emission class is selected from a system dropdown (values: BS IV, BS V, BS VI).
- Each vehicle must be linked to a vendor (supplier/owner) from the vendor master.
- A vehicle cannot be deleted if it has active trips or route assignments. The `is_active` flag should be set to 0 instead.
- Each document upload flag is a simple 0/1 toggle. When the media is uploaded, the flag is automatically set to 1.
- The capacity field represents seating capacity; max_capacity includes standing passengers where permitted.
- The GPS device ID is a free-text field for the installed GPS tracker identifier.

---

## Database Columns & Behavior

### tpt_vehicle
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `vehicle_no` — VARCHAR(20), NOT NULL. Vehicle/chassis number (VIN). Part of unique key with registration_no.
- `registration_no` — VARCHAR(30), NOT NULL. Government registration number. Part of unique key with vehicle_no.
- `model` — VARCHAR(50), nullable. Vehicle model name/number.
- `manufacturer` — VARCHAR(50), nullable. Vehicle manufacturer name.
- `vehicle_type_id` — INT UNSIGNED, NOT NULL. FK to sys_dropdown_table. Values: BUS, VAN, CAR.
- `fuel_type_id` — INT UNSIGNED, NOT NULL. FK to sys_dropdown_table. Values: Diesel, Petrol, CNG, Electric.
- `capacity` — INT UNSIGNED, NOT NULL, default 40. Seating capacity.
- `max_capacity` — INT UNSIGNED, NOT NULL, default 40. Maximum capacity including standing.
- `ownership_type_id` — INT UNSIGNED, NOT NULL. FK to sys_dropdown_table. Values: Owned, Leased, Rented.
- `vendor_id` — INT UNSIGNED, NOT NULL. FK to vnd_vendors. The vehicle supplier/owner.
- `fitness_valid_upto` — DATE, NOT NULL. Fitness certificate expiry.
- `insurance_valid_upto` — DATE, NOT NULL. Insurance policy expiry.
- `pollution_valid_upto` — DATE, NOT NULL. Pollution certificate expiry.
- `vehicle_emission_class_id` — INT UNSIGNED, NOT NULL. FK to sys_dropdown_table. Values: BS IV, BS V, BS VI.
- `fire_extinguisher_valid_upto` — DATE, NOT NULL. Fire extinguisher certificate expiry.
- `gps_device_id` — VARCHAR(50), nullable. Installed GPS device identifier.
- `vehicle_photo_upload` — TINYINT(1) UNSIGNED, default 0. 0 = Not Uploaded, 1 = Uploaded.
- `registration_cert_upload` — TINYINT(1) UNSIGNED, default 0. 0 = Not Uploaded, 1 = Uploaded.
- `fitness_cert_upload` — TINYINT(1) UNSIGNED, default 0. 0 = Not Uploaded, 1 = Uploaded.
- `insurance_cert_upload` — TINYINT(1) UNSIGNED, default 0. 0 = Not Uploaded, 1 = Uploaded.
- `pollution_cert_upload` — TINYINT(1) UNSIGNED, default 0. 0 = Not Uploaded, 1 = Uploaded.
- `vehicle_emission_cert_upload` — TINYINT(1) UNSIGNED, default 0. 0 = Not Uploaded, 1 = Uploaded.
- `fire_extinguisher_cert_upload` — TINYINT(1) UNSIGNED, default 0. 0 = Not Uploaded, 1 = Uploaded.
- `gps_device_cert_upload` — TINYINT(1) UNSIGNED, default 0. 0 = Not Uploaded, 1 = Uploaded.
- `availability_status` — TINYINT(1) UNSIGNED, default 1. 0 = Not Available, 1 = Available.
- `is_active` — TINYINT(1) UNSIGNED, default 1. Soft-delete flag.
- `created_at` — TIMESTAMP. Auto-set on creation.
- `updated_at` — TIMESTAMP. Auto-updated on modification.
- `deleted_at` — TIMESTAMP, nullable. Soft-delete timestamp.

---

## Deep Analysis

### Business Workflows & State Machines

- **CRUD Flow:** Add Vehicle (form + document uploads) → Validate uniqueness → INSERT → Set upload flags to 0 initially → Upload triggers set flags to 1.
- **Edit Flow:** Load existing record → Pre-fill form → UPDATE on save.
- **Soft-Delete Flow:** SET `is_active = 0` instead of DELETE. System must check no active trips or route assignments reference this vehicle before allowing deactivation.
- **Certificate Expiry Monitoring:** Application-level background job or trigger alerts when `fitness_valid_upto`, `insurance_valid_upto`, `pollution_valid_upto`, or `fire_extinguisher_valid_upto` are within 30 days of `CURDATE()`.

### Validation Rules & Edge Cases

- **Unique constraint:** `(registration_no, vehicle_no)` must be unique; enforce both on input and before soft-delete restore.
- **Capacity logic:** `capacity` (seating) must be ≤ `max_capacity` (seating + standing).
- **Date integrity:** All 4 certificate expiry dates must be in the future at time of registration; warn if any are already expired.
- **Default values:** `capacity = 40`, `max_capacity = 40`, `availability_status = 1`, `is_active = 1`.
- **Vendor FK:** `vendor_id` must reference an existing active vendor in `vnd_vendors`.
- **Upload flag toggle:** When a document is uploaded via sys.media, the corresponding upload flag must be atomically set to 1; if upload fails, the flag stays 0.
- **GPS Device ID:** Free-text but should be unique if provided (no duplicate GPS trackers).

### Integration Points

- **tpt_personnel** — `assigned_vehicle_id` references this table.
- **tpt_driver_route_vehicle_jnt** — `vehicle_id` FK; active trips prevent deletion.
- **tpt_route_scheduler_jnt** — `vehicle_id` FK.
- **tpt_trip** — `vehicle_id` FK.
- **tpt_daily_vehicle_inspection** — `vehicle_id` FK.
- **tpt_vehicle_fuel** — `vehicle_id` FK.
- **vnd_vendors** — `vendor_id` FK for vehicle supplier/owner.
- **sys_dropdown_table** — vehicle_type, fuel_type, ownership_type, vehicle_emission_class.
- **sys.media** — document upload storage.

### Permissions Matrix

| Role | View | Create | Edit | Soft-Delete |
|---|---|---|---|---|
| Super Admin | All schools | Yes | Yes | Yes |
| School Admin | Own school | Yes | Yes | Yes |
| Transport Manager | Own school | Yes | Yes | No |
| Driver / Helper | No access | No | No | No |
