# hrs_SalaryComponents_TcList

## Module: HrStaff → HR Masters → Salary Components

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | HR Masters |
| Feature | Salary Components |
| URL(s) | `GET /hr-masters?tab=salary-components` (tab view), `GET /salary-components` (index), `POST /salary-components` (store), `GET /salary-components/{salaryComponent}` (show), `GET /salary-components/{salaryComponent}/edit` (edit), `PUT /salary-components/{salaryComponent}` (update), `DELETE /salary-components/{salaryComponent}` (destroy), `POST /salary-components/{salaryComponent}/toggle-status` (toggleStatus), `GET /salary-components/trash/view` (trashed), `GET /salary-components/{id}/restore` (restore), `DELETE /salary-components/{id}/force-delete` (forceDelete) |
| Controller | `Modules\HrStaff\Http\Controllers\SalaryComponentController` |
| Model(s) | `Modules\HrStaff\Models\SalaryComponent` (table: `pay_salary_components`) |
| Validation (Create/Update) | `Modules\HrStaff\Http\Requests\StoreSalaryComponentRequest` |
| Policy | `Modules\HrStaff\Policies\SalaryComponentPolicy` |
| Permissions | `pay.structure.manage` (controller); `hrs.salary_component.manage` (policy) |
| Pagination | 20 records per page using default `page` parameter; tab view returns full collection |
| Soft Deletes | Yes (SoftDeletes trait); `destroy()` sets `is_active=false` before `delete()`; restore sets `is_active=true` |
| Activity Log | Events: Created, Updated, Trashed, Restored, Deleted (force delete) |

---

## 2. Pre-conditions

- Required permissions: `pay.structure.manage` (or `hrs.salary_component.manage`)
- Required seed data: At least one active SalaryComponent for edit/delete tests; at least one active SalaryStructure with linked component for delete-guard tests
- Test user must have required permissions (default admin user)
- Tenant context must be initialized
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For pagination tests: Create 25 salary components

---

## 3. Default Data Load

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Components Grid (tab) | `HrMenuController@hrMasters()` | `SalaryComponent::orderBy('display_order')->orderBy('name')` | search (name/code), type (component_type) | None (full collection) |
| Components Grid (standalone) | `SalaryComponentController@index()` | `SalaryComponent::orderBy('display_order')->orderBy('name')->withQueryString()` | search (name/code), type (component_type) | 20/page |

---

## 4. Test Data Strategy

- **Code uniqueness**: Each component must have a unique code (e.g., BASIC, HRA, DA)
- **Component types**: Test all three types (earning, deduction, employer_contribution)
- **Calculation types**: Test all five (fixed, percentage_of_basic, percentage_of_gross, statutory, manual)
- **Statutory components**: Create a statutory component for immutability tests
- **Pre-test cleanup**: Delete created components by code before/after tests
- **Pagination**: Create 25 components to test 20-record boundary

---

## 5. Business Conditions

### 5.1 Database Schema — `pay_salary_components`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | name | VARCHAR(150) | NOT NULL |
| BC-DB-03 | code | VARCHAR(30) | NOT NULL, UNIQUE (uq_pay_comp_code) |
| BC-DB-04 | component_type | ENUM('earning','deduction','employer_contribution') | NOT NULL |
| BC-DB-05 | calculation_type | ENUM('fixed','percentage_of_basic','percentage_of_gross','statutory','manual') | NOT NULL |
| BC-DB-06 | default_value | DECIMAL(10,4) | NOT NULL DEFAULT 0.0000 |
| BC-DB-07 | is_taxable | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-08 | is_statutory | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-09 | display_order | TINYINT UNSIGNED | NOT NULL DEFAULT 99 |
| BC-DB-10 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-11 | created_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-12 | updated_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-13 | created_at | TIMESTAMP | NULL |
| BC-DB-14 | updated_at | TIMESTAMP | NULL |
| BC-DB-15 | deleted_at | TIMESTAMP | NULL (soft delete) |

### 5.2 Validation Rules — `StoreSalaryComponentRequest` (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | name | required, string, max:150 | — |
| BC-VAL-02 | code | required, string, max:30, unique:pay_salary_components,code (ignore $id, whereNull deleted_at) | "The code has already been taken." |
| BC-VAL-03 | component_type | required, in:earning,deduction,employer_contribution | — |
| BC-VAL-04 | calculation_type | required, in:fixed,percentage_of_basic,percentage_of_gross,statutory,manual | — |
| BC-VAL-05 | default_value | required, numeric, min:0 | — |
| BC-VAL-06 | is_taxable | required, boolean | — |
| BC-VAL-07 | is_statutory | required, boolean | — |
| BC-VAL-08 | display_order | required, integer, min:1, max:99 | — |
| BC-VAL-09 | is_active | required, boolean | — |
| BC-VAL-10 | **Statutory code (controller)** | code unchanged if is_statutory | "Cannot modify code on statutory components." |
| BC-VAL-11 | **Statutory type (controller)** | component_type unchanged if is_statutory | "Cannot modify component type on statutory components." |
| BC-VAL-12 | **Statutory calc (controller)** | calculation_type unchanged if is_statutory | "Cannot modify calculation type on statutory components." |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `pay.structure.manage` / `hrs.salary_component.manage` | All controller methods gate; without → 403 |
| BC-AUTH-02 | Guest access | Redirect to /login |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with `tab=salary-components` | Components list in tab view |
| BC-BIZ-02 | Standalone index | Paginated at 20/page, ordered by display_order then name |
| BC-BIZ-03 | Search by name | Filtered to matching name |
| BC-BIZ-04 | Search by code | Filtered to matching code |
| BC-BIZ-05 | Filter by component_type | Filtered to earning/deduction/employer_contribution |
| BC-BIZ-06 | Create with is_taxable default=true | is_taxable=1 |
| BC-BIZ-07 | Create with is_statutory default=false | is_statutory=0 |
| BC-BIZ-08 | Create with is_active default=true | is_active=1 |
| BC-BIZ-09 | Update statutory component restricted fields blocked | Controller rejects code/type/calc_type changes |
| BC-BIZ-10 | Delete statutory component blocked | "Cannot delete statutory components." |
| BC-BIZ-11 | Delete component in active structure blocked | "Cannot delete component used in active salary structures." |
| BC-BIZ-12 | Empty grid state | Empty message shown |
| BC-BIZ-13 | Screen loads via SalaryComponentController@index() at GET /salary-components | Standalone paginated; tab via GET /hr-masters?tab=salary-components |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | id (self) | pay_salary_structure_components.component_id | CASCADE (junction FK) — controller checks active refs before delete |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Salary Components page loads with all UI elements | Page loads with search, type filter, Add button, grid | — | — | ⬜ |
| TC-P02 | Search by name | Grid filtered to matching name | — | — | ⬜ |
| TC-P03 | Search by code | Grid filtered to matching code | — | — | ⬜ |
| TC-P04 | Filter by component_type=earning | Grid shows only earnings | — | — | ⬜ |
| TC-P05 | Filter by component_type=deduction | Grid shows only deductions | — | — | ⬜ |
| TC-P06 | Filter by component_type=employer_contribution | Grid shows only employer contributions | — | — | ⬜ |
| TC-P07 | Create earning component all required fields | Component created with correct values | — | — | ⬜ |
| TC-P08 | Create deduction component | Component_type=deduction saved | — | — | ⬜ |
| TC-P09 | Create employer_contribution component | Component_type=employer_contribution saved | — | — | ⬜ |
| TC-P10 | Create component with calculation_type=fixed | Calculation_type saved as fixed | — | — | ⬜ |
| TC-P11 | Create component with calculation_type=percentage_of_basic | Pct of basic saved | — | — | ⬜ |
| TC-P12 | Create component with calculation_type=percentage_of_gross | Pct of gross saved | — | — | ⬜ |
| TC-P13 | Create component with calculation_type=statutory | Statutory calc type saved | — | — | ⬜ |
| TC-P14 | Create component with calculation_type=manual | Manual calc type saved | — | — | ⬜ |
| TC-P15 | Create component with is_taxable=false | is_taxable=0 | — | — | ⬜ |
| TC-P16 | Create component with is_statutory=true | is_statutory=1 | — | — | ⬜ |
| TC-P17 | Create component with display_order=1 | display_order=1 | — | — | ⬜ |
| TC-P18 | Create component with default_value=25.0000 | default_value=25.0000 | — | — | ⬜ |
| TC-P19 | Edit component loads pre-filled data | Edit form shows existing values | — | — | ⬜ |
| TC-P20 | Update name and default_value of non-statutory | Both fields updated | — | — | ⬜ |
| TC-P21 | Update display_order | display_order changed | — | — | ⬜ |
| TC-P22 | View component details | Show page with structures list | — | — | ⬜ |
| TC-P23 | Toggle status active to inactive | AJAX success, is_active flipped | — | — | ⬜ |
| TC-P24 | Soft delete non-statutory component (no structure refs) | Component soft-deleted | — | — | ⬜ |
| TC-P25 | View trashed components | Trash page lists soft-deleted | — | — | ⬜ |
| TC-P26 | Restore trashed component | Restored with is_active=1 | — | — | ⬜ |
| TC-P27 | Force delete from trash | Permanently removed | — | — | ⬜ |
| TC-P28 | Full lifecycle: create→edit→toggle→delete→restore | All transitions succeed | — | — | ⬜ |
| TC-P29 | Pagination — first page 20 records | Page 1 shows 20 records | — | — | ⬜ |
| TC-P30 | Pagination — second page | Page 2 shows records 21+ | — | — | ⬜ |
| TC-P31 | Empty state | Empty message shown | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — missing `name` | Validation error | — | — | ⬜ |
| TC-N02 | Required — missing `code` | Validation error | — | — | ⬜ |
| TC-N03 | Required — missing `component_type` | Validation error | — | — | ⬜ |
| TC-N04 | Required — missing `calculation_type` | Validation error | — | — | ⬜ |
| TC-N05 | Required — missing `default_value` | Validation error | — | — | ⬜ |
| TC-N06 | Required — missing `display_order` | Validation error | — | — | ⬜ |
| TC-N07 | Duplicate code | "The code has already been taken." | — | — | ⬜ |
| TC-N08 | Invalid component_type value | Validation error on in | — | — | ⬜ |
| TC-N09 | Invalid calculation_type value | Validation error on in | — | — | ⬜ |
| TC-N10 | Max length — name > 150 chars | Validation error on name.max | — | — | ⬜ |
| TC-N11 | Max length — code > 30 chars | Validation error on code.max | — | — | ⬜ |
| TC-N12 | display_order < 1 | Validation error on min | — | — | ⬜ |
| TC-N13 | display_order > 99 | Validation error on max | — | — | ⬜ |
| TC-N14 | default_value negative | Validation error on min:0 | — | — | ⬜ |
| TC-N15 | Modify statutory component code | "Cannot modify code on statutory components." | — | — | ⬜ |
| TC-N16 | Modify statutory component type | "Cannot modify component type on statutory components." | — | — | ⬜ |
| TC-N17 | Modify statutory component calculation type | "Cannot modify calculation type on statutory components." | — | — | ⬜ |
| TC-N18 | Delete statutory component | "Cannot delete statutory components." | — | — | ⬜ |
| TC-N19 | Delete component used in active salary structure | "Cannot delete component used in active salary structures." | — | — | ⬜ |
| TC-N20 | View non-existent component (404) | 404 Not Found | — | — | ⬜ |
| TC-N21 | Edit non-existent component (404) | 404 Not Found | — | — | ⬜ |
| TC-N22 | Update non-existent component (404) | 404 Not Found | — | — | ⬜ |
| TC-N23 | Delete non-existent component (404) | 404 Not Found | — | — | ⬜ |
| TC-N24 | Permission denied — user without gate | 403 Forbidden | — | — | ⬜ |
| TC-N25 | Guest access | Redirect to /login | — | — | ⬜ |
| TC-N26 | Whitespace-only name | Validation catches empty | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Soft delete sets is_active=false | is_active=0 before delete() | — | — | ⬜ |
| TC-D02 | A | Restore sets is_active=true | is_active=1 after restore() | — | — | ⬜ |
| TC-D03 | B | Activity logged on create | activityLog 'Created' | — | — | ⬜ |
| TC-D04 | B | Activity logged on update | activityLog 'Updated' | — | — | ⬜ |
| TC-D05 | B | Activity logged on soft delete | activityLog 'Trashed' | — | — | ⬜ |
| TC-D06 | C | Model $casts — default_value decimal:4 | Stored as DECIMAL(10,4), accessed as float | — | — | ⬜ |
| TC-D07 | C | Model $casts — display_order integer | TINYINT accessed as integer | — | — | ⬜ |
| TC-D08 | C | Model $casts — is_taxable, is_statutory, is_active boolean | TINYINT accessed as bool | — | — | ⬜ |
| TC-D09 | D | Model relationship — structureComponents() HasMany | Links to SalaryStructureComponent | — | — | ⬜ |
| TC-D10 | D | Model relationship — structures() BelongsToMany | Links to SalaryStructure via pivot | — | — | ⬜ |
| TC-D11 | E | Controller — findOrFail — 404 | Invalid ID returns 404 | — | — | ⬜ |
| TC-D12 | F | Controller — Gate::authorize() on every method | All methods gate before execution | — | — | ⬜ |
| TC-D13 | G | Unique code enforced at DB level | uq_pay_comp_code unique index | — | — | ⬜ |
| TC-D14 | H | Active structure component blocks delete | structureComponents()->where('is_active',true)->exists() guard | — | — | ⬜ |
| TC-D15 | I | Statutory component blocks delete | is_statutory guard | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — $fillable matches DDL | All non-PK, non-timestamp columns in fillable | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — $casts correct | decimal:4, integer, boolean casts | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait | SoftDeletes imported | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships defined | HasMany and BelongsToMany defined | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — Gate::authorize() on every method | All 10 methods gate | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — activityLog on all state changes | All write methods log | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — is_active=false before soft delete | destroy() sets is_active=false | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — restore sets is_active=true | update is_active=1 | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — toggleStatus() flips | Toggles via update() | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — trash/restore/forceDelete flow | Standard soft-delete lifecycle | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — statutory field guard in update() | Checks 3 restricted fields before updating | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — two delete guards in destroy() | is_statutory + active structure component checks | — | — | ◌ |
| TC-CR13 | CR | P1 | Controller — JSON/flash success response | Flash on CRUD, JSON on toggle | — | — | ◌ |
| TC-CR14 | CR | P1 | Request — rules cover all fillable fields | All columns validated | — | — | ◌ |
| TC-CR15 | CR | P1 | Request — unique ignores current ID on update | code.unique uses ignore($id) | — | — | ◌ |
| TC-CR16 | CR | P1 | Request — prepareForValidation() | 3 booleans cast | — | — | ◌ |
| TC-CR17 | CR | P1 | Policy — all methods defined | 7 gates defined | — | — | ◌ |
| TC-CR18 | CR | P1 | Routes — resource + custom routes | All route entries registered | — | — | ◌ |
| TC-CR19 | CR | P1 | Database — unique index on code | uq_pay_comp_code | — | — | ◌ |

---

## 7. Detailed Test Steps

### Code Review TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-CR01 | Inspect SalaryComponent model $fillable | Matches DDL columns: name, code, component_type, calculation_type, default_value, is_taxable, is_statutory, display_order, is_active, created_by, updated_by |
| TC-CR02 | Inspect $casts array | default_value decimal:4, display_order integer, is_taxable boolean, is_statutory boolean, is_active boolean |
| TC-CR03 | Check SoftDeletes import | use SoftDeletes; present in model |
| TC-CR04 | Check structureComponents() and structures() | HasMany + BelongsToMany defined correctly |
| TC-CR05 | Inspect all SalaryComponentController methods | All 10 call Gate::authorize('pay.structure.manage') |
| TC-CR06 | Inspect store(), update(), destroy(), restore(), forceDelete() | All call activityLog() with appropriate event |
| TC-CR07 | Inspect destroy() | Sets is_active=false before calling delete() |
| TC-CR08 | Inspect restore() | Calls update(['is_active' => true]) after restore() |
| TC-CR09 | Inspect toggleStatus() | Flips is_active via update() |
| TC-CR10 | Inspect trashed(), restore(), forceDelete() | onlyTrashed/findOrFail/withTrashed patterns |
| TC-CR13 | Inspect StoreSalaryComponentRequest rules() | All fillable columns except created_by/updated_by have rules |
| TC-CR14 | Inspect code unique rule | Rule::unique('pay_salary_components','code')->ignore($id)->whereNull('deleted_at') |
| TC-CR15 | Inspect prepareForValidation() | is_taxable, is_statutory, is_active cast via $this->boolean() |
| TC-CR16 | Inspect SalaryComponentPolicy | viewAny, view, create, update, delete, restore, forceDelete defined |
| TC-CR17 | Inspect policy methods | All use $user->can('hrs.salary_component.manage') |
| TC-CR18 | Check web.php routes | resource('salary-components') + toggle-status, trashed, restore, force-delete |
| TC-CR19 | Check DDL | UNIQUE KEY uq_pay_comp_code on code column |

#### TC-CR11: Controller — Statutory Field Guard in update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open SalaryComponentController.php | Controller found |
| 2 | Inspect update() method | Checks `if ($salaryComponent->is_statutory)` before update |
| 3 | Verify 3 restricted fields checked | code, component_type, calculation_type compared against original |
| 4 | Verify error message format | "Cannot modify {field} on statutory components." |

#### TC-CR12: Controller — Two Delete Guards in destroy()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect destroy() method | First checks `is_statutory` |
| 2 | Verify second guard | Checks `structureComponents()->where('is_active', true)->exists()` |
| 3 | Verify error messages | "Cannot delete statutory components." and "Cannot delete component used in active salary structures." |

### 7.1 Positive TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-P02 | Create "Basic Pay" and "HRA", search "Basic" | Only "Basic Pay" shown |
| TC-P03 | Create "BASIC" and "DA", search "DA" by code | Only "DA" shown |
| TC-P04 | Filter by component_type=earning | Only earning type components shown |
| TC-P05 | Filter by component_type=deduction | Only deduction components shown |
| TC-P06 | Filter by employer_contribution | Only employer contribution shown |
| TC-P08 | Create with component_type=deduction | DB has component_type='deduction' |
| TC-P09 | Create with component_type=employer_contribution | DB has component_type='employer_contribution' |
| TC-P10 | Create with calculation_type=fixed | DB has calculation_type='fixed' |
| TC-P11 | Create with calculation_type=percentage_of_basic | DB has percentage_of_basic |
| TC-P12 | Create with calculation_type=percentage_of_gross | DB has percentage_of_gross |
| TC-P13 | Create with calculation_type=statutory | DB has statutory |
| TC-P14 | Create with calculation_type=manual | DB has manual |
| TC-P15 | Create with is_taxable=false | DB has is_taxable=0 |
| TC-P17 | Create with display_order=1 | DB has display_order=1 |
| TC-P18 | Create with default_value=25.0000 | DB has default_value=25.0000 |
| TC-P19 | Click Edit on a component | Edit form pre-filled with existing values |
| TC-P20 | Edit name from "Old" to "New", default_value to 30 | Both updated, flash success |
| TC-P21 | Edit display_order from 3 to 1 | Order updated in DB |
| TC-P22 | Click View on component | Show page with structure list loaded |
| TC-P23 | Toggle active to inactive | AJAX success, is_active=0 |
| TC-P24 | Delete non-statutory component (no structure refs) | Soft-deleted, flash success |
| TC-P25 | Navigate to trash view | Soft-deleted records shown |
| TC-P26 | Restore trashed component | Restored with is_active=1 |
| TC-P27 | Force delete from trash | Permanently removed |
| TC-P28 | Create→edit→toggle→delete→restore cycle | All transitions succeed |
| TC-P29 | Create 25 components, go to page 1 | 20 records shown |
| TC-P30 | Go to page 2 | 5 remaining records |
| TC-P31 | No components exist | Empty state message |

#### TC-P01: Salary Components Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to HrStaff → HR Masters → Salary Components | Page loads with tab=salary-components |
| 3 | Verify search input | Search field visible |
| 4 | Verify type filter | Component type dropdown (earning/deduction/employer_contribution) |
| 5 | Verify Add button | Add button visible |
| 6 | Verify grid columns | Code, Name, Type, Calculation, Default Value, Display Order, Taxable, Status |

#### TC-P07: Create Earning Component

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add" | Create form opens |
| 2 | Enter name: "Basic Pay" | Name filled |
| 3 | Enter code: "BASIC" | Code filled |
| 4 | Select component_type: earning | Type set |
| 5 | Select calculation_type: fixed | Calc type set |
| 6 | Enter default_value: 10000 | Value set |
| 7 | Enter display_order: 1 | Order set |
| 8 | Click Save | POST to /salary-components |
| 9 | Verify flash | "Salary component created successfully." |
| 10 | DB check | Record with code=BASIC exists |

#### TC-P16: Create Component With is_statutory=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Fill with code "PF_EMP", name "PF Employee" | Required fields set |
| 3 | Set is_statutory = ON | Toggle ON |
| 4 | Click Save | Component created with is_statutory=1 |

#### TC-P21: Update Non-Statutory Component

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create component "HRA" with display_order=3 | Component exists |
| 2 | Edit and change display_order to 2 | Order changed |
| 3 | Click Save | Update succeeds |
| 4 | DB check | display_order=2 |

### 7.2 Negative TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-N01 | Submit without name | Validation error |
| TC-N02 | Submit without code | Validation error |
| TC-N03 | Submit without component_type | Validation error |
| TC-N04 | Submit without calculation_type | Validation error |
| TC-N05 | Submit without default_value | Validation error |
| TC-N06 | Submit without display_order | Validation error |
| TC-N07 | Submit duplicate code "BASIC" when one exists | "The code has already been taken." |
| TC-N08 | Enter invalid component_type | Validation error on in |
| TC-N09 | Enter invalid calculation_type | Validation error on in |
| TC-N10 | Enter name > 150 chars | Validation error on name.max |
| TC-N11 | Enter code > 30 chars | Validation error on code.max |
| TC-N12 | Enter display_order = 0 | Validation error on min:1 |
| TC-N13 | Enter display_order = 100 | Validation error on max:99 |
| TC-N14 | Enter default_value = -1 | Validation error on min:0 |
| TC-N20 | Access /salary-components/99999 | 404 Not Found |
| TC-N21 | Access /salary-components/99999/edit | 404 Not Found |
| TC-N22 | PUT /salary-components/99999 | 404 Not Found |
| TC-N23 | DELETE /salary-components/99999 | 404 Not Found |
| TC-N24 | Login as user without pay.structure.manage | 403 Forbidden |
| TC-N25 | Logout and access /salary-components | Redirect to /login |
| TC-N26 | Submit whitespace-only name | Required validation catches empty |

#### TC-N15: Modify Statutory Component Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create component with code "PF_EMP", is_statutory=1 | Component exists |
| 2 | Edit and change code to "PF" | Code field changed |
| 3 | Click Save | Controller detects statutory, returns error: "Cannot modify code on statutory components." |

#### TC-N18: Delete Statutory Component

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create component with is_statutory=1 | Component exists |
| 2 | Click Delete | Controller checks is_statutory = true |
| 3 | Verify error | "Cannot delete statutory components." |

#### TC-N19: Delete Component Used in Active Structure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create component BASIC | Component exists |
| 2 | Create salary structure with BASIC linked | Structure has active junction record |
| 3 | Try to delete BASIC | Controller checks structureComponents()->where('is_active',true)->exists() = true |
| 4 | Verify error | "Cannot delete component used in active salary structures." |

### 7.3 Dependency TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-D01 | Destroy component (no guards triggered) | is_active set to 0 before delete() |
| TC-D02 | Restore trashed component | is_active set to 1 |
| TC-D03 | Create component, check activity log | activityLog called with 'Created' |
| TC-D04 | Update component, check activity log | activityLog called with 'Updated' |
| TC-D05 | Delete component, check activity log | activityLog called with 'Trashed' |
| TC-D06 | Access $component->default_value | Returns float with 4 decimal places |
| TC-D07 | Access $component->display_order | Returns integer |
| TC-D08 | Access $component->is_taxable, is_statutory, is_active | All return boolean |
| TC-D10 | Access $component->structures | Returns BelongsToMany collection with pivot data |
| TC-D11 | Access /salary-components/99999 | 404 Not Found |
| TC-D12 | Inspect SalaryComponentController | All methods call Gate::authorize() |
| TC-D13 | Direct INSERT duplicate code "BASIC" | Integrity constraint violation uq_pay_comp_code |
| TC-D14 | Create structure with component, try delete component | Controller blocks: "Cannot delete component used in active salary structures." |
| TC-D15 | Create component with is_statutory=1, try delete | Controller blocks: "Cannot delete statutory components." |

#### TC-D09: Model Relationship — structureComponents() HasMany

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create component BASIC and link to structure | Junction record exists |
| 2 | Access $component->structureComponents | Returns collection of SalaryStructureComponent |
| 3 | Verify count matches number of structures using it | Correct count |

#### TC-D13: Unique Code Enforced at DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create component with code "BASIC" | Exists |
| 2 | Direct INSERT with code "BASIC" | Integrity constraint violation uniq_pay_comp_code |
