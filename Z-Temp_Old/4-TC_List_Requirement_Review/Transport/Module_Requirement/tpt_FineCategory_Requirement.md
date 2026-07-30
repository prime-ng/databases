# Fine Category — Business Requirements

## What This Screen Does

Fine Category defines the types of fines that can be applied to students for transport-related issues — for example, "Transport Late Fee", "Bus Misconduct", or "Property Damage". Each category specifies which department has the authority to issue that type of fine (Transport department or Finance department) and whether supporting evidence such as a photo or written document must be attached.

Without these categories, every fine would be entered as a plain text description, making it impossible to run reports like "How much late fee was collected this month?" or "How many misconduct incidents occurred on the buses this term?" The categories provide the structure needed for accurate financial tracking and disciplinary record-keeping.

The screen appears in two places:
1. **Transport Master → Fine Category tab** — Shows a list of all fine categories, sorted with the most recently added ones first.
2. **Dedicated Fine Category pages** — Create, Edit, Show, and Trash views are accessed as standalone pages via the main menu.

---

## Default Data Load

When the Transport Manager opens Transport Master and clicks the Fine Category tab, the system fetches all fine categories from the database and displays them in a list, showing the most recently added ones first, 20 categories per page. The view includes a search box and a status (Active/Inactive/All) filter UI, **but the controller does not process them** — the search and filter inputs are rendered but have no effect on the query. The manager sees every category with no way to narrow the list. For a school with many fine categories, this can be inconvenient.

---

## When This Screen Is Used

- **Setting Up Fine Categories at the Start of the Academic Year** — It is April, and Green Valley School is preparing for the new academic year. Mrs. Desai, the Transport Manager, needs to set up the fine categories for the coming year. She creates categories like "Transport Late Fee" (for students who do not pay their transport fees on time), "Bus Misconduct" (for students who misbehave on the bus), and "Property Damage" (for students who damage bus seats or windows). Each category specifies who can issue the fine and whether proof is needed. These categories will be used throughout the year every time a fine is issued.

- **Issuing a Fine for Late Transport Fee Payment** — In July, a student named Aarav has not paid his transport fee for two months. The accounts department needs to issue a late fee fine. The clerk opens the Fine Issuance screen and selects "Transport Late Fee" from the category list — a category that Mrs. Desai created in April. The clerk enters the fine amount of ₹500 (as defined in the Fine Master rules for this category) and issues the fine. Without this category, the clerk would have to type "Late Fee" as free text, making it impossible to later run a report like "How much late fee was collected in July?"

- **Recording a Bus Misconduct Incident** — In September, a group of students on Bus 5 are caught throwing food packets out of the window. The Transport Manager issues a fine of ₹200 per student under the "Bus Misconduct" category. The category requires evidence, so Mrs. Desai attaches a photo of the mess as proof. The category ensures that this incident is recorded under the right type and can be tracked separately from late fees or damage fines.

- **Processing a Property Damage Fine for a Broken Window** — A student accidentally breaks a bus window with their school bag. The Transport Manager issues a fine of ₹1,500 under the "Property Damage" category. This category requires photographic evidence, so the manager takes a photo of the broken window and attaches it to the fine record. The category keeps property damage incidents separate from misconduct or late fees, making it easy to run end-of-term reports on how many damage incidents occurred and how much was collected in damages.

---

## Key Fields at a Glance

**Category Name**
A short label describing the fine reason, such as "Transport Late Fee" or "Bus Misconduct." This is the name that appears in all fine-related dropdowns and reports, so it must be descriptive enough for staff to select the correct category without confusion.

**Initiating Department**
Every fine category specifies which department has the authority to issue fines of this type: Transport (the transport manager can issue it directly) or Finance (only the finance department can initiate it). This controls who sees the "Issue Fine" button in the user interface.

**Evidence Requirement**
A boolean flag determines whether proof — a photo, a written document, or both — must be attached when issuing a fine under this category. For example, "Property Damage" might require a photo of the damage, while "Late Fee" might not require any evidence.

**Active Status**
A simple on-off switch allows disabling a fine category without deleting it, preserving historical fine records that reference it.

---

## Business Rules and Conditions

**A Category Cannot Be Deleted If Fines Have Been Issued Under It (🔴 Gap — Not Implemented)**
If a fine category such as "Transport Late Fee" already has fines issued against it (for example, 15 students were fined ₹200 each under this category), the system **should** block the deletion. However, the `destroy()` method does **not** check the `fineMasters()` relationship. The manager can soft-delete a category that is actively referenced by fine slabs, which would break fine issuance dropdowns and reports. This is a gap the code does not implement.

**Search and Status Filter UI Exists but Controller Ignores Filters (GAP)**
The Fine Category list view (`index.blade.php`) renders a search input and a status (Active/Inactive/All) dropdown, but the controller's `index()` method does not apply any `->when()` conditions for `search` or `status`. Every record is returned regardless of filter input. For a school that has created 20 or more categories over several years, finding a specific one means clicking through multiple pages with non-functional filter controls. Every other master screen in the Transport module processes its filters correctly, making this a noticeable backend gap.

**Missing Cascade Check Before Deletion (GAP)**
The `destroy()` method does not check whether the category has related fine master records (`fineMasters()` relationship) before allowing soft-deletion. The requirement states "A category cannot be deleted if fines have been issued under it," but the controller calls `$record->delete()` unconditionally. The manager can soft-delete a category that is actively referenced by fine slabs, which would break fine issuance dropdowns and reports.

**Missing `is_active = false` Before Soft-Delete (GAP)**
The `destroy()` method soft-deletes the record without first setting `is_active = false`. The standard CRUD pattern requires both steps. While the soft-delete effectively hides the record from active queries, the `is_active` column remains `true` on the soft-deleted row, causing inconsistency in queries that check both `deleted_at IS NULL` and `is_active = 1`.

**Activity Log Missing `performed_by` (GAP)**
All `activityLog()` calls in the controller (`Created`, `Updated`, `Trashed`, `Restored`, `Force Deleted`, `Toggled`) do not include `'performed_by' => Auth::user()->name` or `'changes'` tracking for updates. The requirement states "All changes are recorded in the system's activity log: who made the change, what they changed, and when it happened." The `performed_by` and change-detail data are missing across all methods.

---

## Workflow Steps

**Creating a New Fine Category for the New Academic Year — Mrs. Desai's Planning**
It is March, and Mrs. Desai is preparing the transport fee structure for the next academic year at Green Valley School. She opens the Fine Category screen and clicks "Add Category." The system presents a simple form with three fields. She enters the category name as "Transport Late Fee — Term 1." She selects "Finance" as the initiating department because the accounts team will issue late fee fines, not the transport team. She leaves the evidence requirement set to "No" because late fee fines are based on payment records that already exist in the system — no photo or document is needed. She clicks Save. The category now appears in the list and is available for selection in the Fine Master screen where the actual fine amounts and day ranges will be defined.

**Defining a Misconduct Category That Requires Photo Evidence**
In April, after a few incidents of students eating on the bus and leaving crumbs everywhere, Mrs. Desai decides to create a "Bus Misconduct" category. This time, she selects "Transport" as the initiating department (the transport team will handle misconduct fines directly) and sets evidence requirement to "Yes." She wants to ensure that every misconduct fine has a photo attached — proof of the mess or the behaviour. She saves the category. Now, whenever a driver reports misconduct, Mrs. Desai can issue a fine and must attach a photo before the system accepts it.

**Deactivating an Old Category That Is No Longer Used**
The school used to have a "Bus Late Arrival" fine category from two years ago, but the policy has changed and this type of fine is no longer issued. Mrs. Desai opens the category record and marks it as inactive. The category disappears from the active list but remains in the system — all historical fines that were issued under this category are preserved for audit purposes. If the school ever reinstates this policy, Mrs. Desai can simply reactivate the category instead of creating it from scratch.

---

## Example Scenario — Green Valley School Sets Up Late Fee Fines for the New Year

Green Valley School has 1,200 students, of whom 350 use the school's transport service across 12 buses. Every year, the school struggles with parents who pay transport fees late, sometimes by months. The management decides to implement a structured late fee system for the new academic year starting in April.

Mrs. Desai, the Transport Manager, begins by setting up the fine categories. She opens the Transport Master, clicks the Fine Category tab, and presses "Add Category." She creates the first category: name "Transport Late Fee — 15 Days," initiated by Finance (because the accounts department will track and issue these fines), evidence not required (the payment records speak for themselves). She creates a second category: "Transport Late Fee — 30 Days" for more severe delays, again initiated by Finance with no evidence needed. She creates a third category: "Bus Misconduct," this time initiated by Transport with evidence required, because she wants photographic proof whenever a student misbehaves.

Each category now appears in the Fine Category list. Mrs. Desai moves to the Fine Master screen to define the actual fine amounts. For "Transport Late Fee — 15 Days," she sets a rule: if a student's fee is 1 to 15 days late, the fine is ₹200. For "Transport Late Fee — 30 Days," she sets 16 to 30 days late → ₹500 fine plus restriction from boarding the bus until the fee is cleared.

Two months into the term, a parent has still not paid the transport fee for their child, Priya, who is now 22 days late. The accounts clerk opens the fine issuance screen, selects "Transport Late Fee — 30 Days," and the system automatically calculates the fine as ₹500. The clerk issues the fine, and a notification goes to the parent. Because the categories were set up properly, the school can now run a report at the end of the month showing exactly how much late fee was collected: ₹3,200 from 16 late-paying parents.

---

## Related Screens

- **Fine Master** — Where actual fine calculation rules reference these categories.

---

## Requirements

- Every action on this screen — creating a category, editing it, deleting it, restoring it, or changing its status — is protected by permission checks. Only staff members with the appropriate role can perform these actions.
- All changes are recorded in the system's activity log: who made the change, what they changed, and when it happened. Note: `performed_by` and attribute-level `changes` are not recorded (🔴 Gap).

---

## Who Can Access

- **Transport Manager** — Has full control over fine categories. They can create new categories at the start of the academic year, edit existing ones if policies change, mark categories as inactive when they are no longer needed, delete categories that have never been used, restore accidentally deleted categories, and permanently remove test entries. This is the primary person who manages this screen.

- **Finance Manager** — Can view all fine categories and their details, but cannot create, edit, or delete them. The Finance Manager works with fine categories indirectly when issuing fines through the Fine Issuance screen — they select from the categories that the Transport Manager has already created.

- **Accounts Clerk** — Can view the fine category list to see which categories are available for fine issuance. They select the appropriate category when issuing fines to parents but cannot modify the categories themselves.

- **School Administrator** — Has read-only access to the fine category list. They can see what categories exist and how they are configured but cannot make any changes.

- **Driver or Helper** — Does not have access to this screen. Drivers and helpers report incidents to the Transport Manager, who then issues fines using the appropriate category.

Behind the scenes, each action is protected by a permission check. If a user tries to perform an action they are not authorised for, the system displays an "Access Denied" message.

---

## Logic Flow

When the Transport Manager opens Transport Master and clicks the Fine Category tab, the system fetches all fine categories from the database and displays them in a simple table, 20 categories per page, ordered from newest to oldest. The search box and status filter are rendered in the UI but the controller does not apply them — the manager sees every category with no way to narrow the list. This is different from other Transport screens which all process their search and filter options correctly.

When the manager clicks "Add Category," the system presents a simple form with a few fields: the category name (for example, "Transport Late Fee"), the department that will issue fines under this category (Transport or Finance), and whether evidence such as a photo or document is required. The manager fills in these details and clicks Save.

Before saving, the system checks that the category name is not empty, that a valid department has been selected, and that the evidence requirement is set to Yes or No. If anything is wrong, the form displays an error message and refuses to save.

If everything is correct, the system creates the category, records the action in the activity log, and returns to the category list with a green success message. **Note: the activity log entry does not include `performed_by` (the manager's name)** — this is missing across all controller methods (🔴 Gap). The new category now appears in the list and is available for selection in the Fine Master screen where actual fine amounts and rules are defined.

When the manager clicks Edit on an existing category, the form loads with the current values pre-filled. The manager can change the category name, switch the initiating department, or change whether evidence is required and toggle the active status. The system logs that the category was updated, but does **not** log `performed_by` or detailed attribute-level `changes` (🔴 Gap).

When the manager deletes a category, the system soft-deletes it immediately **without checking** whether any fine rules have been defined for this category in the Fine Master screen. The `destroy()` method does not query the `fineMasters()` relationship before allowing deletion. This means a category with active fine slabs can be removed from the active list, which would break Fine Master dropdowns and reports. The manager must manually ensure no fine rules reference the category before deleting it. (🔴 Gap — cascade check is missing.)

For permanent deletion, the manager switches to the Trash view. The `forceDelete()` method correctly uses the `tenant.fine-category.forceDelete` permission check, and the `trashed()` method correctly requires the `tenant.fine-category.restore` permission. Both permissions are properly enforced — no mismatch exists in the current code.

---

## Validate Before Save — What the System Checks Before Creating a Fine Category

| Field in the Form | What the System Checks | Error Message If Wrong |
|-------------------|----------------------|------------------------|
| Category Name | Must be provided, up to 100 characters. Should clearly describe the fine type, such as "Transport Late Fee" or "Bus Misconduct". | "Please enter a category name." |
| Initiating Department | Must be selected as either Transport or Finance. This controls which department can issue fines under this category. | "Please select a department." |
| Evidence Required | Must be set to Yes or No. If Yes, a photo or document must be attached whenever a fine of this type is issued. | "Please specify whether evidence is required." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Category name left blank | "Please enter a category name." — The form does not submit. | Data entry error — prevented before saving |
| No department selected | "Please select a department." — The form does not submit. | Data entry error — prevented before saving |
| User tries to delete a category that has fines issued under it | **This check is NOT implemented.** The system soft-deletes the category without checking `fineMasters()` relationship. The deletion succeeds even when fine slabs refer to this category. | 🔴 Gap — Business rule not enforced |
| User tries to create or edit a category without authorisation | The system displays an "Access Denied" message and blocks the action. | Permission error — system blocks the action |
| Category is accidentally soft-deleted but has historical fine records | The deletion succeeds (soft delete) without checking for active fine rules. The category disappears from the Fine Master dropdown, so no new fines can be issued under it. The manager must restore the category from Trash if it was deleted by mistake. | 🔴 Gap — No cascade check before deletion |

## Success Scenarios — When Everything Works

**SC-001 — Creating Fine Categories for the New Academic Year**
At the start of the academic year in April, Mrs. Desai creates three fine categories: "Transport Late Fee — 15 Days" (initiated by Finance, no evidence needed), "Bus Misconduct" (initiated by Transport, evidence required), and "Property Damage" (initiated by Transport, evidence required). All three are saved successfully and appear in the Fine Category list. The activity log records each creation. **Note: the activity log does not currently include `performed_by` (Mrs. Desai's name) — gap documented above.** The categories are now available for selection in the Fine Master screen.

**SC-002 — Updating a Category When Policy Changes**
In July, the school management decides that late fee fines should now be handled by the Transport department instead of Finance. Mrs. Desai opens the "Transport Late Fee — 15 Days" category, changes the initiating department from Finance to Transport, and saves. **Note: the system does not currently log attribute-level changes (e.g., "Initiating department changed from Finance to Transport") — only a generic "Fine category updated." message is recorded, and `performed_by` is missing (gaps documented above).** All future fines under this category will now be issued by the Transport team.

**SC-003 — Deactivating an Obsolete Category Without Losing Historical Data**
The school discontinues the "Bus Late Arrival" fine policy after two years. Mrs. Desai opens the category and marks it as inactive. The category disappears from active lists but remains in the system. All 23 fines that were issued under this category over the past two years remain intact and accessible in reports. Six months later, when the policy is reinstated, Mrs. Desai reactivates the category with a single click — all the original settings are preserved.

## Failure Scenarios — What Could Go Wrong

**FC-001 — Category Deleted While Still Referenced by Active Fine Rules (🔴 Gap — No Cascade Check)**
Mrs. Desai attempts to delete the "Transport Late Fee — 15 Days" category, forgetting that 12 fine slabs have been defined under it in the Fine Master screen (for example, "1–5 days → ₹100, 6–10 days → ₹200, 11–15 days → ₹300"). The system does **not** check for related fine masters — it soft-deletes the category immediately. The next time a staff member opens the Fine Issuance screen, the "Transport Late Fee — 15 Days" option is missing from the category dropdown, even though 12 fine slabs still reference it. Reports that join on `tpt_fine_category` may return incomplete or inconsistent results. Mrs. Desai must restore the category from Trash, navigate to Fine Master, delete all 12 slabs, and then delete the category again. The system does not offer any warning or guidance about existing dependencies.

**FC-002 — Search/Filter UI Rendered but Non-Functional (🔴 Gap — Backend Not Connected)**
Mrs. Desai types "Late Fee" into the search box and selects "Active" from the status filter, expecting to see only active late-fee categories. The page reloads with the filter parameters in the URL, but the controller's `index()` method ignores them entirely — all categories are returned regardless of search or status input. Mrs. Desai sees the full list and assumes no matching categories exist. She may create duplicate categories, not realising the filter is broken. This also means the pagination, which does append the tab parameter, carries non-functional filter parameters in every page link.

**FC-003 — Evidence Requirement Not Enforced When Issuing Fines**
Mrs. Desai creates a "Property Damage" category with evidence requirement set to "Yes." However, when she issues a fine under this category through the Fine Issuance screen, the system accepts the fine even without attaching a photo. The evidence requirement flag was stored correctly in the category record, but the Fine Issuance screen does not actually check it before saving — it only displays the field as optional. Mrs. Desai only discovers this gap three months later when she tries to run a report on property damage incidents and finds that 8 out of 12 fines have no photo attached, making it impossible to verify the claims.

## Table: `tpt_fine_category`

| Column | Type | Details |
|--------|------|---------|
| id | TINYINT UNSIGNED PK | Auto-increment |
| category_name | VARCHAR(100) NOT NULL | Fine reason |
| initiated_by | ENUM('Transport','Finance') | Who initiates |
| evidence_required | TINYINT(1) DEFAULT 0 | Proof required? |
| is_active | TINYINT(1) DEFAULT 1 | — |
| created_at | TIMESTAMP | — |
| updated_at | TIMESTAMP | — |
| deleted_at | TIMESTAMP NULL | Soft deletes |
