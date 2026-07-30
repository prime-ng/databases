# Shelf Locations — Business Requirements

## What This Screen Does

The Shelf Locations screen defines the precise physical location where each book copy resides within the library. Unlike the Location Masters screen (which defines the broad zones, floors, aisles, racks, and shelves), the Shelf Locations screen brings all five hierarchy levels together into a single record that represents a specific, unique placement point. For example, a shelf location record might represent "Building A → Zone 1 → Floor 2 → Aisle B → Rack 3 → Shelf 2", which is a specific spot where books are placed. Each shelf location has a unique code, is linked to a building, and references exactly one zone, floor, aisle, rack, and shelf from the Location Masters table. Book copies are then assigned to a shelf location via `lib_book_copies.shelf_location_id`.

---

## When This Screen Is Used

- During initial library setup when defining all physical placement points for books
- When adding new shelving units or expanding the library layout
- When reorganizing books between different shelf locations
- When tracking the exact location of a specific book copy for retrieval or inventory audit

## Default Data Load

This screen renders as the **Shelf Locations** tab within the Library Masters hub (`library.mgt/masters`). When the user navigates to Library → Library Mgt → Masters and selects the Shelf Locations tab, `LibraryController@tabIndex` loads all shelf locations with their related building, zone, floor, aisle, rack, and shelf records, ordered by latest first, paginated at 15 rows per page (`shelf_page`). Search and status filters only apply when the active tab is `shelf-locations`. Additional filter dropdowns for `building_id` and `zone_id` are available. Reference lists of active buildings and zones (type=Zone) are also loaded for the filter UI.

---

---

## Key Fields at a Glance

**Core Identity**
Each shelf location has a unique business code (e.g., "A1-S1-R1-Z1-F1") limited to 30 characters. This code is globally unique across all shelf locations.

**Hierarchical Mapping (Five-Level)**
A shelf location is the leaf node of a five-level hierarchy, each level referencing a record from `lib_locations_master` filtered by its type:
- **zone_id** → Location where `location_type = 'Zone'`
- **floor_id** → Location where `location_type = 'Floor'`
- **aisle_id** → Location where `location_type = 'Aisle'` (one aisle can have multiple racks)
- **rack_id** → Location where `location_type = 'Rack'` (one rack can have multiple shelves)
- **shelf_id** → Location where `location_type = 'Shelf'`

All five FK references must point to valid, active location master records of the correct type.

**Building Context**
The `building_id` references the school building where this shelf location exists. The building is from `sch_buildings` (School Setup module).

**Full Location Display**
The model provides a `getFullLocationAttribute` accessor that builds a human-readable string like "Bldg: Main Building | Zone: Zone 1 | Floor: Floor 2 | Aisle: Aisle B | Rack: Rack 3 | Shelf: Shelf 2" for display purposes.

---

## Business Rules and Conditions

**Full Path Required**
Every shelf location must have a Building, Zone, Floor, Aisle, Rack, and Shelf specified. All six references are mandatory (NOT NULL at database level). A shelf location is the leaf node of the complete hierarchy: Building → Zone → Floor → Aisle → Rack → Shelf.

**Location Hierarchy Definitions**
- **Zone:** A designated area or section within the library having a particular purpose.
- **Floor:** The building level on which the shelving is located.
- **Aisle:** The open passage or walkway between rows of shelving units.
- **Rack:** A framework (bars or hooks) that holds multiple shelves for storage.
- **Shelf:** A flat, horizontal surface (wood or metal) where books are displayed or stored.
- **Rack-Shelf Relationship:** One aisle can have multiple racks, and one rack can have multiple shelves.

**Field-Level Type Validation**
Each FK column must reference a valid `lib_locations_master` record filtered by its specific `location_type`:
- `zone_id` → Location where `location_type = 'Zone'`
- `floor_id` → Location where `location_type = 'Floor'`
- `aisle_id` → Location where `location_type = 'Aisle'`
- `rack_id` → Location where `location_type = 'Rack'`
- `shelf_id` → Location where `location_type = 'Shelf'`

All five FK references must point to valid, active location master records.

**Unique Constraints**
The `code` column has a UNIQUE constraint at the database level. No two shelf locations can share the same code (e.g., 'A1-S1-R1-Z1-F1' must be globally unique). All five location FK columns are required (NOT NULL) in the database, meaning every shelf location must specify all hierarchy levels.

**Deletion Restrictions**
The controller's `destroy()` method soft-deletes without explicit book copy check. However, the database has a FK constraint on `lib_book_copies.shelf_location_id` referencing `lib_locations_master.id`. The `forceDelete()` method catches foreign key constraint violations and displays a generic dependency error.

**Soft Deletes and Restore**
All deletions are soft (`deleted_at` timestamp). Trashed records are accessible via the dedicated Trash view with all relations loaded. Restore sets `deleted_at` to null.

**Inactive Restriction**
When `is_active` = 0, the shelf location cannot be selected while creating or editing a book copy. Book copy dropdowns must filter to only active shelf locations.

---

## Workflow Steps

**Adding a New Shelf Location**
The librarian navigates to Library → Library Mgt → Masters and selects the Shelf Locations tab. They click "Add Shelf Location". They select the building, zone, floor, aisle, rack, and shelf from six cascading dropdowns — each populated with active locations of the correct type. They enter a unique code and optional description. The Active toggle defaults to ON. On Save, the system validates that all six FK references exist and the code is unique.

**Editing a Shelf Location**
The librarian clicks the Edit icon. All hierarchy selections can be changed. The system re-validates code uniqueness, ignoring the current record.

**Deleting a Shelf Location**
Clicking Delete soft-deletes the record. If any book copies are assigned to this shelf location, permanent deletion via force-delete is blocked by the FK constraint.

---

## Example Scenario

The library acquires 50 new book copies that need to be shelved. The librarian goes to Shelf Locations and first ensures a shelf location record exists for the target spot: Building "Main Building", Zone "Junior Section", Floor "Floor 1", Aisle "Aisle C", Rack "Rack 2", Shelf "Shelf A". They create this shelf location with code "JNR-F1-C2A". Later, when adding the 50 book copies in the Books Master or Purchase workflow, they assign each copy to this shelf location. When a student asks for a book at "JNR-F1-C2A", the staff can navigate to Building > Junior Section > Floor 1 > Aisle C > Rack 2 > Shelf A to find the book.

---

## Related Screens

- **Location Masters** — Provides the zone, floor, aisle, rack, and shelf records used in the hierarchy
- **Books Master / Book Copies** — Where each book copy is assigned to a shelf location
- **Inventory Audit** — Where shelf locations are verified during physical inventory counting
- **Buildings** (School Setup) — Provides the building reference

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibShelfLocationController`
**Model:** `Modules\Library\Models\LibShelfLocation` (table: `lib_shelf_locations`)
**Requests:** `LibShelfLocationRequest` (validates create and update)
**Policy:** `LibShelfLocationPolicy` (permissions: `tenant.lib-shelf-locations.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`)
**Route:** Resource route `Route::resource('lib-shelf-locations', LibShelfLocationController::class)` under library prefix plus restore/forceDelete/toggleStatus extras
**Tab:** `shelf-locations` under `library.tabIndex`

Key controller methods:
- `index()` — Direct list view (not redirect) with building/zone/status filters, loads all 6 relations, paginated at 15; also loads `shelfBuildings` and `shelfZones` for filter dropdowns
- `create()` — Returns create view with 6 active location-type-specific dropdowns (buildings, zones, floors, aisles, racks, shelves)
- `store(LibShelfLocationRequest)` — Creates shelf location in DB transaction, logs activity
- `show($id)` — Loads shelf location with all 6 relations; logs view activity
- `edit($id)` — Returns edit view with 6 active location-type-specific dropdowns
- `update(LibShelfLocationRequest, $id)` — Updates shelf location in DB transaction; computes changed attributes for activity log
- `destroy($id)` — Soft-deletes; logs activity
- `trashed()` — Lists soft-deleted shelf locations with all relations, paginated at 15
- `restore($id)` — Restores soft-deleted shelf location in DB transaction
- `forceDelete($id)` — Force-deletes with `QueryException('23000')` catch for FK violations
- `toggleStatus($id)` — Toggles `is_active` boolean; uses `Gate::authorize('tenant.lib-shelf-locations.update')`; supports both AJAX and non-AJAX response

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|--------------|
| Super Admin | `tenant.lib-shelf-locations.*` | Full CRUD + restore + forceDelete |
| Librarian Admin | `tenant.lib-shelf-locations.*` | Full CRUD + restore + forceDelete |
| Librarian (view only) | `tenant.lib-shelf-locations.viewAny`, `.view` | Read-only access to list and detail views |

All access is gated by `LibShelfLocationPolicy` methods which map to `tenant.lib-shelf-locations.*` permissions.

---

## How This Screen Works — Logic Flow (Non-Technical)

The user navigates to Library → Library Mgt → Masters and selects the Shelf Locations tab. The system loads all shelf location records with their full hierarchical description (building, zone, floor, aisle, rack, shelf), 15 per page. The user can filter by building, zone, or search by code or description. To add a new shelf location, the user clicks Add Shelf Location. They select the building, then the zone, floor, aisle, rack, and shelf from six cascading dropdowns. They enter a unique code and optional description, then save. The system validates all references exist and the code is unique. To edit, the user clicks the edit icon and can change any hierarchy level or the code. To delete, the system soft-deletes the record. If any book copies are assigned to this shelf location, the database prevents permanent deletion.

---

## Validate Before Save

**Create/Update (`LibShelfLocationRequest`):**
1. **code:** required, string, max:30, unique on `lib_shelf_locations.code` ignoring self and respecting soft-deletes (`whereNull('deleted_at')`)
2. **building_id:** required, integer, exists on `sch_buildings.id`
3. **zone_id:** required, integer, exists on `lib_locations_master.id`
4. **floor_id:** required, integer, exists on `lib_locations_master.id`
5. **aisle_id:** required, integer, exists on `lib_locations_master.id`
6. **rack_id:** required, integer, exists on `lib_locations_master.id`
7. **shelf_id:** required, integer, exists on `lib_locations_master.id`
8. **description:** nullable, string, max:255
9. **is_active:** boolean (default: true via `prepareForValidation`)

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| Missing code | "Shelf location code is required." | 422 |
| Duplicate code | "This code is already taken." | 422 |
| Missing building | "Building is required." | 422 |
| Missing zone | "Zone is required." | 422 |
| Missing floor | "Floor is required." | 422 |
| Missing aisle | "Aisle is required." | 422 |
| Missing rack | "Rack is required." | 422 |
| Missing shelf | "Shelf is required." | 422 |
| Invalid building/zone/floor/aisle/rack/shelf | Default "The selected [field] is invalid." | 422 |
| Force delete with book copy dependency | "Cannot delete this record: it is referenced by other records. Remove all dependencies first." | 302 (redirect back) |

---

## Success Scenarios

- A librarian creates a shelf location "JNR-F1-C2A" with the full hierarchy (Main Building → Junior Section → Floor 1 → Aisle C → Rack 2 → Shelf A). The system validates all references and displays "Shelf location created successfully."
- A librarian updates a shelf location to change its rack from "Rack 2" to "Rack 5" due to reorganization. The system logs the change and displays "Shelf location updated successfully."
- A librarian deletes a shelf location that has no book copies assigned. The system soft-deletes and displays "Shelf location moved to trash."

---

## Failure Scenarios

- A librarian tries to create a shelf location with code "JNR-F1-C2A" but that code already exists. The system returns "This code is already taken."
- A librarian tries to create a shelf location without selecting a zone. The system returns "Zone is required."
- A librarian tries to force-delete a shelf location from trash that has 30 book copies assigned. The database FK constraint fires and the system shows "Cannot delete this record: it is referenced by other records. Remove all dependencies first."

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Table | `lib_shelf_locations` | Primary table with `code VARCHAR(30) UNIQUE`, five FK columns to `lib_locations_master`, one FK to `sch_buildings`, soft-deletes via `deleted_at` |
| FK Reference | `lib_locations_master` | Five FK columns (`zone_id`, `floor_id`, `aisle_id`, `rack_id`, `shelf_id`) referencing `lib_locations_master.id` by location type |
| FK Reference | `sch_buildings` | `building_id` FK referencing `sch_buildings.id` |
| FK Reference | `lib_book_copies` | `shelf_location_id` FK referencing `lib_shelf_locations.id` — restricts deletion if book copies exist |
