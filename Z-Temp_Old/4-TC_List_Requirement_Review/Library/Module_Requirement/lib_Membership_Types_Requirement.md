# Membership Types Master — Business Requirements

## What This Screen Does

The Membership Types Master screen defines the different categories of library membership available in the system — for example, "Student - Annual", "Teacher - Lifetime", "Staff - Annual", "Premium Student". Each membership type encodes the borrowing rules and privileges for that category: the maximum number of books a member can borrow simultaneously, the standard loan period in days, whether renewals are allowed and how many, a grace period before fines begin, a priority level for reservations, the number of digital access days granted, and whether restricted members can view the book list. These rules are enforced during circulation — when issuing books, processing renewals, calculating fines, and controlling digital resource access.

---

## When This Screen Is Used

- During initial library setup when defining membership categories and their borrowing rules
- When changing borrowing limits or loan periods for an existing membership type
- When adding a new membership category (e.g., "Alumni", "Premium Student")
- When configuring fine slabs that apply differently based on membership type

## Default Data Load

This screen renders as the **Membership Type** tab within the Library Masters hub (`library.mgt/masters`). When the user navigates to Library → Library Mgt → Masters and selects the Membership Type tab, `LibraryController@tabIndex` loads all membership types ordered by priority level descending (highest priority first), paginated at 15 rows per page (`membership_types_page`). Search and status filters only apply when the active tab is `membership-type`.

---

---

## Key Fields at a Glance

**Core Identity**
Each membership type has a unique business code (e.g., "STD_STUDENT", "PREMIUM_STAFF") and a display name (e.g., "Standard Student", "Premium Staff"). The code is limited to 30 characters and is globally unique.

**Borrowing Rules**
- **max_books_allowed** (min: 1) — The maximum number of books a member can have issued at any one time. Enforced during issue: if the member has reached this limit, the system shows "Reached Limit" and blocks further issues.
- **loan_period_days** (min: 1) — The standard loan duration in days. Changes to this value only affect new issues, not already-issued books.
- **renewal_allowed** (boolean) — Whether members of this type can renew borrowed books.
- **max_renewals** (min: 0) — The maximum number of times a single issue can be renewed.

**Grace and Priority**
- **grace_period_days** (min: 0) — The number of days after the due date before late fines begin accruing.
- **priority_level** (min: 0) — Determines priority for reservations and hold queues. Higher values get priority.

**Digital and Visibility Controls**
- **digital_access_days** (min: 0) — The number of days of digital resource access granted to members of this type.
- **can_restricted_members_view_list** (boolean) — If 0, members classified as "restricted" cannot view the book list in the catalog.

---

## Business Rules and Conditions

**Unique Constraints**
The `code` column has a UNIQUE constraint at the database level. No two membership types can share the same code.

**Check Constraints**
The database enforces CHECK constraints on `max_books_allowed > 0` and `loan_period_days > 0`. These values must be positive integers.

**Deletion Restrictions**
A membership type cannot be soft-deleted if it has associated members in the `lib_members` table. The system checks `$membershipType->members()->exists()` before deletion and returns an error listing up to three example member names. The user must reassign or delete those members first.

**Runtime Enforcement**
When issuing a book, the system checks `max_books_allowed` against the member's current issued count. If the limit is reached, the issue is blocked with a "Reached Limit" message. Additionally, the system checks that the user is a valid member before allowing any issue transaction.

**Soft Deletes and Restore**
All deletions are soft (`deleted_at` timestamp). Trashed records are accessible via the dedicated Trash view. Restore sets `deleted_at` to null. Force-deletion from trash catches foreign key constraint violations.

---

## Workflow Steps

**Adding a New Membership Type**
The librarian navigates to Library → Library Mgt → Masters and selects the Membership Type tab. They click "Add Membership Type". They enter a unique code and name. They set the numeric rules: maximum books allowed (e.g., 5), loan period in days (e.g., 14), whether renewal is allowed, maximum renewals (e.g., 2), grace period days (e.g., 1), priority level, digital access days, and whether restricted members can view the book list. The Active toggle defaults to ON. On Save, the system validates and persists.

**Editing a Membership Type**
The librarian clicks the Edit icon. All fields can be modified. Changes to `loan_period_days` only apply to new issues. Changes to `max_books_allowed` take effect immediately for future issues.

**Deleting a Membership Type**
If no members are assigned to this type, clicking Delete soft-deletes the record. If members exist, deletion is blocked with an error message listing example members.

---

## Example Scenario

The school introduces a new "Premium Student" membership category that allows students to borrow up to 8 books for 21 days with 3 renewals and a 2-day grace period. The librarian creates a new membership type with code "PREMIUM_STD", name "Premium Student", Max Books = 8, Loan Period = 21 days, Renewal Allowed = Yes, Max Renewals = 3, Grace Period = 2 days, Priority = 5, Digital Access = 30 days. Now when a premium student tries to borrow books, the system allows up to 8 simultaneous issues. When the library runs a fine slab config, membership type-based rules apply.

---

## Related Screens

- **Members** — Where each member is assigned a membership type
- **Fine Slab Config** — Where membership type can be used as a filter for fine slab applicability
- **Transactions (Issue/Return)** — Where borrowing rules are enforced at runtime

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibMembershipTypeController`
**Model:** `Modules\Library\Models\LibMembershipType` (table: `lib_membership_types`)
**Requests:** `LibMembershipTypeRequest` (validates create and update)
**Policy:** `LibMembershipTypePolicy` (permissions: `tenant.lib-membership-types.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`)
**Route:** Resource route `Route::resource('lib-membership-types', LibMembershipTypeController::class)` under library prefix plus restore/forceDelete/toggleStatus extras
**Tab:** `membership-type` under `library.tabIndex`

Key controller methods:
- `index()` — Redirects to `library.tabIndex` with `tab=membership-type`
- `create()` — Returns create view
- `store(LibMembershipTypeRequest)` — Creates membership type in DB transaction, logs activity
- `show($id)` — Loads membership type with members relation; logs view activity
- `edit($id)` — Returns edit view
- `update(LibMembershipTypeRequest, $id)` — Updates membership type in DB transaction; computes changed attributes for activity log
- `destroy($id)` — Checks for associated members before deletion; blocks if members exist; soft-deletes if safe
- `trashed()` — Lists soft-deleted membership types, paginated at 15
- `restore($id)` — Restores soft-deleted membership type in DB transaction
- `forceDelete($id)` — Force-deletes with `QueryException('23000')` catch for FK violations
- `toggleStatus($id)` — Toggles `is_active` boolean; uses `Gate::authorize('tenant.lib-membership-types.update')`; supports both AJAX and non-AJAX response

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|--------------|
| Super Admin | `tenant.lib-membership-types.*` | Full CRUD + restore + forceDelete |
| Librarian Admin | `tenant.lib-membership-types.*` | Full CRUD + restore + forceDelete |
| Librarian Operator | `tenant.lib-membership-types.viewAny`, `.view` | Read-only access to list and detail views |

All access is gated by `LibMembershipTypePolicy` methods which map to `tenant.lib-membership-types.*` permissions.

---

## How This Screen Works — Logic Flow (Non-Technical)

The user navigates to Library → Library Mgt → Masters and selects the Membership Type tab. The system loads all membership types sorted by priority, 15 per page. The user can search by name or code, or filter by status. To add a new type, the user clicks Add Membership Type, enters the code and name, sets the borrowing rules (max books, loan period, renewals, grace period, priority, digital access days, restricted member visibility), and saves. The system validates the code is unique and numeric values are positive. To edit, the user clicks the edit icon. To delete, the system checks if any members are assigned to this type — if yes, deletion is blocked with member names shown. Otherwise, the record is moved to trash.

---

## Validate Before Save

**Create/Update (`LibMembershipTypeRequest`):**
1. **code:** required, string, max:30, unique on `lib_membership_types.code` (ignoring self on update)
2. **name:** required, string, max:100
3. **max_books_allowed:** required, integer, min:1
4. **loan_period_days:** required, integer, min:1
5. **renewal_allowed:** boolean (default: 0 via `prepareForValidation`)
6. **max_renewals:** required, integer, min:0
7. **grace_period_days:** required, integer, min:0
8. **priority_level:** required, integer, min:0
9. **digital_access_days:** required, integer, min:0
10. **can_restricted_members_view_list:** boolean (default: 0 via `prepareForValidation`)
11. **is_active:** boolean (default: true via `prepareForValidation`)

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| Duplicate code | "This code is already taken." | 422 |
| Missing code | "Membership type code is required." | 422 |
| Missing name | "Membership type name is required." | 422 |
| Missing max books | "Maximum books allowed is required." | 422 |
| Max books below 1 | "Maximum books allowed must be at least 1." | 422 |
| Missing loan period | "Loan period is required." | 422 |
| Loan period below 1 | "Loan period must be at least 1 day." | 422 |
| Delete type with members | "Cannot delete membership type '[name]' because it has [N] associated members. Example members: [names]... Please reassign or delete these members first." | 302 (redirect back) |
| Force delete with FK dependency | "Cannot delete this record: it is referenced by other records. Remove all dependencies first." | 302 (redirect back) |

---

## Success Scenarios

- A librarian creates a "Student - Annual" membership type with code "STD_ANNUAL", max 5 books, 14-day loan period, 2 renewals, 1-day grace period. The system saves and displays "Membership type created successfully."
- A librarian updates the loan period from 14 to 21 days for "Teacher - Lifetime". The system logs the change and displays "Membership type updated successfully."
- A librarian deletes a membership type with no assigned members. The system soft-deletes and displays "Membership type moved to trash successfully."

---

## Failure Scenarios

- A librarian tries to delete "Student - Annual" which has 150 active members. The system blocks deletion and shows "Cannot delete membership type 'Student - Annual' because it has 150 associated members. Example members: Aarav Sharma, Priya Patel, Rohan Singh... Please reassign or delete these members first."
- A librarian tries to set max_books_allowed to 0. The system returns validation error "Maximum books allowed must be at least 1."
- A librarian tries to force-delete a membership type from trash that still has FK references in fine slab configs. The system catches the FK violation and shows the generic dependency error.

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Table | `lib_membership_types` | Primary table with `code VARCHAR(30) UNIQUE`, `name VARCHAR(100) NOT NULL`, CHECK constraints on `max_books_allowed > 0` and `loan_period_days > 0`, soft-deletes via `deleted_at` |
| FK Reference | `lib_members` | `membership_type_id` FK referencing `lib_membership_types.id` — restricts deletion if members exist |
| FK Reference | `lib_fine_slab_config` | `membership_type_id` FK (nullable) referencing `lib_membership_types.id` |

---

## Detailed Business Rules (from Lib_Conditions.md Section 4.7)

### 1. Mandatory Membership Check
Koi bhi book issue karne se pehle check hoga ki user registered library member hai ya nahi. Agar nahi hai to error aayega. Student Portal + Staff Portal — har jagah pehle member check hota hai.

### 2. Maximum Books Allowed (`max_books_allowed`)
- Har membership type ki ek limit hoti hai — maximum kitni books ek saath borrow kar sakta hai.
- Agar limit cross → "Reached Limit (N books)" error.
- Check: Issue karte waqt, reserve karte waqt, student aur staff dono taraf.
- **Minimum value:** 1 (enforced by DB CHECK constraint).

### 3. Loan Period (`loan_period_days`)
- Book issue karne ke baad kitne din mein return karna hai.
- Formula: `due_date = issue_date + loan_period_days`
- Renewal ke time bhi naya due_date aise hi set hota hai.
- **Changes to this value only affect new issues,** not already-issued books.
- **Minimum value:** 1 (enforced by DB CHECK constraint).

### 4. Renewal Rules (`renewal_allowed` + `max_renewals`)
- `renewal_allowed = 0` → renewal bilkul allowed nahi.
- `renewal_allowed = 1` → renewal allowed, but limited.
- `max_renewals` → maximum kitni baar renew kar sakta hai (e.g., 2).
- Renewal approval ke time bhi re-check hota hai (race condition se bachne ke liye).

### 5. Grace Period (`grace_period_days`)
- Due date ke baad kitne free days milte hain fine lagne se pehle.
- Formula: `billable_days = raw_overdue_days - grace_period_days`
- Agar grace period 3 hai aur book 5 din late return ki to sirf 2 din ka fine lagega.
- **Fine Calculation Integration:** Grace period directly affects fine calculation in the slab config system. See Step 2 of the Fine Calculation Flow (Section 3.3 of Lib_Conditions.md):
  - `raw_overdue_days = actual_return_date - due_date`
  - If `raw_overdue_days <= 0` → No fine.
  - `billable_days = raw_overdue_days - grace_period_days`
  - If `billable_days <= 0` → No fine (within grace period).
  - If `billable_days > 0` → Use `billable_days` for fine calculation.

### 6. Fine Rate (`fine_rate_per_day`) — DEPRECATED
- **⚠️ DEPRECATED.** Ab fine calculation Fine Slab Config system se hoti hai (Section 3.3 of Lib_Conditions.md).
- DB mein column hai but system use nahi karta. Fallback ke taur pe code mein hai.
- The Fine Slab Config system (`lib_fine_slab_config` + `lib_fine_slab_details`) provides:
  - Multiple rate types: Fixed per day/week/month/year/book, or Percentage of book cost.
  - Day range slabs (e.g., 1-7 days at ₹2/day, 8-30 days at ₹5/day).
  - Maximum fine cap (Fixed amount, BookCost, or Unlimited).
  - Priority-based slab matching with membership type and resource type filters.

### 7. Priority in Queue (`priority_level`)
- Jab koi book return hoti hai aur multiple pending reservations hain — konsa member pehle book lega?
- **Order:** (1) Sabse high priority level wala, (2) Phir sabse pehle reservation karne wala (FIFO).
- Example: Premium Staff (priority 10) ko Student (priority 1) se pehle milega.
- **Reservation Queue Logic:**
  - Sort: `priority_level DESC` (membership type) → `request_date ASC` (FIFO).
  - Example:
    - Member A (priority 10) requested 10 May
    - Member B (priority 1) requested 10 May
    - Member C (priority 10) requested 12 May
    - Order: A → C → B (priority 10 wale pehle, dono 10 May ko aaye to FIFO, phir priority 1)

### 8. Digital Access Duration (`digital_access_days`)
- Digital resource access approve hone ke baad kitne din access rahega.
- `0` = digital access nahi milega is type ke members ko.
- Applicable for digital resource transactions and access request approvals.
- **Note:** `digital_access_days` column exists in DDL but code mein sirf digital resource flow mein use hota hai, physical issue flow mein nahi.

### 9. Restricted Members View Permission (`can_restricted_members_view_list`)
- `0` → Restricted members ko book list nahi dikhegi. Catalog empty show hoga.
- `1` → Catalog visible hai, but baaki actions limited hain.
- Ye tabhi relevant hai jab membership type restrict ho.

### 10. Active/Inactive
- Sirf active membership types hi assign ho sakte hain.
- Inactive types are hidden from dropdowns in member create/edit forms.
- Existing members with inactive types retain their type reference but no new members can be assigned.

### Fine Calculation Integration (Grace Period + Membership Type)

The membership type's `grace_period_days` and `loan_period_days` indirectly affect fine calculation:

**Step 1: Slab Filter** — `lib_membership_types.membership_type_id` acts as a slab filter only in `lib_fine_slab_config`. It does NOT change the calculation formula.

**Step 2: Due Date Calculation** — `due_date = issue_date + loan_period_days` (from membership type). Stored in `lib_transactions.due_date`.

**Step 3: Grace Period Application** — `billable_days = raw_overdue_days - grace_period_days` (from membership type). If `billable_days <= 0`, no fine applies.

**Step 4: Fine Amount** — Calculated based on the matched fine slab detail row's `fine_rate`, `rate_type`, and `calculation_type`, applied against `billable_days`.
