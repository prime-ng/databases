# hrs_SalaryStructures_TcList

## Module: HrStaff → HR Masters → Salary Structures

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | HR Masters |
| Feature | Salary Structures |
| URL(s) | `GET /hr-masters?tab=salary-structures` (tab view), `GET /salary-structures` (index), `POST /salary-structures` (store), `GET /salary-structures/{salaryStructure}` (show), `GET /salary-structures/{salaryStructure}/edit` (edit), `PUT /salary-structures/{salaryStructure}` (update), `DELETE /salary-structures/{salaryStructure}` (destroy), `POST /salary-structures/{salaryStructure}/toggle-status` (toggleStatus), `GET /salary-structures/trash/view` (trashed), `GET /salary-structures/{id}/restore` (restore), `DELETE /salary-structures/{id}/force-delete` (forceDelete), `GET /salary-structures/{salaryStructure}/preview` (preview) |
| Controller | `Modules\HrStaff\Http\Controllers\SalaryStructureController` |
| Model(s) | `Modules\HrStaff\Models\SalaryStructure` (table: `pay_salary_structures`), `Modules\HrStaff\Models\SalaryStructureComponent` (table: `pay_salary_structure_components`) |
| Service | `Modules\HrStaff\Services\SalaryStructureService` |
| Validation (Create/Update) | `Modules\HrStaff\Http\Requests\StoreSalaryStructureRequest` |
| Policy | `Modules\HrStaff\Policies\SalaryStructurePolicy` |
| Permissions | `pay.structure.manage` |
| Pagination | 20 records per page using default `page` parameter; tab view returns full collection |
| Soft Deletes | Yes (SoftDeletes trait on both models); `destroy()` sets `is_active=false` before `delete()`; restore sets `is_active=true` |
| Activity Log | Events: Created, Updated, Trashed, Restored, Deleted (force delete) |
| Data Source | Components from `Modules\HrStaff\Models\SalaryComponent` |

---

## 2. Pre-conditions

- Required permissions: `pay.structure.manage`
- Required seed data: At least 2 active `SalaryComponent` records (one being BASIC) for structure composition
- Test user must have `pay.structure.manage` permission (default admin user)
- Tenant context must be initialized
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For delete-guard tests: At least one salary assignment referencing the structure with `effective_to_date = null`
- For force-delete tests: At least one salary assignment (even historical)
- For preview tests: At least one structure with active components

---

## 3. Default Data Load

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Structures Grid (tab) | `HrMenuController@hrMasters()` | `SalaryStructure::with('components')->orderBy('name')` | search (name) | None (full collection) |
| Structures Grid (standalone) | `SalaryStructureController@index()` | `SalaryStructure::withCount(['structureComponents' => fn($q) => $q->where('is_active', true)])->orderBy('name')->withQueryString()` | search (name) | 20/page |
| Components (edit/show) | `SalaryStructureController@edit()` | `SalaryComponent::active()->orderBy('display_order')` | is_active=1 | None |

---

## 4. Test Data Strategy

- **BASIC component**: Ensure a component with code BASIC exists before creating structures
- **Structure name**: Unique name suffixed with timestamp
- **Components per structure**: Minimum 1 component (must include BASIC); test with 3-5 components
- **Pre-test cleanup**: Delete created structures by name before/after tests
- **Pagination**: Create 25 structures to test 20-record boundary
- **Salary assignment**: Create an assignment via factory for delete-guard tests
- **CTC preview**: Use realistic CTC values (e.g., 360000, 480000)

---

## 5. Business Conditions

### 5.1 Database Schema — `pay_salary_structures`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | name | VARCHAR(200) | NOT NULL |
| BC-DB-03 | description | TEXT | NULL |
| BC-DB-04 | applicable_to | ENUM('all','teaching','non_teaching','contractual') | NOT NULL DEFAULT 'all' |
| BC-DB-05 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-06 | created_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-07 | updated_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-08 | created_at | TIMESTAMP | NULL |
| BC-DB-09 | updated_at | TIMESTAMP | NULL |
| BC-DB-10 | deleted_at | TIMESTAMP | NULL (soft delete) |

### 5.2 Database Schema — `pay_salary_structure_components`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-11 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-12 | structure_id | BIGINT UNSIGNED FK | NOT NULL, FK → `pay_salary_structures.id` |
| BC-DB-13 | component_id | BIGINT UNSIGNED FK | NOT NULL, FK → `pay_salary_components.id` |
| BC-DB-14 | sequence_order | TINYINT UNSIGNED | NOT NULL DEFAULT 99 |
| BC-DB-15 | calculation_formula | TEXT | NULL |
| BC-DB-16 | is_mandatory | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-17 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-18 | created_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-19 | updated_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-20 | created_at | TIMESTAMP | NULL |
| BC-DB-21 | updated_at | TIMESTAMP | NULL |
| BC-DB-22 | deleted_at | TIMESTAMP | NULL (soft delete) |

### 5.3 Validation Rules — `StoreSalaryStructureRequest` (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | name | required, string, max:200 | — |
| BC-VAL-02 | description | nullable, string, max:500 | — |
| BC-VAL-03 | applicable_to | required, in:all,teaching,non_teaching,contractual | — |
| BC-VAL-04 | is_active | required, boolean | — |
| BC-VAL-05 | components | required, array, min:1 | "The components must contain at least 1 items." |
| BC-VAL-06 | components.*.component_id | required, exists:pay_salary_components,id | — |
| BC-VAL-07 | components.*.sequence_order | required, integer, min:1, max:99 | — |
| BC-VAL-08 | components.*.calculation_formula | nullable, string, max:255 | — |
| BC-VAL-09 | components.*.is_mandatory | required, boolean | — |
| BC-VAL-10 | **BASIC present (service)** | Components must include BASIC code | "Salary structure must include the BASIC component (BR-PAY-011)." |

### 5.4 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `pay.structure.manage` | All controller methods require gate; without → 403 |
| BC-AUTH-02 | Guest access | Redirect to /login |

### 5.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with `tab=salary-structures` | Structures list in tab view |
| BC-BIZ-02 | Standalone index | Paginated 20/page, with active components count |
| BC-BIZ-03 | Search by name | Filtered to matching name |
| BC-BIZ-04 | Create with BASIC component present | Structure created with junction records |
| BC-BIZ-05 | Create without BASIC component | DomainException thrown, redirect with error |
| BC-BIZ-06 | Update adds new component | Component linked via syncComponents (soft-delete old, create new) |
| BC-BIZ-07 | Preview with valid CTC | JSON breakdown returned with earnings/deductions/net |
| BC-BIZ-08 | Preview with zero CTC | 422 "CTC must be greater than zero." |
| BC-BIZ-09 | Delete blocked by active assignments | "Cannot delete structure with active salary assignments." |
| BC-BIZ-10 | Force-delete blocked by any assignments (even historical) | "Cannot permanently delete salary structure. It is currently or historically assigned to employees." |
| BC-BIZ-11 | Force-delete with no assignments | Transaction deletes junction records then structure |
| BC-BIZ-12 | Empty grid | Empty message shown |
| BC-BIZ-13 | Screen loads via SalaryStructureController@index() at GET /salary-structures | Standalone; tab via GET /hr-masters?tab=salary-structures |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | structure_id | pay_salary_structures (id) | CASCADE (in junction) |
| BC-REF-02 | component_id | pay_salary_components (id) | CASCADE (in junction) |
| BC-REF-03 | id (self) | pay_salary_structure_components.structure_id | Child FK |
| BC-REF-04 | id (self) | hrs_salary_assignments.pay_salary_structure_id | Child FK — blocks delete if active |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Salary Structures page loads with all UI elements | Page loads with search, Add button, grid | — | — | ⬜ |
| TC-P02 | Search by name | Grid filtered to matching name | — | — | ⬜ |
| TC-P03 | Create structure with BASIC and 2 other components | Structure created with 3 junction records | — | — | ⬜ |
| TC-P04 | Create structure with is_mandatory=1 on BASIC | BASIC marked mandatory in junction | — | — | ⬜ |
| TC-P05 | Create structure with applicable_to=teaching | applicable_to set to teaching | — | — | ⬜ |
| TC-P06 | Create structure with applicable_to=contractual | applicable_to set to contractual | — | — | ⬜ |
| TC-P07 | Create structure with calculation_formula override | Formula stored in junction | — | — | ⬜ |
| TC-P08 | Edit structure loads pre-filled data with components | Edit form shows structure + linked components | — | — | ⬜ |
| TC-P09 | Update structure name and description | Name/description updated | — | — | ⬜ |
| TC-P10 | Update structure: add new component | New component linked, old ones preserved | — | — | ⬜ |
| TC-P11 | Update structure: remove component | Component removed via syncComponents (soft-deleted) | — | — | ⬜ |
| TC-P12 | View structure details with component list | Show page with component list + Add Component | — | — | ⬜ |
| TC-P13 | Preview CTC with valid amount | JSON response with earnings, deductions, net | — | — | ⬜ |
| TC-P14 | Preview shows correct breakdown for fixed components | Fixed amounts appear correctly | — | — | ⬜ |
| TC-P15 | Preview shows correct breakdown for percentage_of_basic | Pct of basic computed correctly | — | — | ⬜ |
| TC-P16 | Preview shows correct breakdown for percentage_of_gross | Pct of gross computed correctly | — | — | ⬜ |
| TC-P17 | Toggle status active to inactive | AJAX success, is_active flipped | — | — | ⬜ |
| TC-P18 | Soft delete structure (no active assignments) | Structure soft-deleted | — | — | ⬜ |
| TC-P19 | View trashed structures | Trash page lists soft-deleted | — | — | ⬜ |
| TC-P20 | Restore trashed structure | Restored with is_active=1 | — | — | ⬜ |
| TC-P21 | Force delete structure (no assignments at all) | Permanently removed with junction records | — | — | ⬜ |
| TC-P22 | Full lifecycle: create→edit→preview→toggle→delete→restore | All transitions succeed | — | — | ⬜ |
| TC-P23 | Pagination — first page 20 records | Page 1 shows 20 records | — | — | ⬜ |
| TC-P24 | Pagination — second page | Page 2 shows records 21+ | — | — | ⬜ |
| TC-P25 | Empty state | Empty message shown | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — missing `name` | Validation error | — | — | ⬜ |
| TC-N02 | Required — missing `applicable_to` | Validation error | — | — | ⬜ |
| TC-N03 | Required — missing `components` array | "The components field is required." | — | — | ⬜ |
| TC-N04 | Empty components array (min:1) | "The components must contain at least 1 items." | — | — | ⬜ |
| TC-N05 | Missing BASIC component | "Salary structure must include the BASIC component (BR-PAY-011)." | — | — | ⬜ |
| TC-N06 | Invalid component_id in components array | "The selected components.0.component_id is invalid." | — | — | ⬜ |
| TC-N07 | Max length — name > 200 chars | Validation error on name.max | — | — | ⬜ |
| TC-N08 | Invalid applicable_to value | Validation error on in | — | — | ⬜ |
| TC-N09 | sequence_order < 1 | Validation error on min | — | — | ⬜ |
| TC-N10 | sequence_order > 99 | Validation error on max | — | — | ⬜ |
| TC-N11 | Delete structure with active salary assignments | "Cannot delete structure with active salary assignments." | — | — | ⬜ |
| TC-N12 | Force-delete structure with historical assignments | "Cannot permanently delete salary structure. It is currently or historically assigned to employees." | — | — | ⬜ |
| TC-N13 | Preview with zero CTC | 422 "CTC must be greater than zero." | — | — | ⬜ |
| TC-N14 | Preview with negative CTC | 422 "CTC must be greater than zero." | — | — | ⬜ |
| TC-N15 | View non-existent structure (404) | 404 Not Found | — | — | ⬜ |
| TC-N16 | Edit non-existent structure (404) | 404 Not Found | — | — | ⬜ |
| TC-N17 | Update non-existent structure (404) | 404 Not Found | — | — | ⬜ |
| TC-N18 | Delete non-existent structure (404) | 404 Not Found | — | — | ⬜ |
| TC-N19 | Preview non-existent structure (404) | 404 Not Found | — | — | ⬜ |
| TC-N20 | Permission denied — user without `pay.structure.manage` | 403 Forbidden | — | — | ⬜ |
| TC-N21 | Guest access | Redirect to /login | — | — | ⬜ |
| TC-N22 | Whitespace-only name | Validation catches empty | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Soft delete sets is_active=false on structure | is_active=0 before delete() | — | — | ⬜ |
| TC-D02 | A | Restore sets is_active=true | is_active=1 after restore() | — | — | ⬜ |
| TC-D03 | B | Activity logged on create | activityLog 'Created' | — | — | ⬜ |
| TC-D04 | B | Activity logged on update | activityLog 'Updated' | — | — | ⬜ |
| TC-D05 | B | Activity logged on soft delete | activityLog 'Trashed' | — | — | ⬜ |
| TC-D06 | C | Service creates structure in DB transaction | Both structure and junction records created atomically | — | — | ⬜ |
| TC-D07 | C | Service uses updateOrCreate for components | Junction records upserted by (structure_id, component_id) | — | — | ⬜ |
| TC-D08 | C | syncComponents soft-deletes existing junction records | Sets is_active=false on old records before creating new | — | — | ⬜ |
| TC-D09 | D | Service validates BASIC present on create | SalaryComponent::where('code', 'BASIC')->value('id') check | — | — | ⬜ |
| TC-D10 | D | Service validates BASIC present on update (when components provided) | Same check in updateStructure | — | — | ⬜ |
| TC-D11 | E | Model $casts — is_active boolean | TINYINT accessed as bool | — | — | ⬜ |
| TC-D12 | F | Model relationships — structureComponents() HasMany | Returns SalaryStructureComponent records | — | — | ⬜ |
| TC-D13 | F | Model relationships — components() BelongsToMany | Returns SalaryComponent records with pivot data | — | — | ⬜ |
| TC-D14 | F | Model relationships — salaryAssignments() HasMany | Returns SalaryAssignment records | — | — | ⬜ |
| TC-D15 | G | SalaryStructureComponent relationships — structure() BelongsTo | Returns parent SalaryStructure | — | — | ⬜ |
| TC-D16 | G | SalaryStructureComponent relationships — component() BelongsTo | Returns child SalaryComponent | — | — | ⬜ |
| TC-D17 | H | Controller — findOrFail — 404 on invalid ID | All methods 404 | — | — | ⬜ |
| TC-D18 | I | Controller — Gate::authorize() on every method | All methods gate | — | — | ⬜ |
| TC-D19 | J | Force-delete uses DB::transaction | Junction records forceDeleted first, then structure | — | — | ⬜ |
| TC-D20 | K | Preview service computes breakdown correctly | Fixed, pct_of_basic, pct_of_gross types computed per component | — | — | ⬜ |
| TC-D21 | L | Unique constraint on (structure_id, component_id) in junction | Duplicate component for same structure blocked at DB level | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Models — $fillable matches DDL on both tables | Both models have correct fillable | — | — | ◌ |
| TC-CR02 | CR | P1 | Models — $casts correct | is_active boolean on both | — | — | ◌ |
| TC-CR03 | CR | P1 | Models — SoftDeletes trait on both | Both import SoftDeletes | — | — | ◌ |
| TC-CR04 | CR | P1 | Models — relationships defined | All BelongsTo/HasMany/BelongsToMany defined | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — Gate::authorize() on every method | All gate before execution | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB transactions in store/update | Both delegate to service which uses DB::transaction | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — activityLog on all state changes | All write methods log | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — is_active=false before soft delete | destroy() sets is_active=false | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — restore sets is_active=true | update is_active=1 | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — toggleStatus() flips | Toggles via update() | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — trash/restore/forceDelete flow | Standard lifecycle | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — forceDelete checks historical assignments | salaryAssignments()->withTrashed()->exists() | — | — | ◌ |
| TC-CR13 | CR | P1 | Controller — forceDelete catches exceptions | try-catch with generic error message | — | — | ◌ |
| TC-CR14 | CR | P1 | Controller — preview() validates CTC > 0 | abort_if($ctc <= 0, 422) | — | — | ◌ |
| TC-CR15 | CR | P1 | Controller — JSON success on toggle and preview | response()->json() on both | — | — | ◌ |
| TC-CR16 | CR | P1 | Request — components array validation | required, array, min:1 with nested rules | — | — | ◌ |
| TC-CR17 | CR | P1 | Request — prepareForValidation() normalizes is_mandatory | Boolean filter_var on each component | — | — | ◌ |
| TC-CR18 | CR | P1 | Policy — all methods defined | 7 gates defined | — | — | ◌ |
| TC-CR19 | CR | P1 | Routes — resource + custom routes + preview | All mapped | — | — | ◌ |
| TC-CR20 | CR | P1 | Service — validateBasicPresent throws DomainException | throw_unless with DomainException | — | — | ◌ |
| TC-CR21 | CR | P1 | Database — unique key on junction (structure_id, component_id) | uq_pay_struct_comp | — | — | ◌ |

---

## 7. Detailed Test Steps

### Code Review TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-CR01 | Inspect SalaryStructure $fillable | name, description, applicable_to, is_active, created_by, updated_by |
| TC-CR02 | Check $casts on both models | is_active boolean on structure; sequence_order integer, is_mandatory boolean, is_active boolean on component |
| TC-CR03 | Check SoftDeletes on both models | Both import SoftDeletes |
| TC-CR04 | Check all relationships | structureComponents(), components(), salaryAssignments() on Structure; structure(), component() on Junction |
| TC-CR05 | Inspect all controller methods | All gate pay.structure.manage |
| TC-CR06 | Inspect store/update | Both use DB::transaction via service |
| TC-CR07 | Inspect activityLog | All write methods call activityLog() |
| TC-CR08 | Inspect destroy() | Sets is_active=false before delete() |
| TC-CR09 | Inspect restore() | Sets is_active=true |
| TC-CR10 | Inspect toggleStatus() | Flips is_active |
| TC-CR11 | Inspect trash/restore/forceDelete | Standard pattern |
| TC-CR13 | Inspect forceDelete try-catch | Catches exception with generic integrity message |
| TC-CR15 | Inspect flash/JSON responses | Flash on CRUD, JSON on toggle and preview |
| TC-CR16 | Inspect StoreSalaryStructureRequest | components array validation with nested rules |
| TC-CR17 | Inspect prepareForValidation | is_mandatory bool normalized per component |
| TC-CR18 | Check SalaryStructurePolicy | 7 gates all use pay.structure.manage |
| TC-CR19 | Check web.php routes | resource + toggle-status + trash/restore/force-delete + preview |
| TC-CR21 | Check DDL unique key | uq_pay_struct_comp on (structure_id, component_id) |

#### TC-CR12: Controller — forceDelete Checks Historical Assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect forceDelete() | Checks `salaryAssignments()->withTrashed()->exists()` |
| 2 | Verify error message | "Cannot permanently delete salary structure. It is currently or historically assigned to employees." |

#### TC-CR14: Controller — preview() Validates CTC > 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect preview() | `abort_if($ctc <= 0, 422, 'CTC must be greater than zero.')` |

#### TC-CR20: Service — validateBasicPresent Throws DomainException

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open SalaryStructureService.php | Service found |
| 2 | Inspect validateBasicPresent() | Looks up BASIC component ID, throws DomainException if absent |

### 7.1 Positive TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-P02 | Create "Teaching" and "Support" structures, search "Teaching" | Only "Teaching" shown |
| TC-P04 | Create with BASIC marked is_mandatory=1 | Junction has is_mandatory=1 for BASIC |
| TC-P05 | Create with applicable_to=teaching | DB has applicable_to='teaching' |
| TC-P06 | Create with applicable_to=contractual | DB has applicable_to='contractual' |
| TC-P07 | Create with calculation_formula="25" on HRA component | Formula stored in junction record |
| TC-P08 | Click Edit on structure | Edit form pre-filled with structure + linked components |
| TC-P09 | Edit name from "Old" to "New", add description | Both updated, flash success |
| TC-P10 | Update by adding a new component | New junction record created with is_active=1 |
| TC-P11 | Update by removing a component | Old junction record soft-deleted (is_active=0) |
| TC-P12 | Click View on structure | Show page with components list and Add Component |
| TC-P14 | Preview CTC 360000 with BASIC fixed=12000 | Earnings includes "BASIC" with amount=12000 |
| TC-P15 | Preview with HRA as percentage_of_basic (25%) | HRA amount = BASIC * 0.25 |
| TC-P16 | Preview with Conveyance as percentage_of_gross (10%) | Conveyance = monthly_gross * 0.10 |
| TC-P17 | Toggle active to inactive | AJAX success, is_active=0 |
| TC-P18 | Delete structure with no active assignments | Soft-deleted, flash success |
| TC-P19 | Navigate to trash view | Soft-deleted records shown |
| TC-P20 | Restore trashed structure | Restored with is_active=1 |
| TC-P21 | Force delete structure with no assignments (even historical) | Junction + structure permanently deleted |
| TC-P22 | Create→edit→preview→toggle→delete→restore | All transitions succeed |
| TC-P23 | Create 25 structures, page 1 | 20 records shown |
| TC-P24 | Page 2 | 5 remaining records |
| TC-P25 | No structures exist | Empty state message |

#### TC-P01: Salary Structures Page Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to HrStaff → HR Masters → Salary Structures | Page loads with tab=salary-structures |
| 3 | Verify search | Search field visible |
| 4 | Verify Add button | Add button visible |
| 5 | Verify grid columns | Name, Applicable To, Components Count, Status |

#### TC-P03: Create Structure With BASIC and 2 Other Components

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure BASIC component exists with id=X | BASIC exists |
| 2 | Ensure DA component exists with id=Y, HRA with id=Z | DA and HRA exist |
| 3 | Click "Add" | Create form opens |
| 4 | Enter name: "Teaching Staff Structure" | Name filled |
| 5 | Select applicable_to: teaching | Applicability set |
| 6 | Add component BASIC (id=X), sequence=1, mandatory=yes | Component added |
| 7 | Add component DA (id=Y), sequence=2 | Component added |
| 8 | Add component HRA (id=Z), sequence=3, formula="25" | Component with formula override |
| 9 | Click Save | POST to /salary-structures |
| 10 | Verify flash | "Salary structure created successfully." |
| 11 | DB check structure | Record exists with name="Teaching Staff Structure" |
| 12 | DB check junction | 3 records in pay_salary_structure_components with correct structure_id |

#### TC-P13: Preview CTC With Valid Amount

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create structure with BASIC (fixed 12000), DA (pct_of_basic 50), HRA (pct_of_basic 25) | Structure exists with ID=X |
| 2 | Call GET /salary-structures/{X}/preview?ctc=360000 | Preview endpoint |
| 3 | Verify JSON response | status=true, data has earnings[], deductions[], total_earnings, total_deductions, net_monthly |

### 7.2 Negative TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-N01 | Submit without name | Validation error |
| TC-N02 | Submit without applicable_to | Validation error |
| TC-N03 | Submit without components array | "The components field is required." |
| TC-N04 | Submit with empty components array | "The components must contain at least 1 items." |
| TC-N06 | Submit with non-existent component_id | "The selected components.0.component_id is invalid." |
| TC-N07 | Enter name > 200 chars | Validation error on name.max |
| TC-N08 | Enter invalid applicable_to | Validation error on in |
| TC-N09 | sequence_order = 0 | Validation error on min:1 |
| TC-N10 | sequence_order = 100 | Validation error on max:99 |
| TC-N13 | Preview with CTC = 0 | 422 "CTC must be greater than zero." |
| TC-N14 | Preview with CTC = -1000 | 422 "CTC must be greater than zero." |
| TC-N15 | Access /salary-structures/99999 | 404 Not Found |
| TC-N16 | Access /salary-structures/99999/edit | 404 Not Found |
| TC-N17 | PUT /salary-structures/99999 | 404 Not Found |
| TC-N18 | DELETE /salary-structures/99999 | 404 Not Found |
| TC-N19 | Preview /salary-structures/99999/preview?ctc=360000 | 404 Not Found |
| TC-N20 | Login as user without pay.structure.manage | 403 Forbidden |
| TC-N21 | Logout and access | Redirect to /login |
| TC-N22 | Submit whitespace-only name | Required validation catches empty |

#### TC-N05: Missing BASIC Component

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Add a non-BASIC component (e.g., HRA) only | Component added |
| 3 | Click Save | Service throws DomainException |
| 4 | Verify error | "Salary structure must include the BASIC component (BR-PAY-011)." |
| 5 | Verify redirected back with input | Form retains entered data |

#### TC-N11: Delete Structure With Active Assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create structure with ID=1 | Structure exists |
| 2 | Create salary assignment referencing structure with effective_to_date=null | Active assignment exists |
| 3 | Try to delete structure | Controller checks salaryAssignments()->whereNull('effective_to_date')->exists() = true |
| 4 | Verify error | "Cannot delete structure with active salary assignments." |

#### TC-N12: Force-Delete Structure With Historical Assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create structure with ID=1, soft-delete it first | Structure in trash |
| 2 | Create historical salary assignment with effective_to_date set | Assignment references structure |
| 3 | Try force-delete from trash | Controller checks withTrashed()->exists() = true |
| 4 | Verify error | "Cannot permanently delete salary structure..." |

### 7.3 Dependency TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-D01 | Destroy structure (no guards) | is_active=0 before delete() |
| TC-D02 | Restore trashed structure | is_active=1 after restore() |
| TC-D03 | Create structure, check activity log | activityLog with 'Created' |
| TC-D04 | Update structure, check activity log | activityLog with 'Updated' |
| TC-D05 | Delete structure, check activity log | activityLog with 'Trashed' |
| TC-D06 | Inspect createStructure in service | Uses DB::transaction |
| TC-D07 | Update structure with new component | updateOrCreates/updates junction record |
| TC-D09 | Create structure without BASIC | DomainException: "must include the BASIC component" |
| TC-D10 | Update structure removing BASIC | DomainException thrown |
| TC-D11 | Access $structure->is_active | Returns boolean |
| TC-D12 | Access $structure->structureComponents | Returns HasMany collection |
| TC-D13 | Access $structure->components | Returns BelongsToMany with pivot data |
| TC-D14 | Access $structure->salaryAssignments | Returns HasMany collection |
| TC-D15 | Access $sc->structure (on SalaryStructureComponent) | Returns parent SalaryStructure |
| TC-D16 | Access $sc->component | Returns linked SalaryComponent |
| TC-D17 | Access /salary-structures/99999 | 404 on all methods |
| TC-D18 | Inspect SalaryStructureController methods | All gate pay.structure.manage |
| TC-D19 | Force delete, inspect code | forceDeleteStructureComponents then forceDelete in transaction |
| TC-D20 | Preview CTC 360000 with fixed BASIC 12000 | Earnings shows BASIC=12000 |

#### TC-D08: syncComponents Soft-Deletes Old Junction Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create structure with 2 components | Junction records exist, is_active=1 |
| 2 | Update structure with different component set | syncComponents called |
| 3 | Check old junction record | is_active=0, deleted_at set |
| 4 | Check new junction record | is_active=1, created |

#### TC-D21: Unique Constraint on Junction (structure_id, component_id)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create structure with BASIC component | Junction record (S1, C1) exists |
| 2 | Try direct INSERT of duplicate (S1, C1) | Integrity constraint violation uq_pay_struct_comp |
