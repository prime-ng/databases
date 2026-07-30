# Location Masters — Business Requirements

## What This Screen Does

The Location Masters screen defines the hierarchical physical locations within the school campus where library resources are stored. These are not the specific shelf or rack identifiers (which are handled by the separate Shelf Locations screen), but rather the broad zones, floors, aisles, shelves, and racks that make up the library's physical layout. For example, "Main Library - Ground Floor", "Science Wing - First Floor", "Junior Section - Zone A". Each location record has a unique code, a display name, a location type (Zone, Floor, Aisle, Shelf, or Rack), and is linked to a specific building. These location records are referenced by the Shelf Locations screen where the exact placement of books is tracked.

---

## When This Screen Is Used

- During initial library setup when mapping the physical layout of the library
- When adding a new zone, floor, aisle, shelf, or rack to the library's spatial hierarchy
- When updating location names or descriptions (e.g., renaming a floor after renovation)
- When reorganizing the library layout and reclassifying location types

## Default Data Load

This screen renders as the **Location Masters** tab within the Library Masters hub (`library.mgt/masters`). When the user navigates to Library → Library Mgt → Masters and selects the Location Masters tab, `LibraryController@tabIndex` loads all location masters with their related building, ordered by latest first, paginated at 15 rows per page (`location_masters_page`). Search and status filters only apply when the active tab is `location-masters`. An additional `location_type` dropdown filter is available in this tab.

---

---

## Key Fields at a Glance

**Core Identity**
Each location has a unique business code (e.g., "ZONE_A", "FLR_01", "AISLE_B2") limited to 30 characters, and a display name (e.g., "Zone A", "Floor 1", "Aisle B2") limited to 50 characters. The code is globally unique across all location types.

**Hierarchical Classification**
The `location_type` field is an ENUM with five allowed values: `Zone`, `Floor`, `Aisle`, `Shelf`, `Rack`. This determines the location's role in the physical layout hierarchy. The hierarchy flows: Building → Zone → Floor → Aisle → Rack → Shelf. One aisle can have multiple racks, and one rack can have multiple shelves.

**Relational Mapping**
Each location is linked to a building via `building_id` (FK to `sch_buildings.id`). The building reference provides the top-level context — which building on campus this location belongs to. The optional description field provides additional details about the location.

---

## Business Rules and Conditions

**Unique Constraints**
The `code` column has a UNIQUE constraint at the database level. No two locations can share the same code, even if they are of different types (e.g., 'A1-S1-R1' cannot be reused across Zone, Floor, or any other type).

**Location Type Validation**
The `location_type` must be one of the five ENUM values: Zone, Floor, Aisle, Shelf, Rack. This is validated both at the database level (ENUM) and in the FormRequest (`in:Zone,Floor,Aisle,Shelf,Rack`).

**Building Association**
Every location must be linked to a valid building from the school's building master (`sch_buildings.id`). The building provides the top-level context for the location's physical placement.

**Deletion Restrictions**
The controller's `destroy()` method soft-deletes without explicit dependency check. However, the `forceDelete()` method catches foreign key constraint violations. The error message specifically mentions shelf locations as potential dependents: "Cannot delete this location: it is referenced by shelf locations or other records." The database FK constraints on `lib_shelf_locations` (zone_id, floor_id, aisle_id, rack_id, shelf_id) all reference `lib_locations_master.id`, so a location used in any shelf location record cannot be force-deleted.

**Soft Deletes and Restore**
All deletions are soft (`deleted_at` timestamp). Trashed records are accessible via the dedicated Trash view with building relation loaded. Restore sets `deleted_at` to null.

**Inactive Restriction**
When `is_active` = 0, the location cannot be selected while setting up shelf locations. The shelf location dropdowns must filter to only active location master records.

---

## Workflow Steps

**Adding a New Location**
The librarian navigates to Library → Library Mgt → Masters and selects the Location Masters tab. They click "Add Location". They select the building from a dropdown of active buildings. They enter a unique code (e.g., "ZONE_B") and name (e.g., "Zone B - Reference Section"). They select the location type (Zone, Floor, Aisle, Shelf, or Rack) from a dropdown. An optional description can be added. The Active toggle defaults to ON. On Save, the system validates the code uniqueness and persists.

**Editing a Location**
The librarian clicks the Edit icon. The building, code, name, location type, and description can all be modified. The system re-validates code uniqueness, ignoring the current record.

**Deleting a Location**
Clicking Delete soft-deletes the record. If the location is referenced by any shelf location record, the database FK constraint prevents permanent deletion during force-delete.

---

## Example Scenario

The school library is being set up in a new building with two floors. The librarian creates location records: First, they add "Main Library Building" as a Zone (or use the building reference from the existing building master). They add "Floor 1 - Junior Section" as type Floor and "Floor 2 - Senior Section" as type Floor. On Floor 1, they add aisles "Aisle A" and "Aisle B". Each aisle gets racks "Rack 1", "Rack 2", etc. Each rack gets shelves "Shelf A" (top), "Shelf B" (middle), "Shelf C" (bottom). These location records are later used when creating Shelf Locations to map the exact placement of each book copy.

---

## Related Screens

- **Shelf Locations** — Where these location records are selected as zone, floor, aisle, rack, and shelf to define precise book placement
- **Buildings** (School Setup) — Provides the `building_id` reference

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibLocationMasterController`
**Model:** `Modules\Library\Models\LibLocationMaster` (table: `lib_locations_master`)
**Requests:** `LibLocationMasterRequest` (validates create and update)
**Policy:** `LibLocationMasterPolicy` (permissions: `tenant.lib-location-masters.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`)
**Route:** Resource route `Route::resource('lib-location-masters', LibLocationMasterController::class)` under library prefix plus restore/forceDelete/toggleStatus extras
**Tab:** `location-masters` under `library.tabIndex`

Key controller methods:
- `index()` — Redirects to `library.tabIndex` with `tab=location-masters`
- `create()` — Returns create view with active buildings list
- `store(LibLocationMasterRequest)` — Creates location in DB transaction, logs activity
- `show($id)` — Loads location with building relation; logs view activity
- `edit($id)` — Returns edit view with active buildings list
- `update(LibLocationMasterRequest, $id)` — Updates location in DB transaction; computes changed attributes for activity log
- `destroy($id)` — Soft-deletes location; logs activity
- `trashed()` — Lists soft-deleted locations with building relation, paginated at 15
- `restore($id)` — Restores soft-deleted location in DB transaction
- `forceDelete($id)` — Force-deletes with `QueryException('23000')` catch; error message specifically mentions shelf locations
- `toggleStatus($id)` — Toggles `is_active` boolean; uses `Gate::authorize('tenant.lib-location-masters.update')`; supports both AJAX and non-AJAX response

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|--------------|
| Super Admin | `tenant.lib-location-masters.*` | Full CRUD + restore + forceDelete |
| Librarian Admin | `tenant.lib-location-masters.*` | Full CRUD + restore + forceDelete |
| Librarian (view only) | `tenant.lib-location-masters.viewAny`, `.view` | Read-only access to list and detail views |

All access is gated by `LibLocationMasterPolicy` methods which map to `tenant.lib-location-masters.*` permissions.

---

## How This Screen Works — Logic Flow (Non-Technical)

The user navigates to Library → Library Mgt → Masters and selects the Location Masters tab. The system loads all location records with their building info, 15 per page. The user can search by code, name, or description; filter by location type (Zone/Floor/Aisle/Shelf/Rack); or filter by active/inactive status. To add a new location, the user clicks Add Location, selects the building, enters a unique code and name, chooses the location type, adds an optional description, and saves. The system validates the code is unique and the type is one of the five allowed values. To edit, the user clicks the edit icon. To delete, the system soft-deletes the record. If the location is in use by any shelf location, permanent deletion is blocked.

---

## Validate Before Save

**Create/Update (`LibLocationMasterRequest`):**
1. **code:** required, string, max:30, unique on `lib_locations_master.code` (ignoring self on update)
2. **name:** required, string, max:50
3. **description:** nullable, string, max:255
4. **location_type:** required, in:Zone,Floor,Aisle,Shelf,Rack
5. **building_id:** required, integer, exists on `sch_buildings.id`
6. **is_active:** boolean (default: true via `prepareForValidation`)

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| Duplicate code | "The code has already been taken." (default Laravel unique message) | 422 |
| Missing code | "The code field is required." | 422 |
| Invalid location type | "The selected location type is invalid." | 422 |
| Missing location type | "The location type field is required." | 422 |
| Invalid building | "The selected building is invalid." | 422 |
| Force delete with shelf location dependency | "Cannot delete this location: it is referenced by shelf locations or other records. Remove all dependencies first." | 302 (redirect back) |
| Force delete other FK violation | "Cannot delete this record: it is referenced by other records. Remove all dependencies first." | 302 (redirect back) |

---

## Success Scenarios

- A librarian adds a new Zone "Reference Section - Zone A" with code "ZONE_A" linked to the main building. The system saves and displays "Location created successfully."
- A librarian updates a floor name from "Floor 1" to "Ground Floor". The system logs the change and displays "Location updated successfully."
- A librarian deletes a location that is not used by any shelf location. The system soft-deletes and displays "Location moved to trash."

---

## Failure Scenarios

- A librarian tries to create a location with code "ZONE_A" but that code already exists. The system returns "The code has already been taken."
- A librarian tries to add a location with type "Room" which is not in the allowed ENUM. The system returns "The selected location type is invalid."
- A librarian tries to force-delete "Floor 1" from trash, but 12 shelf locations reference this floor. The system catches the FK violation and shows "Cannot delete this location: it is referenced by shelf locations or other records. Remove all dependencies first."

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Table | `lib_locations_master` | Primary table with `code VARCHAR(30) UNIQUE`, `name VARCHAR(50) NOT NULL`, `location_type ENUM('Zone','Floor','Aisle','Shelf','Rack') NOT NULL`, soft-deletes via `deleted_at` |
| FK Reference | `sch_buildings` | `building_id` FK referencing `sch_buildings.id` |
| FK Reference | `lib_shelf_locations` | Five FK columns (`zone_id`, `floor_id`, `aisle_id`, `rack_id`, `shelf_id`) all reference `lib_locations_master.id` — restricts deletion if shelf locations exist |
