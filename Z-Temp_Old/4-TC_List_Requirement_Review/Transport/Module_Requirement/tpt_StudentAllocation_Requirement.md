# Student Transport Allocation — Business Requirements

## What This Screen Does

The Student Transport Allocation screen records which student uses which route for pickup and drop-off, at which stops, and at what fare amount. It is the master record that answers the question: "Is this student registered for school transport, and if so, what are their pickup and drop arrangements?"

Every year, before the school session starts or when a new student enrolls, the Transport Manager allocates transport to each student. This allocation becomes the source of truth for:
- Which students should appear on which bus (used by the boarding log and trip management screens)
- What fare amount should be charged (used by the Fee Creation / Invoicing screen)
- Which route's capacity is consumed

Without an allocation record, a student cannot use school transport, cannot be scanned at a stop, and cannot receive a transport fee invoice.

This screen appears as the first tab within the Student Route Fees Management section, loaded by the `StudentAllocationController`.

---

## Default Data Load

When the user opens Student Route Fees Management and clicks the Student Transport Allocation tab, the system loads a paginated list of all allocation records. Each row shows the student's name, admission number, class, pickup route name, pickup stop, drop route name, drop stop, fare amount, effective date, and active status.

Filters are available to narrow down by class, section, route, or status. An AJAX-based class-to-section cascading dropdown lets the user first select a class, then a section, then the system loads only students in that section.

---

## When This Screen Is Used

- **Registering a New Student for Transport** — A new student joins the school in the middle of the session. The parent has opted for transport. Mrs. Desai opens this screen and creates a new allocation. She selects the student's name, chooses their pickup route and stop, drop route and stop, enters the fare amount, sets today as the effective date, and marks the status as Active.

- **Changing a Student's Pickup Stop** — A parent calls to say their child will now board from a different stop. Mrs. Desai edits the existing allocation, changes the pickup stop, and saves. If the stop changes, the system triggers a `TPT_PICKUP_CHANGE` accounting event for audit.

- **Changing a Student's Route** — A family moves to a new area. The student needs to switch from the MG Road route to the Indiranagar route. Mrs. Desai edits the allocation, changes both the pickup route and stop, and saves. The route change triggers a `TPT_MODE_CHANGE` accounting event.

- **Deactivating a Student's Transport** — A parent informs the school that their child will now commute by private vehicle. Mrs. Desai toggles the allocation's active status to Inactive. The student will no longer appear on the bus roster, and future fee invoices will not be generated.

- **Removing a Student's Allocation** — A student has left the school. Mrs. Desai deletes the allocation (soft delete). The record moves to the Trash. If needed, she can restore it later or permanently delete it from the Trash screen.

- **Bulk Import via Excel** — At the start of the academic year, the school receives 500 transport applications. Instead of entering each one manually, Mrs. Desai prepares an Excel file with columns for roll number, route code, pickup stop code, drop stop code, status, effective date, and fare amount. She uploads the file, validates it, and then starts the import. The system creates 500 allocation records in seconds.

---

## Key Fields at a Glance

**Student Identity**
Each allocation is linked to a specific student through their `student_session_id`, which connects to the academic session record. The student's name, class, section, roll number, and admission number are displayed.

**Transport Usage Type**
A dropdown with three options:
- Pickup — The student only uses the bus for the morning pickup (they go home by other means).
- Drop — The student only uses the bus for the afternoon drop (they come to school by other means).
- Both — The student uses the bus for both pickup and drop.

Based on this selection, certain fields become mandatory or optional. For example, if "Pickup" is selected, the drop route and drop stop fields are saved as null, and the validation ignores them.

**Pickup Route and Stop**
These two fields define where the student gets on the bus in the morning. The route is selected from the Route master. The stop is selected from the available stops on that route (only stops marked as "Pickup" or "Both" in the route-stop mapping).

**Drop Route and Stop**
These two fields define where the student gets off the bus in the afternoon. The route and stop work the same way as pickup, but only stops marked as "Drop" or "Both" are shown.

**Fare Amount**
The monthly transport fee for this student. This amount is used by the Fee Creation screen to generate monthly invoices. The fare is a numeric field without any automatic calculation — the Transport Manager enters it manually based on the route's fee structure.

**Effective From**
The date from which this allocation is valid. For a new registration at the start of the session, this would be 1 April. For a mid-session enrollment, it would be the joining date.

**Active Status**
A toggle (Active / Inactive) that controls whether the student is currently using transport. Inactive students are excluded from bus rosters and fee generation.

---

## Business Rules and Conditions

**Student Academic Session Is Auto-Resolved**
When creating an allocation, the system does not ask for the academic session separately. It looks up the student's current academic session record (where `is_current = 1`) based on the selected student ID. If no academic session is found, the allocation cannot be created.

**Transport Usage Type Controls Which Fields Are Saved**
If the user selects "Pickup," the system automatically sets the drop route and drop stop to null before saving. If "Drop" is selected, the pickup route and pickup stop are set to null. This ensures that only the relevant half of the journey is recorded.

**Route Must Have an Active Vehicle**
Before saving a new allocation, the system checks whether the selected route has an active vehicle assigned through the Driver-Route-Vehicle junction table. If no active vehicle is assigned to that route, the allocation is rejected with the message: "No active vehicle assigned to this route." This prevents assigning students to a route that has no bus.

**Vehicle Capacity Is Enforced**
After confirming the route has a vehicle, the system checks the vehicle's student capacity. It compares the current number of students allocated to that route (`total_students` in the junction table) against the vehicle's capacity. There are two capacity limits:
- Normal capacity: The standard number of seats.
- Maximum capacity: A higher limit that is only used if the setting `allow_extra_student_in_vehicale_beyond_capacity` is enabled.

If the current student count equals or exceeds the applicable capacity limit, the allocation is rejected.

**Student Count Is Incremented on Creation**
When an allocation is successfully created, the system increments the `total_students` counter on the active Driver-Route-Vehicle junction record. When an allocation is deleted, the counter is decremented. This keeps the student count accurate without counting records each time.

**Duplicate Allocations Can Be Prevented During Import**
During Excel import validation, the system checks whether a student already has an allocation. If a student is already allocated, the import row is rejected with the error "Student already allocated." This prevents creating duplicate records accidentally.

**Accounting Events Are Triggered for Changes**
The system sends events to the accounting module when significant changes occur:
- New allocation (registration): `TPT_NEW_REGISTRATION`
- Stop change: `TPT_PICKUP_CHANGE`
- Route change: `TPT_MODE_CHANGE`

These events flow to the school's accounting system so that fee adjustments and audits are automatically recorded.

---

## Workflow Steps

**Creating a Single Allocation**
Mrs. Desai clicks the Create button. A form opens showing a student selection field. She first selects a class, then a section — the system loads only students in that section via AJAX. She selects the student. She sets the transport usage type to "Both." She picks the pickup route "MG Road" from the dropdown, then the pickup stop "Indiranagar Main Road" from the available stops. She does the same for the drop. She enters ₹800 as the fare. She sets effective date to 1 April. She clicks Save. Behind the scenes, the system verifies the route has a vehicle, checks capacity, increments the student count, logs the activity, and triggers the accounting event.

**Editing an Allocation**
Mrs. Desai clicks the Edit button on an existing record. The form is pre-filled with the current data. She changes the pickup stop from "Indiranagar Main Road" to "MG Road Signal" because the family moved. She saves. The system compares old and new stop values, and if changed, triggers a pickup change accounting event.

**Deleting an Allocation**
Mrs. Desai clicks the Delete button. The system decreases the `total_students` count on the route's vehicle assignment. The allocation is soft-deleted (moved to trash). She can view the Trash screen to see all deleted allocations and can restore them if needed.

**Bulk Import**
Mrs. Desai clicks the Import button. She uploads an Excel file. The system validates each row — checking roll numbers against the database, verifying route codes, stop codes, status values, effective dates, and fare amounts. Any errors are returned as a downloadable text report showing which rows failed and why. If validation passes, the file is stored and Mrs. Desai clicks Start Import. The system processes all valid rows and creates allocation records in a single batch.

**Export to Excel**
Mrs. Desai clicks Export. The system generates an Excel file containing all current allocation records (with filters applied). This is useful for sharing with the Finance department or for offline review.

---

## Example Scenario

Green Valley School starts its new academic session on 1 April. Mrs. Desai has received 450 transport applications. She imports them via Excel in one batch. The system validates all 450 rows — 445 pass and 5 fail (2 students have invalid roll numbers, 2 have invalid route codes, and 1 student is already allocated).

Mrs. Desai reviews the error report, corrects the 5 errors in the Excel file, and re-imports. This time all 450 pass.

During the session, student Aarav Sharma's family moves from Indiranagar to MG Road. Mrs. Desai edits Aarav's allocation, changes the pickup stop, and saves. The system logs the change and triggers an accounting event.

Later, student Priya leaves the school. Mrs. Desai deletes her allocation. The system reduces the student count on the MG Road route and soft-deletes the record. Three months later, Priya re-enrolls, and Mrs. Desai restores her allocation from the Trash screen.

---

## Related Screens

- **Route Master** — Routes that are selected in the allocation must be defined here first.
- **Transport Stops** — Stops must be defined and mapped to routes with the correct pickup/drop type.
- **Driver/Vehicle Roster** — Route-vehicle assignments are used to verify that a route has an active vehicle.
- **Fee Creation (Invoicing)** — The fare from the allocation is used to generate monthly fee invoices.

---

## Requirements

- Controller: `StudentAllocationController` with CRUD + `toggleStatus()`, `export()`, `validateFile()`, `startImport()`, `getSections()`, `getStudents()`
- Model: `TptStudentAllocationJnt` (table: `tpt_student_route_allocation_jnt`) — SoftDeletes
- Import: `StudentAllocationImport`, `StudentAllocationReadOnly`
- Export: `StudentAllocationExport`
- Form Request: `StudentAllocationRequest`
- Permissions: `tenant.student-allocation.{viewAny,view,create,update,delete,restore,forceDelete,import,export}`
- Activity logging: ✅ Present on create, update, delete, restore, forceDelete, toggleStatus

---

## Who Can Access

- **Transport Manager** — Full access. Can create, edit, delete, toggle status, import, export, and restore allocations.

- **Fleet Supervisor** — Can view and export allocations but cannot create, edit, or delete.

- **School Administrator** — Can view allocations for reporting purposes.

- **Accountant** — Can view allocation fare amounts for fee calculation purposes but cannot modify transport arrangements.

Behind the scenes, each action is protected by a permission check against the user's role.

---

## Logic Flow

When the user opens the Student Transport Allocation tab, the system queries all `TptStudentAllocationJnt` records with eager-loaded relations for student details, routes, and stops. The records are paginated.

When creating, the form first loads classes, then uses AJAX to load sections when a class is selected, then loads students when a section is selected. The pickup and drop stop dropdowns are populated based on the selected route, filtered by the transport use type (Pickup/Drop/Both).

On save, the system:
1. Resolves the academic session ID from the student
2. Checks whether transport usage is Pickup-only or Drop-only and nullifies the irrelevant fields
3. Checks route has an active vehicle via `DriverRouteVehicleJnt`
4. Checks vehicle capacity against current student count
5. Creates the allocation record
6. Increments the `total_students` counter on the route-vehicle junction
7. Logs the activity
8. Triggers accounting events

On update, the system:
1. Snapshot old values of pickup/drop stops and routes
2. Update the allocation
3. Log the activity
4. Compare old vs new values; if stop or route changed, trigger relevant accounting event

On delete, the system:
1. Decrement `total_students` on the route-vehicle assignment
2. Soft delete the allocation
3. Log the activity

On import validation, the system reads the Excel file, validates each row for roll number existence, route code, stop codes, status format, effective date, and fare numeric format. Duplicates within the Excel file and against existing allocations are flagged.

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Student | Must exist and have a current academic session | "Student not found." / "No academic session found" |
| Transport Usage Type | Must be Pickup, Drop, or Both | "Please select a valid transport use type." |
| Pickup Route | Must exist if usage is Pickup or Both | "Please select a valid pickup route." |
| Pickup Stop | Must belong to the selected route and be a Pickup/Both stop | "Please select a valid pickup stop." |
| Drop Route | Must exist if usage is Drop or Both | "Please select a valid drop route." |
| Drop Stop | Must belong to the selected route and be a Drop/Both stop | "Please select a valid drop stop." |
| Fare | Must be a number | "Please enter a valid fare amount." |
| Effective From | Must be a valid date | "Please enter a valid effective date." |
| Route Vehicle | Must have an active vehicle assigned | "No active vehicle assigned to this route." |
| Vehicle Capacity | Current count must be below capacity limit | "Vehicle capacity exceeded." / "Vehicle maximum capacity exceeded." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Selected route has no active vehicle | "No active vehicle assigned to this route." — allocation cannot be created | Business rule validation |
| Bus is already full | "Vehicle capacity exceeded." — allocation rejected | Business rule validation |
| Student already allocated (during import) | "Student already allocated" — row skipped | Duplicate detection |
| Invalid roll number in import | "Invalid Student Roll Number" — row flagged | Data entry error |
| Wrong pickup stop selected | Stop is saved — system does not verify the stop against the student's home address | 🔴 Gap — no address matching |
| Fare set to zero | System allows it — no minimum fare check | 🔴 Gap — no minimum fare rule |
| Effective date in the past | System accepts it — no validation against session dates | 🔴 Gap — no date range check |
| Student assignment without active route-vehicle | Blocked by design — error thrown | Proper guard |
| Delete allocation with existing fee records | System allows it — fee records remain orphaned | 🔴 Gap — no cascade check |

---

## Success Scenarios — When Everything Works

**SC-001 — New Student Registered for Transport**
A new student, Ravi, enrolls at Green Valley School. Mrs. Desai creates his allocation: Pickup and Drop on the MG Road route, ₹800 fare, effective immediately. The system creates the record, increments the student count on the bus, and logs the creation. Ravi's name now appears on the bus roster.

**SC-002 — Bulk Import of 500 Students**
Mrs. Desai imports 500 allocations via Excel at the start of the session. All 500 pass validation. The process takes less than a minute. Each student now has a transport record.

**SC-003 — Stop Change for Existing Student**
Aarav's family moves. Mrs. Desai edits his allocation to change the pickup stop. The system saves the update, logs the change, and triggers a `TPT_PICKUP_CHANGE` accounting event. The bus driver's stop list is automatically updated.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Import Fails Due to Invalid Data**
Mrs. Desai imports an Excel file where 20 of 500 rows have errors (invalid roll numbers, wrong route codes, missing effective dates). The system generates a text report listing all 20 errors. She corrects the file and re-imports. The valid rows from the first attempt were not saved — only rows that pass validation in the re-imported file are created.

**FC-002 — Allocation Created for Route Without Vehicle**
Mrs. Desai tries to allocate a student to the "Lake View" route. The system rejects it because no active vehicle has been assigned to that route. She must first assign a vehicle to the route through the Driver/Vehicle Roster screen.

**FC-003 — Deleted Allocation Leaves Orphaned Fee Records**
Mrs. Desai deletes a student's allocation after the student leaves school. The fee invoice records for that student remain in the system with no link back to a valid allocation. The accountant sees fee records with no student transport reference.