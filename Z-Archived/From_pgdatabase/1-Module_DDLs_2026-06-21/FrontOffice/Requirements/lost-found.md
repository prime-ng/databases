# Lost & Found Register — Requirements

## What It Does
Tracks lost items found on campus. Records item description, category, location found, and optional photo. Supports the disposition lifecycle: Unclaimed → Claimed/Disposed/Returned_to_Authority.

## Database Fields

### fof_lost_found

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `item_number` | VARCHAR(25) | Required. Unique. Auto-generated: `LF-YYYY-NNNN`. |
| `item_description` | VARCHAR(300) | Required. |
| `category` | ENUM('Electronics','Clothing','Stationery','ID_Card','Money','Jewellery','Books','Sports','Other') | Required. |
| `found_date` | DATE | Required. |
| `found_location` | VARCHAR(200) | Required. |
| `found_by_name` | VARCHAR(100) | Required. |
| `found_by_user_id` | INT UNSIGNED FK → `sys_users` | Nullable. If finder is staff. |
| `photo_media_id` | INT UNSIGNED FK → `sys_media` | Nullable. Item photo. |
| `status` | ENUM('Unclaimed','Claimed','Disposed','Returned_to_Authority') | Default 'Unclaimed'. |
| `claimant_name` | VARCHAR(100) | Nullable. Set when claimed. |
| `claimant_contact` | VARCHAR(15) | Nullable. |
| `claimed_date` | DATE | Nullable. |
| `disposal_notes` | TEXT | Nullable. For Disposed or Returned. |

## Business Rules
- Status transitions: Unclaimed → Claimed / Disposed / Returned_to_Authority
- Claiming sets claimant details and claimed_date
- Disposal/Return requires disposal_notes
- Photo is optional but recommended for high-value items
- Items can be filtered by status and found_date

## CRUD Operations

**Register Found Item**
- `POST /front-office/lost-found` — validates description, category, found_date, found_location, found_by_name

**Mark Claimed**
- `PATCH /front-office/lost-found/{lostFound}/claim` — sets claimant_name, claimant_contact, claimed_date, status = 'Claimed'

**List**
- Filters: Unclaimed / Claimed / Disposed / All
- Photo thumbnail in list
- Search by description, category, found location

## Permissions

| Operation | Permission Key |
|---|---|
| View items | `frontoffice.visitor.view` |
| Register/claim items | `frontoffice.visitor.create` |
