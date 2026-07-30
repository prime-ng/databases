# Digital Resource Access Restrictions — Business Requirements

## What This Screen Does

The Digital Resource Access Restrictions screen lets the librarian define fine-grained access control rules for digital resources. Each restriction specifies that a particular digital resource can only be accessed by users matching a specific role, designation, department, or individual user. A resource can have multiple restrictions (e.g., only "Science Teachers" AND "Head of Department" designation), and the approval logic in `LibDigitalAccessRequestController` checks that the requesting member matches at least one active restriction before approval. If a digital resource has no restrictions at all, any library member can request access. The CHECK constraint `chk_drar_at_least_one` on the database ensures that every restriction record specifies at least one target (role, designation, department, or user). The DDL also enforces uniqueness on `(digital_resource_id, user_id)` — a specific user can only have one restriction per digital resource.

---

## When This Screen Is Used

- When an e-book should only be accessible to specific roles (e.g., only Teachers, not Students)
- When an e-book should only be accessible to a specific department (e.g., Science Department)
- When an e-book should only be accessible to a specific designation (e.g., Head of Department)
- When granting access to specific individual users (e.g., a particular teacher who needs the resource)
- When reviewing which restrictions are active for which digital resources
- When modifying or removing existing restrictions as access policies change

## Default Data Load

The Access Restrictions screen opens as a tab pane within the Library Acquisition hub page (`library.acquisitionIndex`). When the `access-restrictions` tab is active, the controller loads all restriction records with eager-loaded digital resource, user, role, designation, and department relationships, ordered by latest first, paginated at 15 per page (`access_restrictions_page` paginator name). Filters support search by digital resource file name or user name, dropdown filter by digital resource, and active status filter.

---

---

## Key Fields at a Glance

**Resource and Restriction Targets**
Every restriction record links to a `digital_resource_id` (FK to `lib_digital_resources`). The restriction targets are stored across four nullable FK columns: `role_id` (FK to `sys_roles`), `designation_id` (FK to `sys_designations`), `department_id` (FK to `sys_departments`), and `user_id` (FK to `sys_users`). At least one of these four must be non-null per record (enforced by database CHECK constraint).

**Status**
`is_active` is a boolean toggle controlling whether the restriction is enforced. Inactive restrictions are still visible in the list but are excluded by the approval logic query (which adds `->where('is_active', true)`).

---

## Business Rules and Conditions

**At Least One Target Required**
The database CHECK constraint `chk_drar_at_least_one` enforces that every record must have at least one of the four target fields populated. The FormRequest reinforces this with a custom `withValidator()` method that adds a validation error if all four fields are empty: "At least one restriction (Role, Designation, Department, or User) must be specified."

**Unique User per Resource**
The DDL has a unique constraint `uq_lib_drar_digRes_userId` on `(digital_resource_id, user_id)`. The FormRequest checks this with a manual query that excludes the current record on update, displaying: "This user already has an access restriction for the selected digital resource."

**Approval Enforcement**
The approval logic in `LibDigitalAccessRequestController::approve()` queries `LibDigitalResourceAccessRestriction::where('digital_resource_id', $id)->where('is_active', true)`. If any active restrictions exist, the system checks whether the requesting member matches at least one. The matching logic uses an OR condition across all four target types: the member's user_id must match, OR the member has a role matching `role_id`, OR the member has a designation matching `designation_id`, OR the member has a department matching `department_id`. If no match is found, approval is blocked with: "Cannot approve: member is restricted from accessing this digital resource."

**No Restrictions = Open Access**
If a digital resource has zero active restrictions, any library member can request access regardless of role, designation, department, or user identity.

**Soft Delete and FK Protection**
Restrictions are soft-deleted. On force delete, a try-catch block catches `QueryException` with code 23000 and prevents deletion if the restriction is referenced by other records, showing: "Cannot delete this record: it is referenced by other records. Remove all dependencies first."

---

## Workflow Steps

1. Navigate to Library → Acquisition hub and select the Access Restrictions tab
2. Click "Add Restriction" to open the create form
3. Select the Digital Resource from a dropdown of active resources
4. Specify at least one restriction target:
   a. Select a **Role** (e.g., Teacher, Student, Staff)
   b. OR select a **Designation** (e.g., Head of Department, Lab Assistant)
   c. OR select a **Department** (e.g., Science, Mathematics)
   d. OR select a specific **User** (individual person)
5. Toggle Active ON
6. Click Save — system validates at least one target provided and unique user constraint
7. Edit existing restrictions to change targets or deactivate
8. Delete (soft delete) moves to trash
9. Restore from trash or permanently delete with FK safety checks

---

## Example Scenario

The library acquires a digital resource titled "Advanced Chemistry Lab Manual" that is only relevant to the Science Department's teachers. The librarian creates two restrictions on this resource: one with `department_id` = Science Department and one with `role_id` = Teacher. When a Grade 10 student tries to request access, the approval logic checks: the student's department is "Student" not "Science" and the student's role is "Student" not "Teacher" — neither restriction matches, so access is blocked with "Cannot approve: member is restricted from accessing this digital resource." Later, a new chemistry teacher joins the Science Department — they can request access because their role matches "Teacher" and their department matches "Science."

---

## Related Screens

- **Digital Resources** — The parent resources that restrictions are applied to
- **Digital Access Requests** — Where restrictions are enforced during approval
- **Digital Access Transactions** — Created after successful restriction check approval
- **Library Acquisition Hub** — Parent hub containing the Access Restrictions tab

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibDigitalResourceAccessRestrictionController`
**Model:** `Modules\Library\Models\LibDigitalResourceAccessRestriction` (table: `lib_digital_resource_access_restrictions`)
**Request:** `LibDigitalResourceAccessRestrictionRequest`
**Policy:** None — uses `Gate::authorize()` with string permissions
**Route:** Resource route `Route::resource('lib-digital-resource-access-restrictions', LibDigitalResourceAccessRestrictionController::class)->parameters(['lib-digital-resource-access-restrictions' => 'access_restriction'])` plus `trashed`, `restore`, `forceDelete`, `toggleStatus`

Key controller methods:
- `index(Request)` — Redirects to acquisition hub with tab=access-restrictions
- `create()` — Returns form with digital resources, roles, designations, departments, and users
- `store(LibDigitalResourceAccessRestrictionRequest)` — Validates (at least one target, unique user per resource), creates record, logs activity
- `show($id)` — Shows restriction details with eager-loaded relations
- `edit($id)` — Returns edit form with all relations and dropdown data
- `update(LibDigitalResourceAccessRestrictionRequest, $id)` — Updates record, logs changes
- `destroy($id)` — Soft-deletes, logs activity
- `trashed()` — Lists soft-deleted restrictions with digital resource and user eager-loaded, paginated 15
- `restore($id)` — Restores from trash, logs activity
- `forceDelete($id)` — Permanently deletes with FK exception handling (QueryException 23000)
- `toggleStatus($id)` — Toggles `is_active` boolean via AJAX, permission: `tenant.lib-digital-resource-access-restrictions.update`

---

## Who Can Access

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.lib-digital-resource-access-restrictions.*` | Full access (bypasses policy via Gate::before) |
| Library Admin | `tenant.lib-digital-resource-access-restrictions.*` | Full CRUD |
| Librarian | `tenant.lib-digital-resource-access-restrictions.viewAny`, `.view`, `.create`, `.update` | View, add, edit restrictions |
| Library Assistant | `tenant.lib-digital-resource-access-restrictions.viewAny`, `.view` | Read-only access |

---

## How This Screen Works — Logic Flow (Non-Technical)

The librarian opens the Access Restrictions tab under Library Acquisition to see a list of all rules applied to digital resources. Each row shows which digital resource is restricted, what type of restriction (Role, Designation, Department, or User), and what the restriction applies to (e.g., "Teacher" role, "Science" department). To add a new restriction, the librarian selects the digital resource first, then picks at least one target type — they can restrict by role, designation, department, specific user, or any combination. When a member later requests access to that digital resource, the system automatically checks these restrictions. If the member matches any one of the active restrictions, they are allowed through. If they don't match any, access is denied. If the resource has zero restrictions, no checks are performed and any member can request access.

---

## Validate Before Save

| # | Field | Rule | Error Message |
|---|---|---|---|
| 1 | digital_resource_id | Required, integer, exists:lib_digital_resources,id | Invalid digital resource. |
| 2 | role_id | Nullable, integer, exists:sys_roles,id | Invalid role. |
| 3 | designation_id | Nullable, integer, exists:sys_designations,id | Invalid designation. |
| 4 | department_id | Nullable, integer, exists:sys_departments,id | Invalid department. |
| 5 | user_id | Nullable, integer, exists:sys_users,id | Invalid user. |
| 6 | is_active | Boolean | Invalid value. |

**Custom After-Validation Rules:**
- At least one of role_id, designation_id, department_id, or user_id must be specified: "At least one restriction (Role, Designation, Department, or User) must be specified."
- If user_id is provided, it must be unique per digital_resource_id: "This user already has an access restriction for the selected digital resource."

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Validation fails | (per-field messages from Validate Before Save table) | 422 |
| Gate authorization fails | This action is unauthorized. | 403 |
| At least one target required | At least one restriction (Role, Designation, Department, or User) must be specified. | 422 |
| Duplicate user restriction | This user already has an access restriction for the selected digital resource. | 422 |
| Force delete — FK constraint | Cannot delete this record: it is referenced by other records. | 422 (redirect) |
| Model not found | No query results for model [LibDigitalResourceAccessRestriction] | 404 |
| AJAX toggle fails | Failed to update status. | 500 |

---

## Success Scenarios

**SC-001: Create a role-based restriction**
1. User selects digital resource "Advanced Chemistry Lab Manual", selects Role = "Teacher", leaves other target fields empty
2. System validates at least one target is provided
3. Record saved with `role_id = Teacher`, all other target fields NULL
4. Success flash: "Access restriction created successfully."
5. The restriction is now enforced — only users with the Teacher role can request access to this resource

**SC-002: Add a user-specific restriction**
1. User selects the same digital resource, selects a specific User "Dr. Smith"
2. System validates user_id is unique per digital_resource_id
3. Record saved — Dr. Smith can now access the resource regardless of role/department checks
4. Another attempt to add Dr. Smith to the same resource would fail with duplicate error

**SC-003: Toggle restriction active/inactive**
1. User clicks status switch on an existing restriction
2. AJAX request toggles `is_active`
3. Inactive restrictions are ignored by the approval logic

---

## Failure Scenarios

**FC-001: Save without specifying any target**
1. User clicks Save without selecting any role, designation, department, or user
2. FormRequest's withValidator checks all four fields are empty
3. Validation error: "At least one restriction (Role, Designation, Department, or User) must be specified."
4. Form re-displays with the error

**FC-002: Duplicate user restriction on same resource**
1. User creates a user-specific restriction for user_id=5 on digital_resource_id=10
2. User tries to create another restriction for user_id=5 on digital_resource_id=10
3. FormRequest detects existing record with same digital_resource_id+user_id
4. Validation error: "This user already has an access restriction for the selected digital resource."

---

## OR-Based Allowlist Matching Logic (from Lib_Conditions.md Section 4.9)

### Rule 1: OR-Based Allowlist (Koi Ek Match = Access Milega)
- Ek digital resource par multiple restrictions ho sakti hain.
- User ko access milta hai agar **koi bhi ek** restriction match kare.
- Check order: `user_id` → `role_id` → `designation_id` → `department_id`.
- Example: Agar resource restrictions mein `role_id=Teacher` aur `user_id=123` hai, to Teacher role wale sab users + user 123 specifically access kar sakte hain.

### Rule 2: CHECK Rule — At Least One Condition
- Har restriction row mein kam se kam ek value set honi chahiye — `user_id`, `role_id`, `designation_id`, ya `department_id`.
- Sab NULL nahi ho sakte. Kuch na kuch to restrict karo.
- Enforced by database CHECK constraint `chk_drar_at_least_one` and reinforced by `withValidator()` in FormRequest.

### Rule 3: Listing Filter Bug Fixed (Jun 17)
- **Problem (Before):** Jab system mein restrictions hain, aur user kisi restriction se match nahi karta, to ALL books dikh jaati thin (including restricted ones).
- **Fix (Now):**
  - Pehle check karo: kya restrictions exist karti hain?
  - Agar hain → sirf wahi books dikhao: (jinka koi restriction nahi) + (jin tak user ka access hai)
  - Agar nahi hain → all books dikhao.
- **Student Portal + Staff Library** — dono mein same fix applied.

### Rule 4: Access Request Par Restriction Check (GAP FIXED Jun 17)
- Jab user digital access request raise kare → `digital_resource_id` par restriction check karein.
- Agar restriction hai aur user match nahi karta → 403: "You are restricted from accessing this digital resource."
- **Student Portal + Staff Library** — dono portals mein applied.

### Rule 5: Download/View Par Restriction Check (4 Locations)
- Download aur View karne se pehle bhi same restriction check hota hai.
- **4 total check locations:**
  1. Student download (`StudentLibraryController`)
  2. Student view (`StudentLibraryController`)
  3. Staff download (`StaffLibraryController`)
  4. Staff view (`StaffLibraryController`)
- Sab jagah check hai.

### Rule 6: Unique Constraint
- Ek digital resource par ek user ke liye sirf ek user-specific restriction row.
- Enforced by UNIQUE KEY `uq_lib_drar_digRes_userId` on `(digital_resource_id, user_id)`.

### Rule 7: Auto Cleanup (CASCADE)
- Agar digital resource delete hoga to uski saari restrictions apne aap delete ho jayengi (CASCADE on delete).
- Koi orphan record nahi bachega.

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | lib_digital_resource_access_restrictions | Main restrictions table with CHECK constraint (at least one target), UNIQUE (digital_resource_id, user_id) |
| Table | lib_digital_resources | Parent resource being restricted (FK: digital_resource_id, CASCADE on delete) |
| Table | sys_roles | Role target (FK: role_id) |
| Table | sys_designations | Designation target (FK: designation_id) |
| Table | sys_departments | Department target (FK: department_id) |
| Table | sys_users | User target (FK: user_id) |
| Module | Library Digital Resources | Parent module |
| Module | Library Digital Access Requests | Enforces restrictions during approval |
| Module | Library Acquisition Hub | Parent hub containing the Access Restrictions tab |
