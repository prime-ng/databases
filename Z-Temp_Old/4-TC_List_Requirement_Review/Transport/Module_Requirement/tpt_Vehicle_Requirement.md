# Vehicle Master — Business Requirements

## What This Screen Does

The Vehicle Master screen is the digital garage of the school's entire fleet. It allows the Transport Manager to register every bus, van, or car the school owns or leases, track 8 types of statutory compliance documents (fitness, insurance, pollution, fire extinguisher, etc.) with expiry dates, upload scanned copies of each document, link hired vehicles to vendor records, and control vehicle availability for trip assignment.

Without this screen, the Transport Manager would need to maintain separate physical files and spreadsheets for each vehicle's registration details, insurance certificates, fitness expiry dates, and maintenance records — a chaotic and error-prone process that risks lapsing critical compliance documents and leaving the school exposed to legal penalties.

The screen appears in two contexts:
1. **As a tab in Transport Master** — Shows a paginated list of all vehicles with search, status filter, and inline actions (view, edit, delete, toggle status).
2. **As a standalone CRUD** — The full `VehicleController` resource handles create, edit, show, trash, restore, and force-delete via dedicated Blade views.

---

## Default Data Load

When the Transport Manager opens Transport Master and clicks the Vehicle tab, the system immediately fetches the most recently added vehicles and displays them in a list — 10 vehicles per page. The search box at the top lets the manager type a vehicle number, registration number, model, or manufacturer name to narrow down the list. A status filter dropdown lets them switch between viewing Active vehicles, Inactive vehicles, or All vehicles. The tab loads quietly in the background without refreshing the entire page.

If the Transport Manager accesses the Vehicle Master through the dedicated menu item (instead of the Transport Master hub), the same list appears with the same search and filtering options, but the page layout is different — it uses a full-page standalone view instead of a compact tabbed interface.

---

## When This Screen Is Used

- **Adding a New Vehicle to the Fleet** — The school has just taken delivery of a new bus from Tata Motors. Before the bus can be put into service, the Transport Manager must register it in the system with its chassis number (VIN), government registration plate, seating capacity, vehicle type, fuel type, and ownership details. Without this registration, the bus does not exist in the system — it cannot be assigned to routes, cannot be listed on the dashboard, and cannot appear in maintenance reports. All four statutory compliance documents (fitness certificate, insurance, pollution certificate, fire extinguisher certificate) must be entered at this stage, with their expiry dates and scanned copies uploaded.

- **Renewing a Compliance Document Before It Expires** — It is January 10th and the insurance for Bus KL-05 expires on January 25th. The Transport Manager opens the vehicle record, uploads the renewed insurance certificate PDF, and updates the `insurance_valid_upto` date to the new policy expiry. The system discards the old scanned copy and replaces it with the new one. The Dashboard's maintenance alerts section now shows that Bus KL-05's insurance is valid again. This routine renewal process happens multiple times every month across a fleet of 20+ vehicles.

- **Retiring an Old Vehicle** — The school is replacing a 15-year-old bus that has reached the end of its service life. The Transport Manager finds the vehicle in the list and clicks Delete. The system immediately hides the vehicle from all active lists and dropdowns (so it cannot be assigned to new trips), but keeps the record in the Trash for future reference. All historical trip data, fuel logs, and inspection records linked to this bus remain intact — only the vehicle itself is retired. If needed, the manager can restore the vehicle later, though it will remain inactive until manually toggled back on.

- **Checking Fleet Availability Before Trip Planning** — Every morning, before generating the day's trips, the Transport Manager glances at the vehicle list to see which buses are marked as Available versus Not Available. A vehicle might be unavailable because it is in the workshop for engine repair, because its insurance has expired and the manager has not yet renewed it, or because it was manually taken out of service for the summer break. The availability status is a manual switch — the system does not automatically mark vehicles as unavailable when documents expire, so the manager must check this manually.

---

## Key Fields at a Glance

**Vehicle Identity**
Every vehicle in the fleet needs two critical identity numbers. The Vehicle Identification Number, known as `vehicle_no`, is the manufacturer's unique chassis fingerprint that stays with the vehicle for life. The Registration Number, called `registration_no`, is the official government number plate assigned by the Regional Transport Office — something like "KA-01-AB-1234". Together, they form a composite unique pair, meaning no two vehicles in the school can ever share the same VIN and registration combination. Additional details like the vehicle's `model` (e.g., "Tata Starbus") and `manufacturer` (e.g., "Tata Motors") are also captured to help identify and classify the fleet for maintenance and reporting.

**Vehicle Classification**
The Transport Manager classifies each vehicle by four key dimensions: the body type (Bus, Van, or Car), the fuel it runs on (Diesel, Petrol, CNG, or Electric), how the school holds it (Outright Owned, Leased from a financing company, or Rented from a third-party vendor), and its Bharat Stage emission standard (BS IV, BS V, or BS VI). These classifications drive everything from fuel cost reporting and environmental compliance audits to vendor billing for hired vehicles. All four values come from the system's global dropdown configuration, so the school can customise the available options to match their fleet.

**Seating Capacity**
Every vehicle records both a standard seating capacity and a maximum allowed capacity. For example, a bus labelled for 50 passengers but legally approved to carry up to 55 would have `capacity = 50` and `max_capacity = 55`. The system strictly enforces that the maximum must always be at least as high as the standard capacity — preventing data entry errors like claiming a 50-seater can only hold 40.

**Vendor Link for Hired Vehicles**
If a vehicle is leased or rented rather than owned, it must be linked to a vendor record in the Vendor module. This `vendor_id` connection ensures that rental contracts, billing, and vendor communications are all centrally tracked. Vehicles that are outright owned also require a vendor selection — typically the dealership from which the vehicle was purchased.

**Compliance Document Expiry Tracking**
Four statutory compliance documents are tracked with their expiry dates: the Fitness Certificate (`fitness_valid_upto`) proving the vehicle is roadworthy, the Insurance Policy (`insurance_valid_upto`) covering third-party liability, the Pollution Under Control Certificate (`pollution_valid_upto`), and the Fire Extinguisher Certificate (`fire_extinguisher_valid_upto`). All four are mandatory fields — the system will not allow a vehicle to be registered without them. The Transport Master dashboard uses these dates to generate maintenance alerts when documents are due to expire, helping the manager avoid legal non-compliance.

**GPS Tracking**
An optional GPS device serial number (`gps_device_id`) can be recorded for real-time vehicle tracking integration. This is a simple text field that stores the device's unique identifier, which can be used by the tracking system to pull location data.

**Operational Status Flags**
Two separate on-off switches control how a vehicle behaves in the system. The `availability_status` flag (Available or Not Available) is the primary gate for trip assignment — a vehicle marked unavailable cannot be assigned to a new trip. The `is_active` flag controls whether the vehicle record is considered active or has been soft-deleted. These two flags operate independently, allowing scenarios like a temporarily unavailable-but-active vehicle (e.g., in for repairs) versus a retired vehicle that has been deactivated permanently.

**Compliance Document Uploads**
For each of the four statutory documents, plus the vehicle photo, registration certificate, emission certificate, and GPS device certificate, the system provides individual upload slots using the Spatie MediaLibrary. Each slot is single-file only — exactly one scanned copy per document type. The vehicle photo has automatic thumbnail generation (150×150 and 300×300). However, the underlying database defines 8 separate boolean flags for tracking upload status per document type, while the code model only exposes a single combined flag — a known mismatch that means the system cannot report precisely which documents have been uploaded through the model alone.

---

## Business Rules and Conditions

**Fleet Identity Uniqueness (BR-TPT-015)**
No two vehicles in the school can share the same VIN or the same registration number. This sounds obvious, but when a school operates 50+ buses across multiple campuses with vehicles purchased years apart, duplicate entries are a real risk — especially when vehicles are returned from lease and re-registered. The system enforces this at two levels: a database-level composite unique constraint on the pair `(registration_no, vehicle_no)`, and a validation rule in `VehicleRequest` that catches duplicates before the database is ever hit.

**Capacity Sanity Check**
The `max_capacity` must always be equal to or greater than the `capacity`. This prevents absurd entries like a minibus with seating for 40 but a maximum of 25. If violated, the form request returns a clear validation error and refuses to save.

**Compliance Document Expiry Auto-Blocking — NOT IMPLEMENTED (BR-TPT-002)**
In an ideal world, a vehicle whose fitness certificate or insurance has expired should automatically become unavailable for trip assignment — the system should check the current date against all four `*_valid_upto` fields every time a trip is created or modified. Currently, this auto-blocking logic does **not exist**. No cron job, no model observer, no validation rule checks whether documents have expired. The `availability_status` is a manual switch that the Transport Manager must remember to flip. This is a significant compliance gap, because a vehicle with lapsed insurance is legally not allowed to carry students on public roads, yet the system would happily assign it to a morning route if the manager forgot to deactivate it.

**Document Upload — DDL vs Model Mismatch**
The database table `tpt_vehicle` was designed with 8 separate boolean columns — one per document type — to track exactly which documents have been uploaded (e.g., `fitness_cert_upload`, `insurance_cert_upload`, `pollution_cert_upload`, etc.). However, the Eloquent model's `$fillable` array only contains a single field called `documents_uploaded`. This means the application code can only ever set a generic "yes, some documents exist" flag, and the individual upload status columns in the database are never updated by the create or update flows. The only reliable way to check whether a specific document exists is to query the Spatie MediaLibrary collections directly. This mismatch means the system cannot answer the question "Which vehicles are missing their pollution certificate upload?" through the standard model and form request flow.

**Document Media Storage**
Eight Spatie MediaLibrary collections handle the actual file storage: `registration_img`, `pollution_img`, `fitness_img`, `insurance_img`, `vehicle_emission_cert_img`, `fire_extinguisher_cert_img`, `gps_device_cert_img`, and `vehicle_photo`. Each collection stores exactly one file — when the manager uploads a replacement, the old file is automatically deleted before the new one is stored. Only the `vehicle_photo` collection generates image thumbnails (small 150×150 and medium 300×300 versions), which are used for display in vehicle lists and detail views.

**Soft Delete Behaviour**
When the Transport Manager deletes a vehicle, the system does two things: it sets `is_active = false` to immediately hide the vehicle from active lists and dropdowns, then it calls the Eloquent soft delete to set `deleted_at`. However, restoring a vehicle only clears the `deleted_at` timestamp — the `is_active` flag remains `false`. This means a restored vehicle does not automatically reappear in active lists; the manager must also toggle the status switch back to active. This is by design but can confuse users who expect restoration to fully reinstate the record.

---

## Workflow Steps

**Registering a New Vehicle**
The Transport Manager clicks the Add Vehicle button. The create form loads with dropdowns for vehicle type, fuel type, ownership type, emission class, and vendor (filtered to vendor type matching the transport vendor type dropdown key). The manager fills in all fields, uploads document images (optional), and clicks Save. The system validates via `VehicleRequest`, creates the record, uploads media files, logs the activity, and redirects back to the Transport Master tab with a success message.

**Editing a Vehicle**
The manager clicks Edit on a vehicle row. The edit form loads pre-populated with existing data. The manager can change any field and replace any document (the old file is deleted from the media collection before the new one is added). On save, the system logs which fields changed.

**Soft-Deleting a Vehicle**
The manager clicks Delete. The system sets `is_active = false`, calls `delete()`, logs the activity, and redirects with a "trashed" message. The vehicle disappears from the active list but remains in the trash.

**Restoring a Vehicle**
The manager navigates to the Trash view, clicks Restore. The system calls `restore()` which sets `deleted_at = NULL`. The vehicle reappears in the active list (but `is_active` remains false — it needs to be manually toggled back on).

**Toggle Active Status**
The manager clicks the status toggle switch. An AJAX POST request updates `is_active` to the opposite value and logs the action. Returns JSON with the new status and a success message.

---

## Example Scenario

Green Valley School operates a fleet of 12 buses, 2 vans, and 1 staff car. In April, the school purchases a brand-new 50-seater diesel bus from Tata Motors to serve a new residential colony that has come up near Whitefield. The bus has been delivered with its temporary registration plates, and the official RTO registration is expected in two weeks.

The Transport Manager, Mrs. Desai, opens the Vehicle Master to register this bus. She clicks Add Vehicle and enters the chassis number (a 17-character alphanumeric VIN stamped on the bus chassis), notes the temporary registration number assigned by the dealer, selects "Bus" as the vehicle type, "Diesel" as the fuel type, and "Outright Owned" as the ownership type since the school paid cash.

For seating, she enters 50 as the standard capacity and 55 as the maximum capacity (the bus has 50 seats plus 5 foldable jump seats that are legally permitted). She then enters the compliance document expiry dates: the fitness certificate is valid until June 2027 (3 years from manufacture), the insurance policy runs until January 15th of next year (a standard one-year comprehensive policy), the pollution certificate is valid for one year, and the fire extinguisher certificate is also valid for one year.

She uploads scanned copies of the insurance policy PDF and the temporary fitness certificate. The dealer has promised to send the final RTO registration certificate once the registration is complete, which she will upload later.

She clicks Save. The bus appears in the vehicle list with a green "Active" badge and a green "Available" badge, meaning it is ready to be assigned to routes. The dashboard's vehicle count has now increased from 15 to 16. Mrs. Desai notes in her calendar to return to this record in two weeks to upload the final registration certificate and update the registration number once the RTO formalities are complete.

---

## Related Screens

- **Dashboard** — The main operational screen that shows how many vehicles are active today, how many are currently on the road, and which vehicles have compliance documents expiring soon. The vehicle data entered here feeds directly into those dashboard widgets.

- **Driver-Route-Vehicle Assignment** — The screen where the Transport Manager decides which driver and which bus will handle which route each day. Only vehicles marked as "Available" in the Vehicle Master appear in the assignment dropdown.

- **Vehicle Fuel Log** — A separate screen where fuel purchases are recorded for each vehicle. Each fuel entry is linked to a specific vehicle registered here.

- **Vehicle Inspection** — The pre-trip inspection checklist that drivers must complete before starting their route. Each inspection record belongs to a specific vehicle.

- **Vehicle Service Request & Maintenance** — Where the Transport Manager or workshop supervisor logs service requests and maintenance work done on each vehicle.

---

## Requirements

- Controller: `VehicleController` with full resource methods: `index`, `show`, `create`, `store`, `edit`, `update`, `destroy`, plus `trashed`, `restore`, `forceDelete`, `toggleStatus`
- Hub tab data: `TransportMasterController@vehiclesAjax()` + `vehiclesQuery()`
- Route: `Route::resource('vehicle', VehicleController::class)` + 4 additional routes (`trashed`, `restore`, `forceDelete`, `toggleStatus`)
- Permission gates: `tenant.vehicle.viewAny`, `tenant.vehicle.view`, `tenant.vehicle.create`, `tenant.vehicle.update`, `tenant.vehicle.delete`, `tenant.vehicle.restore`, `tenant.vehicle.forceDelete`
- Form request: `VehicleRequest` — validates all fields, enforces unique constraints, capacity rules
- Policy: `VehiclePolicy` (tenant.vehicle.*)
- Activity logging: ✅ Present on `store` (Stored), `update` (Updated with field-level changes), `destroy` (Trashed), `restore` (Restored), `forceDelete` (Deleted), `toggleStatus` (Toggled)

---

## Who Can Access

- **Transport Manager** — Has full control over the fleet. They can add new vehicles, edit existing records, upload and replace compliance documents, soft-delete retired vehicles, restore accidentally deleted records, permanently remove test entries, and toggle vehicle availability. This is the primary user who works with this screen daily.

- **Fleet Supervisor** — Can view all vehicle details and edit operational information like seating capacity and document expiry dates, but cannot delete or permanently remove any vehicle records. This role is typically held by the workshop in-charge who manages maintenance but does not make fleet-level decisions.

- **School Administrator** — Has read-only access to the vehicle list. They can see how many vehicles the school owns, check document expiry dates, and view utilisation reports, but cannot make any changes to the records.

- **Driver** — Does not have access to this screen. Drivers interact with vehicles only through the trip assignment screen, where they see which bus they have been assigned to for the day.

Behind the scenes, each action is protected by a permission check. If a user tries to perform an action they are not authorised for, the system displays an "Access Denied" message.

---

## Logic Flow

When the Transport Manager opens Transport Master and clicks the Vehicle tab, the system fetches the most recently added vehicle records from the database — 10 at a time — and displays them in a table. The manager can type a vehicle number or registration number into the search box to filter the list, or use the status dropdown to see only active or only inactive vehicles. Each search or filter change reloads the table while remembering which page the manager was on.

When the manager clicks "Add Vehicle," the system prepares a blank form and fills the dropdown menus with the school's configured options for vehicle type (Bus, Van, Car), fuel type (Diesel, Petrol, CNG, Electric), ownership type (Owned, Leased, Rented), and emission class (BS IV, BS V, BS VI). It also loads the list of registered vendors from the Vendor module so the manager can select which dealership or rental company the vehicle was acquired from. The manager fills in all the fields and submits the form.

Before saving, the system checks every field for correctness: it confirms the vehicle number and registration number are not already used by another vehicle, that the seating capacity is a positive number, that the maximum capacity is at least as high as the standard capacity, and that all four compliance document expiry dates are valid dates. It also checks that the selected vendor actually exists in the system. If anything is wrong, the form highlights the problem fields and refuses to save — the manager must correct the errors first.

If everything is correct, the system creates the vehicle record, uploads any scanned documents the manager attached (keeping each document type in its own separate folder), records the action in the activity log with the manager's name and the time, and returns to the vehicle list with a green success message at the top of the page. The new vehicle now appears in the list and is available for route assignment.

When the manager clicks Edit on an existing vehicle, the form loads with all the current values pre-filled. The manager can change any field, upload replacement documents (which automatically removes the old scanned copies), and save. The system compares the old and new values before saving — if anything changed, it records exactly which fields were modified, what the old values were, and what the new values are in the activity log. If nothing changed, it simply notes "No changes were made" without creating a noisy audit entry.

When the manager clicks Delete, the system does not actually erase the vehicle. Instead, it marks the vehicle as inactive and hides it from the main list. The record continues to exist in the system's "Trash" folder, and all its historical data — trips, fuel logs, inspection records — remain untouched. To see the trashed vehicles, the manager switches to the Trash view where they can either Restore a vehicle (which brings it back to the main list but keeps it inactive until toggled on) or permanently delete it (which removes it from the database entirely, typically only done for test entries that should never have existed).

For the status toggle switch next to each vehicle in the list, clicking it sends a quick update to the system in the background — the vehicle's active status flips from Yes to No (or No to Yes), the toggle moves to its new position, and the activity log records the change. The page does not reload; the toggle updates instantly.

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Vehicle Number | Must be provided, maximum 20 characters, must not match any existing vehicle | "The vehicle no has already been taken." |
| Registration Number | Must be provided, maximum 30 characters, must not match any existing registration | "The registration no has already been taken." |
| Vehicle Model | Optional — if provided, maximum 50 characters | — |
| Manufacturer | Optional — if provided, maximum 50 characters | — |
| Vehicle Type | Must be selected from the pre-configured options (Bus, Van, Car) | "Please select a vehicle type." |
| Fuel Type | Must be selected from the pre-configured options (Diesel, Petrol, CNG, Electric) | "Please select a fuel type." |
| Ownership Type | Must be selected from the pre-configured options (Owned, Leased, Rented) | "Please select an ownership type." |
| Emission Class | Must be selected from the pre-configured options (BS IV, BS V, BS VI) | "Please select an emission class." |
| Seating Capacity | Must be at least 1 | "Seating capacity must be at least 1." |
| Maximum Capacity | Must be equal to or greater than the seating capacity | "Max capacity must be greater than or equal to seating capacity" |
| Fitness Certificate Expiry | Must be a valid date | "Please enter a valid fitness certificate expiry date." |
| Insurance Expiry | Must be a valid date | "Please enter a valid insurance expiry date." |
| Pollution Certificate Expiry | Must be a valid date | "Please enter a valid pollution certificate expiry date." |
| Fire Extinguisher Expiry | Must be a valid date | "Please enter a valid fire extinguisher expiry date." |
| Vendor | Must be selected and must exist in the vendor records | "The selected vendor is invalid." |
| GPS Device ID | Optional — if provided, maximum 50 characters | — |
| Active Status | Must be Yes or No | "The active status must be yes or no." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Vehicle number already exists | "The vehicle no has already been taken." — the form does not submit until a unique number is entered | Data entry error — prevented before saving |
| Registration number already exists | "The registration no has already been taken." — the form does not submit | Data entry error — prevented before saving |
| Maximum capacity lower than seating capacity | "Max capacity must be greater than or equal to seating capacity" — the form blocks submission | Data entry error — prevented before saving |
| Vendor selected does not exist | "The selected vendor is invalid." — the form blocks submission | Database reference error — prevented before saving |
| User tries to add a vehicle without permission | The system displays a blank "Forbidden" page with HTTP 403 error | Permission error — system blocks the action |
| File upload fails due to server limits | The system may show a generic file upload error depending on the server configuration | Technical error — no user-friendly message defined |
| Vehicle deleted with active trip assignments still in the database | The deletion succeeds silently — the system does not check whether the vehicle has ongoing trips. The trips still reference the vehicle in the database, potentially causing reports to show incomplete data. | 🔴 Gap — missing safety check |
| Individual document upload status not tracked | After uploading a fitness certificate, the system cannot answer the question "Has the pollution certificate been uploaded yet?" by looking at the vehicle record alone. The upload tracking flags in the database are never updated. | 🔴 Gap — model does not match database design |
| Fitness certificate expires but vehicle stays available | A vehicle whose insurance or fitness certificate has expired will continue to show as "Available" for trip assignment. The system does not automatically block assignment when documents expire — the Transport Manager must remember to manually mark the vehicle as unavailable. | 🔴 Gap — compliance risk |

---

## Success Scenarios — When Everything Works

**SC-001 — Registering a Brand-New Bus for the Fleet**
The Transport Manager registers a new 50-seater diesel bus with all four compliance documents uploaded. The system accepts the record, stores all four scanned documents in their separate folders, and displays the new bus in the vehicle list with both the "Active" and "Available" badges turned on. The activity log records "Vehicle created" along with the manager's name and the timestamp. The Dashboard's vehicle count increases by one.

**SC-002 — Renewing an Insurance Certificate Before It Expires**
The Transport Manager notices that Bus KL-05's insurance expires in 5 days. They open the vehicle record, upload the renewed insurance certificate PDF, and update the expiry date. The system removes the old scanned copy, stores the new one, and logs the exact change in the activity log: "Insurance valid upto changed from 2025-07-15 to 2026-07-15." The Dashboard's maintenance alerts section now shows Bus KL-05 as compliant.

**SC-003 — Taking a Vehicle Out of Service Temporarily**
A bus develops a mechanical issue and needs to spend two weeks in the workshop. The Transport Manager clicks the toggle switch next to the bus in the vehicle list. The bus immediately shows as "Inactive" and disappears from all assignment dropdowns — no driver can be assigned to this bus until it is toggled back on. The activity log records the change.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Vehicle Deleted While Still Assigned to Active Trips**
The Transport Manager deletes a vehicle that still has three upcoming trips scheduled for next week. The system does not check for active trips before deleting — the deletion succeeds, but the trips now reference a vehicle that no longer exists. When the driver opens the trip list tomorrow, the vehicle column shows blank, causing confusion.

**FC-002 — Document Upload Status Cannot Be Reliably Tracked**
The database has eight separate on-off switches designed to track which documents have been uploaded (fitness certificate uploaded? Yes/No. Insurance uploaded? Yes/No. And so on for all 8 document types). However, the form that processes the data only sets a single combined "Documents uploaded" flag. As a result, those eight individual switches in the database are never turned on. If a manager wants to run a report showing which vehicles are missing their pollution certificate, the system cannot answer that question from the vehicle data alone — it would have to inspect the file storage directly.

**FC-003 — Vehicle with Expired Documents Still Marked Available**
A bus's fitness certificate expired last week. The Transport Manager has been busy with admissions and has not noticed the expiry. Because the system does not automatically check document expiry dates against today's date, the bus continues to show as "Available" on the dashboard. The Trip Assignment screen allows this bus to be assigned to a morning route with 40 school children on board — even though a bus with an expired fitness certificate is legally not allowed to operate on public roads. The only safeguard is the Transport Manager's manual diligence, which is not always reliable.

---

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `sys_dropdown_table` | FK Table | Vehicle type, fuel type, ownership type, emission class |
| `vnd_vendors` | FK Table | Vendor link for hired vehicles |
| `tpt_daily_vehicle_inspection` | Child Table | Inspections per vehicle |
| `tpt_driver_route_vehicle_jnt` | Child Table | Vehicle assignments |
| `tpt_vehicle_fuel` | Child Table | Fuel entries per vehicle |
| `tpt_vehicle_service_request` | Child Table | Service requests per vehicle |
| `tpt_vehicle_maintenance` | Child Table | Maintenance records per vehicle |
| `tpt_trip` | Child Table | Trips using this vehicle |
| Spatie MediaLibrary | Media | Document file storage |
| **GlobalMaster** | Module | Dropdown configuration |
| **Vendor** | Module | Vendor records for hired vehicles |

**Table:** `tpt_vehicle`

| Column | Type | Details |
|--------|------|---------|
| id | INT UNSIGNED PK | Auto-increment |
| vehicle_no | VARCHAR(20) NOT NULL UNIQUE | Vehicle identification number |
| registration_no | VARCHAR(30) NOT NULL UNIQUE | Government registration number |
| model | VARCHAR(50) NULL | Vehicle model |
| manufacturer | VARCHAR(50) NULL | Vehicle manufacturer |
| vehicle_type_id | INT UNSIGNED NOT NULL FK | → `sys_dropdown_table.id` CASCADE |
| fuel_type_id | INT UNSIGNED NOT NULL FK | → `sys_dropdown_table.id` CASCADE |
| capacity | INT UNSIGNED DEFAULT 40 | Seating capacity |
| max_capacity | INT UNSIGNED DEFAULT 40 | Maximum allowed capacity |
| ownership_type_id | INT UNSIGNED NOT NULL FK | → `sys_dropdown_table.id` CASCADE |
| vendor_id | INT UNSIGNED NOT NULL FK | → `vnd_vendors.id` CASCADE |
| fitness_valid_upto | DATE NOT NULL | Fitness certificate expiry |
| insurance_valid_upto | DATE NOT NULL | Insurance expiry |
| pollution_valid_upto | DATE NOT NULL | Pollution certificate expiry |
| vehicle_emission_class_id | INT UNSIGNED NOT NULL FK | → `sys_dropdown_table.id` CASCADE |
| fire_extinguisher_valid_upto | DATE NOT NULL | Fire extinguisher expiry |
| gps_device_id | VARCHAR(50) NULL | GPS device identifier |
| vehicle_photo_upload | TINYINT(1) DEFAULT 0 | Photo upload flag |
| registration_cert_upload | TINYINT(1) DEFAULT 0 | Registration cert upload flag |
| fitness_cert_upload | TINYINT(1) DEFAULT 0 | Fitness cert upload flag |
| insurance_cert_upload | TINYINT(1) DEFAULT 0 | Insurance cert upload flag |
| pollution_cert_upload | TINYINT(1) DEFAULT 0 | Pollution cert upload flag |
| vehicle_emission_cert_upload | TINYINT(1) DEFAULT 0 | Emission cert upload flag |
| fire_extinguisher_cert_upload | TINYINT(1) DEFAULT 0 | Fire extinguisher cert upload flag |
| gps_device_cert_upload | TINYINT(1) DEFAULT 0 | GPS device cert upload flag |
| availability_status | TINYINT(1) DEFAULT 1 | 0=Not Available, 1=Available |
| is_active | TINYINT(1) DEFAULT 1 | Activity flag |
| created_at | TIMESTAMP | — |
| updated_at | TIMESTAMP | — |
| deleted_at | TIMESTAMP NULL | Soft deletes |
| UNIQUE KEY | `(registration_no, vehicle_no)` | Composite unique |
