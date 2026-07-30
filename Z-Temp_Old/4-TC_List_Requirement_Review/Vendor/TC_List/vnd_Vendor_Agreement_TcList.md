# vnd_Vendor_Agreement_TcList

## Module: Vendor → Vendor Agreement Management → Agreement CRUD

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Vendor (VND) — Agreement Management |
| Tab Group | Vendor Dashboard (Agreements Tab) |
| Features | Agreement List, Create/Edit/View/Delete/Restore/Force-Delete, Toggle Status, Agreement File Upload, Activity Logging, Agreement Items with Billing Model |
| URL(s) | `/vendor-agreement`, `/vendor-agreement/create`, `/vendor-agreement/{vendor-agreement}/edit`, `/vendor-agreement/{vendor-agreement}`, `/vendor-agreement/trash/view`, `/vendor-agreement/{id}/restore`, `/vendor-agreement/{id}/force-delete`, `/vendor-agreement/{id}/toggle-status` |
| Controller | `Modules\Vendor\Http\Controllers\VendorAgreementController` |
| Model(s) | `VndAgreement`, `VndAgreementItem`, `VndVendor`, `VndItem`, `Vehicle`, `DriverHelper` |
| Validation | `VendorAgreementRequest` (10 rules) |
| Permission Gates | `tenant.vendor-agreement.viewAny`, `tenant.vendor-agreement.view`, `tenant.vendor-agreement.create`, `tenant.vendor-agreement.update`, `tenant.vendor-agreement.delete`, `tenant.vendor-agreement.restore`, `tenant.vendor-agreement.forceDelete` |
| Soft Deletes | Yes — VndAgreement and VndAgreementItem use `SoftDeletes` trait |
| Events | `activityLog()` on store, update, destroy, restore, forceDelete, toggleStatus |

---

## 2. Pre-conditions

- Required permissions: `tenant.vendor-agreement.viewAny`, `tenant.vendor-agreement.create`, `tenant.vendor-agreement.update`, `tenant.vendor-agreement.view`, `tenant.vendor-agreement.delete`, `tenant.vendor-agreement.restore`, `tenant.vendor-agreement.forceDelete`
- At least one active vendor must exist in `vnd_vendors` (referenced by `vendor_id`)
- At least one active item must exist in `vnd_items` (referenced by `item_id`)
- For `related_entity_type`: at least one record in `sys_dropdown_table` with valid `additional_info` JSON containing `table_name` key
- For agreement file tests: Spatie Media Library configured with `public` disk
- For agreement items-related tests: vehicles and driver helpers seeded in respective tables
- For trash/restore tests: at least one soft-deleted agreement record
- For toggle-status tests: at least one active and one inactive agreement record
- For pagination tests: at least 11 agreement records

---

## 3. Default Data Load

### 3.1 Filter Data for Agreements Tab (index page)

| Parameter | Source | Notes |
|-----------|--------|-------|
| `vendor-agreement` records | `VndAgreement::with('vendor')->latest()->paginate(10)` | Paginated list with vendor relation |
| `vendors` (active) | `VndVendor::active()->get()` | Dropdown for create/edit forms |
| `items` (active) | `VndItem::active()->get()` | Dropdown for agreement item |
| `vehicles` (active) | `Vehicle::active()->get()` | Dropdown for related entity |
| `driver helpers` (active) | `DriverHelper::active()->get()` | Dropdown for related entity |

### 3.2 Search/Filter Behaviours

- `index()` — No search/filter params processed in controller; returns full paginated list
- `create()` / `edit()` — Loads vendors, items, vehicles, driver helpers as dropdown data
- `show()` — Loads single agreement with `vendor` and `agreementItems` relations

---

## 4. BC-DB — Database Schema

### 4.1 `vnd_agreements` — Primary Agreement Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| vendor_id | INT UNSIGNED | NOT NULL | — | FK → vnd_vendors(id) CASCADE |
| agreement_ref_no | VARCHAR(50) | YES | NULL | Reference number (nullable) |
| start_date | DATE | NOT NULL | — | Agreement start date |
| end_date | DATE | NOT NULL | — | Agreement end date |
| status | ENUM('DRAFT','ACTIVE','EXPIRED','TERMINATED') | YES | 'DRAFT' | Current status |
| billing_cycle | ENUM('MONTHLY','ONE_TIME','ON_DEMAND') | YES | 'MONTHLY' | Billing frequency |
| payment_terms_days | INT UNSIGNED | YES | 30 | Payment due days |
| remarks | TEXT | YES | NULL | Free-text remarks |
| agreement_uploaded | TINYINT(1) | YES | 0 | File upload flag |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| is_deleted | TINYINT(1) | YES | 0 | Legacy deleted flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- KEY `fk_vnd_agreements_vendor` (`vendor_id`)
- KEY `idx_vnd_agreements_status` (`status`)
- KEY `idx_vnd_agreements_dates` (`start_date`, `end_date`)

**Foreign Keys:**
- `fk_vnd_agreements_vendor` → `vnd_vendors(id)` ON DELETE CASCADE

### 4.2 `vnd_agreement_items_jnt` — Agreement Items Junction Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| agreement_id | INT UNSIGNED | NOT NULL | — | FK → vnd_agreements(id) CASCADE |
| item_id | INT UNSIGNED | NOT NULL | — | FK → vnd_items(id) RESTRICT |
| billing_model | ENUM('FIXED','PER_UNIT','HYBRID') | YES | 'FIXED' | Billing methodology |
| fixed_charge | DECIMAL(12,2) | YES | 0.00 | Fixed charge amount |
| unit_rate | DECIMAL(10,2) | YES | 0.00 | Per-unit rate |
| min_guarantee_qty | DECIMAL(10,2) | YES | 0.00 | Minimum guarantee quantity |
| tax1_percent | DECIMAL(5,2) | YES | 0.00 | Tax 1 percentage |
| tax2_percent | DECIMAL(5,2) | YES | 0.00 | Tax 2 percentage |
| tax3_percent | DECIMAL(5,2) | YES | 0.00 | Tax 3 percentage |
| tax4_percent | DECIMAL(5,2) | YES | 0.00 | Tax 4 percentage |
| related_entity_type | INT UNSIGNED | YES | NULL | FK → sys_dropdown_table(id) RESTRICT |
| related_entity_table | VARCHAR(60) | YES | NULL | Table name (derived from sys_dropdown) |
| related_entity_id | INT UNSIGNED | YES | NULL | ID in related_entity_table |
| description | VARCHAR(255) | YES | NULL | Line-item description |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| is_deleted | TINYINT(1) | YES | 0 | Legacy deleted flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- KEY `fk_vnd_agr_items_agreement` (`agreement_id`)
- KEY `fk_vnd_agr_items_item` (`item_id`)
- KEY `fk_vnd_agr_items_entity_type` (`related_entity_type`)

**Foreign Keys:**
- `fk_vnd_agr_items_agreement` → `vnd_agreements(id)` ON DELETE CASCADE
- `fk_vnd_agr_items_item` → `vnd_items(id)` ON DELETE RESTRICT
- `fk_vnd_agr_items_entity_type` → `sys_dropdown_table(id)` ON DELETE RESTRICT

---

## 5. BC-VAL — Validation Rules

### 5.1 VendorAgreementRequest Validation

| Field | Rules | Error Message |
|-------|-------|---------------|
| vendor_id | required, exists:vnd_vendors,id | "The vendor id field is required." |
| agreement_ref_no | nullable, string, max:50 | — |
| start_date | required, date | "The start date field is required." |
| end_date | required, date, after_or_equal:start_date | "The end date must be a date after or equal to start date." |
| status | required, in:DRAFT,ACTIVE,EXPIRED,TERMINATED | "The status field is required." or invalid value |
| billing_cycle | required, in:MONTHLY,ONE_TIME,ON_DEMAND | "The billing cycle field is required." or invalid value |
| payment_terms_days | nullable, integer, min:0 | — |
| remarks | nullable, string | — |
| agreement_file | nullable, file, mimes:pdf,jpg,jpeg,png, max:5120 | File type or size validation |
| is_active | boolean | "The is active field must be true or false." |

**prepareForValidation:** `is_active` is converted from checkbox to boolean via `$this->boolean('is_active')` if present

**Authorization:** `authorize()` method returns `true` (no Gate check in FormRequest — defence delegated to controller)

**Known Validation Gaps:**
- No `exists:vnd_vendors,id,is_active,1` check — vendor must exist but may be inactive
- No `after_or_equal:start_date` on end_date but no upper bound check (no max end_date validation)
- No `exists:vnd_items,id` validation on item_id (validated only at DB FK level)
- No validation for related_entity fields (entity_type, entity_id)

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method(s) | Model Policy |
|----------------|---------------------|-------------|
| tenant.vendor-agreement.viewAny | index() | Policy@viewAny |
| tenant.vendor-agreement.view | show() | Policy@view |
| tenant.vendor-agreement.create | create(), store() | Policy@create |
| tenant.vendor-agreement.update | edit(), update(), toggleStatus() | Policy@update |
| tenant.vendor-agreement.delete | destroy() | Policy@delete |
| tenant.vendor-agreement.restore | trashed(), restore() | Policy@restore |
| tenant.vendor-agreement.forceDelete | forceDelete() | Policy@forceDelete |

**Blade @can directives (expected in views):**
- `@can('tenant.vendor-agreement.viewAny')` — Index list access
- `@can('tenant.vendor-agreement.create')` — Create button
- `@can('tenant.vendor-agreement.update')` — Edit and Toggle Status actions
- `@can('tenant.vendor-agreement.view')` — View action button
- `@can('tenant.vendor-agreement.delete')` — Delete action button

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | Single Item Per Agreement | store() creates ONE `VndAgreementItem::create()` per agreement, not a loop; edit() returns `agreementSingleItem` via hasOne — effectively a one-to-one despite junction table design |
| BC-BIZ-02 | Update Overwrites All Items | update() calls `VndAgreementItem::where(agreement_id,$id)->update()` — updates ALL existing items for the agreement (does NOT create new items) |
| BC-BIZ-03 | Destroy Cascades to Items | destroy() manually deletes `VndAgreementItem::where(agreement_id)->delete()` before agreement delete — redundant with ON DELETE CASCADE (Known Issue) |
| BC-BIZ-04 | Restore Restores Items | restore() restores agreement then restores agreement items (onlyTrashed->where->restore) |
| BC-BIZ-05 | ForceDelete Cascades | forceDelete() force-deletes agreement items, clears media collection, then force-deletes agreement |
| BC-BIZ-06 | Toggle Status Cascades to Items | toggleStatus() toggles `is_active` on both agreement and ALL its agreement items — potentially unexpected side effect |
| BC-BIZ-07 | Agreement File Upload on Store | store() uploads file to Spatie Media Library collection `agreement` (model registers as 'agreement' but controller uses 'agreement_file' — mismatch Known Issue) |
| BC-BIZ-08 | Agreement File Replace on Update | update() clears media collection and re-uploads if new file provided |
| BC-BIZ-09 | Activity Log All Operations | activityLog() called on store, update, destroy, restore, forceDelete, toggleStatus |
| BC-BIZ-10 | Related Entity Type Lookup | store/update look up `sys_dropdown_table` by `related_entity_type` ID, extract `table_name` from `additional_info` JSON, store in `related_entity_table` |
| BC-BIZ-11 | Redirect to Vendor Dashboard | store/update redirect to `vendor.vendor.index` (not agreement.index) — Known Issue |
| BC-BIZ-12 | Transactional Safety | store, update, destroy, restore, forceDelete, toggleStatus use `DB::transaction()` or `DB::beginTransaction/commit/rollback` |
| BC-BIZ-13 | File Upload Flag | When agreement_file is uploaded, `agreement_uploaded` set to `true` in DB; cleared to `false` on forceDelete |
| BC-BIZ-14 | Change Tracking on Update | update() captures changes on agreement model before/after update for activity log |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_vnd_agreements_vendor | vnd_agreements.vendor_id | vnd_vendors.id | CASCADE |
| fk_vnd_agr_items_agreement | vnd_agreement_items_jnt.agreement_id | vnd_agreements.id | CASCADE |
| fk_vnd_agr_items_item | vnd_agreement_items_jnt.item_id | vnd_items.id | RESTRICT |
| fk_vnd_agr_items_entity_type | vnd_agreement_items_jnt.related_entity_type | sys_dropdown_table.id | RESTRICT |

---

## 9. Test Case Summary

### 9.1 Agreement CRUD — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VNDAGR-P01 | Agreement CRUD | Positive | Agreement list loads with pagination and vendor relation | 4 |
| TC-VNDAGR-P02 | Agreement CRUD | Positive | Create agreement — all required fields (minimal) | 7 |
| TC-VNDAGR-P03 | Agreement CRUD | Positive | Create agreement — all optional fields including agreement_file | 8 |
| TC-VNDAGR-P04 | Agreement CRUD | Positive | Create agreement — billing model FIXED with fixed_charge | 7 |
| TC-VNDAGR-P05 | Agreement CRUD | Positive | Create agreement — billing model PER_UNIT with unit_rate and min_guarantee_qty | 7 |
| TC-VNDAGR-P06 | Agreement CRUD | Positive | Create agreement — billing model HYBRID with both fixed_charge and unit_rate | 7 |
| TC-VNDAGR-P07 | Agreement CRUD | Positive | Create agreement — with all 4 tax percentages | 7 |
| TC-VNDAGR-P08 | Agreement CRUD | Positive | Create agreement — with related entity (vehicle) | 8 |
| TC-VNDAGR-P09 | Agreement CRUD | Positive | Create agreement — with related entity (driver helper) | 8 |
| TC-VNDAGR-P10 | Agreement CRUD | Positive | Create agreement — agreement_ref_no provided | 6 |
| TC-VNDAGR-P11 | Agreement CRUD | Positive | Create agreement — remarks field populated | 6 |
| TC-VNDAGR-P12 | Agreement CRUD | Positive | Create agreement — payment_terms_days set to custom value | 6 |
| TC-VNDAGR-P13 | Agreement CRUD | Positive | View agreement detail with vendor and agreement items | 4 |
| TC-VNDAGR-P14 | Agreement CRUD | Positive | Edit agreement — update start_date, end_date, status | 6 |
| TC-VNDAGR-P15 | Agreement CRUD | Positive | Edit agreement — replace agreement_file | 6 |
| TC-VNDAGR-P16 | Agreement CRUD | Positive | Edit agreement — change billing model and rates | 6 |
| TC-VNDAGR-P17 | Agreement CRUD | Positive | Edit agreement — update tax percentages | 6 |
| TC-VNDAGR-P18 | Agreement CRUD | Positive | Edit agreement — change related entity | 6 |
| TC-VNDAGR-P19 | Agreement CRUD | Positive | Edit agreement — update remarks | 5 |
| TC-VNDAGR-P20 | Agreement CRUD | Positive | Toggle status — active to inactive | 5 |
| TC-VNDAGR-P21 | Agreement CRUD | Positive | Toggle status — inactive to active | 5 |
| TC-VNDAGR-P22 | Agreement CRUD | Positive | Soft-delete agreement | 5 |
| TC-VNDAGR-P23 | Agreement CRUD | Positive | Restore agreement from trash | 5 |
| TC-VNDAGR-P24 | Agreement CRUD | Positive | Force-delete agreement | 5 |
| TC-VNDAGR-P25 | Agreement CRUD | Positive | Activity log created on agreement store | 4 |
| TC-VNDAGR-P26 | Agreement CRUD | Positive | Activity log created on agreement update | 4 |
| TC-VNDAGR-P27 | Agreement CRUD | Positive | Activity log created on agreement soft-delete | 3 |
| TC-VNDAGR-P28 | Agreement CRUD | Positive | Activity log created on agreement restore | 3 |
| TC-VNDAGR-P29 | Agreement CRUD | Positive | Activity log created on agreement force-delete | 3 |
| TC-VNDAGR-P30 | Agreement CRUD | Positive | Activity log created on agreement toggle-status | 3 |
| TC-VNDAGR-P31 | Agreement CRUD | Positive | Agreement file upload — verify media stored and conversion generated | 5 |
| TC-VNDAGR-P32 | Agreement CRUD | Positive | Agreement file — clear old file on second upload | 4 |
| TC-VNDAGR-P33 | Agreement CRUD | Positive | Create agreement with status=DRAFT | 6 |
| TC-VNDAGR-P34 | Agreement CRUD | Positive | Create agreement with status=ACTIVE and start_date <= today | 6 |
| TC-VNDAGR-P35 | Agreement CRUD | Positive | Create agreement with billing_cycle=ONE_TIME | 6 |
| TC-VNDAGR-P36 | Agreement CRUD | Positive | Create agreement with billing_cycle=ON_DEMAND | 6 |
| TC-VNDAGR-P37 | Agreement CRUD | Positive | Agreement item record created with correct defaults for missing optional fields | 6 |
| TC-VNDAGR-P38 | Agreement CRUD | Positive | Store — related_entity_type dropdown lookup resolves table_name from sys_dropdown_table JSON | 5 |
| TC-VNDAGR-P39 | Agreement CRUD | Positive | ToggleStatus — DB transaction toggles is_active on both agreement and agreement items | 6 |
| TC-VNDAGR-P40 | Agreement CRUD | Positive | Scope current() — filters agreements where start_date <= now AND end_date >= now | 6 |
| TC-VNDAGR-P41 | Agreement CRUD | Positive | Model defaults — status, billing_cycle, payment_terms_days, agreement_uploaded, is_active | 4 |
| TC-VNDAGR-P42 | Agreement CRUD | Positive | Agreement file upload — stored in 'agreement' collection on 'public' disk as singleFile | 5 |
| TC-VNDAGR-P43 | Agreement CRUD | Positive | Agreement file upload — agreement_uploaded flag set to true after file upload | 4 |

### 9.2 Agreement CRUD — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VNDAGR-N01 | Agreement CRUD | Negative | Create — missing vendor_id | 2 |
| TC-VNDAGR-N02 | Agreement CRUD | Negative | Create — vendor_id does not exist in vnd_vendors | 2 |
| TC-VNDAGR-N03 | Agreement CRUD | Negative | Create — vendor_id is for a soft-deleted vendor | 2 |
| TC-VNDAGR-N04 | Agreement CRUD | Negative | Create — missing start_date | 2 |
| TC-VNDAGR-N05 | Agreement CRUD | Negative | Create — missing end_date | 2 |
| TC-VNDAGR-N06 | Agreement CRUD | Negative | Create — end_date before start_date | 2 |
| TC-VNDAGR-N07 | Agreement CRUD | Negative | Create — end_date equals start_date (boundary — valid per after_or_equal) | 2 |
| TC-VNDAGR-N08 | Agreement CRUD | Negative | Create — missing status | 2 |
| TC-VNDAGR-N09 | Agreement CRUD | Negative | Create — invalid status value | 2 |
| TC-VNDAGR-N10 | Agreement CRUD | Negative | Create — missing billing_cycle | 2 |
| TC-VNDAGR-N11 | Agreement CRUD | Negative | Create — invalid billing_cycle value | 2 |
| TC-VNDAGR-N12 | Agreement CRUD | Negative | Create — agreement_ref_no exceeds 50 chars | 2 |
| TC-VNDAGR-N13 | Agreement CRUD | Negative | Create — payment_terms_days negative integer | 2 |
| TC-VNDAGR-N14 | Agreement CRUD | Negative | Create — agreement_file invalid mime type (.exe) | 2 |
| TC-VNDAGR-N15 | Agreement CRUD | Negative | Create — agreement_file exceeds 5MB (5120 KB) | 2 |
| TC-VNDAGR-N16 | Agreement CRUD | Negative | Create — is_active missing (checkbox not checked) — expect false/default | 2 |
| TC-VNDAGR-N17 | Agreement CRUD | Negative | Update — non-existent agreement ID | 2 |
| TC-VNDAGR-N18 | Agreement CRUD | Negative | Destroy — non-existent agreement ID | 2 |
| TC-VNDAGR-N19 | Agreement CRUD | Negative | Restore — non-existent agreement ID | 2 |
| TC-VNDAGR-N20 | Agreement CRUD | Negative | Force delete — non-existent agreement ID | 2 |
| TC-VNDAGR-N21 | Agreement CRUD | Negative | Toggle — missing is_active parameter | 2 |
| TC-VNDAGR-N22 | Agreement CRUD | Negative | Toggle — non-boolean is_active value | 2 |
| TC-VNDAGR-N23 | Agreement CRUD | Negative | Toggle — non-existent agreement ID | 2 |
| TC-VNDAGR-N24 | Agreement CRUD | Negative | Permission — index without tenant.vendor-agreement.viewAny | 2 |
| TC-VNDAGR-N25 | Agreement CRUD | Negative | Permission — create without tenant.vendor-agreement.create | 2 |
| TC-VNDAGR-N26 | Agreement CRUD | Negative | Permission — store without tenant.vendor-agreement.create | 2 |
| TC-VNDAGR-N27 | Agreement CRUD | Negative | Permission — edit without tenant.vendor-agreement.update | 2 |
| TC-VNDAGR-N28 | Agreement CRUD | Negative | Permission — update without tenant.vendor-agreement.update | 2 |
| TC-VNDAGR-N29 | Agreement CRUD | Negative | Permission — view show without tenant.vendor-agreement.view | 2 |
| TC-VNDAGR-N30 | Agreement CRUD | Negative | Permission — destroy without tenant.vendor-agreement.delete | 2 |
| TC-VNDAGR-N31 | Agreement CRUD | Negative | Permission — trashed without tenant.vendor-agreement.restore | 2 |
| TC-VNDAGR-N32 | Agreement CRUD | Negative | Permission — restore without tenant.vendor-agreement.restore | 2 |
| TC-VNDAGR-N33 | Agreement CRUD | Negative | Permission — forceDelete without tenant.vendor-agreement.forceDelete | 2 |
| TC-VNDAGR-N34 | Agreement CRUD | Negative | Permission — toggleStatus without tenant.vendor-agreement.update | 2 |
| TC-VNDAGR-N35 | Agreement CRUD | Negative | Store — DB transaction rollback on file upload failure | 3 |
| TC-VNDAGR-N36 | Agreement CRUD | Negative | Update — agreement_ref_no changed to a value exceeding 50 chars | 2 |
| TC-VNDAGR-N37 | Agreement CRUD | Negative | Restore — attempt to restore non-trashed (active) agreement | 2 |
| TC-VNDAGR-N38 | Agreement CRUD | Negative | Force delete — active (non-trashed) agreement | 2 |
| TC-VNDAGR-N39 | Agreement CRUD | Negative | Store — related_entity_type dropdown record missing, firstOrFail throws exception | 3 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR-VAGR-01 | Code Review | Review | index() — Gate + with('vendor') + latest() + paginate(10) | 4 |
| TC-CR-VAGR-02 | Code Review | Review | create() — Gate + eager load vendors, items, vehicles, driver helpers | 4 |
| TC-CR-VAGR-03 | Code Review | Review | store() — Gate + DB::transaction + create + file upload + item create + activityLog + redirect | 7 |
| TC-CR-VAGR-04 | Code Review | Review | store() — single VndAgreementItem::create() (not a loop) | 3 |
| TC-CR-VAGR-05 | Code Review | Review | show() — Gate + with(['vendor','agreementItems']) + findOrFail | 3 |
| TC-CR-VAGR-06 | Code Review | Review | edit() — Gate + findOrFail + agreementSingleItem hasOne pattern | 4 |
| TC-CR-VAGR-07 | Code Review | Review | update() — Gate + DB::transaction + change tracking + file replace + update existing items | 6 |
| TC-CR-VAGR-08 | Code Review | Review | update() — VndAgreementItem::where()->update() overwrites all items | 3 |
| TC-CR-VAGR-09 | Code Review | Review | destroy() — Gate + delete items + delete agreement + redirect | 4 |
| TC-CR-VAGR-10 | Code Review | Review | trashed() — Gate + onlyTrashed + with('vendor') + paginate(10) | 3 |
| TC-CR-VAGR-11 | Code Review | Review | restore() — Gate + DB::transaction + restore agreement + restore items | 4 |
| TC-CR-VAGR-12 | Code Review | Review | forceDelete() — Gate + DB::transaction + forceDelete items + clearMedia + forceDelete agreement | 5 |
| TC-CR-VAGR-13 | Code Review | Review | toggleStatus() — Gate + validate + update agreement + update all items + activityLog + JSON | 6 |
| TC-CR-VAGR-14 | Code Review | Review | VendorAgreementRequest — all validation rules | 5 |
| TC-CR-VAGR-15 | Code Review | Review | VendorAgreementRequest — authorize() returns true (no Gate) | 2 |
| TC-CR-VAGR-16 | Code Review | Review | VndAgreement Model — fillable, casts, defaults, relationships, scopes, media | 6 |
| TC-CR-VAGR-17 | Code Review | Review | VndAgreementItem Model — fillable, casts, relationships | 4 |
| TC-CR-VAGR-18 | Code Review | Review | Related entity type lookup — sys_dropdown_table additional_info JSON parsing | 4 |
| TC-CR-VAGR-19 | Code Review | Review | Collection name mismatch — model registers 'agreement', controller adds to 'agreement_file' | 3 |
| TC-CR-VAGR-20 | Code Review | Review | Redirect route — store/update redirect to vendor.vendor.index (not agreement.index) | 2 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-D-VAGR-01 | Dependency | Dependency | Vendor FK CASCADE — deleting vendor cascades to agreements | 4 |
| TC-D-VAGR-02 | Dependency | Dependency | Agreement FK CASCADE — deleting agreement cascades to agreement items | 4 |
| TC-D-VAGR-03 | Dependency | Dependency | Item FK RESTRICT — cannot delete item referenced by agreement item | 3 |
| TC-D-VAGR-04 | Dependency | Dependency | Entity type FK RESTRICT — cannot delete sys_dropdown referenced by agreement item | 3 |
| TC-D-VAGR-05 | Dependency | Dependency | SoftDelete — soft-deleted agreements excluded from normal queries | 3 |
| TC-D-VAGR-06 | Dependency | Dependency | SoftDelete — agreement items soft-deleted when agreement is soft-deleted | 3 |
| TC-D-VAGR-07 | Dependency | Dependency | Spatie Media Library — agreement collection single-file, public disk | 4 |
| TC-D-VAGR-08 | Dependency | Dependency | Spatie Media Conversions — small (150x150) and medium (400x400) | 3 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Agreement CRUD

#### TC-VNDAGR-P01: Agreement list loads with pagination and vendor relation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-agreement.viewAny` permission navigates to `/vendor-agreement` | Agreement list loads |
| 2 | Verify list includes columns: vendor name, agreement_ref_no, start_date, end_date, status, billing_cycle, is_active toggle, Actions | All columns present |
| 3 | Verify each row shows vendor name (from vendor relation) | Vendor relation loaded |
| 4 | Verify pagination links (10 per page) | Paginated |

#### TC-VNDAGR-P02: Create agreement — all required fields (minimal)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-agreement.create` permission clicks "Add Agreement" | Create form loads |
| 2 | Select a valid vendor from vendor dropdown | Vendor selected |
| 3 | Enter start_date = "2026-01-01", end_date = "2026-12-31" | Dates populated |
| 4 | Select status = "ACTIVE", billing_cycle = "MONTHLY" | Fields set |
| 5 | Leave agreement_ref_no, payment_terms_days, remarks, agreement_file, is_active as defaults | Defaults applied |
| 6 | Select a valid item from item dropdown, verify billing_model defaults to "FIXED" | Item selected |
| 7 | Click Submit | Redirected to vendor dashboard |
| 8 | Verify success flash message appears and new agreement exists in DB with default payment_terms_days=30, is_active=1, agreement_uploaded=0 | Agreement created |

#### TC-VNDAGR-P03: Create agreement — all optional fields including agreement_file

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill all required fields: vendor_id (valid), start_date="2026-06-01", end_date="2027-05-31", status="ACTIVE", billing_cycle="MONTHLY" | Required fields set |
| 3 | Fill optional fields: agreement_ref_no="AGR-001", payment_terms_days=45, remarks="Test agreement with file" | Optional populated |
| 4 | Upload agreement_file = valid PDF (size < 5MB) | File attached |
| 5 | Set is_active = true (checkbox checked) | Active |
| 6 | Select item, set billing_model = "FIXED", fixed_charge = 15000.00 | Item data set |
| 7 | Click Submit | Success |
| 8 | Verify DB: agreement_uploaded = 1, media record exists in media table, file on public disk | File uploaded |

#### TC-VNDAGR-P04: Create agreement — billing model FIXED with fixed_charge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter required fields: vendor_id, start_date, end_date, status, billing_cycle | Required set |
| 3 | Select item, set billing_model = "FIXED" | FIXED selected |
| 4 | Set fixed_charge = 25000.00 (unit_rate, min_guarantee_qty remain 0.00) | Charge set |
| 5 | Submit form | Success |
| 6 | Verify DB: billing_model = 'FIXED', fixed_charge = 25000.00, unit_rate = 0.00 | FIXED billing stored |
| 7 | Verify success flash message | Flash shown |

#### TC-VNDAGR-P05: Create agreement — billing model PER_UNIT with unit_rate and min_guarantee_qty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter required fields | Required set |
| 3 | Select item, set billing_model = "PER_UNIT" | PER_UNIT selected |
| 4 | Set unit_rate = 500.00, min_guarantee_qty = 100.00 (fixed_charge remains 0.00) | Rate and qty set |
| 5 | Submit form | Success |
| 6 | Verify DB: billing_model = 'PER_UNIT', unit_rate = 500.00, min_guarantee_qty = 100.00, fixed_charge = 0.00 | PER_UNIT stored |
| 7 | Verify flash message | Flash shown |

#### TC-VNDAGR-P06: Create agreement — billing model HYBRID with both fixed_charge and unit_rate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter required fields | Required set |
| 3 | Select item, set billing_model = "HYBRID" | HYBRID selected |
| 4 | Set fixed_charge = 10000.00, unit_rate = 200.00, min_guarantee_qty = 50.00 | All three set |
| 5 | Submit form | Success |
| 6 | Verify DB: billing_model = 'HYBRID', fixed_charge = 10000.00, unit_rate = 200.00, min_guarantee_qty = 50.00 | HYBRID stored |
| 7 | Verify flash message | Flash shown |

#### TC-VNDAGR-P07: Create agreement — with all 4 tax percentages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter required fields | Required set |
| 3 | Select item, set billing_model = "FIXED", fixed_charge = 10000.00 | Base rate set |
| 4 | Set tax1_percent = 5.00, tax2_percent = 3.50, tax3_percent = 2.00, tax4_percent = 1.25 | All 4 taxes set |
| 5 | Submit form | Success |
| 6 | Verify DB: tax1_percent=5.00, tax2_percent=3.50, tax3_percent=2.00, tax4_percent=1.25 | All taxes stored |
| 7 | Verify flash message | Flash shown |

#### TC-VNDAGR-P08: Create agreement — with related entity (vehicle)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter required fields | Required set |
| 3 | Select item, set billing_model = "FIXED", fixed_charge = 5000.00 | Item data set |
| 4 | Select related_entity_type = dropdown value pointing to "vehicles" table | Entity type selected |
| 5 | Select related_entity_id = a valid vehicle ID from dropdown | Vehicle selected |
| 6 | Enter description = "Vehicle rental agreement" | Description set |
| 7 | Submit form | Success |
| 8 | Verify DB: related_entity_table = 'vehicles', related_entity_id = selected vehicle ID | Entity linked |

#### TC-VNDAGR-P09: Create agreement — with related entity (driver helper)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter required fields | Required set |
| 3 | Select item, billing_model = "FIXED", fixed_charge = 3000.00 | Item data set |
| 4 | Select related_entity_type = dropdown value pointing to "driver_helpers" table | Entity type selected |
| 5 | Select related_entity_id = a valid driver helper ID | Driver helper selected |
| 6 | Submit form | Success |
| 7 | Verify DB: related_entity_table = 'driver_helpers', related_entity_id = selected ID | Driver helper linked |
| 8 | Verify description is NULL (not provided — nullable) | Description null |

#### TC-VNDAGR-P10: Create agreement — agreement_ref_no provided

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill required fields: vendor_id, start_date, end_date, status, billing_cycle | Required set |
| 3 | Enter agreement_ref_no = "AGR-REF-001" | Ref no populated |
| 4 | Select item, set billing_model = "FIXED", fixed_charge = 1000.00 | Item data set |
| 5 | Click Submit | Success |
| 6 | Verify DB: agreement_ref_no = "AGR-REF-001" | Ref no stored |

#### TC-VNDAGR-P11: Create agreement — remarks field populated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill required fields: vendor_id, start_date, end_date, status, billing_cycle | Required set |
| 3 | Enter remarks = "This is a long remark describing the agreement terms" | Remarks populated |
| 4 | Select item, set billing_model = "FIXED" | Item selected |
| 5 | Click Submit | Success |
| 6 | Verify DB: remarks = "This is a long remark describing the agreement terms" | Remarks stored |

#### TC-VNDAGR-P12: Create agreement — payment_terms_days set to custom value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill required fields: vendor_id, start_date, end_date, status, billing_cycle | Required set |
| 3 | Set payment_terms_days = 60 | Custom terms |
| 4 | Select item, billing_model = "FIXED" | Item selected |
| 5 | Click Submit | Success |
| 6 | Verify DB: payment_terms_days = 60 (not default 30) | Custom terms stored |

#### TC-VNDAGR-P13: View agreement detail with vendor and agreement items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-agreement.view` permission clicks "View" on an agreement row | Show page loads |
| 2 | Verify vendor name, agreement_ref_no, start_date, end_date, status, billing_cycle, payment_terms_days, remarks displayed | All fields visible |
| 3 | Verify agreement items table shows: item name, billing_model, fixed_charge, unit_rate, min_guarantee_qty, tax percentages, entity | Items visible |
| 4 | Verify agreement_uploaded flag reflected (if true, file download link visible) | File status shown |

#### TC-VNDAGR-P14: Edit agreement — update start_date, end_date, status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-agreement.update` permission clicks "Edit" | Edit form loads with pre-filled data |
| 2 | Change start_date to "2026-02-01", end_date to "2027-01-31", status to "ACTIVE" | Fields changed |
| 3 | Verify item data pre-filled with existing agreement item values | Item data pre-filled |
| 4 | Click Update | Redirected to vendor dashboard |
| 5 | Verify success flash message | Success message |
| 6 | Verify DB: start_date, end_date, status updated | Changes persisted |

#### TC-VNDAGR-P15: Edit agreement — replace agreement_file

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Existing agreement has agreement_file uploaded (agreement_uploaded=1) | Existing file |
| 2 | Open edit form, upload a new PDF file | New file attached |
| 3 | Click Update | Success |
| 4 | Verify media collection cleared of old file and new file added | File replaced |
| 5 | Verify DB: agreement_uploaded = 1 | Flag remains true |
| 6 | Verify old media record deleted from media table | Old file removed |

#### TC-VNDAGR-P16: Edit agreement — change billing model and rates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Existing agreement item has billing_model="FIXED", fixed_charge=10000.00 | Existing values |
| 2 | Open edit form, change billing_model to "HYBRID" | Model changed |
| 3 | Set fixed_charge = 5000.00, unit_rate = 150.00, min_guarantee_qty = 30.00 | New rates set |
| 4 | Click Update | Success |
| 5 | Verify DB: billing_model='HYBRID', fixed_charge=5000.00, unit_rate=150.00, min_guarantee_qty=30.00 | Changes stored |
| 6 | Verify agreement item record was UPDATED (not new row created) | Same item ID |

#### TC-VNDAGR-P17: Edit agreement — update tax percentages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Existing agreement item has tax1_percent=5.00, all others 0.00 | Existing taxes |
| 2 | Open edit form, set tax1_percent=10.00, tax2_percent=5.00, tax3_percent=2.50 | Tax changes |
| 3 | Click Update | Success |
| 4 | Verify DB: tax1_percent=10.00, tax2_percent=5.00, tax3_percent=2.50, tax4_percent=0.00 | Taxes updated |
| 5 | Verify old values logged in activity log | Change tracked |
| 6 | Verify flash message | Flash shown |

#### TC-VNDAGR-P18: Edit agreement — change related entity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Existing agreement item has related_entity_type pointing to "vehicles", vehicle ID 5 | Existing entity |
| 2 | Open edit form, change related_entity_type to driver helper type, select helper ID 3 | Entity changed |
| 3 | Click Update | Success |
| 4 | Verify DB: related_entity_table = 'driver_helpers', related_entity_id = 3 | Entity updated |
| 5 | Verify old entity values logged in activity log | Change tracked |
| 6 | Verify flash message | Flash shown |

#### TC-VNDAGR-P19: Edit agreement — update remarks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Existing agreement has remarks = "Old remarks" | Existing text |
| 2 | Open edit form, change remarks to "Updated remarks after review" | Remarks changed |
| 3 | Click Update | Success |
| 4 | Verify DB: remarks = "Updated remarks after review" | Remarks updated |
| 5 | Verify flash message | Flash shown |

#### TC-VNDAGR-P20: Toggle status — active to inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an active agreement (is_active=true) in the list | Active agreement |
| 2 | Click status toggle to deactivate | AJAX call made |
| 3 | Verify JSON response: `{"success": true, "is_active": false, "message": "..."}` | AJAX success |
| 4 | Verify DB: agreement.is_active = 0 AND agreement items is_active = 0 | Cascaded deactivation |
| 5 | Verify activity log entry created for toggle | Activity logged |

#### TC-VNDAGR-P21: Toggle status — inactive to active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an inactive agreement (is_active=false) in the list | Inactive agreement |
| 2 | Click status toggle to activate | AJAX call made |
| 3 | Verify JSON response: `{"success": true, "is_active": true, "message": "..."}` | AJAX success |
| 4 | Verify DB: agreement.is_active = 1 AND agreement items is_active = 1 | Cascaded activation |
| 5 | Verify activity log entry created | Activity logged |

#### TC-VNDAGR-P22: Soft-delete agreement

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-agreement.delete` permission clicks "Delete" on an agreement | Confirmation prompt |
| 2 | Confirm deletion | Agreement soft-deleted |
| 3 | Verify agreement no longer appears in active agreement list | Removed from active |
| 4 | Verify DB: agreement.deleted_at is not null | Soft-deleted |
| 5 | Verify DB: agreement items deleted_at is not null (cascaded soft-delete) | Items also soft-deleted |

#### TC-VNDAGR-P23: Restore agreement from trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-agreement.restore` permission navigates to `/vendor-agreement/trash/view` | Trash list loads |
| 2 | Locate a soft-deleted agreement | Agreement visible in trash |
| 3 | Click Restore | Agreement restored |
| 4 | Verify agreement appears in active list, deleted_at is NULL | Restored |
| 5 | Verify agreement items have deleted_at = NULL (restored) | Items also restored |

#### TC-VNDAGR-P24: Force-delete agreement

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-agreement.forceDelete` permission navigates to trash view | Trash list loads |
| 2 | Locate a soft-deleted agreement and click "Force Delete" | Confirmation prompt |
| 3 | Confirm permanent deletion | Agreement permanently deleted |
| 4 | Verify DB record no longer exists (including withTrashed) | Permanently deleted |
| 5 | Verify agreement items also permanently deleted and media collection cleared | Full cleanup |

#### TC-VNDAGR-P25: Activity log created on agreement store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new agreement via store() | Success |
| 2 | Verify `activityLog()` was called with the VndAgreement model | Logged |
| 3 | Verify action='Stored' and message='A new vendor agreement was created.' | Action correct |
| 4 | Verify performed_by = authenticated user's name | Performer tracked |

#### TC-VNDAGR-P26: Activity log created on agreement update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update an agreement via update() | Success |
| 2 | Verify `activityLog()` called with action='Updated' and changes array | Logged |
| 3 | Verify changes contains old/new values for modified fields | Change tracking |
| 4 | Verify performed_by = authenticated user's name | Performer tracked |

#### TC-VNDAGR-P27: Activity log created on agreement soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete an agreement via destroy() | Success |
| 2 | Verify `activityLog()` called with action='Trashed' | Logged |
| 3 | Verify message='Vendor agreement was deactivated and trashed.' | Message correct |

#### TC-VNDAGR-P28: Activity log created on agreement restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a trashed agreement via restore() | Success |
| 2 | Verify `activityLog()` called with action='Restored' | Logged |
| 3 | Verify message='Vendor agreement was restored.' | Message correct |

#### TC-VNDAGR-P29: Activity log created on agreement force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete a trashed agreement via forceDelete() | Success |
| 2 | Verify `activityLog()` called with action='Deleted' | Logged |
| 3 | Verify message='Vendor agreement was permanently deleted.' | Message correct |

#### TC-VNDAGR-P30: Activity log created on agreement toggle-status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle agreement status via toggleStatus() | AJAX success |
| 2 | Verify `activityLog()` called with action='Toggled' | Logged |
| 3 | Verify message='Vendor agreement status was updated.' | Message correct |

#### TC-VNDAGR-P31: Agreement file upload — verify media stored and conversion generated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create agreement with agreement_file = valid PDF | File uploaded |
| 2 | Query media table: model_type = VndAgreement, collection_name = ? (see Known Issue KI-04) | Media record exists |
| 3 | Verify file exists on 'public' disk in storage | File stored |
| 4 | Verify media conversions: small (150x150) and medium (400x400) generated | Conversions present |
| 5 | Verify $agreement->getMedia('agreement')->count() = 1 (singleFile) | Single file enforced |

#### TC-VNDAGR-P32: Agreement file — clear old file on second upload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement has one existing file in media collection | Existing file |
| 2 | Update agreement with new file | File replaced |
| 3 | Verify old media record deleted, new media record created | Single file remains |
| 4 | Verify agreement_uploaded = 1 | Flag remains true |

#### TC-VNDAGR-P33: Create agreement with status=DRAFT

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill required fields: vendor_id, start_date, end_date, select status="DRAFT" | DRAFT selected |
| 3 | Select billing_cycle, select item | Fields set |
| 4 | Submit form | Success |
| 5 | Verify DB: status = 'DRAFT' | DRAFT stored |
| 6 | Verify flash message | Flash shown |

#### TC-VNDAGR-P34: Create agreement with status=ACTIVE and start_date <= today

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill required fields: vendor_id, start_date=today, end_date=future date | Dates set |
| 3 | Select status="ACTIVE" | ACTIVE selected |
| 4 | Select billing_cycle, select item | Fields set |
| 5 | Submit form | Success |
| 6 | Verify DB: status = 'ACTIVE', start_date <= now <= end_date | Current active agreement |

#### TC-VNDAGR-P35: Create agreement with billing_cycle=ONE_TIME

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill required fields: vendor_id, start_date, end_date, status | Required set |
| 3 | Select billing_cycle = "ONE_TIME" | ONE_TIME selected |
| 4 | Select item, set billing_model, rates | Item data set |
| 5 | Submit form | Success |
| 6 | Verify DB: billing_cycle = 'ONE_TIME' | ONE_TIME stored |

#### TC-VNDAGR-P36: Create agreement with billing_cycle=ON_DEMAND

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill required fields: vendor_id, start_date, end_date, status | Required set |
| 3 | Select billing_cycle = "ON_DEMAND" | ON_DEMAND selected |
| 4 | Select item, set billing_model, rates | Item data set |
| 5 | Submit form | Success |
| 6 | Verify DB: billing_cycle = 'ON_DEMAND' | ON_DEMAND stored |

#### TC-VNDAGR-P37: Agreement item record created with correct defaults for missing optional fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create agreement with only required fields and item_id | Minimal data |
| 2 | Submit form | Success |
| 3 | Verify agreement item record: billing_model='FIXED', fixed_charge=0.00, unit_rate=0.00, min_guarantee_qty=0.00, all tax%=0.00, is_active=1 | Defaults applied |
| 4 | Verify related_entity_type, related_entity_table, related_entity_id, description all NULL | Nullable defaults |
| 5 | Verify is_active = 1 (default) | Active item |

#### TC-VNDAGR-P38: Store — related_entity_type dropdown lookup resolves table_name from sys_dropdown_table JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure sys_dropdown_table has record with key='vnd_agreement_items_jnt.related_entity_type', id=X, additional_info='{"table_name":"vehicles"}' | Dropdown seeded |
| 2 | Open create form, fill required fields (vendor_id, start_date, end_date, status, billing_cycle), select item | Required fields set |
| 3 | Select related_entity_type = dropdown X, select a valid vehicle as related_entity_id | Entity fields set |
| 4 | Submit form | Success |
| 5 | Verify DB: vnd_agreement_items_jnt.related_entity_type = X, related_entity_table = 'vehicles', related_entity_id = selected vehicle ID | Entity resolved correctly |

#### TC-VNDAGR-P39: ToggleStatus — DB transaction toggles is_active on both agreement and agreement items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an active agreement (is_active=1) with at least one agreement item (is_active=1) | Active agreement with items |
| 2 | POST `/vendor-agreement/{id}/toggle-status` with is_active=false | AJAX call made |
| 3 | Verify JSON response: {"success":true, "is_active":false} | AJAX success |
| 4 | Verify DB: vnd_agreements.is_active = 0 AND vnd_agreement_items_jnt.is_active = 0 | Cascaded deactivation |
| 5 | POST toggle-status again with is_active=true | AJAX call made |
| 6 | Verify DB: both tables show is_active = 1 | Cascaded activation |

#### TC-VNDAGR-P40: Scope current() — filters agreements where start_date <= now AND end_date >= now

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create agreement A1: start_date=yesterday, end_date=tomorrow | Current agreement |
| 2 | Create agreement A2: start_date=last-month, end_date=yesterday | Expired agreement |
| 3 | Create agreement A3: start_date=tomorrow, end_date=next-year | Future agreement |
| 4 | Execute VndAgreement::current()->get() | Scope applied |
| 5 | Verify A1 is in result set | Current agreement included |
| 6 | Verify A2 and A3 are NOT in result set | Expired and future excluded |

#### TC-VNDAGR-P41: Model defaults — status, billing_cycle, payment_terms_days, agreement_uploaded, is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create agreement with only required fields: vendor_id, start_date, end_date, status, billing_cycle | Minimal data |
| 2 | Do NOT set payment_terms_days, agreement_uploaded, is_active, agreement_file | Defaults expected |
| 3 | Submit form | Success |
| 4 | Verify DB defaults: status='DRAFT', billing_cycle='MONTHLY', payment_terms_days=30, agreement_uploaded=0, is_active=1 | All defaults applied |

#### TC-VNDAGR-P42: Agreement file upload — stored in 'agreement' collection on 'public' disk as singleFile

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create agreement with agreement_file = valid PDF | File uploaded |
| 2 | Query media table: model_type=VndAgreement, collection_name='agreement' | Collection name matches model registration |
| 3 | Verify file exists on 'public' disk in storage | Public disk used |
| 4 | Verify $agreement->getMedia('agreement')->count() = 1 | Single file |
| 5 | Upload second file — verify count remains 1 and old file replaced | singleFile enforced |

#### TC-VNDAGR-P43: Agreement file upload — agreement_uploaded flag set to true after file upload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create agreement without agreement_file | No file |
| 2 | Verify DB: agreement_uploaded = 0 | Flag initially false |
| 3 | Update agreement with agreement_file upload | File attached |
| 4 | Verify DB: agreement_uploaded = 1 and media record exists | Flag set to true |

### 10.2 Negative TC Steps — Agreement CRUD

#### TC-VNDAGR-N01: Create — missing vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create agreement form without selecting vendor_id | Validation error |
| 2 | Verify error: "The vendor id field is required." | Error shown |

#### TC-VNDAGR-N02: Create — vendor_id does not exist in vnd_vendors

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST create with vendor_id = 99999 (non-existent) | Validation error |
| 2 | Verify error: "The selected vendor id is invalid." (exists rule) | Error shown |

#### TC-VNDAGR-N03: Create — vendor_id is for a soft-deleted vendor

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a vendor (deleted_at set) | Vendor trashed |
| 2 | POST create with vendor_id = that trashed vendor's ID | Validation passes (exists rule checks only existence) |
| 3 | Verify error or success — depends on DB FK enforcement (CASCADE deletes agreements, but FK only checks existence) | Potential data integrity gap (Known Issue) |

#### TC-VNDAGR-N04: Create — missing start_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without start_date | Validation error |
| 2 | Verify error: "The start date field is required." | Error shown |

#### TC-VNDAGR-N05: Create — missing end_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without end_date | Validation error |
| 2 | Verify error: "The end date field is required." | Error shown |

#### TC-VNDAGR-N06: Create — end_date before start_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set start_date = "2026-06-01", end_date = "2026-05-31" | end_date before start |
| 2 | Submit | Validation error: "The end date must be a date after or equal to start date." |

#### TC-VNDAGR-N07: Create — end_date equals start_date (boundary — valid per after_or_equal)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set start_date = "2026-06-15", end_date = "2026-06-15" | Equal dates |
| 2 | Submit | Validation passes (after_or_equal allows same day) |
| 3 | Verify agreement created with same start and end date | Created |

#### TC-VNDAGR-N08: Create — missing status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without selecting status | Validation error |
| 2 | Verify error: "The status field is required." | Error shown |

#### TC-VNDAGR-N09: Create — invalid status value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set status = "INVALID_STATUS" | Not in allowed list |
| 2 | Submit | Validation error: invalid value (not in DRAFT,ACTIVE,EXPIRED,TERMINATED) |

#### TC-VNDAGR-N10: Create — missing billing_cycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without billing_cycle | Validation error |
| 2 | Verify error: "The billing cycle field is required." | Error shown |

#### TC-VNDAGR-N11: Create — invalid billing_cycle value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set billing_cycle = "YEARLY" | Not in allowed list |
| 2 | Submit | Validation error: invalid value (not in MONTHLY,ONE_TIME,ON_DEMAND) |

#### TC-VNDAGR-N12: Create — agreement_ref_no exceeds 50 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set agreement_ref_no to a 51-character string | Exceeds max |
| 2 | Submit | Validation error: "The agreement ref no must not be greater than 50 characters." |

#### TC-VNDAGR-N13: Create — payment_terms_days negative integer

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set payment_terms_days = -10 | Negative value |
| 2 | Submit | Validation error: "The payment terms days must be at least 0." |

#### TC-VNDAGR-N14: Create — agreement_file invalid mime type (.exe)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload agreement_file = an executable (.exe) file | Invalid mime |
| 2 | Submit | Validation error: file must be of type pdf/jpg/jpeg/png |

#### TC-VNDAGR-N15: Create — agreement_file exceeds 5MB (5120 KB)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload agreement_file = a file > 5120 KB (~6MB) | Exceeds max |
| 2 | Submit | Validation error: "The agreement file must not be greater than 5120 kilobytes." |

#### TC-VNDAGR-N16: Create — is_active missing (checkbox not checked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without checking is_active checkbox | Field not sent |
| 2 | Verify `prepareForValidation()` converts missing to boolean false and agreement is created with is_active=0 | Defaults to false |

#### TC-VNDAGR-N17: Update — non-existent agreement ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/vendor-agreement/99999` with valid data | Agreement 99999 doesn't exist |
| 2 | Verify 404 Not Found from findOrFail | 404 error |

#### TC-VNDAGR-N18: Destroy — non-existent agreement ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/vendor-agreement/99999` | Agreement 99999 doesn't exist |
| 2 | Verify 404 Not Found from findOrFail | 404 error |

#### TC-VNDAGR-N19: Restore — non-existent agreement ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/vendor-agreement/99999/restore` | Agreement 99999 doesn't exist |
| 2 | Verify 404 Not Found from onlyTrashed()->findOrFail | 404 error |

#### TC-VNDAGR-N20: Force delete — non-existent agreement ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/vendor-agreement/99999/force-delete` | Agreement 99999 doesn't exist |
| 2 | Verify 404 Not Found from withTrashed()->findOrFail | 404 error |

#### TC-VNDAGR-N21: Toggle — missing is_active parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/vendor-agreement/{id}/toggle-status` without is_active in request body | Validation error |
| 2 | Verify error: "The is active field is required." | Error returned |

#### TC-VNDAGR-N22: Toggle — non-boolean is_active value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/vendor-agreement/{id}/toggle-status` with is_active="not-a-boolean" | Validation error |
| 2 | Verify error: "The is active field must be true or false." | Error returned |

#### TC-VNDAGR-N23: Toggle — non-existent agreement ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/vendor-agreement/99999/toggle-status` with is_active=true | Agreement 99999 doesn't exist |
| 2 | Verify 404 Not Found from findOrFail | 404 error |

#### TC-VNDAGR-N24: Permission — index without tenant.vendor-agreement.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-agreement.viewAny` permission accesses `/vendor-agreement` | 403 Forbidden |

#### TC-VNDAGR-N25: Permission — create without tenant.vendor-agreement.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-agreement.create` accesses `/vendor-agreement/create` | 403 Forbidden |

#### TC-VNDAGR-N26: Permission — store without tenant.vendor-agreement.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-agreement.create` POSTs to `/vendor-agreement` | 403 Forbidden |

#### TC-VNDAGR-N27: Permission — edit without tenant.vendor-agreement.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-agreement.update` accesses `/vendor-agreement/{id}/edit` | 403 Forbidden |

#### TC-VNDAGR-N28: Permission — update without tenant.vendor-agreement.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-agreement.update` PUTs to `/vendor-agreement/{id}` | 403 Forbidden |

#### TC-VNDAGR-N29: Permission — view show without tenant.vendor-agreement.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-agreement.view` accesses `/vendor-agreement/{id}` | 403 Forbidden |

#### TC-VNDAGR-N30: Permission — destroy without tenant.vendor-agreement.delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-agreement.delete` DELETEs `/vendor-agreement/{id}` | 403 Forbidden |

#### TC-VNDAGR-N31: Permission — trashed without tenant.vendor-agreement.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-agreement.restore` accesses `/vendor-agreement/trash/view` | 403 Forbidden |

#### TC-VNDAGR-N32: Permission — restore without tenant.vendor-agreement.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-agreement.restore` GETs `/vendor-agreement/{id}/restore` | 403 Forbidden |

#### TC-VNDAGR-N33: Permission — forceDelete without tenant.vendor-agreement.forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-agreement.forceDelete` DELETEs `/vendor-agreement/{id}/force-delete` | 403 Forbidden |

#### TC-VNDAGR-N34: Permission — toggleStatus without tenant.vendor-agreement.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-agreement.update` POSTs to `/vendor-agreement/{id}/toggle-status` | 403 Forbidden |

#### TC-VNDAGR-N35: Store — DB transaction rollback on file upload failure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trigger a scenario where agreement is created but file upload fails (e.g., disk full, invalid file) | Exception thrown |
| 2 | Verify DB transaction is rolled back — no agreement record created | Rollback |
| 3 | Verify no orphaned agreement items in DB | Clean rollback |

#### TC-VNDAGR-N36: Update — agreement_ref_no changed to a value exceeding 50 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit agreement, set agreement_ref_no to a 51-character string | Exceeds max |
| 2 | Submit | Validation error: "The agreement ref no must not be greater than 50 characters." |

#### TC-VNDAGR-N37: Restore — attempt to restore non-trashed (active) agreement

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/vendor-agreement/{id}/restore` where agreement has deleted_at = NULL (active) | onlyTrashed() findOrFail returns 404 |
| 2 | Verify 404 Not Found | Only trashed agreements can be restored |

#### TC-VNDAGR-N38: Force delete — active (non-trashed) agreement

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/vendor-agreement/{id}/force-delete` where agreement has deleted_at = NULL | withTrashed()->findOrFail finds it (bypasses SoftDeletes) |
| 2 | Agreement is permanently deleted despite not being in trash | Force-delete succeeds (may be unintended — Known Issue if view only shows trashed) |

#### TC-VNDAGR-N39: Store — related_entity_type dropdown record missing, firstOrFail throws exception

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST create agreement with required fields valid, set related_entity_type = 99999 (non-existent dropdown ID) | firstOrFail triggers |
| 2 | Verify ModelNotFoundException is thrown (caught by store() catch block) | Exception thrown |
| 3 | Verify DB transaction rolled back — no agreement or agreement item records created | Clean rollback |

### 10.3 Code Review TC Steps

#### TC-CR-VAGR-01: index() — Gate + with('vendor') + latest() + paginate(10)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-agreement.viewAny')` at method start | Gate present |
| 2 | Review `VndAgreement::with('vendor')->latest()->paginate(10)` query | Eager loading + ordering + pagination |
| 3 | Review $agreements passed to view | Data sent to view |
| 4 | Review no search/filter params in index() | No search — full list |

#### TC-CR-VAGR-02: create() — Gate + eager load vendors, items, vehicles, driver helpers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-agreement.create')` | Gate present |
| 2 | Review `VndVendor::active()->get()` for vendors dropdown | Active vendors only |
| 3 | Review `VndItem::active()->get()` for items dropdown | Active items only |
| 4 | Review `Vehicle::active()->get()` and `DriverHelper::active()->get()` for entity dropdowns | Active entities |

#### TC-CR-VAGR-03: store() — Gate + DB::transaction + create + file upload + item create + activityLog + redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-agreement.create')` | Gate present |
| 2 | Review `DB::transaction(...)` wrapping all operations | Transactional |
| 3 | Review `VndAgreement::create($request->validated())` | Agreement created via validated data |
| 4 | Review `addMedia($request->file('agreement_file'))` → collection 'agreement_file' | File uploaded (collection name mismatch — see KI-04) |
| 5 | Review `VndAgreementItem::create([...])` — single item only | Single item created |
| 6 | Review `activityLog(...)` and `redirect()->route('vendor.vendor.index')` | Activity logged, redirected to vendor dashboard |
| 7 | Review catch/throw on error — transaction rollback | Error handling |

#### TC-CR-VAGR-04: store() — single VndAgreementItem::create() (not a loop)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review store() method body | No loop construct |
| 2 | Review single `VndAgreementItem::create(...)` call | One item created |
| 3 | Note: Junction table supports many-to-many but controller only creates one item per agreement | Design limitation |

#### TC-CR-VAGR-05: show() — Gate + with(['vendor','agreementItems']) + findOrFail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-agreement.view')` | Gate present |
| 2 | Review `VndAgreement::with(['vendor','agreementItems'])->findOrFail($id)` | Eager loading |
| 3 | Review $agreement passed to view | Data sent |

#### TC-CR-VAGR-06: edit() — Gate + findOrFail + agreementSingleItem hasOne pattern

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-agreement.update')` | Gate present |
| 2 | Review `VndAgreement::findOrFail($id)` | Model binding |
| 3 | Review `$agreement->agreementSingleItem` used to pre-fill item form | hasOne relationship |
| 4 | Review vendors, items, vehicles, driver helpers loaded for dropdowns | Dropdown data |

#### TC-CR-VAGR-07: update() — Gate + DB::transaction + change tracking + file replace + update existing items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-agreement.update')` | Gate present |
| 2 | Review `DB::transaction(...)` | Transactional |
| 3 | Review `$agreement->getChanges()` tracking before/after update | Change tracking |
| 4 | Review `$agreement->clearMediaCollection('agreement_file')` then addMedia | File replace |
| 5 | Review `VndAgreementItem::where('agreement_id', $id)->update([...])` | Items updated (not created) |
| 6 | Review activityLog + redirect | Log + redirect |

#### TC-CR-VAGR-08: update() — VndAgreementItem::where()->update() overwrites all items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review update() item handling — no whereIn, no create call | Uses where()->update() |
| 2 | Confirm this updates ALL items with matching agreement_id | Bulk update |
| 3 | Note: If multiple items existed for an agreement, all get the same values | Overwrite behaviour |

#### TC-CR-VAGR-09: destroy() — Gate + delete items + delete agreement + redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-agreement.delete')` | Gate present |
| 2 | Review `VndAgreementItem::where('agreement_id', $id)->delete()` | Manual item delete |
| 3 | Review `VndAgreement::findOrFail($id)->delete()` | Agreement soft-delete |
| 4 | Review activityLog + redirect with flash | Log + redirect |

#### TC-CR-VAGR-10: trashed() — Gate + onlyTrashed + with('vendor') + paginate(10)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-agreement.restore')` | Gate present |
| 2 | Review `VndAgreement::onlyTrashed()->with('vendor')->paginate(10)` | Trashed only |
| 3 | Review $trashedAgreements passed to view | Data sent |

#### TC-CR-VAGR-11: restore() — Gate + DB::transaction + restore agreement + restore items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-agreement.restore')` | Gate present |
| 2 | Review `DB::transaction(...)` | Transactional |
| 3 | Review `VndAgreement::onlyTrashed()->findOrFail($id)->restore()` | Restore agreement |
| 4 | Review `VndAgreementItem::onlyTrashed()->where('agreement_id', $id)->restore()` | Restore items |

#### TC-CR-VAGR-12: forceDelete() — Gate + DB::transaction + forceDelete items + clearMedia + forceDelete agreement

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-agreement.forceDelete')` | Gate present |
| 2 | Review `DB::transaction(...)` | Transactional |
| 3 | Review `VndAgreementItem::withTrashed()->where('agreement_id', $id)->forceDelete()` | Items force-deleted |
| 4 | Review `$agreement->clearMediaCollection('agreement_file')` | Media cleared |
| 5 | Review `$agreement->forceDelete()` | Agreement permanently deleted |

#### TC-CR-VAGR-13: toggleStatus() — Gate + validate + update agreement + update all items + activityLog + JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-agreement.update')` | Gate present |
| 2 | Review `$request->validate(['is_active' => 'required|boolean'])` | Inline validation |
| 3 | Review `$agreement->update(['is_active' => $isActive])` | Agreement status updated |
| 4 | Review `VndAgreementItem::where('agreement_id', $id)->update(['is_active' => $isActive])` | Items status cascaded |
| 5 | Review `activityLog()` called before commit | Activity logged |
| 6 | Review JSON response(201) on success / throw on error | AJAX response |

#### TC-CR-VAGR-14: VendorAgreementRequest — all validation rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review vendor_id: required|exists:vnd_vendors,id | FK validation |
| 2 | Review agreement_ref_no: nullable|string|max:50 | Nullable ref no |
| 3 | Review start_date: required|date, end_date: required|date|after_or_equal:start_date | Date validation |
| 4 | Review status: required|in:DRAFT,ACTIVE,EXPIRED,TERMINATED | ENUM validation |
| 5 | Review billing_cycle: required|in:MONTHLY,ONE_TIME,ON_DEMAND, payment_terms_days: nullable|integer|min:0 | Billing + terms |

#### TC-CR-VAGR-15: VendorAgreementRequest — authorize() returns true (no Gate)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `authorize()` method | Returns `true` |
| 2 | Note: No Gate check in FormRequest — relies entirely on controller Gate | Defence-in-depth gap |

#### TC-CR-VAGR-16: VndAgreement Model — fillable, casts, defaults, relationships, scopes, media

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review $fillable — 10 fields (vendor_id through is_active) | Fillable fields |
| 2 | Review $casts — start_date/end_date→date, agreement_uploaded/is_active→boolean, payment_terms_days→integer | Casts configured |
| 3 | Review $attributes defaults — status='DRAFT', billing_cycle='MONTHLY', payment_terms_days=30, agreement_uploaded=false, is_active=true | Defaults |
| 4 | Review relationships: vendor() (belongsTo), agreementItems() (hasMany), agreementSingleItem() (hasOne) | Relationships |
| 5 | Review scopes: active() (is_active=1), current() (start_date<=now AND end_date>=now) | Scopes |
| 6 | Review registerMediaCollections: 'agreement' collection, singleFile, public disk, conversions small(150x150) and medium(400x400) | Media config |

#### TC-CR-VAGR-17: VndAgreementItem Model — fillable, casts, relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review $fillable — 16 fields (agreement_id through is_active) | All fillable |
| 2 | Review $casts — all decimal fields→decimal:2, is_active→boolean | Casts |
| 3 | Review relationships: Vehicle(), DriverHelper(), agreement(), item(), relatedEntityType(), invoices(), latestInvoice() | All relationships |

#### TC-CR-VAGR-18: Related entity type lookup — sys_dropdown_table additional_info JSON parsing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review store() — lookup Dropdown::find($relatedEntityType) | Dropdown lookup |
| 2 | Review `$dropdown->additional_info` JSON decode → extract `table_name` | JSON parsing |
| 3 | Review `related_entity_table` set from table_name, `related_entity_id` from request | Fields populated |
| 4 | Review update() — same logic repeated | Consistent lookup |

#### TC-CR-VAGR-19: Collection name mismatch — model registers 'agreement', controller adds to 'agreement_file'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review VndAgreement model: `registerMediaCollections()` — `$this->addMediaCollection('agreement')->singleFile()` | Collection name: 'agreement' |
| 2 | Review controller store(): `$agreement->addMedia($file)->toMediaCollection('agreement_file')` | Collection name: 'agreement_file' |
| 3 | Note: MISMATCH — model registers 'agreement' but controller uses 'agreement_file' | File may not be stored under expected collection (Known Issue KI-04) |

#### TC-CR-VAGR-20: Redirect route — store/update redirect to vendor.vendor.index (not agreement.index)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review store() redirect: `redirect()->route('vendor.vendor.index')` | Redirects to vendor dashboard |
| 2 | Review update() redirect: same route | Same redirect |

### 10.4 Dependency TC Steps

#### TC-D-VAGR-01: Vendor FK CASCADE — deleting vendor cascades to agreements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor V1 has 2 agreements in vnd_agreements | Existing vendor with agreements |
| 2 | Delete V1 from vnd_vendors (soft-delete or force-delete) | Vendor deleted |
| 3 | Query vnd_agreements: agreements for V1 have deleted_at = not null (if vendor soft-deleted) or records deleted (if vendor force-deleted) | Cascaded |
| 4 | Verify agreement items also cascaded (due to fk_vnd_agr_items_agreement CASCADE) | Items also affected |

#### TC-D-VAGR-02: Agreement FK CASCADE — deleting agreement cascades to agreement items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement A1 has 2 agreement items in vnd_agreement_items_jnt | Existing agreement with items |
| 2 | Force-delete A1 from vnd_agreements | Agreement deleted |
| 3 | Query vnd_agreement_items_jnt: no records for agreement_id = A1 | Items cascaded |
| 4 | Note: Controller also manually deletes items — redundant CASCADE (Known Issue KI-03) | Redundant |

#### TC-D-VAGR-03: Item FK RESTRICT — cannot delete item referenced by agreement item

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Item I1 is used in at least one vnd_agreement_items_jnt record | Referenced item |
| 2 | Attempt to delete I1 from vnd_items | RESTRICT violation |
| 3 | Verify DB error: Cannot delete or update a parent row — FK constraint fails | Delete blocked |

#### TC-D-VAGR-04: Entity type FK RESTRICT — cannot delete sys_dropdown referenced by agreement item

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Dropdown D1 is used as related_entity_type in an agreement item | Referenced dropdown |
| 2 | Attempt to delete D1 from sys_dropdown_table | RESTRICT violation |
| 3 | Verify DB error: Cannot delete or update a parent row — FK constraint fails | Delete blocked |

#### TC-D-VAGR-05: SoftDelete — soft-deleted agreements excluded from normal queries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement A1 is soft-deleted (deleted_at IS NOT NULL) | Trashed agreement |
| 2 | Access index() — list does not include A1 | Excluded from active list |
| 3 | Access trashed() — list includes A1 | Visible in trash only |

#### TC-D-VAGR-06: SoftDelete — agreement items soft-deleted when agreement is soft-deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement A1 has items, soft-delete A1 | Agreement trashed |
| 2 | Query vnd_agreement_items_jnt without withTrashed: items hidden | Items excluded |
| 3 | Query with withTrashed: items have deleted_at set | Items soft-deleted |

#### TC-D-VAGR-07: Spatie Media Library — agreement collection single-file, public disk

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload first file to agreement | File stored in media library |
| 2 | Upload second file to same agreement | First file replaced (singleFile) |
| 3 | Verify only 1 media record exists for this agreement | Single file enforced |
| 4 | Verify storage disk is 'public' | Public disk used |

#### TC-D-VAGR-08: Spatie Media Conversions — small (150x150) and medium (400x400)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload an image file (jpg/png) to agreement collection | Image uploaded |
| 2 | Verify small conversion: 150x150 generated | Small conversion |
| 3 | Verify medium conversion: 400x400 generated | Medium conversion |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/vendor-agreement` | vendor-agreement.index | index() | tenant.vendor-agreement.viewAny |
| GET | `/vendor-agreement/create` | vendor-agreement.create | create() | tenant.vendor-agreement.create |
| POST | `/vendor-agreement` | vendor-agreement.store | store() | tenant.vendor-agreement.create |
| GET | `/vendor-agreement/{vendor-agreement}` | vendor-agreement.show | show() | tenant.vendor-agreement.view |
| GET | `/vendor-agreement/{vendor-agreement}/edit` | vendor-agreement.edit | edit() | tenant.vendor-agreement.update |
| PUT | `/vendor-agreement/{vendor-agreement}` | vendor-agreement.update | update() | tenant.vendor-agreement.update |
| DELETE | `/vendor-agreement/{vendor-agreement}` | vendor-agreement.destroy | destroy() | tenant.vendor-agreement.delete |
| GET | `/vendor-agreement/trash/view` | vendor-agreement.trashed | trashed() | tenant.vendor-agreement.restore |
| GET | `/vendor-agreement/{id}/restore` | vendor-agreement.restore | restore() | tenant.vendor-agreement.restore |
| DELETE | `/vendor-agreement/{id}/force-delete` | vendor-agreement.forceDelete | forceDelete() | tenant.vendor-agreement.forceDelete |
| POST | `/vendor-agreement/{id}/toggle-status` | vendor-agreement.toggleStatus | toggleStatus() | tenant.vendor-agreement.update |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | store/update handle only ONE agreement item per agreement | **High** | Junction table `vnd_agreement_items_jnt` is designed for many-to-many but controller create/update only handle a single item. edit view uses `agreementSingleItem` (hasOne). True one-to-many not implemented. |
| KI-02 | store/update redirect to vendor.vendor.index (vendor dashboard) not vendor-agreement.index | **Low** | After create/update, user is redirected to the vendor dashboard instead of the agreement list page — inconsistent UX. |
| KI-03 | destroy() manually deletes agreement items before agreement delete — redundant with ON DELETE CASCADE | **Low** | DDL has `ON DELETE CASCADE` on `fk_vnd_agr_items_agreement`; the manual `VndAgreementItem::where()->delete()` in controller is unnecessary. |
| KI-04 | Collection name mismatch: model registers 'agreement' but controller uses 'agreement_file' | **High** | In `VndAgreement` model: `$this->addMediaCollection('agreement')`. In controller: `$agreement->addMedia($file)->toMediaCollection('agreement_file')`. Files may not be retrievable via `$agreement->getMedia('agreement')` if stored under 'agreement_file'. |
| KI-05 | No validation for end_date being unreasonably far in the past or future | **Medium** | Only `after_or_equal:start_date` is enforced. An end_date 10 years in the past or 100 years in the future passes validation. |
| KI-06 | toggleStatus() cascades is_active to ALL agreement items — potentially unexpected | **Medium** | Toggling an agreement's status also toggles all associated items. If items should be independently manageable, this cascading behaviour may be incorrect. |
| KI-07 | store() does NOT validate that vendor exists AND is active — only DB FK check | **Medium** | Validation rule is `exists:vnd_vendors,id` but not `where('is_active', 1)`. Agreements can be created referencing inactive/deactivated vendors. |
| KI-08 | No validation for item_id or related_entity fields in VendorAgreementRequest | **Medium** | item_id and related_entity fields are sent in the request but not validated by FormRequest rules — only enforced at DB FK level. |
| KI-09 | VendorAgreementRequest authorize() returns true | **Medium** | No Gate check in FormRequest — defence-in-depth collapsed; relies solely on controller Gate. |
| KI-10 | toggleStatus uses DB::beginTransaction/commit/rollback (manual) vs store/update use DB::transaction (closure) | **Low** | Inconsistent transaction handling patterns across controller methods. toggleStatus uses manual begin/commit while store/update use closure-based DB::transaction. |

---

## 13. Feature Summary Matrix

| Feature | Controller Method(s) | Key Models | Pagination |
|---------|---------------------|------------|------------|
| Agreement List | index() | VndAgreement, VndVendor | 10 per page |
| Create Agreement | create(), store() | VndAgreement, VndAgreementItem, VndVendor, VndItem, Vehicle, DriverHelper | None (form) |
| View Agreement | show() | VndAgreement, VndAgreementItem, VndVendor | None |
| Edit Agreement | edit(), update() | VndAgreement, VndAgreementItem, VndVendor, VndItem, Vehicle, DriverHelper | None (form) |
| Soft-Delete / Restore | destroy(), trashed(), restore() | VndAgreement, VndAgreementItem | 10 per page (trash) |
| Force Delete | forceDelete() | VndAgreement, VndAgreementItem | None |
| Toggle Status | toggleStatus() | VndAgreement, VndAgreementItem | None (AJAX) |
| File Upload (Agreement) | store(), update() | VndAgreement (Spatie Media) | None |
| Activity Logging | All CRUD + toggleStatus | VndAgreement | None |
