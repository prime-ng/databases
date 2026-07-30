# caf_Supplier — Test Case List & Business Conditions

**Module:** Cafeteria (CODE `CAF`, prefix `caf_`) · **Feature:** Suppliers (Vendor Management + FSSAI Expiry Tracking)
**DB scope:** TENANT-side (`caf_suppliers`) · **Test style:** Browser Dusk
**Primary table:** `caf_suppliers` · **Module URL prefix:** `/cafeteria/stock-compliance?tab=suppliers`
**Test file:** `caf_Supplier_TestCas.php`
**Tab:** Suppliers (second tab of Stock & Compliance)

Controllers:
- `SupplierController` — index (redirect), create, store, show, edit, update, destroy, toggleStatus, trashed, restore, forceDelete
- `CafeteriaController::stockCompliance()` — loads suppliers for tabbed page

Routes (`cafeteria.` prefix):
- `GET /cafeteria/stock-compliance` — tabbed page (suppliers tab)
- `GET /cafeteria/suppliers/create` — create page
- `POST /cafeteria/suppliers` — store
- `GET /cafeteria/suppliers/{supplier}` — show (with linked stock items)
- `GET /cafeteria/suppliers/{supplier}/edit` — edit
- `PUT /cafeteria/suppliers/{supplier}` — update
- `DELETE /cafeteria/suppliers/{supplier}` — destroy
- `POST /cafeteria/suppliers/{supplier}/toggle-status` — Ajax status toggle

**DDL reference:** `caf_suppliers` (Cafeteria DDL)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `caf_suppliers`: id (INT UNSIGNED PK AI), name (VARCHAR 150 NOT NULL), contact_person (VARCHAR 100 NULL), phone (VARCHAR 20 NULL), email (VARCHAR 100 NULL), address (TEXT NULL), fssai_license_no (VARCHAR 50 NULL), fssai_expiry_date (DATE NULL), supply_categories_json (JSON NULL), is_active (TINYINT 1 DEFAULT 1), created_by, created_at, updated_at, deleted_at. Index: idx_caf_sup_name | DDL |
| BC-DB-02 | Model `Supplier`: table caf_suppliers, SoftDeletes, fillable 9 fields, casts: supply_categories_json→array, fssai_expiry_date→date, is_active→boolean. Scopes: active(). Relations: stockItems() hasMany | Model |

### BC-VAL — Validation (StoreSupplierRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `name` required string max:150 | FR |
| BC-VAL-02 | `contact_person` nullable string max:100 | FR |
| BC-VAL-03 | `phone` nullable string max:20 | FR |
| BC-VAL-04 | `email` nullable email max:100 | FR |
| BC-VAL-05 | `address` nullable string | FR |
| BC-VAL-06 | `fssai_license_no` nullable string max:50 | FR |
| BC-VAL-07 | `fssai_expiry_date` nullable date | FR |
| BC-VAL-08 | `supply_categories_json` nullable array | FR |
| BC-VAL-09 | `supply_categories_json.*` string | FR |

### BC-AUTH — Authorization (SupplierPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `cafeteria.suppliers` (viewAny) — note: policy uses `cafeteria.supplier.viewAny` | View |
| BC-AUTH-02 | create/store gate `cafeteria.supplier.create` | Policy |
| BC-AUTH-03 | show/view gate `cafeteria.supplier.view` | Policy |
| BC-AUTH-04 | update/toggle gate `cafeteria.supplier.update` | Policy |
| BC-AUTH-05 | delete gate `cafeteria.supplier.delete` | Policy |
| BC-AUTH-06 | Status column visibility gate `cafeteria.suppliers.update` | View |
| BC-AUTH-07 | Action column visibility gate `cafeteria.suppliers.update` or `cafeteria.suppliers.delete` | View |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Suppliers tab: paginated table with Supplier Name (+ contact_person subtitle), Phone, Email, FSSAI Expiry, Status toggle, Actions | View |
| BC-BIZ-02 | Search: by supplier name | View |
| BC-BIZ-03 | Status filter: All / Active (1) / Inactive (0) | View |
| BC-BIZ-04 | FSSAI Expired (date past): red text + fa-circle-exclamation icon | View |
| BC-BIZ-05 | FSSAI Expiring ≤30 days: amber text + fa-triangle-exclamation icon | View |
| BC-BIZ-06 | No FSSAI expiry date: "—" em dash | View |
| BC-BIZ-07 | Status toggle: Ajax POST → flips is_active, returns JSON {success, is_active, message} | Ctrl |
| BC-BIZ-08 | Soft delete: destroy() sets deleted_at | Ctrl |
| BC-BIZ-09 | Show page: supplier details with linked StockItems relation | Ctrl |
| BC-BIZ-10 | Activity logged for: create, update, delete, toggle | Ctrl |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | No suppliers → empty state "No suppliers added yet." with truck icon | View |
| BC-EDG-02 | Delete supplier with linked stock items → supplier_id set to NULL (ON DELETE SET NULL) | DB |
| BC-EDG-03 | Delete already-deleted supplier → 404 (SoftDeletes) | Ctrl |

---

## 2. Test Case List

### Screen 1: Suppliers Tab (GET /cafeteria/stock-compliance?tab=suppliers)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFSUP-P10 | Positive | View | Suppliers tab: table with Name (+ contact person subtitle), Phone, Email, FSSAI Expiry, Status, Actions | Rendered | test_caf_sup_10 | Automated |
| TC-CAFSUP-P11 | Positive | View | Search filters by supplier name | Search | test_caf_sup_11 | Automated |
| TC-CAFSUP-P12 | Positive | View | Status filter: All / Active / Inactive | Filters | test_caf_sup_12 | Automated |
| TC-CAFSUP-P13 | Positive | View | Expired FSSAI: red text + exclamation icon | Red indicator | test_caf_sup_13 | Automated |
| TC-CAFSUP-P14 | Positive | View | Expiring FSSAI (≤30 days): amber text + triangle icon | Amber indicator | test_caf_sup_14 | Automated |
| TC-CAFSUP-P15 | Positive | View | No FSSAI expiry: "—" displayed | No data | test_caf_sup_15 | Automated |
| TC-CAFSUP-P16 | Positive | View | Empty state "No suppliers added yet." with icon | Empty | test_caf_sup_16 | Automated |
| TC-CAFSUP-P17 | Positive | View | Paginated 15 per page | Paginated | test_caf_sup_17 | Automated |

### Screen 2: CRUD + Status Toggle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFSUP-P30 | Positive | Ctrl | Create supplier → stored, redirect "Supplier added." | Created | test_caf_sup_30 | Automated |
| TC-CAFSUP-P31 | Positive | Ctrl | Update supplier → updated, redirect "Supplier updated." | Updated | test_caf_sup_31 | Automated |
| TC-CAFSUP-P32 | Positive | Ctrl | Soft delete supplier → deleted, trashed view | Deleted | test_caf_sup_32 | Automated |
| TC-CAFSUP-P33 | Positive | Ctrl | Toggle status active/inactive → Ajax JSON success | Toggled | test_caf_sup_33 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFSUP-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_caf_sup_200 | Automated |
| TC-CAFSUP-N201 | Negative | Auth | Without viewAny → tab hidden | Hidden | test_caf_sup_201 | Automated |
| TC-CAFSUP-N202 | Negative | Auth | Without create → 403 on store | 403 | test_caf_sup_202 | Automated |
| TC-CAFSUP-N203 | Negative | Auth | Without update → 403 on edit/toggle | 403 | test_caf_sup_203 | Automated |
| TC-CAFSUP-N204 | Negative | Auth | Without delete → 403 on destroy | 403 | test_caf_sup_204 | Automated |
