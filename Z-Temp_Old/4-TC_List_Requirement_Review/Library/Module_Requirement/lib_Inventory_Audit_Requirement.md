# Lib Inventory Audit — Business Requirements

## What This Screen Does

The Inventory Audit screen manages physical shelf-verification sessions where librarians reconcile the library's digital records against actual books on the shelves. Each audit session tracks the total expected copies (count of active copies in the system), total scanned copies, and the number of missing, misplaced, and damaged copies discovered during the audit. The audit follows a state-machine lifecycle: it starts In Progress, can be completed (which applies scanned location/condition updates to book copies) or cancelled.

This screen is a tab within the Library History & Audit hub. Beyond standard CRUD, it provides dedicated workflows: initialize (creates an audit with today's date and zero counts), scan (the main barcode-scanning interface), quickCreate (one-click audit creation), markCompleted (completes audit and updates copy locations/conditions from scan data), cancel, and changeStatus (AJAX status transition). The store and update methods accept a nested `details` array for bulk-adding scanned records. Audit summary counts are auto-calculated from the detail records.

---

## When This Screen Is Used

- When performing annual or monthly physical shelf verification of the entire collection
- When investigating reported book losses by running a targeted audit on a section
- When reconciling barcode scan data against the library management system
- When updating shelf locations and conditions of copies based on physical findings
- When generating audit reports showing matched, missing, misplaced, and damaged counts

## Default Data Load

The Inventory Audit screen opens as a tab within the Library History & Audit hub (`library.historyIndex` with `tab=inventory-audit`). The controller's `index()` method (which also loads other hub data) paginates audits at 15 per page with the `performedBy` relation. The create form loads active users, copies (with book), locations, and conditions. The scan view loads the full audit with all details, shelf locations, conditions, and scan statuses.

---

## Key Fields at a Glance

**Core Identity**
Each audit has a UUID (generated via `Str::uuid()`) for external reference, an audit date (DATE) for when the physical verification was performed, and a performed-by link (FK to `sys_users.id`) identifying the librarian who conducted it.

**Counts and Results**
The total expected count (`total_expected`) is the number of active book copies in the system at audit time. The total scanned count (`total_scanned`) increments as barcodes are scanned. Three issue counters track discovered problems: `missing_copies` (copies not found on shelf), `misplaced_copies` (found at wrong location), and `damaged_copies` (found in damaged condition).

**Status Lifecycle**
The `status` FK points to `lib_library_status_masters` where `status_type = 'Inventory Audit Status'`. Valid statuses: `In Progress` (initial state), `Completed` (finalized with location/condition updates applied), `Cancelled` (abandoned mid-audit). `completed_at` records the timestamp of completion.

---

## Business Rules and Conditions

**Status Transition Control**
The `markCompleted()` method checks that the audit is currently In Progress before allowing completion. Only in-progress audits can be completed or cancelled. The `cancel()` method also checks this precondition. Both return flash errors if violated.

**Completion Applies Physical Findings**
When `markCompleted()` is called, the system iterates every scanned detail record and updates the corresponding `LibBookCopy` record:
- If `actual_location_id` is set → `shelf_location_id` is updated
- If `condition_id` is set → `current_condition_id` is updated
The updates use `updateQuietly()` to avoid triggering unnecessary events.

**Auto-Count Recalculation**
The `recalculateAuditCounts()` private method (shared by `LibInventoryAuditDetailController`) recalculates total_scanned, missing_copies, misplaced_copies, and damaged_copies by querying the detail records with their status IDs. This is called after every detail create, update, or delete.

**Validation Cross-Checks**
The `LibInventoryAuditRequest` includes after-validation logic that checks:
- `total_scanned` must not exceed `total_expected`
- Sum of misplaced + damaged must not exceed total_scanned
- Detail count must match total_scanned
- Summary counts (missing/misplaced/damaged) must match the counts derived from individual detail statuses

**Uniqueness per Copy**
The `lib_inventory_audit_details` table has a unique constraint on `(audit_id, copy_id)`, ensuring each copy can only appear once per audit session.

---

## Workflow Steps

1. Navigate to Library → History & Audit → Inventory Audit tab
2. View existing audits with their status, dates, and summary counts
3. Click "New Audit" to begin a session — enter audit date and assign the performing staff member
4. Optionally use "Quick Create" for a one-click audit with today's date
5. Click "Continue" on an In Progress audit to open the scanning interface
6. Scan book barcodes using a handheld scanner — each scan adds a detail record
7. For each scan, the system shows expected vs actual location and allows setting condition and scan status (Found, Missing, Misplaced, Damaged)
8. Click "Complete Audit" to finalize — system applies location and condition updates to all scanned copies
9. View completed audit results with counts of matched, missing, misplaced, and damaged copies
10. Cancel an In Progress audit if needed (keeps detail data but marks cancelled)

---

## Example Scenario

It's the end of the academic year and the librarian initiates an annual stock verification. They click "Quick Create" which creates an audit for today dated July 24, 2026. The system calculates total expected as 5,234 active copies. The librarian takes a barcode scanner to the shelves and scans each book over three days. For each scan, they note if the book is at the correct shelf location and assess its condition. After scanning 5,100 copies, they notice 134 copies are unaccounted for. They complete the audit: the system marks them as missing, updates the locations of 45 copies that were misplaced, and flags 12 damaged copies that need repair. The summary shows: 5,100 scanned, 4,909 found correctly, 134 missing, 45 misplaced, 12 damaged.

---

## Related Screens

- Inventory Audit Details — individual scan records within each audit
- Book Copies — copy records that are updated when audit is completed
- Shelf Locations — expected vs actual location comparison
- Book Conditions — condition assessment during scanning
- Library History & Audit Hub — parent tab container

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibInventoryAuditController`
**Model:** `Modules\Library\Models\LibInventoryAudit` (table: `lib_inventory_audit`, uses `SoftDeletes`)
**Requests:** `LibInventoryAuditRequest` (validates header + details array with cross-field and cross-detail validation)
**Policy:** Named permission string `tenant.lib-inventory-audit.*`
**Route:** Resource route `Route::resource('lib-inventory-audit', LibInventoryAuditController::class)` with extras: `trashed`, `restore`, `forceDelete`, `quickCreate`, `scan`, `markCompleted`, `cancel`, `changeStatus`, `initialize`, `complete`, `storeWithDetails`, `checkCopy`, `getAuditData`, `getBookDetails`

Key controller methods:
- `index()` — Loads hub data with audits paginated (15 per page)
- `create()` — Returns create form with users, copies, locations, conditions, totalExpected count
- `store(LibInventoryAuditRequest)` — Creates audit with UUID and nested details; supports JSON response
- `show($id)` — Loads with performedBy, details (copy.book, expectedLocation, actualLocation, condition)
- `edit($id)` — Loads for editing with users, totalExpected, auditStatuses
- `update(Request, $id)` — Updates header and handles details CRUD (create/update/delete) within a single transaction; recalculates counts
- `destroy($id)` — Soft-deletes
- `trashed()` — Lists soft-deleted audits with performedBy
- `restore($id)` — Restores from trash
- `forceDelete($id)` — Force-deletes with FK exception catching
- `markCompleted($id)` — Validates In Progress status; updates copy locations/conditions from details; calls `$audit->markCompleted()`
- `cancel($id)` — Validates In Progress status; calls `$audit->cancel()`
- `changeStatus(Request, $id)` — AJAX endpoint for status transitions; handles completed_at timestamp logic
- `initialize(Request)` — API-style audit creation with validation
- `complete(Request)` — API-style audit finalization with bulk detail creation
- `quickCreate(Request)` — One-click audit with today's date and auto-calculated total_expected
- `scan($id)` — Full scan page view with locations, conditions, and statuses
- `checkCopy($identifier)` — Finds copy by barcode/accession/rfid for real-time validation
- `getAuditData($id)` — JSON endpoint returning full audit with details
- `getBookDetails(Request, $identifier)` — Rich copy details for scanning modal
- `storeWithDetails(Request)` — Creates audit with details in a single request

**Model Helpers:** `markCompleted()` sets status to completed + completed_at; `cancel()` sets status to cancelled

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|-------------|
| Super Admin | `tenant.lib-inventory-audit.*` | Full access (bypasses policy via Gate::before) |
| Library Admin | `tenant.lib-inventory-audit.*` | Create, scan, complete, cancel audits; view results |
| Librarian | `tenant.lib-inventory-audit.create`, `.view`, `.update` | Create and scan during audit; view results |
| Library Assistant | `tenant.lib-inventory-audit.viewAny`, `.view` | View audit results only |

---

## How This Screen Works — Logic Flow (Non-Technical)

The librarian opens the History & Audit section and selects the Inventory Audit tab. They click "New Audit" or "Quick Create" to start a verification session. The system records who is conducting the audit and automatically notes the total number of book copies that should exist. The librarian then goes to the shelves with a barcode scanner and opens the audit's scanning page. Each time they scan a barcode, the system looks up the copy, shows where it's supposed to be located and its expected condition, and lets the librarian confirm whether the book is found, missing, misplaced, or damaged. If the location or condition differs from what's on record, the librarian can update it right there. When all shelves have been checked, the librarian clicks "Complete Audit" — the system applies all the location and condition updates to the actual copy records, locking in the audit results for reporting.

---

## Validate Before Save

| # | Field | Rule | Error Message |
|---|-------|------|---------------|
| 1 | audit_date | Required, Date | Audit date is required. |
| 2 | performed_by_id | Required, Exists:sys_users,id | Please select who performed the audit. |
| 3 | total_scanned | Required, Integer, Min:0 | Total scanned count is required. |
| 4 | total_expected | Required, Integer, Min:0 | Total expected count is required. |
| 5 | missing_copies | Nullable, Integer, Min:0 | Missing copies cannot be negative. |
| 6 | misplaced_copies | Nullable, Integer, Min:0 | Misplaced copies cannot be negative. |
| 7 | damaged_copies | Nullable, Integer, Min:0 | Damaged copies cannot be negative. |
| 8 | notes | Nullable, String, Max:1000 | Notes cannot exceed 1000 characters. |
| 9 | status (update) | Required (on PUT/PATCH), In:In_Progress,Completed,Cancelled | Invalid status selected. |
| 10 | details.*.copy_id | Required with details, Exists:lib_book_copies,id | Book copy is required for each detail row. |
| 11 | details.*.status | Required with details, In:Found,Missing,Misplaced,Damaged | Invalid status selected for detail row. |

Cross-field validation (after hook):
- total_scanned must not exceed total_expected
- Sum of misplaced + damaged must not exceed total_scanned
- Number of details must match total_scanned
- Summary counts must match detail-level status counts

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| Validation fails | (per-field messages from Validate Before Save table) | 422 |
| Gate authorization fails | This action is unauthorized. | 403 |
| Model not found | No query results for model | 404 |
| Total scanned exceeds expected | Total scanned cannot be greater than total expected (N). | 422 |
| Issue count exceeds scanned | Misplaced + Damaged copies (N) cannot exceed total scanned (M). | 422 |
| Detail count mismatch | Number of details (N) does not match total scanned (M). | 422 |
| Count mismatch — missing | Missing copies count (N) does not match details (M). | 422 |
| Mark completed on non-in-progress | Only in-progress audits can be marked as completed. | 422 (redirect) |
| Cancel on non-in-progress | Only in-progress audits can be cancelled. | 422 (redirect) |
| Force delete — FK constraint | Cannot delete this record: it is referenced by other records. Remove all dependencies first. | 422 (redirect) |
| Store/update exception | Failed to create/update audit: [detail] | 500 / 422 |
| QuickCreate status not found | System config: "in_progress" status not found for Inventory Audit. | 422 (redirect) |

---

## Success Scenarios

**SC-001: Full audit lifecycle — create, scan, complete**
1. Librarian clicks "Quick Create" — audit created for today, 5,234 total expected
2. Librarian opens scan page, scans 150 barcodes — each scan verified with location and condition
3. Among 150 scans: 145 Found, 3 Missing, 1 Misplaced, 1 Damaged
4. Librarian clicks "Complete Audit" — system updates locations for the misplaced copy and condition for the damaged copy
5. Summary shows: 150 scanned, 145 matched, 3 missing, 1 misplaced, 1 damaged
6. Flash success: "Audit completed and 150 copies updated."

**SC-002: Cancel an in-progress audit**
1. Librarian starts an audit but realizes the barcode scanner is malfunctioning after 20 scans
2. Clicks "Cancel" — system validates In Progress status, cancels the audit
3. Flash success: "Audit cancelled."
4. Audit status = Cancelled; 20 detail records remain visible for reference

---

## Failure Scenarios

**FC-001: Complete an already completed audit**
1. Librarian navigates to a previously completed audit and clicks "Mark Complete"
2. Controller checks `$audit->status !== $inProgressId` → true
3. Flash error: "Only in-progress audits can be marked as completed."
4. No changes made to audit or copies

**FC-002: Store audit with count mismatch**
1. Librarian enters total_scanned = 100 but only provides 95 detail records
2. LibInventoryAuditRequest after-validation detects mismatch
3. Validation error: "Number of details (95) does not match total scanned (100)."
4. Form re-displays with error; librarian must correct counts or details

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Table | lib_inventory_audit | Main audit table with UUID, audit_date, performed_by_id (FK sys_users.id), summary counters, status (FK lib_library_status_masters.id), completed_at |
| Table | lib_inventory_audit_details | Child table with audit_id (CASCADE), copy_id (FK lib_book_copies.id), expected_location_id, actual_location_id, condition_id, scanned_at, status; unique (audit_id, copy_id) |
| Table | lib_book_copies | Copy records updated on audit completion (shelf_location_id, current_condition_id) |
| Table | lib_shelf_locations | FK for expected and actual location comparison |
| Table | lib_book_conditions | FK for condition assessment during scanning |
| Table | lib_library_status_masters | Statuses for both audit (Inventory Audit Status) and details (Inventory Audit Detail Status) |
| Module | Library Book Copies | Consumer of audit results — locations and conditions updated on completion |
