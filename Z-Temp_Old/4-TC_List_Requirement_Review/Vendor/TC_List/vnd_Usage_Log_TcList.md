# vnd_Usage_Log_TcList

## Module: Vendor → Usage Log → VndUsageLog CRUD

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Vendor (VND) — Usage Log |
| Tab Group | Vendor Dashboard (Usage Logs Tab) |
| Features | Usage Log List (with vendor & agreementItem relations), Create/Edit/View/Delete/Restore/Force-Delete, Filter by vendor_id and usage_date, Activity Logging, Auto-Populate from Invoice Generation |
| URL(s) | `/vendor-usage-log`, `/vendor-usage-log/create`, `/vendor-usage-log/{id}/edit`, `/vendor-usage-log/{id}`, `/vendor-usage-log/trash/view`, `/vendor-usage-log/{id}/restore`, `/vendor-usage-log/{id}/force-delete` |
| Controller | `Modules\Vendor\Http\Controllers\VndUsageLogController` |
| Model(s) | `VndUsageLog`, `Vendor`, `VndAgreementItem` |
| Validation | **None** — store() and update() use plain `Illuminate\Http\Request`; no FormRequest exists |
| Permission Gates | `tenant.usage-log.viewAny`, `tenant.usage-log.view`, `tenant.usage-log.create`, `tenant.usage-log.update`, `tenant.usage-log.delete`, `tenant.usage-log.restore`, `tenant.usage-log.forceDelete` |
| Soft Deletes | Yes — VndUsageLog model uses `SoftDeletes` trait (deleted_at column added via separate migration `2026_06_18_100111`) |
| Events | `activityLog()` on store, update, destroy, restore, forceDelete; auto-logged via `VndUsageLogService::logUsageFromInvoice()` on invoice generation |

---

## 2. Pre-conditions

- Required permissions: `tenant.usage-log.viewAny`, `tenant.usage-log.create`, `tenant.usage-log.update`, `tenant.usage-log.view`, `tenant.usage-log.delete`, `tenant.usage-log.restore`, `tenant.usage-log.forceDelete`
- At least one active Vendor record must exist in `vnd_vendors` (FK: `vendor_id`)
- For agreement_item_id tests: at least one record in `vnd_agreement_items_jnt` (FK: nullable)
- For search/filter tests: at least one usage log record with populated fields
- For trash/restore tests: at least one soft-deleted usage log record
- For validation tests: **No validation exists** — all input accepted as-is (known issue)

---

## 3. Default Data Load

### 3.1 Index View Data

The `index()` method returns:
- `logs` — Paginated VndUsageLog records (10 per page) with `vendor` and `agreementItem` relations, ordered by `latest()`
- Eager loads: `vendor` (belongsTo Vendor), `agreementItem` (belongsTo VndAgreementItem)

### 3.2 Filter Parameters

| Filter | Source | Behaviour | SQL |
|--------|--------|-----------|-----|
| `vendor_id` | `$request->vendor_id` (filled check) | `where('vendor_id', $request->vendor_id)` | Exact match on vendor_id |
| `date` | `$request->date` (filled check) | `whereDate('usage_date', $request->date)` | Date-only comparison on usage_date |

### 3.3 Create/Edit View Data

The `create()` and `edit()` methods return:
- `vendorsList` — All vendors (`Vendor::get()`)
- `AgreementItemList` — All agreement items (`VndAgreementItem::get()`)

---

## 4. BC-DB — Database Schema

### 4.1 `vnd_usage_logs` — Usage Log Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| vendor_id | INT UNSIGNED | NOT NULL | — | FK → vnd_vendors(id) ON DELETE CASCADE |
| agreement_item_id | INT UNSIGNED | YES | NULL | FK → vnd_agreement_items_jnt(id) ON DELETE SET NULL |
| usage_date | DATE | NOT NULL | — | Date of usage |
| qty_used | DECIMAL(10,2) | NOT NULL | 0.00 | Quantity used |
| remarks | VARCHAR(255) | YES | NULL | Free-text remarks |
| logged_by | INT UNSIGNED | YES | NULL | User ID who logged the entry |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time (added via migration 2026_06_18_100111) |

**Indexes:**
- PRIMARY KEY (`id`)
- KEY `fk_vnd_usage_vendor` (`vendor_id`)
- KEY `fk_vnd_usage_agr_item` (`agreement_item_id`)

**Foreign Keys:**

| FK Name | Column | References | On Delete |
|---------|--------|------------|-----------|
| fk_vnd_usage_vendor | vendor_id | vnd_vendors(id) | CASCADE |
| fk_vnd_usage_agr_item | agreement_item_id | vnd_agreement_items_jnt(id) | SET NULL |

**Known Issues:**
- **No UNIQUE constraints** — duplicate records possible
- **No INDEX on usage_date, logged_by, or deleted_at** — potential query performance issues with large datasets
- **No CHECK constraints** — qty_used could accept negative values (no DB-level validation)

---

## 5. BC-VAL — Validation Rules

### 5.1 Current State: No Validation (Critical Known Issue)

**store()** uses `Request $request` (not a FormRequest). The `create()` call passes raw request values directly:

```php
$log = VndUsageLog::create([
    'vendor_id'         => $request->vendor_id,
    'agreement_item_id' => $request->agreement_item_id,
    'usage_date'        => $request->usage_date,
    'qty_used'          => $request->qty_used,
    'remarks'           => $request->remarks,
    'logged_by'         => Auth::user()->id,
]);
```

**update()** similarly uses `Request $request` without validation:

```php
$log->update([
    'vendor_id'         => $request->vendor_id,
    'agreement_item_id' => $request->agreement_item_id,
    'usage_date'        => $request->usage_date,
    'qty_used'          => $request->qty_used,
    'remarks'           => $request->remarks,
]);
```

### 5.2 Recommended Validation Rules (For Future Implementation)

| Field | Recommended Rules | Notes |
|-------|-------------------|-------|
| vendor_id | required, integer, exists:vnd_vendors,id | Required FK |
| agreement_item_id | nullable, integer, exists:vnd_agreement_items_jnt,id | Optional FK |
| usage_date | required, date, before_or_equal:today | Cannot be future date |
| qty_used | required, numeric, min:0, max:99999999.99 | Non-negative decimal |
| remarks | nullable, string, max:255 | Optional text |
| logged_by | nullable, integer, exists:users,id | Currently hardcoded to Auth::user()->id |

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method(s) | Model Policy |
|----------------|---------------------|-------------|
| tenant.usage-log.viewAny | index() | VndUsageLogPolicy@viewAny |
| tenant.usage-log.view | show() | VndUsageLogPolicy@view |
| tenant.usage-log.create | create(), store() | VndUsageLogPolicy@create |
| tenant.usage-log.update | edit(), update() | VndUsageLogPolicy@update |
| tenant.usage-log.delete | destroy() | VndUsageLogPolicy@delete |
| tenant.usage-log.restore | trashed(), restore() | VndUsageLogPolicy@restore |
| tenant.usage-log.forceDelete | forceDelete() | VndUsageLogPolicy@forceDelete |

**index() Gate:** Uses `Gate::authorize('tenant.usage-log.viewAny')` — user MUST have this specific permission (NOT Gate::any() pattern like VendorController)

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | Usage Log List with Relations | index() returns VndUsageLog records with eager-loaded `vendor` and `agreementItem` relations, ordered by `latest()`, paginated at 10 per page |
| BC-BIZ-02 | Filter by vendor_id (Exact Match) | index() applies `where('vendor_id', $request->vendor_id)` when `vendor_id` is present in request — no search/wildcard, exact FK match only |
| BC-BIZ-03 | Filter by usage_date (Date-Only) | index() applies `whereDate('usage_date', $request->date)` when `date` is present — compares only date portion, no time component |
| BC-BIZ-04 | Create with Hardcoded logged_by | store() passes `logged_by = Auth::user()->id` — user cannot set logged_by via form; always defaults to the authenticated user |
| BC-BIZ-05 | Update Excludes logged_by | update() only modifies `vendor_id`, `agreement_item_id`, `usage_date`, `qty_used`, `remarks` — logged_by is never updated |
| BC-BIZ-06 | Change Tracking on Update | update() captures `$log->getOriginal()` before update and `$log->getChanges()` after update; iterates changes (excluding updated_at) and logs old/new values via activityLog |
| BC-BIZ-07 | Soft Delete with activityLog | destroy() calls `findOrFail($id)`, then `$log->delete()`, then `activityLog($log, 'Trashed', ...)` |
| BC-BIZ-08 | Restore with onlyTrashed Scope | restore() uses `VndUsageLog::onlyTrashed()->findOrFail($id)` to scope to trashed records only, calls `$log->restore()` |
| BC-BIZ-09 | Force Delete with withTrashed Scope | forceDelete() uses `VndUsageLog::withTrashed()->findOrFail($id)` to find even soft-deleted records, calls `$log->forceDelete()` |
| BC-BIZ-10 | Redirect All Operations to Dashboard | All controller methods redirect to `route('vendor.vendor.index')` (vendor dashboard), NOT to usage-log.index — user must navigate back to usage-log tab after any operation |
| BC-BIZ-11 | Activity Log All Operations | activityLog() called with model, action ('Stored','Updated','Trashed','Restored','Deleted'), and performed_by=Auth::user()->name on all 5 CRUD operations |
| BC-BIZ-12 | No Input Validation | store() and update() accept raw request values without any validation rules — null, invalid, or malicious data may be persisted |
| BC-BIZ-13 | qty_used Not Cast to Decimal | Model has no `$casts` array — qty_used stored as-is from request; may lose decimal precision or store non-numeric values (DB DECIMAL may reject, causing PDO exception) |
| BC-BIZ-14 | Create View Supplies All Vendors + Items | create() passes `Vendor::get()` (all vendors, unpaginated) and `VndAgreementItem::get()` (all agreement items) for dropdown selects |
| BC-BIZ-15 | Edit View Same Data as Create | edit() passes same `vendorsList` and `AgreementItemList` plus the existing `$log` record for pre-population |
| BC-BIZ-16 | Auto-Populate from Invoice Generation | `VndUsageLogService::logUsageFromInvoice()` is called from `VendorInvoiceController::generateInvoice()` — when an invoice is generated, a usage log entry is auto-created with the same `qty_used` as the invoice |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete | Note |
|-------------|--------|-----------------|-----------|------|
| fk_vnd_usage_vendor | vnd_usage_logs.vendor_id | vnd_vendors.id | CASCADE | Deleting a vendor deletes all its usage logs |
| fk_vnd_usage_agr_item | vnd_usage_logs.agreement_item_id | vnd_agreement_items_jnt.id | SET NULL | Deleting an agreement item sets usage log's agreement_item_id to NULL |

---

## 9. Test Case Summary

### 9.1 Usage Log CRUD — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-UL-P01 | Usage Log CRUD | Positive | Usage log list loads with eager-loaded relations and pagination | 4 |
| TC-UL-P02 | Usage Log CRUD | Positive | Filter usage logs by vendor_id (exact match) | 4 |
| TC-UL-P03 | Usage Log CRUD | Positive | Filter usage logs by usage_date (date-only) | 4 |
| TC-UL-P04 | Usage Log CRUD | Positive | Combine vendor_id + usage_date filters | 4 |
| TC-UL-P05 | Usage Log CRUD | Positive | Create usage log — all fields (vendor_id, agreement_item_id, usage_date, qty_used, remarks) | 6 |
| TC-UL-P06 | Usage Log CRUD | Positive | Create usage log — NULL agreement_item_id and NULL remarks | 5 |
| TC-UL-P07 | Usage Log CRUD | Positive | Create usage log — qty_used with decimal precision | 5 |
| TC-UL-P08 | Usage Log CRUD | Positive | View usage log detail | 3 |
| TC-UL-P09 | Usage Log CRUD | Positive | Edit usage log — update all fields | 5 |
| TC-UL-P10 | Usage Log CRUD | Positive | Edit usage log — change tracking logs old/new values | 4 |
| TC-UL-P11 | Usage Log CRUD | Positive | Edit usage log — set agreement_item_id from value to NULL | 5 |
| TC-UL-P12 | Usage Log CRUD | Positive | Soft-delete usage log | 4 |
| TC-UL-P13 | Usage Log CRUD | Positive | Restore usage log from trash | 4 |
| TC-UL-P14 | Usage Log CRUD | Positive | Force-delete usage log | 4 |
| TC-UL-P15 | Usage Log CRUD | Positive | Create — logged_by auto-set to Auth::user()->id | 3 |
| TC-UL-P16 | Usage Log CRUD | Positive | Activity log created on usage log store | 3 |
| TC-UL-P17 | Usage Log CRUD | Positive | Activity log created on usage log update | 3 |
| TC-UL-P18 | Usage Log CRUD | Positive | Activity log created on usage log soft-delete | 3 |
| TC-UL-P19 | Usage Log CRUD | Positive | Activity log created on usage log restore | 3 |
| TC-UL-P20 | Usage Log CRUD | Positive | Activity log created on usage log force-delete | 3 |
| TC-UL-P21 | Usage Log CRUD | Positive | user() relationship (via logged_by) returns the User who logged the usage | 4 |
| TC-UL-P22 | Usage Log CRUD | Positive | Filter by vendor_id — controller applies where('vendor_id') when filled | 3 |
| TC-UL-P23 | Usage Log CRUD | Positive | Filter by usage_date — controller applies whereDate('usage_date') when filled | 3 |
| TC-UL-P24 | Usage Log CRUD | Positive | Auto-populate — usage log created when invoice is generated via generateSingle() | 4 |
| TC-UL-P25 | Usage Log CRUD | Positive | Auto-populate — usage log created when invoice is generated via generateMultiple() | 4 |
| TC-UL-P26 | Usage Log CRUD | Positive | Auto-populate — remarks contains invoice number reference | 3 |

### 9.2 Usage Log CRUD — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-UL-N01 | Usage Log CRUD | Negative | Create — null/missing vendor_id (DB FK violation) | 3 |
| TC-UL-N02 | Usage Log CRUD | Negative | Create — non-existent vendor_id (no validation, DB FK constraint) | 3 |
| TC-UL-N03 | Usage Log CRUD | Negative | Create — non-existent agreement_item_id (no validation, DB SET NULL) | 3 |
| TC-UL-N04 | Usage Log CRUD | Negative | Create — missing usage_date (DB NOT NULL constraint) | 3 |
| TC-UL-N05 | Usage Log CRUD | Negative | Create — invalid usage_date format (SQL error likely) | 3 |
| TC-UL-N06 | Usage Log CRUD | Negative | Create — qty_used = negative value (no validation to reject) | 4 |
| TC-UL-N07 | Usage Log CRUD | Negative | Create — qty_used = non-numeric string (PDO error) | 3 |
| TC-UL-N08 | Usage Log CRUD | Negative | Create — remarks exceeds 255 chars (DB truncation or error) | 3 |
| TC-UL-N09 | Usage Log CRUD | Negative | Update — missing vendor_id (FK violation) | 3 |
| TC-UL-N10 | Usage Log CRUD | Negative | Update — non-existent vendor_id (DB FK constraint) | 3 |
| TC-UL-N11 | Usage Log CRUD | Negative | Update — non-existent agreement_item_id (DB SET NULL or FK error) | 3 |
| TC-UL-N12 | Usage Log CRUD | Negative | Update — invalid usage_date format | 3 |
| TC-UL-N13 | Usage Log CRUD | Negative | Update — qty_used = non-numeric value | 3 |
| TC-UL-N14 | Usage Log CRUD | Negative | Update — remarks exceeds 255 chars | 3 |
| TC-UL-N15 | Usage Log CRUD | Negative | Show — non-existent usage log ID (findOrFail → 404) | 2 |
| TC-UL-N16 | Usage Log CRUD | Negative | Edit — non-existent usage log ID | 2 |
| TC-UL-N17 | Usage Log CRUD | Negative | Destroy — non-existent usage log ID | 2 |
| TC-UL-N18 | Usage Log CRUD | Negative | Restore — non-existent usage log ID (onlyTrashed scope) | 2 |
| TC-UL-N19 | Usage Log CRUD | Negative | Force delete — non-existent usage log ID | 2 |
| TC-UL-N20 | Usage Log CRUD | Negative | Permission — index without tenant.usage-log.viewAny | 2 |
| TC-UL-N21 | Usage Log CRUD | Negative | Permission — create without tenant.usage-log.create | 2 |
| TC-UL-N22 | Usage Log CRUD | Negative | Permission — store without tenant.usage-log.create | 2 |
| TC-UL-N23 | Usage Log CRUD | Negative | Permission — edit without tenant.usage-log.update | 2 |
| TC-UL-N24 | Usage Log CRUD | Negative | Permission — update without tenant.usage-log.update | 2 |
| TC-UL-N25 | Usage Log CRUD | Negative | Permission — view show without tenant.usage-log.view | 2 |
| TC-UL-N26 | Usage Log CRUD | Negative | Permission — destroy without tenant.usage-log.delete | 2 |
| TC-UL-N27 | Usage Log CRUD | Negative | Permission — trashed without tenant.usage-log.restore | 2 |
| TC-UL-N28 | Usage Log CRUD | Negative | Permission — restore without tenant.usage-log.restore | 2 |
| TC-UL-N29 | Usage Log CRUD | Negative | Permission — forceDelete without tenant.usage-log.forceDelete | 2 |
| TC-UL-N30 | Usage Log CRUD | Negative | Update — logged_by cannot be changed via form (hardcoded in controller) | 4 |
| TC-UL-N31 | Usage Log CRUD | Negative | Redirect — after all operations, user is redirected to vendor dashboard, not usage-log list | 3 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR01 | Code Review | Review | index() — Gate + with() + filters + latest() + paginate | 5 |
| TC-CR02 | Code Review | Review | create() — Gate + new model + vendors + agreement items list | 4 |
| TC-CR03 | Code Review | Review | store() — Gate + no FormRequest + raw create + hardcoded logged_by | 6 |
| TC-CR04 | Code Review | Review | show() — Gate + findOrFail | 3 |
| TC-CR05 | Code Review | Review | edit() — Gate + findOrFail + vendors + agreement items list | 4 |
| TC-CR06 | Code Review | Review | update() — change tracking with getOriginal/getChanges | 6 |
| TC-CR07 | Code Review | Review | destroy() — Gate + findOrFail + delete + activityLog | 4 |
| TC-CR08 | Code Review | Review | trashed() — Gate + onlyTrashed + paginate | 3 |
| TC-CR09 | Code Review | Review | restore() — Gate + onlyTrashed findOrFail + restore + activityLog | 4 |
| TC-CR10 | Code Review | Review | forceDelete() — Gate + withTrashed findOrFail + forceDelete + activityLog | 4 |
| TC-CR11 | Code Review | Review | VndUsageLogPolicy — all 7 method signatures | 4 |
| TC-CR13 | Code Review | Review | VndUsageLog Model — fillable, SoftDeletes, relationships, missing casts | 5 |
| TC-CR14 | Code Review | Review | Flash messages — all 5 controller operations redirect to vendor.vendor.index | 5 |
| TC-CR15 | Code Review | Review | No FormRequest — store/update use plain Request, zero validation | 3 |
| TC-CR16 | Code Review | Review | qty_used not cast to decimal in model — potential type/rounding issues | 3 |
| TC-CR17 | Code Review | Review | VndUsageLogService::logUsageFromInvoice() — service method signature, create call, remarks format | 4 |
| TC-CR18 | Code Review | Review | VendorInvoiceController::generateInvoice() — integration: auto-log call after invoice creation, invoice number passed in remarks | 3 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-D01 | Dependency | Dependency | Cascade delete — deleting a vendor cascades to delete all related usage logs | 4 |
| TC-D02 | Dependency | Dependency | SET NULL — deleting an agreement_item sets usage_log.agreement_item_id to NULL | 4 |
| TC-D03 | Dependency | Dependency | SoftDeletes + deleted_at migration — verify deleted_at column exists in DB and SoftDeletes trait functions | 4 |
| TC-D04 | Dependency | Dependency | Filter by vendor_id depends on vnd_vendors table having records | 3 |
| TC-D05 | Dependency | Dependency | Filter by usage_date depends on correct DATE column type in DB | 3 |
| TC-D06 | Dependency | Dependency | User relationship (logged_by) depends on users table | 3 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Usage Log CRUD

#### TC-UL-P01: Usage log list loads with eager-loaded relations and pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.usage-log.viewAny` permission navigates to `/vendor-usage-log` | Usage log list loads |
| 2 | Verify each log entry displays vendor name (from vendor relation) and agreement item info (from agreementItem relation) | Relations eager-loaded |
| 3 | Verify columns: vendor, agreement_item, usage_date, qty_used, remarks, logged_by, Actions | All columns present |
| 4 | Verify pagination links (10 per page) with `withQueryString()` | Paginated |

#### TC-UL-P02: Filter usage logs by vendor_id (exact match)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Usage log list has records from multiple vendors | Diverse data |
| 2 | Add `?vendor_id=5` to URL (or select vendor from dropdown if UI exists) | Filter applied |
| 3 | Verify only logs with vendor_id=5 are displayed | Exact match |
| 4 | Verify logs from other vendors are excluded | Filtered correctly |

#### TC-UL-P03: Filter usage logs by usage_date (date-only)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Usage log list has records across multiple dates | Diverse data |
| 2 | Add `?date=2026-06-15` (or select date via date picker) | Filter applied |
| 3 | Verify only logs with usage_date = 2026-06-15 are displayed | Date-only comparison |
| 4 | Verify logs from other dates are excluded | Filtered correctly |

#### TC-UL-P04: Combine vendor_id + usage_date filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add `?vendor_id=3&date=2026-06-15` as query params | Both filters applied |
| 2 | Verify only logs matching BOTH vendor_id=3 AND usage_date=2026-06-15 shown | Intersection filter |
| 3 | Verify logs matching only one condition are excluded | Both conditions enforced |
| 4 | Verify query string preserved in pagination links (`withQueryString()`) | Query string preserved |

#### TC-UL-P05: Create usage log — all fields filled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.usage-log.create` permission navigates to `/vendor-usage-log/create` | Create form loads |
| 2 | Select vendor_id (valid), select agreement_item_id (valid), enter usage_date="2026-06-15", enter qty_used="150.50", enter remarks="Weekly usage log entry" | All fields populated |
| 3 | Submit form | Redirected to vendor dashboard |
| 4 | Verify success flash message: "Usage log created successfully" (or similar) | Flash success |
| 5 | Navigate back to usage log list and verify new entry is present with all values | Record created |
| 6 | Verify DB: logged_by = id of authenticated user | Logged by set correctly |

#### TC-UL-P06: Create usage log — NULL agreement_item_id and NULL remarks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select vendor_id (valid), do NOT select agreement_item_id (leave empty/null), enter usage_date="2026-06-15", enter qty_used="75.00", leave remarks blank | Optional fields empty |
| 3 | Submit form | Success |
| 4 | Verify DB: agreement_item_id = NULL, remarks = NULL | Nullable fields stored as NULL |
| 5 | Verify entry displays correctly in list (shows "-" or blank for null fields) | Display handles null |

#### TC-UL-P07: Create usage log — qty_used with decimal precision

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter qty_used = "0.01" (minimum positive decimal) | Small decimal entered |
| 3 | Submit | Success |
| 4 | Verify DB stores exactly 0.01 (DECIMAL(10,2) precision) | Precision maintained |
| 5 | Enter qty_used = "99999999.99" (max DECIMAL(10,2) value) and submit | Max value accepted |

#### TC-UL-P08: View usage log detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.usage-log.view` permission clicks "View" on a usage log entry | Show page loads |
| 2 | Verify all fields displayed: vendor name, agreement item, usage_date, qty_used, remarks, logged_by, created_at, updated_at | All fields visible |
| 3 | Verify vendor name is resolved from FK (not raw vendor_id) | Relation displayed |

#### TC-UL-P09: Edit usage log — update all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.usage-log.update` permission clicks "Edit" on a usage log | Edit form loads with pre-filled data |
| 2 | Change vendor_id, agreement_item_id, usage_date to a different date, change qty_used to a new value, update remarks | All fields changed |
| 3 | Click Update | Redirected to vendor dashboard |
| 4 | Verify success flash message | Success message |
| 5 | Navigate back to usage log list and verify all fields reflect updated values | Changes persisted |

#### TC-UL-P10: Edit usage log — change tracking logs old/new values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Usage log has qty_used="100.00", remarks="Original remark" | Existing values |
| 2 | Edit and change qty_used to "200.00" and remarks to "Updated remark" | Fields changed |
| 3 | Submit update | Success |
| 4 | Verify activity log entry contains old="100.00"/new="200.00" for qty_used and old="Original remark"/new="Updated remark" for remarks | Change tracked |

#### TC-UL-P11: Edit usage log — set agreement_item_id from value to NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Usage log has agreement_item_id set to a valid value | Existing relation |
| 2 | Edit and deselect/clear the agreement_item_id dropdown (set to null) | Field cleared |
| 3 | Submit update | Success |
| 4 | Verify DB: agreement_item_id = NULL for the record | Set to null |
| 5 | Verify activity log contains old agreement_item_id value and new=null | Change tracked |

#### TC-UL-P12: Soft-delete usage log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.usage-log.delete` permission clicks "Delete" on a usage log | Confirmation prompt |
| 2 | Confirm deletion | Usage log soft-deleted |
| 3 | Verify log no longer appears in active usage log list | Removed from list |
| 4 | Verify DB: deleted_at is NOT NULL for the record | Soft-deleted |

#### TC-UL-P13: Restore usage log from trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.usage-log.restore` permission navigates to `/vendor-usage-log/trash/view` | Trash list loads |
| 2 | Locate a soft-deleted usage log | Vendor visible in trash |
| 3 | Click Restore | Usage log restored |
| 4 | Verify log appears in active list, deleted_at is NULL, and activity log entry created | Restored |

#### TC-UL-P14: Force-delete usage log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.usage-log.forceDelete` permission navigates to trash view | Trash list loads |
| 2 | Locate a soft-deleted usage log and click "Force Delete" | Confirmation prompt |
| 3 | Confirm permanent deletion | Usage log permanently deleted |
| 4 | Verify DB record no longer exists (including withTrashed) and activity log entry created | Permanently deleted |

#### TC-UL-P15: Create — logged_by auto-set to Auth::user()->id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A (id=10) creates a new usage log via store() | Request sent |
| 2 | Submit form with all required fields | Success |
| 3 | Verify DB: logged_by = 10 (User A's id) regardless of any form input for logged_by | Hardcoded to auth user |

#### TC-UL-P16: Activity log created on usage log store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new usage log via store() | Success |
| 2 | Verify `activityLog()` was called with VndUsageLog model, action='Stored', and message='Vendor usage log created.' | Logged |
| 3 | Verify performed_by = authenticated user's name | Performer tracked |

#### TC-UL-P17: Activity log created on usage log update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update a usage log via update() | Success |
| 2 | Verify `activityLog()` called with action='Updated' and changes array containing old/new values for changed fields | Logged |
| 3 | Verify changes excludes updated_at field | updated_at filtered |

#### TC-UL-P18: Activity log created on usage log soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a usage log via destroy() | Success |
| 2 | Verify `activityLog()` called with action='Trashed' and message='Vendor usage log deleted.' | Logged |

#### TC-UL-P19: Activity log created on usage log restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a trashed usage log via restore() | Success |
| 2 | Verify `activityLog()` called with action='Restored' and message='Vendor usage log restored.' | Logged |

#### TC-UL-P20: Activity log created on usage log force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete a trashed usage log via forceDelete() | Success |
| 2 | Verify `activityLog()` called with action='Deleted' and message='Vendor usage log permanently deleted.' | Logged |

#### TC-UL-P21: user() relationship (via logged_by) returns the User who logged the usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access a VndUsageLog record where `logged_by` is set to a valid sys_users id | Record loaded |
| 2 | Call `$usageLog->user` relationship | Returns User model instance |
| 3 | Verify the returned User's id matches the `logged_by` column value | Correct user returned |
| 4 | Verify `user()` is a `belongsTo` relationship with foreign key `logged_by` targeting `User::class` | belongsTo defined |

#### TC-UL-P22: Filter by vendor_id — controller applies where('vendor_id') when filled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Usage logs exist for Vendor A (id=1) and Vendor B (id=2) | Diverse data |
| 2 | Request `GET /vendor-usage-log?vendor_id=1` | Filter applied |
| 3 | Verify only logs with `vendor_id = 1` are returned — controller applies `when($request->filled('vendor_id'), fn($q) => $q->where('vendor_id', $request->vendor_id))` | Filtered by vendor |

#### TC-UL-P23: Filter by usage_date — controller applies whereDate('usage_date') when filled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Usage logs exist with different usage_date values (2026-06-15, 2026-06-20, etc.) | Diverse dates |
| 2 | Request `GET /vendor-usage-log?date=2026-06-15` | Filter applied |
| 3 | Verify only logs with `usage_date = 2026-06-15` are returned — controller applies `when($request->filled('date'), fn($q) => $q->whereDate('usage_date', $request->date))` | Date-only filter works |

#### TC-UL-P24: Auto-populate — usage log created when invoice is generated via generateSingle()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate a single invoice via `generateSingle()` for an agreement item | Invoice created successfully |
| 2 | Navigate to Usage Log list | New log entry visible |
| 3 | Verify log has same vendor_id, agreement_item_id, and qty_used as the invoice | Matches invoice data |
| 4 | Verify usage_date = current date and logged_by = authenticated user | Auto-populated correctly |

#### TC-UL-P25: Auto-populate — usage log created when invoice is generated via generateMultiple()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate invoices for multiple agreement items via `generateMultiple()` | All invoices created |
| 2 | Navigate to Usage Log list | One log entry per invoice generated |
| 3 | Verify each log corresponds to its respective invoice's vendor_id, agreement_item_id, qty_used | Mapped correctly |
| 4 | Verify total logs count = number of invoices generated | Count matches |

#### TC-UL-P26: Auto-populate — remarks contains invoice number reference

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate an invoice | Invoice and usage log created |
| 2 | Check the usage log remarks field | Contains "Auto-logged from invoice: INV-..." with the invoice number |
| 3 | Verify traceability — log can be linked back to the source invoice via remarks | Traceable |

### 10.2 Negative TC Steps — Usage Log CRUD

#### TC-UL-N01: Create — null/missing vendor_id (DB FK violation)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without selecting vendor_id (or set to null/empty) | No validation to reject |
| 2 | DB: vendor_id is NOT NULL — will cause SQL integrity constraint violation | DB exception (PDO error) |
| 3 | Verify user sees 500 error or Laravel debug error (no try-catch in controller) | Error not handled gracefully |

#### TC-UL-N02: Create — non-existent vendor_id (no validation, DB FK constraint)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create with vendor_id=99999 (non-existent) | No validation to reject |
| 2 | DB: FK constraint violation on fk_vnd_usage_vendor | DB exception |
| 3 | Verify 500 error returned (no validation, no try-catch) | Error |

#### TC-UL-N03: Create — non-existent agreement_item_id (no validation, DB SET NULL)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create with agreement_item_id=99999 (non-existent) | No validation to reject |
| 2 | DB: If FK constraint is enforced, violation error; if FK constraint is deferred, may store and fail later | DB exception or silent failure |
| 3 | Verify system behaviour — both outcomes are problematic | FK inconsistency |

#### TC-UL-N04: Create — missing usage_date (DB NOT NULL constraint)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without usage_date (leave empty/null) | No validation to reject |
| 2 | DB: usage_date is NOT NULL — SQL error | DB exception |
| 3 | Verify 500 error | Error not handled |

#### TC-UL-N05: Create — invalid usage_date format (SQL error likely)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter usage_date = "not-a-date" or "13-13-2026" (invalid) | No validation to reject |
| 2 | MySQL STRICT mode may reject or silently convert to 0000-00-00 | SQL error or data corruption |
| 3 | Verify DB stores correct value or throws error | Inconsistent behaviour |

#### TC-UL-N06: Create — qty_used = negative value (no validation to reject)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter qty_used = "-50.00" | Negative value entered |
| 2 | Submit form | No validation to reject |
| 3 | Verify DB stores -50.00 (DECIMAL allows negative) | Negative persisted |
| 4 | Note: No business rule prevents negative usage — potential data integrity issue | Data quality gap |

#### TC-UL-N07: Create — qty_used = non-numeric string (PDO error)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter qty_used = "abc" | Non-numeric value |
| 2 | Submit form | No validation to reject |
| 3 | DB DECIMAL(10,2) expects numeric — PDO exception thrown | 500 error |

#### TC-UL-N08: Create — remarks exceeds 255 chars (DB truncation or error)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter remarks with 300 characters | Exceeds VARCHAR(255) |
| 2 | Submit form | No validation to reject |
| 3 | MySQL strict mode: error; non-strict: truncates to 255 without warning | Data loss or error |

#### TC-UL-N09: Update — missing vendor_id (FK violation)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit usage log and clear vendor_id (set to null/empty) | No validation to reject |
| 2 | Submit update | DB exception (vendor_id is NOT NULL) |
| 3 | Verify 500 error | Error not handled |

#### TC-UL-N10: Update — non-existent vendor_id (DB FK constraint)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit usage log and set vendor_id=99999 | Non-existent vendor |
| 2 | Submit | DB FK violation |
| 3 | Verify 500 error | Error not handled |

#### TC-UL-N11: Update — non-existent agreement_item_id (DB SET NULL or FK error)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit usage log and set agreement_item_id=99999 | Non-existent item |
| 2 | Submit | DB FK violation (if enforced) or silent failure |
| 3 | Verify system behaviour | Inconsistent |

#### TC-UL-N12: Update — invalid usage_date format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit usage log, set usage_date = "invalid-date" | Invalid format |
| 2 | Submit | SQL error or silent date conversion |
| 3 | Verify DB state | Data corruption risk |

#### TC-UL-N13: Update — qty_used = non-numeric value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit usage log, set qty_used = "NaN" | Non-numeric |
| 2 | Submit | PDO exception (expected) |
| 3 | Verify 500 error | Error not handled |

#### TC-UL-N14: Update — remarks exceeds 255 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit usage log, set remarks to 300-character string | Exceeds max length |
| 2 | Submit | Truncation or error depending on MySQL mode |
| 3 | Verify data integrity | Potential data loss |

#### TC-UL-N15: Show — non-existent usage log ID (findOrFail → 404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/vendor-usage-log/99999` | Non-existent ID |
| 2 | Verify 404 Not Found from `findOrFail` | 404 returned |

#### TC-UL-N16: Edit — non-existent usage log ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/vendor-usage-log/99999/edit` | Non-existent ID |
| 2 | Verify 404 Not Found | 404 returned |

#### TC-UL-N17: Destroy — non-existent usage log ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/vendor-usage-log/99999` | Non-existent ID |
| 2 | Verify 404 Not Found from `findOrFail` | 404 returned |

#### TC-UL-N18: Restore — non-existent usage log ID (onlyTrashed scope)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/vendor-usage-log/99999/restore` | Non-existent ID |
| 2 | Verify 404 Not Found from `onlyTrashed()->findOrFail` | 404 returned |

#### TC-UL-N19: Force delete — non-existent usage log ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/vendor-usage-log/99999/force-delete` | Non-existent ID |
| 2 | Verify 404 Not Found from `withTrashed()->findOrFail` | 404 returned |

#### TC-UL-N20: Permission — index without tenant.usage-log.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.usage-log.viewAny` permission accesses `/vendor-usage-log` | 403 Forbidden |
| 2 | Verify Gate::authorize() throws AuthorizationException | Aborted |

#### TC-UL-N21: Permission — create without tenant.usage-log.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.usage-log.create` accesses `/vendor-usage-log/create` | 403 Forbidden |

#### TC-UL-N22: Permission — store without tenant.usage-log.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.usage-log.create` POSTs to `/vendor-usage-log` | 403 Forbidden |

#### TC-UL-N23: Permission — edit without tenant.usage-log.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.usage-log.update` accesses `/vendor-usage-log/{id}/edit` | 403 Forbidden |

#### TC-UL-N24: Permission — update without tenant.usage-log.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.usage-log.update` PUTs to `/vendor-usage-log/{id}` | 403 Forbidden |

#### TC-UL-N25: Permission — view show without tenant.usage-log.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.usage-log.view` accesses `/vendor-usage-log/{id}` | 403 Forbidden |

#### TC-UL-N26: Permission — destroy without tenant.usage-log.delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.usage-log.delete` DELETEs `/vendor-usage-log/{id}` | 403 Forbidden |

#### TC-UL-N27: Permission — trashed without tenant.usage-log.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.usage-log.restore` accesses `/vendor-usage-log/trash/view` | 403 Forbidden |

#### TC-UL-N28: Permission — restore without tenant.usage-log.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.usage-log.restore` GETs `/vendor-usage-log/{id}/restore` | 403 Forbidden |

#### TC-UL-N29: Permission — forceDelete without tenant.usage-log.forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.usage-log.forceDelete` DELETEs `/vendor-usage-log/{id}/force-delete` | 403 Forbidden |

#### TC-UL-N30: Update — logged_by cannot be changed via form (hardcoded in controller)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit usage log where logged_by=5 (User B) | Existing value |
| 2 | Attempt to pass logged_by=10 in the update request form | Parameter ignored |
| 3 | Submit update | Success |
| 4 | Verify DB: logged_by still = 5 (unchanged) — update() does NOT include logged_by in the update array | Hardcoded exclusion confirmed |

#### TC-UL-N31: Redirect — after all operations, user is redirected to vendor dashboard, not usage-log list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Perform any CRUD operation (create, update, delete, restore, forceDelete) | Operation succeeds |
| 2 | Verify redirect URL is `route('vendor.vendor.index')` (vendor dashboard) | Redirected to `/vendor` |
| 3 | Verify user must manually switch to Usage Logs tab to see the result | Navigation friction |

### 10.3 Code Review TC Steps

#### TC-CR01: index() — Gate + with() + filters + latest() + paginate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.usage-log.viewAny')` at method start | Gate present (single permission, not Gate::any) |
| 2 | Review `with(['vendor', 'agreementItem'])` — eager loads relations | Eager loading for N+1 prevention |
| 3 | Review `when($request->filled('vendor_id'), ...)` conditional filters | Conditional filtering |
| 4 | Review `when($request->filled('date'), ...)` with `whereDate('usage_date', ...)` | Date-only comparison |
| 5 | Review `latest()->paginate(10)->withQueryString()` | Pagination with query string preservation |

#### TC-CR02: create() — Gate + new model + vendors + agreement items list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.usage-log.create')` | Gate present |
| 2 | Review `$log = new VndUsageLog()` — empty model for form binding | Empty model instance |
| 3 | Review `Vendor::get()` — all vendors for dropdown, no pagination | Vendor list |
| 4 | Review `VndAgreementItem::get()` — all agreement items for dropdown | Agreement item list |

#### TC-CR03: store() — Gate + no FormRequest + raw create + hardcoded logged_by

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.usage-log.create')` | Gate present |
| 2 | Review `Request $request` parameter — NOT a FormRequest | No validation |
| 3 | Review `VndUsageLog::create([...])` — all values passed directly from `$request->field` | Raw input stored |
| 4 | Review `'logged_by' => Auth::user()->id` — hardcoded to auth user | Cannot be changed |
| 5 | Review `activityLog($log, 'Stored', ['message' => 'Vendor usage log created.'])` | Activity logged |
| 6 | Review `redirect()->route('vendor.vendor.index')` — redirects to dashboard, not usage-log list | Redirect target |

#### TC-CR04: show() — Gate + findOrFail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.usage-log.view')` | Gate present |
| 2 | Review `VndUsageLog::findOrFail($id)` — model binding by ID | findOrFail |
| 3 | Review no eager loading on show — vendor and agreementItem accessed via lazy loading | Potential N+1 query |

#### TC-CR05: edit() — Gate + findOrFail + vendors + agreement items list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.usage-log.update')` | Gate present |
| 2 | Review `VndUsageLog::findOrFail($id)` — same pattern as show | findOrFail |
| 3 | Review `Vendor::get()` and `VndAgreementItem::get()` — same as create | Dropdown lists |
| 4 | Review `compact('log', 'vendorsList', 'AgreementItemList')` — passes all to view | View data |

#### TC-CR06: update() — change tracking with getOriginal/getChanges

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.usage-log.update')` | Gate present |
| 2 | Review `$original = $log->getOriginal()` before update | Original captured |
| 3 | Review `$log->update([...])` — 5 fields, no logged_by | Update excludes logged_by |
| 4 | Review `foreach ($log->getChanges() as $field => $newValue)` — iterates changes | Changes captured |
| 5 | Review `if ($field === 'updated_at') continue;` — excludes timestamp | updated_at filtered |
| 6 | Review changes[field] = ['old' => original, 'new' => newValue] format | Change tracking structure |

#### TC-CR07: destroy() — Gate + findOrFail + delete + activityLog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.usage-log.delete')` | Gate present |
| 2 | Review `VndUsageLog::findOrFail($id)` — standard model binding | findOrFail |
| 3 | Review `$log->delete()` — SoftDeletes (marks deleted_at) | Soft delete |
| 4 | Review `activityLog($log, 'Trashed', ['message' => 'Vendor usage log deleted.'])` | Activity + flash |

#### TC-CR08: trashed() — Gate + onlyTrashed + paginate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.usage-log.restore')` | Gate present |
| 2 | Review `VndUsageLog::onlyTrashed()->paginate(10)` | Scoped to trashed only |
| 3 | Review no eager loading on trashed list — vendor and agreementItem may be null | Potential null relation access |

#### TC-CR09: restore() — Gate + onlyTrashed findOrFail + restore + activityLog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.usage-log.restore')` | Gate present |
| 2 | Review `VndUsageLog::onlyTrashed()->findOrFail($id)` — scoped to trashed | onlyTrashed scope |
| 3 | Review `$log->restore()` — sets deleted_at = null | Restore |
| 4 | Review `activityLog($log, 'Restored', ['message' => 'Vendor usage log restored.'])` | Activity + flash |

#### TC-CR10: forceDelete() — Gate + withTrashed findOrFail + forceDelete + activityLog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.usage-log.forceDelete')` | Gate present |
| 2 | Review `VndUsageLog::withTrashed()->findOrFail($id)` — bypasses soft-delete scope | withTrashed scope |
| 3 | Review `$log->forceDelete()` — permanently removes record | Permanent delete |
| 4 | Review `activityLog($log, 'Deleted', ['message' => 'Vendor usage log permanently deleted.'])` | Activity + flash |

#### TC-CR11: VndUsageLogPolicy — all 7 method signatures

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review viewAny(User) — returns $user->can('tenant.usage-log.viewAny') | Policy method |
| 2 | Review view(User, VndUsageLog) — returns $user->can('tenant.usage-log.view') | Policy method |
| 3 | Review create(User) — returns $user->can('tenant.usage-log.create') | Policy method |
| 4 | Review update(User, VndUsageLog), delete(), restore(), forceDelete() — all return corresponding can() checks | All 7 methods |

#### TC-CR12: VndUsageLog Model — fillable, SoftDeletes, relationships, missing casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$fillable` array — 6 fields: vendor_id, agreement_item_id, usage_date, qty_used, remarks, logged_by | All fillable fields |
| 2 | Review `SoftDeletes` trait used and `$dates = ['deleted_at']` | SoftDeletes enabled |
| 3 | Review `vendor()` — belongsTo Vendor::class | Vendor relationship |
| 4 | Review `agreementItem()` — belongsTo VndAgreementItem::class with foreign key | Agreement item relationship |
| 5 | Review `user()` — belongsTo User::class with foreign key 'logged_by' | User relationship |
| 6 | Review no `$casts` array — qty_used is NOT cast to decimal or float | Missing cast |

#### TC-CR13: Flash messages — all 5 controller operations redirect to vendor.vendor.index

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review store() flash: `flash('created.item')` | Create flash |
| 2 | Review update() flash: `flash('updated.item')` | Update flash |
| 3 | Review destroy() flash: `flash('trashed.item')` | Delete flash |
| 4 | Review restore() flash: `flash('restored.item')` | Restore flash |
| 5 | Review forceDelete() flash: `flash('force_deleted.item')` | Force delete flash |

#### TC-CR14: No FormRequest — store/update use plain Request, zero validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store(Request $request)` — parameter type is `Illuminate\Http\Request` | No FormRequest |
| 2 | Review `update(Request $request, $id)` — same plain Request type | No FormRequest |
| 3 | Verify no `$request->validate()` call exists anywhere in either method | Zero validation in controller |

#### TC-CR15: qty_used not cast to decimal in model — potential type/rounding issues

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review VndUsageLog model for `$casts = ['qty_used' => 'decimal:2']` | No cast defined |
| 2 | Note: qty_used stored as-is from $request — may be string, int, or float; DB DECIMAL will convert but Eloquent returns raw DB value | Type inconsistency |
| 3 | Verify decimal precision in edge cases: 150.50 stored as 150.50 vs 150.5; 0 stored as 0 vs 0.00 | Precision handling |

#### TC-CR16: VndUsageLogService::logUsageFromInvoice() — service method signature, create call, remarks format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `VndUsageLogService::logUsageFromInvoice($vendorId, $agreementItemId, $qtyUsed, $remarks)` signature | 4 params, static method, returns VndUsageLog |
| 2 | Review `VndUsageLog::create([...])` inside the service — all 6 fillable fields set | Proper create call |
| 3 | Review `'usage_date' => now()` — uses current timestamp | Date set correctly |
| 4 | Review `'remarks' => $remarks ?? 'Auto-logged from invoice generation'` — default remarks if null | Default fallback |

#### TC-CR17: VendorInvoiceController::generateInvoice() — integration: auto-log call after invoice creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review import: `use Modules\Vendor\Services\VndUsageLogService;` at top of controller | Import present |
| 2 | Review call: `VndUsageLogService::logUsageFromInvoice(...)` right after `VndInvoice::create(...)` | Called after invoice creation |
| 3 | Review params passed: vendor_id, agreement_item_id, qty_used, remarks with invoice_number reference | All required data passed |

### 10.4 Dependency TC Steps

#### TC-D01: Cascade delete — deleting a vendor cascades to delete all related usage logs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor V1 has 5 usage logs in vnd_usage_logs | Existing usage logs |
| 2 | Delete Vendor V1 (soft or hard delete triggers CASCADE) | Vendor deleted |
| 3 | Verify all 5 usage logs for V1 are also deleted (or soft-deleted depending on DB cascade timing) | Cascaded |
| 4 | Verify usage logs for other vendors are unaffected | Other data intact |

#### TC-D02: SET NULL — deleting an agreement_item sets usage_log.agreement_item_id to NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Usage log has agreement_item_id = 10 (references vnd_agreement_items_jnt) | Existing FK relation |
| 2 | Delete the referenced record from vnd_agreement_items_jnt where id=10 | Agreement item deleted |
| 3 | Verify usage_log.agreement_item_id = NULL for the related usage log | SET NULL applied |
| 4 | Verify other usage logs with different agreement_item_id are unaffected | No side effects |

#### TC-D03: SoftDeletes + deleted_at migration — verify deleted_at column exists in DB and SoftDeletes trait functions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check database schema: `DESCRIBE vnd_usage_logs;` | deleted_at column exists (TIMESTAMP NULL) |
| 2 | Create usage log, then destroy it | Soft-delete succeeds |
| 3 | Query DB: `SELECT * FROM vnd_usage_logs WHERE id = X` | deleted_at is NOT NULL |
| 4 | Restore usage log | deleted_at becomes NULL |

#### TC-D04: Filter by vendor_id depends on vnd_vendors table having records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No vendors exist in vnd_vendors table | Empty vendor list |
| 2 | Access usage log index with ?vendor_id=1 filter | Filter applied but no matching records |
| 3 | Verify empty result is returned (no error) | Graceful empty state |

#### TC-D05: Filter by usage_date depends on correct DATE column type in DB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify usage_date column type is DATE (not DATETIME or TIMESTAMP) | DATE type confirmed |
| 2 | Verify `whereDate('usage_date', $request->date)` works correctly with DATE type | Date-only comparison works |
| 3 | Verify filter works with various date formats (YYYY-MM-DD, with time component if sent) | Filter behaviour |

#### TC-D06: User relationship (logged_by) depends on users table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Usage log has logged_by = user_id that exists in users table | Valid user reference |
| 2 | Access `$usageLog->user` relationship | Returns User model |
| 3 | Usage log has logged_by = NULL (nullable field) | user() returns null without error |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/vendor-usage-log` | vendor-usage-log.index | index() | tenant.usage-log.viewAny |
| GET | `/vendor-usage-log/create` | vendor-usage-log.create | create() | tenant.usage-log.create |
| POST | `/vendor-usage-log` | vendor-usage-log.store | store() | tenant.usage-log.create |
| GET | `/vendor-usage-log/{vendor_usage_log}` | vendor-usage-log.show | show() | tenant.usage-log.view |
| GET | `/vendor-usage-log/{vendor_usage_log}/edit` | vendor-usage-log.edit | edit() | tenant.usage-log.update |
| PUT/PATCH | `/vendor-usage-log/{vendor_usage_log}` | vendor-usage-log.update | update() | tenant.usage-log.update |
| DELETE | `/vendor-usage-log/{vendor_usage_log}` | vendor-usage-log.destroy | destroy() | tenant.usage-log.delete |
| GET | `/vendor-usage-log/trash/view` | vendor-usage-log.trashed | trashed() | tenant.usage-log.restore |
| GET | `/vendor-usage-log/{id}/restore` | vendor-usage-log.restore | restore() | tenant.usage-log.restore |
| DELETE | `/vendor-usage-log/{id}/force-delete` | vendor-usage-log.forceDelete | forceDelete() | tenant.usage-log.forceDelete |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | No FormRequest — store() and update() use plain Request | **Critical** | No validation rules exist for any input field. `vendor_id`, `agreement_item_id`, `usage_date`, `qty_used`, `remarks` are all accepted raw from `$request->field` without validation. DB constraints (FK, NOT NULL, DECIMAL) may throw unhandled PDO exceptions. |
| KI-02 | DDL has no deleted_at column in initial migration (2026_06_15) | **High** | Original migration creates `vnd_usage_logs` without `deleted_at`. A second migration (2026_06_18_100111) adds `softDeletes()` conditionally. If the second migration is not run, destroy/restore/forceDelete operations will fail silently or throw errors. |
| KI-03 | logged_by is hardcoded to Auth::user()->id in store() | **Medium** | `logged_by` is forced to authenticated user's ID. There is no way to set a different logged_by value via the form. Additionally, update() does NOT include `logged_by` in the update array — it can never be changed after creation. |
| KI-04 | qty_used not cast to decimal in model | **Low** | `$casts` array is absent in VndUsageLog model. `qty_used` (DECIMAL(10,2)) is not cast to decimal, float, or any type. Eloquent returns the raw DB value (may be string). Decimal precision (e.g. 150.50 vs 150.5) may behave inconsistently. |
| KI-05 | All redirects go to vendor.vendor.index (dashboard) | **Low** | Every controller method redirects to `route('vendor.vendor.index')` (the vendor dashboard at `/vendor`), not to `vendor-usage-log.index` (the usage log list). Users must manually navigate to the Usage Logs tab after any CRUD operation. |
| KI-06 | index() uses single permission Gate (not Gate::any()) | **Info** | Unlike VendorController which uses `Gate::any()` with 7 permissions for dashboard access, VndUsageLogController uses `Gate::authorize('tenant.usage-log.viewAny')` — only users with this specific permission can access the list. |
| KI-07 | No unique constraints on any field | **Low** | The table has no UNIQUE keys. Duplicate usage log records (same vendor, same date, same item) can be created without any DB-level prevention. |
| KI-08 | No indexes on usage_date, logged_by, deleted_at | **Low** | Query performance may degrade with large datasets when filtering by usage_date or querying trashed records (deleted_at). |
| KI-09 | Auto-populate only covers invoice generation | **Info** | `VndUsageLogService::logUsageFromInvoice()` is only called from `VendorInvoiceController::generateInvoice()`. Other potential triggers (agreement changes, manual adjustments) are not auto-logged — manual CRUD still required for those cases. |

---

## 13. Feature Summary Matrix

| Feature | Controller Method(s) | Key Models | Pagination |
|---------|---------------------|------------|------------|
| Usage Log List | index() | VndUsageLog + Vendor + VndAgreementItem | 10 per page |
| Filter by vendor_id | index() (when vendor_id present) | VndUsageLog | 10 per page |
| Filter by usage_date | index() (when date present) | VndUsageLog | 10 per page |
| Create Usage Log | create(), store() | VndUsageLog | None (form) |
| View Usage Log | show() | VndUsageLog | None |
| Edit Usage Log | edit(), update() | VndUsageLog | None (form) |
| Soft-Delete / Restore | destroy(), trashed(), restore() | VndUsageLog | 10 per page (trash) |
| Force Delete | forceDelete() | VndUsageLog | None |
| Auto-Populate (Invoice) | `VndUsageLogService::logUsageFromInvoice()` called from `VendorInvoiceController::generateInvoice()` | VndUsageLog + VndInvoice | N/A (auto) |
