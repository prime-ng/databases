# Lib Inventory Audit Details — Business Requirements

## What This Screen Does

The Inventory Audit Details screen manages individual scan records within an inventory audit. When the librarian scans a book barcode during a physical shelf-verification session, each scan creates a detail record linked to the parent audit. This screen shows what copy was scanned, its expected vs actual shelf location, its condition at scan time, and the scan status (Found, Missing, Misplaced, Damaged).

This screen is a tab within the Library History & Audit hub. Beyond standard CRUD (create, edit, show, trash), it provides dedicated AJAX workflows: `storeScan` (single barcode scan from the scan page), `deleteScan` (removes a scan and recalculates audit counts), `bulkStore` (batch-import multiple detail records), and `byAudit` (lists all details for a specific audit in a filtered view). Every create/update/delete triggers `recalculateAuditCounts()` to keep the parent audit summary in sync.

---

## When This Screen Is Used

- When scanning book barcodes during a physical inventory audit
- When reviewing which books were found, missing, misplaced, or damaged during an audit
- When correcting a scan entry (updating location, condition, or status)
- When removing an incorrect scan from an audit
- When bulk-importing scan data from a handheld scanner or spreadsheet
- When viewing the full scan log for a completed audit

## Default Data Load

The Inventory Audit Details index is a tab within the Library History & Audit hub (`library.historyIndex` with `tab=inventory-audit-detail`). The controller's `index()` method paginates details at 15 per page with the `audit`, `copy.book`, `expectedLocation`, `actualLocation`, and `condition` relations. Filters are available by `audit_id` and `status`. The create form loads only in-progress audits, active copies (with book), active locations, active conditions, and active detail statuses.

---

## Key Fields at a Glance

**Parent Link**
Each detail belongs to exactly one audit via `audit_id` (FK to `lib_inventory_audit.id`, CASCADE on delete). The `copy_id` FK links to the scanned book copy.

**Location Comparison**
The `expected_location_id` is auto-populated from the copy's `shelf_location_id` at scan time. The `actual_location_id` is set by the librarian during scanning — mismatch between the two flags a misplaced book.

**Condition & Status**
`condition_id` records the book's physical condition at scan time. The `status` field is an FK to `lib_library_status_masters` where `status_type = 'Inventory Audit Detail Status'`. Four detail-level statuses exist: `Found` (book at expected location, good condition), `Missing` (not found on shelf), `Misplaced` (found at wrong location), `Damaged` (found but in damaged condition).

**Scan Metadata**
`scanned_at` records the datetime of the scan with millisecond precision. `notes` allows free-text observations.

---

## Business Rules and Conditions

**Uniqueness per Audit-Copy Pair**
The table enforces a unique constraint on `(audit_id, copy_id)`, ensuring each book copy can only be scanned once per audit session. The `storeScan` method explicitly checks for duplicates before inserting: `LibInventoryAuditDetail::where('audit_id', $auditId)->where('copy_id', $copyId)->first()`. Returns 422 with "This book copy has already been scanned in this audit."

**Auto-Populated Expected Location**
When a barcode is scanned via `storeScan`, the system fetches the copy's `shelf_location_id` and auto-sets it as `expected_location_id`. This provides a live comparison between where the book should be and where it was found.

**Copy Table Synced on Scan**
When a detail is created via `storeScan`, the system immediately updates the corresponding `LibBookCopy` record using `updateQuietly()`:
- `shelf_location_id` → `actual_location_id` (if provided)
- `condition_id` → scanned `condition_id` (always set, since the field is required in storeScan validation)

**AJAX Edit Syncs Copy Table**
The `update()` method (when called via AJAX) also updates the `LibBookCopy` record's `shelf_location_id` and `condition_id` from the scanned values. This ensures that the copy record always reflects the most recent audit finding.

**Recalculation Cascade**
Every detail create (`storeScan`), update (AJAX), or delete (`deleteScan`) calls `recalculateAuditCounts($auditId)`, which queries the detail table to recalculate:
- `total_scanned` = count of details for the audit
- `missing_copies` = count of details with status = missing
- `misplaced_copies` = count of details with status = misplaced
- `damaged_copies` = count of details with status = damaged

These counts are written to the parent `LibInventoryAudit` record via `updateQuietly()`.

**Status ID Resolution**
The recalculate method and other internal logic use `LibLibraryStatusMaster::getIdByCode('Inventory Audit Detail Status', '{code}')` to resolve status FK IDs dynamically. Never hardcoded IDs.

**Delete Protection**
Soft deletes are used (model uses `SoftDeletes` trait). `forceDelete` catches `QueryException` with code `23000` (FK constraint violation) to prevent deletion of records referenced elsewhere.

**Bulk Store**
The `bulkStore()` method accepts an array of copies and creates detail records in a loop. Each entry requires `copy_id` and `status`; optional fields include `expected_location_id`, `actual_location_id`, `condition_id`, and `notes`. `scanned_at` is auto-set to `now()`.

---

## Workflow Steps

1. Navigate to Library → History & Audit → Inventory Audit Details tab
2. View all scan records across all audits, filtered by audit or status
3. Click "Add Scan Entry" to manually create a detail record linked to an in-progress audit
4. From the audit scan page, scan a barcode — system creates a detail via AJAX (`storeScan`)
5. The scan result appears instantly with expected vs actual location, condition, and status
6. Click "Edit" on a scan record to update location, condition, or scan status
7. AJAX edit sends the update and refreshes the copy record and audit counts
8. Click "Delete" to remove an incorrect scan — audit counts recalculated automatically
9. For bulk imports, use the bulk store endpoint to load multiple scan records at once
10. View completed audit details via the by-audit filtered view

---

## Example Scenario

During a shelf audit of the Science section, the librarian scans a barcode on "Introduction to Physics" (accession no. PHY-001). The system fetches the copy record, sees its expected location is "Shelf A-12" and auto-sets `expected_location_id`. The librarian finds the book on "Shelf B-03" — they note the actual location as B-03 and set status to "Misplaced". The system records the scan, updates the parent audit's misplaced count, and updates the copy's shelf_location_id to B-03 for future reference.

---

## Related Screens

- Inventory Audit — parent session; summary counts recalculated from this detail table
- Book Copies — copy records updated with actual location and condition on scan
- Shelf Locations — expected vs actual location lookup
- Book Conditions — condition assessment reference

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibInventoryAuditDetailController`
**Model:** `Modules\Library\Models\LibInventoryAuditDetail` (table: `lib_inventory_audit_details`, uses `SoftDeletes`)
**Requests:** Standard `Request` with inline validation (no dedicated FormRequest)
**Policy:** Named permission string `tenant.lib-inventory-audit-details.*`
**Route:** Resource route `Route::resource('lib-inventory-audit-details', LibInventoryAuditDetailController::class)` with extras: `trashed`, `restore`, `forceDelete`, `storeScan`, `deleteScan`, `bulkStore`, `byAudit`

Key controller methods:
- `index(Request)` — Hub tab view with paginated details, filters by audit_id and status
- `create(Request)` — Create form loading in-progress audits, active copies/locations/conditions/statuses; accepts `?audit_id=` query param
- `show($id)` — Loads with audit, copy.book, expectedLocation, actualLocation, condition
- `edit($id)` — Edit form with all lookup lists
- `update(Request, $id)` — Dual-mode: AJAX (scan update + copy sync + recalculate) or full form update
- `destroy($id)` — Soft-deletes
- `trashed()` — Lists soft-deleted with all relations
- `restore($id)` — Restores from trash
- `forceDelete($id)` — Force-deletes with FK exception catching
- `storeScan(Request)` — AJAX single-scan: validates, checks duplicate, auto-pops expected_location, creates detail, updates copy, recalculates counts; returns JSON with detail+counts
- `deleteScan($id)` — AJAX delete with recalculate; returns JSON with counts
- `bulkStore(Request)` — Batch create from array of copies; auto-sets scanned_at to now()
- `byAudit($auditId)` — Filtered view showing all details for a specific audit

**Private Methods:** `recalculateAuditCounts($auditId)` — Refreshes parent audit's total_scanned, missing_copies, misplaced_copies, damaged_copies from detail records

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|-------------|
| Super Admin | `tenant.lib-inventory-audit-details.*` | Full access (bypasses policy via Gate::before) |
| Library Admin | `tenant.lib-inventory-audit-details.*` | Create, edit, delete scan records; view all details |
| Librarian | `tenant.lib-inventory-audit-details.create`, `.update`, `.view` | Scan books and update scan records; cannot delete |
| Library Assistant | `tenant.lib-inventory-audit-details.viewAny`, `.view` | View scan results only |

---

## How This Screen Works — Logic Flow (Non-Technical)

When the librarian enters the scanning page for an active audit, each barcode scan sends the copy ID, the actual shelf location (if found), the book's physical condition, and the scan status (found, missing, misplaced, or damaged) to the server. The system checks if that copy has already been scanned in this audit — if so, it rejects the duplicate. Otherwise, it creates a scan record, immediately updates the copy's recorded location and condition to match what was found, and recalculates the audit's running totals. Later, if the librarian realizes they made a mistake, they can edit the scan record — the system updates both the detail and the copy record. Deleting a scan removes it from the audit and recalculates the counts, but the copy's location and condition stay as updated.

---

## Validate Before Save

| # | Field | Rule | Error Message |
|---|-------|------|---------------|
| 1 | audit_id | Required, Exists:lib_inventory_audit,id | Audit session is required. |
| 2 | copy_id | Required, Exists:lib_book_copies,id | Book copy is required. |
| 3 | status | Required, Integer, Exists:lib_library_status_masters,id | Scan status is required. |
| 4 | condition_id | Nullable (full form) / Required (storeScan AJAX), Exists:lib_book_conditions,id | Condition is required when scanning. |
| 5 | actual_location_id | Nullable, Exists:lib_shelf_locations,id | Invalid location selected. |
| 6 | expected_location_id | Nullable (full form only), Exists:lib_shelf_locations,id | Invalid expected location. |
| 7 | scanned_at | Nullable, Date | Invalid scan timestamp. |
| 8 | notes | Nullable, String, Max:1000 (500 for storeScan) | Notes cannot exceed allowed length. |

AJAX storeScan additional validation: `condition_id` is REQUIRED (unlike full form where it's nullable). Duplicate check: `(audit_id, copy_id)` pair must not already exist for the audit.

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| Validation fails | (per-field messages from Validate Before Save table) | 422 |
| Gate authorization fails | This action is unauthorized. | 403 |
| Model not found | No query results for model | 404 |
| Duplicate scan | This book copy has already been scanned in this audit. | 422 (JSON) |
| Store scan exception | Failed to add scanned book: [detail] | 500 (JSON) |
| Force delete — FK constraint | Cannot delete this record: it is referenced by other records. Remove all dependencies first. | 422 (redirect) |
| No in-progress audits available | (create form shows empty dropdown — no error, just no options) | 200 |
| Audit not found for recalculate | (silently returns without updating — no error displayed) | — |

---

## Success Scenarios

**SC-001: Quick scan during audit**
1. Librarian opens the scan page for audit #42 and scans barcode "BC-1001"
2. `storeScan` receives copy_id = 1001, actual_location_id = 15, condition_id = 3, status = "found"
3. System finds copy, sets expected_location_id = 12, creates detail record, updates copy location to 15, recalculates audit counts
4. Response: `{"success": true, "message": "Book copy scanned and added to audit.", "counts": {"total_scanned": 151, ...}}`
5. Flash: "Book copy scanned and added to audit."

**SC-002: Edit a scan record to correct status**
1. Librarian realizes they marked a book as "Missing" but it was actually "Misplaced"
2. Opens edit form, changes status to "Misplaced", sets actual_location_id
3. AJAX update sends the change; system updates the detail, updates the copy record, recalculates audit counts
4. Response: `{"success": true, "message": "Scan entry updated successfully."}`
5. Parent audit's misplaced count increments; missing count decrements

**SC-003: Delete an incorrect scan**
1. Librarian accidentally scanned the same book twice; clicks delete on the duplicate
2. `deleteScan` removes the detail, recalculates audit counts
3. Response: `{"success": true, "message": "Scanned book removed from audit."}`
4. Audit total_scanned decrements by 1

---

## Failure Scenarios

**FC-001: Scan a duplicate copy**
1. Librarian scans barcode "BC-1001" which was already scanned 5 minutes ago
2. `storeScan` finds existing record with same audit_id + copy_id
3. Response: `{"success": false, "message": "This book copy has already been scanned in this audit."}` (422)
4. No record created; audit counts unchanged

**FC-002: Force delete with dependencies**
1. Admin tries to permanently delete a detail record that is referenced by another table
2. `forceDelete` triggers QueryException with code 23000
3. Redirect with error: "Cannot delete this record: it is referenced by other records. Remove all dependencies first."
4. Record remains in trash

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Table | lib_inventory_audit_details | Detail records with audit_id (CASCADE), copy_id, expected_location_id, actual_location_id, scanned_at, condition_id, status (FK lib_library_status_masters), notes; unique (audit_id, copy_id) |
| Table | lib_inventory_audit | Parent audit — summary counts recalculated from detail records |
| Table | lib_book_copies | Copy records updated on scan with actual location and condition |
| Table | lib_shelf_locations | FK for expected and actual location (two separate FKs to same table) |
| Table | lib_book_conditions | FK for condition assessment at scan time |
| Table | lib_library_status_masters | Statuses for both audit (Inventory Audit Status) and details (Inventory Audit Detail Status): Found, Missing, Misplaced, Damaged |
