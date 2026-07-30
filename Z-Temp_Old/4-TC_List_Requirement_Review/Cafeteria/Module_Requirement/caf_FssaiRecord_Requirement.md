# FSSAI Records — Business Requirements

## What This Screen Does

The FSSAI tab manages the institution's FSSAI (Food Safety and Standards Authority of India) compliance records — both **Licenses** and **Audit** reports. This includes the school's own FSSAI licenses (FssaiRecord with `record_type = 'License'`) and supplier FSSAI information (stored both on the Supplier model as `fssai_expiry_date` and on FssaiRecord records linked to suppliers).

The tab shows expiry alerts at the top: supplier FSSAI licenses expiring within 30 days and school FSSAI licenses expiring within 60 days. Each row shows days remaining and visual styling (amber for <30 days, red badge for expired).

## When This Screen Is Used

- **License Management**: Tracking school FSSAI license issuance and renewal
- **Audit Tracking**: Recording FSSAI audit visits, scores, and corrective actions
- **Compliance Monitoring**: Ensuring all food-handling entities have valid licenses
- **Renewal Planning**: Identifying upcoming expirations for proactive renewal

## Key Fields

### License Records (`record_type = 'License'`)
- **Supplier** (FK → `caf_suppliers`, nullable) — Linked supplier (optional; school licenses have no supplier)
- **License Number** (string 50) — FSSAI license number
- **License Type** (enum) — Basic, State, Central
- **Licensed Entity Name** (string 150) — Name of the entity holding the license
- **Issue Date** (date) — When license was issued
- **Expiry Date** (date) — When license expires (must be ≥ issue_date)
- **Document Media ID** (FK → `sys_media`, nullable) — Uploaded license document (feature placeholder, commented out)

### Audit Records (`record_type = 'Audit'`)
- **Supplier** (FK → `caf_suppliers`, nullable) — Audited supplier
- **Audit Date** (date) — When audit was conducted
- **Auditor Name** (string 100) — Name of the auditor
- **Audit Score** (integer 1-10) — Compliance score
- **Audit Remarks** (text, nullable) — Notes from the audit
- **Corrective Actions** (text, nullable) — Actions taken post-audit
- **Next Audit Date** (date, nullable) — Scheduled next audit (must be > audit_date)

### Shared Fields
- **Record Type** (enum) — License, Audit
- **Is Active** (boolean, default true) — Toggle via status switch
- **Staff Name** — From `creator` relation

## Business Rules

**Record Type Switching:** The create modal dynamically shows/hides fields based on `record_type`:
- License: shows supplier, license_number, license_type, issue_date, expiry_date, licensed_entity_name
- Audit: shows supplier, audit_date, auditor_name, audit_score, audit_remarks, corrective_actions, next_audit_date

**Expiry Alerts:**
- Supplier FSSAI (from `Supplier` model): Expiring within 30 days → warning alert on FSSAI tab
- School License (from `FssaiRecord` where `record_type = 'License'`): Expiring within 60 days → danger alert on FSSAI tab
- Row-level: <30 days before expiry → `table-warning` class on tr + badge showing days remaining
- Expired: `badge bg-danger-subtle` showing "Expired"

**Expiry Check Service:** `StockService::checkFssaiExpiry()` scans supplier FSSAI (30-day and 7-day batches) and school licenses (60-day and 30-day batches), dispatching placeholder alerts (connected to NTF module).

**Delete:** Sets `is_active = false`, then soft deletes. The destroy() method also calls `$record->delete()` for soft delete.

**Status Toggle:** Ajax endpoint `toggleStatus()` flips `is_active`. Returns JSON `{success, is_active, message}`.

**Soft Delete:** Model uses SoftDeletes. Controller has `trashed()`, `restore()`, `forceDelete()` methods. Restore also sets `is_active = true`.

**Document Download:** Feature is commented out (`download()` method in controller is commented). The `fssai_document_media_id` field and `@if($rec->fssai_document_media_id)` button in view are preserved but non-functional.

**Activity Logging:**
- Create: `"FSSAI record created."`
- Update: `"FSSAI record updated."` (with changes diff logged)
- Delete: `"FSSAI record deactivated and trashed."`
- Toggle: `"FSSAI record status updated."`
- Restore: `"FSSAI record restored."`
- Force Delete: `"FSSAI record permanently deleted."`

## Workflow

1. Staff navigates to Cafeteria → Stock & Compliance → FSSAI tab
2. Expiry alerts shown at top if any licenses are expiring
3. Staff sees paginated table: Licence #, Holder (licensed_entity_name), Type (License/Audit), Issue Date, Expires (with days-remaining badge), Status toggle, Actions
4. Staff clicks "Add FSSAI" → modal with dynamic form (License fields or Audit fields based on record_type dropdown)
5. Staff can view detail page, edit, toggle status, or delete records

## Related Screens

- **Suppliers** — Second tab; supplier FSSAI expiry shown in supplier table
- **Dashboard** — Expiring supplier/school FSSAI alerts on dashboard
- **Stock Items** — Items linked to suppliers who need valid FSSAI

## Requirements

- MUST display FSSAI records at `/cafeteria/stock-compliance?tab=fssai` as paginated table with search + status filter (Active/Expired)
- MUST authorize via `cafeteria.fssai.*` permission gates (note: no dedicated policy file exists)
- MUST support two record types: License and Audit with conditional form fields
- MUST show expiry alerts: supplier (30d) and school license (60d)
- MUST show days-remaining badge on each row (warning if <30d, danger if expired)
- MUST support status toggle via Ajax
- MUST support soft delete with restore/forceDelete (restore reactivates is_active)
- MUST validate expiry_date after_or_equal:issue_date, next_audit_date after:audit_date
- MUST log all CRUD and toggle actions via activityLog() with change tracking
