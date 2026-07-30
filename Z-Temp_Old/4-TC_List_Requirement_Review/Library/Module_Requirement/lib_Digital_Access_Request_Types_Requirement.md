# Digital Access Request Types — Business Requirements

## What This Screen Does

The Digital Access Request Types screen stores a simple lookup table of access request types that members can select when requesting access to a digital resource. Each type defines the kind of access a member is requesting, such as "Download", "View_Online", "Stream", "Offline", or "Extended" (renewal). The `code` field serves as the stable business identifier and is used by the `LibDigitalAccessRequest::mapRequestTypeToAccessType()` method to resolve which access type ('Download' or 'Read_Online') to grant upon approval. The "Extended" type is a special case — it represents a renewal request and produces a null access type, triggering a separate renewal flow in the controller. This module has no create/edit/delete forms; new types are seeded directly into the database. The only available action is toggling the active status.

---

## When This Screen Is Used

- When setting up digital access request types for the first time during library configuration
- When a pre-seeded type needs to be deactivated (e.g., "Stream" is no longer a supported access method)
- During troubleshooting when the approval flow fails because the request type code does not match the expected mapping values

## Default Data Load

The Access Request Types screen opens as a tab pane within the Library Acquisition hub page (`library.acquisitionIndex`). When the `digital-access-request-types` tab is active, the controller loads the list via the hub's `acquisitionIndex()` private query helper. No dedicated paginator name is used because the data set is typically small (under 20 records). The tab redirect passes search and status filter parameters, though no dedicated search/filter logic is implemented in the hub for this tab.

---

---

## Key Fields at a Glance

**Core Identity**
Every request type has a unique `code` (VARCHAR 30) that serves as the stable business identifier — for example, 'Download', 'View_Online', 'Stream', 'Offline', 'Extended'. The `name` (VARCHAR 100) is the human-readable display name. An optional `description` (VARCHAR 255) explains what each access type means.

**Status**
`is_active` is a boolean toggle controlling whether the request type appears in the selection dropdown when members submit a digital access request. Inactive types remain in the database but are excluded from active workflows.

---

## Business Rules and Conditions

**Code-Based Access Type Mapping**
The `LibDigitalAccessRequest::mapRequestTypeToAccessType()` method maps request type codes to transaction access type ENUM values: 'Download' maps to 'Download', 'View_Online', 'Stream', and 'Offline' all map to 'Read_Online'. The 'Extended' code returns null, which signals the controller to block direct approval and require a separate renewal flow.

**No Create/Update/Delete in UI**
This module has a minimal interface — there is no create form, edit form, or delete action. New request types must be seeded directly into the database via migration or manual insert. The controller exposes only `index()` (redirect to hub) and `toggleStatus()` (AJAX toggle).

**Status Toggle Only**
The only mutable field through the interface is `is_active`. The controller's `toggleStatus()` method uses `Gate::authorize('tenant.lib-digital-access-request-types.update')` and returns a JSON response on toggle. No activity log is recorded for toggles.

---

## Workflow Steps

1. Navigate to Library → Acquisition hub and select the Digital Access Request Types tab
2. View the list of pre-seeded request types with their codes and active status
3. Click the status toggle to activate or deactivate a request type
4. Deactivated types are hidden from the dropdown when members submit access requests
5. No other CRUD operations are available through this screen

---

## Example Scenario

The library initially seeds five request types: Download, View_Online, Stream, Offline, and Extended. After a policy review, the library decides to discontinue the "Stream" access method for digital resources. The librarian navigates to the Access Request Types tab and toggles "Stream" to inactive. When a member tries to request access, "Stream" no longer appears in the request type dropdown. Meanwhile, the "Extended" type is reserved for renewal requests — when a member selects it, the controller's approval logic detects the null access type mapping and redirects to the renewal approval flow instead.

---

## Related Screens

- **Digital Resources** — The resources that members request access to
- **Digital Access Requests** — Where the request type is selected by the member
- **Digital Access Transactions** — Where the resolved access type is stored after approval
- **Library Acquisition Hub** — Parent hub containing the Access Request Types tab

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibDigitalAccessRequestTypeController`
**Model:** `Modules\Library\Models\LibDigitalAccessRequestType` (table: `lib_digital_access_request_types`)
**Request:** None — no store/update forms
**Policy:** None — uses `Gate::authorize()` with string permissions
**Route:** Two routes: `GET /lib-digital-access-request-types` (index) and `POST /lib-digital-access-request-types/{id}/toggle-status`

Key controller methods:
- `index()` — Redirects to acquisition hub with tab=digital-access-request-types, permission: `tenant.lib-digital-access-request-types.viewAny`
- `toggleStatus($id)` — Toggles `is_active` boolean via AJAX, returns JSON response, permission: `tenant.lib-digital-access-request-types.update`

---

## Who Can Access

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.lib-digital-access-request-types.*` | Full access (bypasses policy via Gate::before) |
| Library Admin | `tenant.lib-digital-access-request-types.viewAny`, `.update` | View and toggle active status |
| Librarian | `tenant.lib-digital-access-request-types.viewAny` | Read-only access |

**Note:** The permission group `lib-digital-access-request-types` is **not defined** in `config/permissionslist.php` as of the current version. This is a known gap — the controller references these permission strings but the group must be added to the permissions list by the development team.

---

## How This Screen Works — Logic Flow (Non-Technical)

The user navigates to the Library Acquisition hub and selects the Digital Access Request Types tab. The system loads a simple table listing all request types with their code, name, description, and active status. There are no add, edit, or delete buttons — new types are added directly in the database. The only interactive element is the status toggle switch. When the librarian clicks the toggle, an AJAX request updates the `is_active` field and the UI reflects the change without a page reload. The primary purpose of this screen is to allow the library team to enable or disable access types as policies change, without requiring a developer to write a database query.

---

## Validate Before Save

No create/edit forms exist for this module. The only validation is performed on the `toggleStatus` route, which does not use a FormRequest — the controller directly calls `findOrFail($id)` and updates `is_active` by inverting the current value. No input validation is required beyond the route model binding.

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Gate authorization fails (view) | This action is unauthorized. | 403 |
| Gate authorization fails (toggle) | This action is unauthorized. | 403 |
| Record not found | No query results for model [LibDigitalAccessRequestType] | 404 |
| AJAX toggle fails | (exception caught by Laravel, generic 500) | 500 |

---

## Success Scenarios

**SC-001: Toggle request type from active to inactive**
1. User clicks status toggle on the "Stream" request type
2. AJAX request POST to `/lib-digital-access-request-types/{id}/toggle-status`
3. Controller inverts `is_active` from 1 to 0
4. Response: `{ success: true, message: "Access request type status toggled successfully." }`
5. Toggle switch updates in the UI, type no longer appears in member dropdowns

---

## Failure Scenarios

**FC-001: User without update permission tries to toggle**
1. User with read-only role clicks status toggle
2. `Gate::authorize('tenant.lib-digital-access-request-types.update')` throws AuthorizationException
3. Response: 403 "This action is unauthorized."
4. Toggle does not execute

---

## 5 Fixed Request Types (from Lib_Conditions.md Section 4.5)

The system defines exactly 5 fixed request types. These are system-defined lookup values — admin cannot change them through the UI.

| Code | Display Name | Maps To (access_type) | Description |
|------|-------------|----------------------|-------------|
| `Download` | Download | `Download` | Full file download |
| `View_Online` | View Online | `Read_Online` | Online viewing only |
| `Stream` | Stream | `Read_Online` | Audio/video streaming |
| `Offline` | Offline | `Read_Online` | Offline access (cached) |
| `Extended` | Extended | `null` (special — triggers renewal flow) | Renewal of existing access |

### Mapping Rules

The `LibDigitalAccessRequest::mapRequestTypeToAccessType()` method uses these rules:

1. **`Download`** → maps to `'Download'` access type in `lib_digital_access_transactions`.
2. **`View_Online`**, **`Stream`**, **`Offline`** → all map to `'Read_Online'` access type.
3. **`Extended`** → returns `null`, which signals the controller to block direct approval and trigger a separate renewal/re-issue flow.

### Business Rules

1. Sirf 5 fixed types hain: Download, View Online, Stream, Offline, Extended.
2. Jab bhi student/staff digital resource ka access request karega, to request type select karega — above 5 mein se koi ek.
3. Ye master data hai — iska CRUD UI nahi hai, seed migration se set hota hai.
4. Request types delete nahi ho sakti jab tak us type ki koi request existing ho.

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | lib_digital_access_request_types | Main request types lookup table with unique code |
| Table | lib_digital_access_requests | Consumes request_type FK for member access requests |
| Table | lib_digital_access_transactions | Resolved access_type derived from request type code mapping |
| Module | Library Digital Resources | The resources being requested |
| Module | Library Digital Access Requests | Where request types are used by members |
| Module | Library Acquisition Hub | Parent hub containing the Access Request Types tab |
