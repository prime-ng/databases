# Hostel Setup — Requirements

## What It Does
The unified setup page that provides access to all hostel configuration entities — room types, bed types, status masters, hostels, floors, rooms, beds, emergency contacts, and warden assignments. Serves as the landing page for administrative configuration.

## Database Fields
No database table. This is an aggregate view page that provides tabbed access to CRUD operations on 9 configuration entities.

## Business Rules

**Setup Order**
1. Room Types → 2. Bed Types → 3. Status Masters → 4. Hostels → 5. Floors → 6. Rooms → 7. Beds → 8. Emergency Contacts → 9. Warden Assignments

**Data Dependency Chain**
- Floors require a hostel
- Rooms require a floor
- Beds require a room
- Warden assignments require a hostel

**Tabbed Interface**
- Each entity is displayed as a Bootstrap nav-tab within the setup page
- The active tab is preserved in the URL hash (`#beds`, `#rooms`, etc.)
- Each tab shows its own paginated table with search/filter
- Redirects from CRUD operations return to the setup page with the correct hash

## CRUD Operations

**View** — `GET /hostel/setup` → renders the setup page with all 9 tabs | Each tab shows a paginated table of the entity records | Supports hash-based tab selection

**Create/Edit/Delete** — Delegated to individual entity controllers (RoomTypeController, BedTypeController, etc.) with redirect back to `hostel.setup.index` with the appropriate `#entity` hash

## Permissions

| Operation | Permission Key |
|---|---|
| View setup page | `tenant.hostel.setup` |
| Each tab gated by its own entity permissions | As per individual entities |
