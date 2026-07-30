# slb_competencies_TcList

## Module: Syllabus → Syllabus Master → Competencies

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Syllabus |
| Tab Group | Syllabus Master |
| Feature | Competencies |
| URL(s) | `/syllabus/master` (index via tab), `/syllabus/competency/store` (create/update), `/syllabus/competency/{id}` (show), `/syllabus/competency/{id}/destroy` (delete), `/syllabus/competency/trash/view` (trash), `/syllabus/competency/{id}/restore` (restore), `/syllabus/competency/parents` (getParentCompetencies), `/syllabus/competency/tree` (getCompetencyTree), `/syllabus/competency/by-filter` (getByFilter), `/syllabus/competency/update-hierarchy` (updateHierarchy) |
| Controller | `Modules\Syllabus\Http\Controllers\CompetencieController` |
| Model(s) | `Modules\Syllabus\Models\Competencie` |
| Validation (Create) | `Modules\Syllabus\Http\Requests\CompetencyRequest` |
| Validation (Update) | `Modules\Syllabus\Http\Requests\CompetencyRequest` (store acts as both create + update) |
| Permissions | `tenant.competencies.viewAny`, `tenant.competencies.view`, `tenant.competencies.create`, `tenant.competencies.update`, `tenant.competencies.delete` |
| Soft Deletes | Yes (`Competencie` uses `SoftDeletes` trait) |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted` |
| Hierarchy | Self-referencing `parent_id` FK CASCADE, auto-computed `level` and `path` |

---

## 2. Pre-conditions

- Required permissions: `tenant.competencies.viewAny`, `tenant.competencies.view`, `tenant.competencies.create`, `tenant.competencies.update`, `tenant.competencies.delete`
- Required seed data: At least one active `SchoolClass`, one active `Subject`, one active `CompetencyType`
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For hierarchy tests: At least 2 root competencies with children
- For domain tests: Competency types for COGNITIVE, AFFECTIVE, PSYCHOMOTOR must be seeded

---

---

## 3. Default Data Load

When the page loads via SyllabusController@master() (GET /syllabus/master), the following data is fetched and passed to the view:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: Classes | SyllabusController@master() | SchoolClass::where('is_active',1)->orderBy('ordinal') | is_active=1 | None |
| Shared: Sections | SyllabusController@master() | Section::where('is_active',1)->orderBy('name') | is_active=1 | None |
| Shared: Subjects | SyllabusController@master() | Subject::where('is_active',1)->orderBy('name') | is_active=1 | None |
| Shared: Academic Sessions | SyllabusController@master() | OrganizationAcademicSession::orderBy('name') | None | None |
| Shared: Books | SyllabusController@master() | BokBook::where('is_active',1)->orderBy('title') | is_active=1 | None |
| Shared: All Lessons | SyllabusController@master() | Lesson::with(class,subject)->orderBy('name') | None | None |
| Shared: Topic Level Types | SyllabusController@master() | TopicLevelType::where('is_active',1)->orderBy('level') | is_active=1 | None |
| Shared: Competency Types | SyllabusController@master() | CompetencyType::where('is_active',1) | is_active=1 | None |
| Shared: All Competencies | SyllabusController@master() | Competencie::all() | None | None |
| Shared: All Topics | SyllabusController@master() | Topic::all() | None | None |
| Competencies Grid | getCompetencies() | Competencie::with(class,subject) | search(name), filters(class_id,subject_id) | 10/page (competencies_page) |
## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Code uniqueness**: Scoped to `(class_id, subject_id)` combination
- **Name**: String max 255, no uniqueness constraint
- **Level**: Auto-computed on `creating` event: root = 0, child = parent.level + 1
- **Path**: Auto-generated on `creating`: root = `/`, child = `/parentId/`
- **UUID**: Auto-generated `Str::random(16)` on create (binary 16)
- **Pre-test cleanup**: Delete created competencies by UUID before/after tests
- **Store duality**: `store()` acts as create (no id) and update (with id); gate changes accordingly
- **Drag-drop hierarchy**: `updateHierarchy()` first nulls all parent_ids, then assigns new structure in transaction

---

## 5. Business Conditions

### 4.1 Database Schema — `slb_competencies`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT PK | Auto-increment |
| BC-DB-02 | uuid | BINARY(16) | NOT NULL, UNIQUE |
| BC-DB-03 | parent_id | BIGINT FK NULL | Self-FK → `slb_competencies.id`, ON DELETE CASCADE |
| BC-DB-04 | code | VARCHAR(60) | NOT NULL, UNIQUE scoped `(class_id, subject_id)` |
| BC-DB-05 | name | VARCHAR(150) | NOT NULL |
| BC-DB-06 | short_name | VARCHAR(50) | DEFAULT NULL |
| BC-DB-07 | description | VARCHAR(255) | DEFAULT NULL |
| BC-DB-08 | class_id | BIGINT FK | NOT NULL, FK → `sch_classes.id`, ON DELETE CASCADE |
| BC-DB-09 | subject_id | BIGINT FK | NOT NULL, FK → `sch_subjects.id`, ON DELETE CASCADE |
| BC-DB-10 | competency_type_id | BIGINT FK | NOT NULL, FK → `slb_competency_types.id`, ON DELETE CASCADE |
| BC-DB-11 | domain | ENUM('COGNITIVE','AFFECTIVE','PSYCHOMOTOR') | NOT NULL |
| BC-DB-12 | nep_framework_ref | VARCHAR(100) | DEFAULT NULL |
| BC-DB-13 | ncf_alignment | VARCHAR(100) | DEFAULT NULL |
| BC-DB-14 | learning_outcome_code | VARCHAR(50) | DEFAULT NULL |
| BC-DB-15 | path | VARCHAR(500) | NOT NULL, materialized |
| BC-DB-16 | level | TINYINT | NOT NULL, 0 = root |
| BC-DB-17 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-18 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-19 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-20 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules — `CompetencyRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | class_id | required, integer, exists:sch_classes,id | "Class is required." / "Selected class is invalid." |
| BC-VAL-02 | subject_id | required, integer, exists:sch_subjects,id | "Subject is required." / "Selected subject is invalid." |
| BC-VAL-03 | parent_id | nullable, integer, exists:slb_competencies,id + not-self callback | "A competency cannot be its own parent." |
| BC-VAL-04 | code | required, string, max:50, unique scoped `(class_id, subject_id)` | "This competency code already exists for the selected class and subject." |
| BC-VAL-05 | name | required, string, max:255 | "Competency name is required." |
| BC-VAL-06 | competency_type_id | required, integer, exists:slb_competency_types,id | "Competency type is required." |
| BC-VAL-07 | domain | required, in:COGNITIVE,AFFECTIVE,PSYCHOMOTOR | — |
| BC-VAL-08 | short_name | nullable, string, max:50 | — |
| BC-VAL-09 | nep_alignment | nullable, string, max:100 | "NEP alignment must not exceed 100 characters." |
| BC-VAL-10 | nep_framework_ref | nullable, string, max:255 | — |
| BC-VAL-11 | learning_outcome_code | nullable, string, max:100 | — |
| BC-VAL-12 | description | nullable, string | — |
| BC-VAL-13 | is_active | required, boolean | "Status is required." |

### 4.3 Validation Rules — `CompetencyRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | code | unique scoped + ignore given ID | "This competency code already exists for the selected class and subject." |
| BC-VAL-U02 | Self-parent (controller) | parent_id cannot equal own id | "A competency cannot be its own parent." |
| BC-VAL-U03 | Circular parent (controller) | New parent cannot be a descendant | "Invalid parent-child relationship." |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.competencies.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.competencies.view | show(), edit(), getParentCompetencies(), getCompetencyTree(), getByFilter() | Without → 403 |
| BC-AUTH-03 | tenant.competencies.create | store() (no id) | Without → 403 |
| BC-AUTH-04 | tenant.competencies.update | store() (with id), update(), updateHierarchy() | Without → 403 |
| BC-AUTH-05 | tenant.competencies.delete | destroy() | Without → 403 |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Store duality | `store()` acts as create (id absent) or update (id present) |
| BC-BIZ-02 | Level auto-compute | Root → level 0; child → parent.level + 1 |
| BC-BIZ-03 | Path auto-generate | Root → `/`; child → `/parentId/` |
| BC-BIZ-04 | UUID auto-generation | `Str::random(16)` on `creating` event |
| BC-BIZ-05 | Code uniqueness scope | Unique within (class_id, subject_id) combination |
| BC-BIZ-06 | Parent cannot be self | Controller validates self-parent |
| BC-BIZ-07 | Circular parent detection | Controller detects if new parent is a descendant |
| BC-BIZ-08 | Delete blocked by children | `children()->exists()` → 500 |
| BC-BIZ-09 | Soft delete cascades | `deleting` boot event cascades to children and topicCompetencies |
| BC-BIZ-10 | Drag-drop hierarchy update | `updateHierarchy()` nulls all parent_ids then assigns new tree |
| BC-BIZ-11 | Domain strict ENUM | Only COGNITIVE, AFFECTIVE, PSYCHOMOTOR allowed |
| BC-BIZ-12 | Global vs specific scope | Empty class/subject = global; filled = scoped |
| BC-BIZ-13 | Activity logging | Stored, Updated, Trashed, Restored, Deleted all logged |
| BC-BIZ-14 | Screen loads via SyllabusController@master() at GET /syllabus/master with master tab group | Navigating to GET /syllabus/master with appropriate permissions loads the Master tab group; this screen's grid data is fetched and displayed |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | parent_id | slb_competencies (id) | CASCADE |
| BC-REF-02 | class_id | sch_classes (id) | CASCADE |
| BC-REF-03 | subject_id | sch_subjects (id) | CASCADE |
| BC-REF-04 | competency_type_id | slb_competency_types (id) | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Competencies Page Loads With All UI Elements | Page loads with class/subject filter, tree view, Add Competency button | — | — | ⬜ |
| TC-P02 | Filter Competencies By Class + Subject | Tree shows only competencies matching selected class and subject | — | — | ⬜ |
| TC-P03 | Filter By Domain (Cognitive/Affective/Psychomotor) | Tree filters to show only competencies of selected domain | — | — | ⬜ |
| TC-P04 | Search Competencies By Name Or Code | Tree filters to show only matching competencies | — | — | ⬜ |
| TC-P05 | Create Root Competency With All Required Fields | Competency created with correct class_id, subject_id, competency_type_id, domain, code, name | — | — | ⬜ |
| TC-P06 | Create Root With Auto-Computed Fields | Level=0, path=`/`, uuid auto-generated, code saved | — | — | ⬜ |
| TC-P07 | Create Child Competency Under Root | Child created with parent_id set, level=1, path=`/parentId/` | — | — | ⬜ |
| TC-P08 | Create Child Competency 2 Levels Deep | level=2, path includes both ancestors | — | — | ⬜ |
| TC-P09 | Create Competency With All Optional Fields | Short name, description, NEP framework ref, NCF alignment, learning outcome code all saved | — | — | ⬜ |
| TC-P10 | Create Competency With Each Cognitive Domain | COGNITIVE, AFFECTIVE, PSYCHOMOTOR — all three types saved correctly | — | — | ⬜ |
| TC-P11 | Create Global Competency (No Class/Subject Scope) | Global competency visible across all class+subject combinations | — | — | ⬜ |
| TC-P12 | Create Competency With Specific Competency Type | competency_type_id links to correct type in slb_competency_types | — | — | ⬜ |
| TC-P13 | Edit Competency Loads Pre-Filled Data | Edit form shows existing data with parent options excluding self and descendants | — | — | ⬜ |
| TC-P14 | Update Competency Name, Code, Domain | Name, code, domain updated; code unique validation passes for new value | — | — | ⬜ |
| TC-P15 | Update Competency — Change Parent | Parent changed; level and path auto-updated | — | — | ⬜ |
| TC-P16 | View Competency Details Page | Details shown with name, code, domain, type, path, NEP ref, NCF alignment | — | — | ⬜ |
| TC-P17 | Drag-Drop Reparenting (Hierarchy Update) | Competency moved to new parent; parent_id, level, path updated | — | — | ⬜ |
| TC-P18 | Drag-Drop Make Root Competency | Competency's parent_id set to null, level=0, path=`/` | — | — | ⬜ |
| TC-P19 | Soft Delete Competency (No Children) | `deleted_at` set; competency no longer visible on tree | — | — | ⬜ |
| TC-P20 | Trash Page Shows Deleted Competencies | Trash page lists soft-deleted competencies with restore + force delete | — | — | ⬜ |
| TC-P21 | Restore Competency From Trash | `deleted_at` set to NULL; competency visible again; activity log "Restored" | — | — | ⬜ |
| TC-P22 | Force Delete Competency (Permanent) | Record permanently removed; activity log "Deleted" | — | — | ⬜ |
| TC-P23 | Toggle Status Active ↔ Inactive | `is_active` flips; JSON 200 with success | — | — | ⬜ |
| TC-P24 | Get Parent Competencies AJAX | `getParentCompetencies()` returns JSON of eligible parents | — | — | ⬜ |
| TC-P25 | Get Competency Tree AJAX | `getCompetencyTree()` returns nested JSON hierarchy | — | — | ⬜ |
| TC-P26 | Get By Filter AJAX | `getByFilter(class_id, subject_id)` returns filtered tree | — | — | ⬜ |
| TC-P27 | Full Lifecycle: Create → Edit → Add Child → Toggle → Delete → Trash → Restore | All transitions successful; activity logged at each step | — | — | ⬜ |
| TC-P28 | Empty State — No Competencies For Filter | Tree shows "No competencies found" message | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `class_id` | Validation error: "Class is required." | — | — | ⬜ |
| TC-N02 | Required — Missing `subject_id` | Validation error: "Subject is required." | — | — | ⬜ |
| TC-N03 | Required — Missing `code` | Validation error: "The code field is required." | — | — | ⬜ |
| TC-N04 | Required — Missing `name` | Validation error: "Competency name is required." | — | — | ⬜ |
| TC-N05 | Required — Missing `competency_type_id` | Validation error: "Competency type is required." | — | — | ⬜ |
| TC-N06 | Required — Missing `domain` | Validation error: "The domain field is required." | — | — | ⬜ |
| TC-N07 | Duplicate Code Within Same Class+Subject Scope | "This competency code already exists for the selected class and subject." | — | — | ⬜ |
| TC-N08 | Same Code Allowed For Different Class+Subject | Code unique only within scope; same code for different scope allowed | — | — | ⬜ |
| TC-N09 | Max Length — Code > 50 Characters | Validation fails on code.max | — | — | ⬜ |
| TC-N10 | Max Length — Name > 255 Characters | Validation fails on name.max | — | — | ⬜ |
| TC-N11 | Max Length — Short Name > 50 Characters | Validation fails on short_name.max | — | — | ⬜ |
| TC-N12 | Max Length — NEP Alignment > 100 Characters | "NEP alignment must not exceed 100 characters." | — | — | ⬜ |
| TC-N13 | Invalid Domain Value (Not In ENUM) | Validation fails on domain.in | — | — | ⬜ |
| TC-N14 | Invalid FK — Non-Existent `class_id` | "Selected class is invalid." | — | — | ⬜ |
| TC-N15 | Invalid FK — Non-Existent `competency_type_id` | Validation error: "The selected competency type id is invalid." | — | — | ⬜ |
| TC-N16 | Self-Parent Assignment | "A competency cannot be its own parent." | — | — | ⬜ |
| TC-N17 | Circular Parent-Child Relationship | "Invalid parent-child relationship." | — | — | ⬜ |
| TC-N18 | Delete Competency With Children | "Cannot delete competency because it has child competencies." | — | — | ⬜ |
| TC-N19 | View Competency With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N20 | Edit/Update Competency With Invalid ID (404) | 404 error: Model not found | — | — | ⬜ |
| TC-N21 | Permission 403 — No Competency Permissions | 403 Forbidden on all CRUD endpoints | — | — | ⬜ |
| TC-N22 | Guest Access Redirect | Redirected to /login for all competency routes | — | — | ⬜ |
| TC-N23 | XSS Injection In Name | Stored as literal string; Blade `{{ }}` escapes output; no script execution | — | — | ⬜ |
| TC-N24 | Whitespace-Only Code/Name | Required validation catches empty/whitespace-only strings | — | — | ⬜ |
| TC-N25 | Restore Non-Deleted Competency | `onlyTrashed()->find()` returns null → 404 | — | — | ⬜ |
| TC-N26 | Force Delete Non-Trashed Competency | `onlyTrashed()->find()` returns null → 404 | — | — | ⬜ |
| TC-N27 | Invalid `is_active` Value (Non-Boolean) | Validation fails: "Status is required." or boolean cast | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create Root → Level Auto-0, Path Auto-/ | `level` = 0, `path` = `/` | — | — | ⬜ |
| TC-D02 | A | Create Child → Level = Parent+1, Path Contains Parent | `level` = 1, `path` = `/parentId/` | — | — | ⬜ |
| TC-D03 | B | Drag-Drop Parent Change → Level + Path Recalculated | New parent_id, level, path all updated | — | — | ⬜ |
| TC-D04 | C | Soft Delete Competency → Children Cascade | All children soft-deleted via `deleting` event | — | — | ⬜ |
| TC-D05 | C | Soft Delete Competency → TopicCompetency Cascade | Junction records soft-deleted | — | — | ⬜ |
| TC-D06 | D | Restore Competency → Children Remain Deleted | restore() does NOT cascade to children | — | — | ⬜ |
| TC-D07 | E | Class Deletion Cascades To Competencies (CASCADE) | Deleting class deletes all its competencies | — | — | ⬜ |
| TC-D08 | E | Subject Deletion Cascades To Competencies (CASCADE) | Deleting subject deletes all its competencies | — | — | ⬜ |
| TC-D09 | F | Global Competency Visible Across All Scopes | Competency with null class/subject appears in all filters | — | — | ⬜ |
| TC-D10 | F | Scoped Competency Only Visible For Its Class | Competency with class_id set filtered for that class only | — | — | ⬜ |
| TC-D11 | G | Same Ordinal Allowed Under Different Parents | Two competencies under different parents share ordinal | — | — | ⬜ |
| TC-D12 | G | Concurrent Update — Two Users Edit Same Competency | Last save wins; no data corruption | — | — | ⬜ |
| TC-D13 | H | Activity Log — All Events Tracked | Stored, Updated, Trashed, Restored, Deleted events logged | — | — | ⬜ |
| TC-D14 | I | Self-Referencing FK CASCADE — Parent Competency Deletion | Deleting a parent competency (slb_competencies.id) cascades to delete all child competencies where parent_id = deleted id | — | — | ⬜ |
| TC-D15 | J | Binary(16) UUID Format Validation — uuid Column | uuid stores 16-byte binary; auto-generated via Str::uuid()->getBytes(); unique constraint uq_competency_uuid enforced at DB level | — | — | ⬜ |
| TC-D16 | K | ENUM Field Validation — domain | Invalid values for domain (not COGNITIVE/AFFECTIVE/PSYCHOMOTOR) are rejected by validation | — | — | ⬜ |
| TC-D17 | L | FK CASCADE — competency_type_id Deletion | Deleting a competency type (slb_competency_types.id) cascades to delete all competencies referencing that type | — | — | ⬜ |
| TC-D18 | M | Multi-FK Dependency — Competency References 4 Tables | Competency enforces all 4 FKs: parent_id (self CASCADE), class_id (CASCADE), subject_id (CASCADE), competency_type_id (CASCADE); deleting any parent record cascades appropriately | — | — | ⬜ |
| TC-D19 | N | Model Mass Assignment — fillable attributes are properly guarded; non-fillable attributes (e.g. id, uuid, created_at) are silently ignored | Mass assignment via `create()` or `fill()` only sets fillable columns (`name`, `code`, `class_id`, `subject_id`, `competency_type_id`, `parent_id`, `description`, `is_active`); non-fillable attributes ignored | — | — | ⬜ |
| TC-D20 | O | SoftDeletes Trait — active records have `deleted_at=NULL`; `onlyTrashed()` scope correctly filters trashed records | `SELECT * FROM slb_competencies WHERE deleted_at IS NULL` returns only active competencies; `onlyTrashed()` scope returns only soft-deleted records | — | — | ⬜ |
| TC-D21 | P | belongsTo `competencyType` Relationship — calling `->competencyType` returns the related `slb_competency_types` record | `$competency->competencyType->id` matches `competency_type_id`; eager loading via `->with('competencyType')` prevents N+1 queries | — | — | ⬜ |
| TC-D22 | Q | belongsTo `parent` Self-Reference Relationship — `->parent` returns the parent competency or `null` for root nodes | Root competency returns `null`; child competency returns correct parent competency model; nested eager loading works through `->with('parent')` | — | — | ⬜ |
| TC-D23 | R | hasMany `children` Relationship — `->children` returns all direct child competencies ordered by ordinal | `$competency->children->count()` matches number of direct children; `children()` query builder supports further chaining (e.g. `->where('is_active', true)`) | — | — | ⬜ |
| TC-D24 | S | hasMany `topicCompetencies` Relationship — `->topicCompetencies` returns junction records; cascades on soft delete | Junction records in `slb_topic_competencies` soft-deleted when competency is trashed via `deleting` event; `topicCompetencies()` query builder accessible | — | — | ⬜ |
| TC-D25 | T | `$casts is_active` as Boolean — DB stores TINYINT 0/1, model returns `true`/`false`; attribute assignment toggles correctly | `$competency->is_active` returns `bool` type; setting `$competency->is_active = true` stores 1 in DB; setting `false` stores 0 | — | — | ⬜ |
| TC-D26 | U | `findOrFail` in edit/update/show/destroy — non-existent ID returns HTTP 404 `ModelNotFoundException` | All five controller methods (`edit`, `update`, `show`, `destroy`, `restore`) use `findOrFail`; invalid UUID or non-existent ID returns 404 JSON response | — | — | ⬜ |
| TC-D27 | V | `Gate::authorize` Before Controller Actions — each CRUD method gates the appropriate permission string | `index` gates `tenant.competencie.viewAny`; `show`/`edit` gate `tenant.competencie.view`; `store` (create) gates `tenant.competencie.create`; `store` (update) gates `tenant.competencie.update`; `destroy` gates `tenant.competencie.delete`; missing permission → 403 Forbidden | — | — | ⬜ |
| TC-D28 | W | `activityLog` After CRUD Operations — Stored, Updated, Trashed, Restored, Deleted events logged with correct description and causer | `activity_log` table contains entries with `causer_id`=authenticated user ID, `description` matching event type, `subject_type`=`Modules\Syllabus\Models\Competencie`, `subject_id` matching the competency | — | — | ⬜ |
| TC-D29 | X | Controller Sets `is_active=false` Before Soft Delete — controller flips `is_active` to 0 before setting `deleted_at` | After delete request, `SELECT is_active FROM slb_competencies WHERE id={id}` returns 0; `deleted_at` is also set; competency visually disabled before removal | — | — | ⬜ |
| TC-D30 | Y | CompetencyRequest Unique Code Validation on Update — unique rule ignores the current record's own ID | `unique:slb_competencies,code,{ignore_id},id,class_id,{class_id},subject_id,{subject_id}` — same code on a different record within same scope is rejected; own code preserved on update | — | — | ⬜ |
| TC-D31 | Z | Required Fields Validation — `name` and `competency_type_id` must be present; missing returns HTTP 500 | Validation errors: "The name field is required." / "Competency type is required."; all other fields remain independently validatable | — | — | ⬜ |
| TC-D32 | AA | Nullable Fields — `description` and `parent_id` accept `null` and are stored as NULL in the database | `description=null` stored as DB NULL; `parent_id=null` stored as DB NULL (root competency); empty string for `description` stored as NULL or empty string per mutator | — | — | ⬜ |
| TC-D33 | AB | Max Length Enforcement — `name` max 100, `code` max 20, `description` max 255; exceeding returns HTTP 500 | String exceeding max length for each field rejected with validation error; boundary values at exactly max length accepted; error messages reference field-specific max | — | — | ⬜ |
| TC-D34 | AC | Empty string parent_id converted to null in prepareForValidation() | Submitting parent_id as "" (empty string) is converted to NULL before validation; stored as NULL in DB | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.competencies.create'), @can('tenant.competencies.edit'), @can('tenant.competencies.delete'), @can('tenant.competencies.status'), @can('tenant.competencies.view'), @canany(['tenant.competencies.restore', 'tenant.competencies.forceDelete']) for access control on all CRUD buttons and actions | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | `syllabus.master` key → `'syllabus/master'` defined in `config/breadcrumb.php`; breadcrumb visible and links correctly to parent screen | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — DB Transactions in updateHierarchy | updateHierarchy() uses DB::transaction() to wrap all tree reordering operations; if any write fails, entire hierarchy change is rolled back | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks for Relationship Variables | Relationship expressions in Blade use isset($var->relation) / optional($var?->relation) / null-safe operator; no undefined index/property errors when relation is null | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — JSON Success Response After Create/Update/Delete | All CRUD actions return response()->json() with success: true/false and message; client-side JS handles display of success/error feedback to user | — | — | ◌ |


---



## 7. Detailed Test Steps



#### TC-CR04: Controller — DB Transactions in updateHierarchy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open CompetencieController.php | Controller class found in Modules/Syllabus/Http/Controllers/ |
| 2 | Inspect updateHierarchy() method | All tree reordering operations wrapped in DB::transaction() |
| 3 | Simulate DB failure during hierarchy update | Entire hierarchy change is rolled back; no partial writes occur |
| 4 | Verify no other CRUD methods have DB::transaction | Only updateHierarchy() uses transactions; store/update/destroy do not |


#### TC-CR05: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open index.blade.php for this screen | View file found in lesson-management/partials/
| 2 | Scan for relationship access patterns (e.g. $record->relation->field) | All such expressions use isset() or optional() or ?-> null-safe operator
| 3 | Scan for foreach loops over relationships | Loop target checked with isset() or !empty() before iterating
| 4 | Create a record with null relationship | View renders without undefined index/property error
| 5 | Load index page with records that have missing relations | No 500 errors; null values displayed gracefully (dash or empty string)


#### TC-CR06: Controller — JSON Success Response After Create/Update/Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new record | POST to store(); controller returns response()->json() |
| 2 | Verify JSON response after create | Response contains success: true and message: 'Competency created successfully' |
| 3 | Update the record | PUT/PATCH to update(); JSON response with success flag |
| 4 | Verify JSON response after update | success: true with update confirmation message |
| 5 | Delete the record | DELETE to destroy(); JSON response |
| 6 | Verify JSON response after delete | success: true with deletion confirmation message |
| 7 | Trigger validation error | JSON response with success: false and error message; 422 status |


#### TC-CR01: Blade @can Directives — Permission-based Visibility for All Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php for add/create button | @can('tenant.competencies.create') wraps the Add New button; user without create permission does not see it
| 2 | Inspect row-level action buttons (view, edit, delete, status toggle) | @can('tenant.competencies.view'), @can('tenant.competencies.edit'), @can('tenant.competencies.delete'), @can('tenant.competencies.status') used appropriately; expired permissions hide corresponding buttons
| 3 | Inspect trash.blade.php for restore/forceDelete buttons | @canany(['tenant.competencies.restore', 'tenant.competencies.forceDelete']) wraps action buttons in trash view
| 4 | Inspect view.blade.php for edit button | @can('tenant.competencies.edit') wraps the Edit button on show/details page
| 5 | Log in as user with all permissions | All buttons visible and functional |
| 6 | Log in as user with viewAny only (no create/edit/delete) | Add New button hidden; action columns show view icon only or no actions |

#### TC-CR02: Breadcrumb Config — Route Registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File contains routing configuration for the syllabus module |
| 2 | Verify the 'syllabus.master' key exists | Config has 'syllabus.master' => 'syllabus/master' entry
| 3 | Verify its value points to the correct parent screen URL | Value 'syllabus/master' correctly references Master tab view
| 4 | Load the screen via the Master tab tab | Breadcrumb trail shows correct hierarchy and highlights current screen |
| 5 | Click the breadcrumb parent link | Navigates correctly to Master tab page without errors |
### 6.1 Positive TC Steps

#### TC-P01: Competencies Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Expand "Syllabus" from left sidebar | Menu options appear |
| 3 | Click "Syllabus Master" and select "Competencies" tab | Page loads with `tab=competencies` |
| 4 | Check the class filter dropdown | Dropdown with list of active classes present |
| 5 | Check the subject filter dropdown | Dropdown with list of active subjects present |
| 6 | Check the domain filter (Cognitive/Affective/Psychomotor) | Filter dropdown present |
| 7 | Check the search input | Search text field with placeholder present |
| 8 | Check the "Add Competency" button | Button visible (if create permission) |
| 9 | Check the tree view container | Container ready to render hierarchical competency tree |

---

#### TC-P02: Filter Competencies By Class + Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 competencies for Class A/Subject X, 1 for Class B/Subject Y | Competencies exist |
| 2 | Select Class A | Page reloads, tree shows only Class A competencies |
| 3 | Also select Subject X | Only Class A + Subject X competencies visible |
| 4 | Clear both filters | All competencies visible again |

---

#### TC-P03: Filter By Domain

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competencies: "Critical Thinking" (COGNITIVE), "Teamwork" (AFFECTIVE), "Motor Skills" (PSYCHOMOTOR) | 3 competencies exist |
| 2 | Select "COGNITIVE" from domain filter | Only "Critical Thinking" visible |
| 3 | Select "AFFECTIVE" | Only "Teamwork" visible |
| 4 | Select "PSYCHOMOTOR" | Only "Motor Skills" visible |
| 5 | Select "All" | All 3 competencies visible |

---

#### TC-P04: Search Competencies By Name Or Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competencies: code="CRIT_THINK", code="ANALYZE", code="CREATE" | 3 competencies exist |
| 2 | Type "CRIT" in search box | Only "Critical Thinking" shown (matched by code) |
| 3 | Clear search, type "Think" | Only "Critical Thinking" shown (matched by name) |

---

#### TC-P05: Create Root Competency With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Syllabus Master → Competencies tab | Page loads |
| 2 | Click "Add Competency" button | Competency form opens |
| 3 | Select class from dropdown | Class selected |
| 4 | Select subject from dropdown | Subject selected |
| 5 | Leave parent field empty (root) | Parent null |
| 6 | Enter code: "CRIT_THINK_01" | Code field filled |
| 7 | Enter name: "Critical Thinking" | Name filled |
| 8 | Select competency type from dropdown | Type selected |
| 9 | Select domain: "COGNITIVE" | Domain selected |
| 10 | Set is_active = ON | Active |
| 11 | Click "Save" | AJAX POST to `/syllabus/competency/store` |
| 12 | Check response | Success |
| 13 | DB check: `SELECT * FROM slb_competencies WHERE code='CRIT_THINK_01'` | Record exists; `level`=0; `path`=`/`; `parent_id`=NULL |

---

#### TC-P06: Create Root With Auto-Computed Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create root competency | Competency created |
| 2 | Verify `level` = 0 | Root level |
| 3 | Verify `path` = `/` | Root path |
| 4 | Verify `uuid` is BINARY(16) | Auto-generated |
| 5 | Verify code saved as entered | Code stored |

---

#### TC-P07: Create Child Competency Under Root

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create root competency "Critical Thinking" (ID=P1) | Root exists |
| 2 | Add child: select parent = "Critical Thinking" | Parent set |
| 3 | Enter code: "ANALYZE_01", name: "Analyzing Arguments" | Fields filled |
| 4 | Click "Save" | Created |
| 5 | DB check: `SELECT * FROM slb_competencies WHERE code='ANALYZE_01'` | `parent_id`=P1; `level`=1; `path`=`/P1/` |

---

#### TC-P08: Create Child Competency 2 Levels Deep

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Root "Critical Thinking" → Child "Analyzing" → Grandchild "Identifying Bias" | 3-level hierarchy |
| 2 | DB check grandchild | `parent_id` = child ID; `level` = 2; `path` = `/rootId/childId/` |

---

#### TC-P09: Create Competency With All Optional Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Competency form | Form visible |
| 2 | Fill required fields: class, subject, code="FULL_01", name="Full Competency", type, domain | Required set |
| 3 | Enter short_name="Full Comp" | Optional field filled |
| 4 | Enter description="A comprehensive description" | Description filled |
| 5 | Enter nep_framework_ref="NEP-2020-3.5" | Field filled |
| 6 | Enter ncf_alignment="NCF-SE-2023-4.2" | Field filled |
| 7 | Enter learning_outcome_code="LO-SCI-9-01" | Field filled |
| 8 | Click "Save" | Created |
| 9 | DB check: All optional fields saved | Values match |

---

#### TC-P10: Create Competency With Each Cognitive Domain

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency with domain = COGNITIVE | Saved: domain = 'COGNITIVE' |
| 2 | Create competency with domain = AFFECTIVE | Saved: domain = 'AFFECTIVE' |
| 3 | Create competency with domain = PSYCHOMOTOR | Saved: domain = 'PSYCHOMOTOR' |

---

#### TC-P11: Create Global Competency (No Class/Subject Scope)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Competency form | Form visible |
| 2 | Leave class_id and subject_id empty | Scope = global |
| 3 | Fill all other required fields | Valid data |
| 4 | Click "Save" | Created |
| 5 | Verify competency appears in all class+subject filter combinations | Global visibility |

---

#### TC-P12: Create Competency With Specific Competency Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency type "Analytical Skills" (ID=T1) | Type exists |
| 2 | Create competency with competency_type_id = T1 | Created |
| 3 | DB check: `SELECT competency_type_id FROM slb_competencies WHERE id={id}` | = T1 |

---

#### TC-P13: Edit Competency Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency: code="EDIT_01", name="Edit Test" | Competency exists |
| 2 | Click "Edit" button | Edit form loads |
| 3 | Verify code, name, domain, type pre-filled | All fields match |
| 4 | Verify parent options exclude self and descendants | Correct filter |

---

#### TC-P14: Update Competency Name, Code, Domain

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency: name="Old Name", code="OLD01", domain=COGNITIVE | Exists |
| 2 | Edit: name="New Name", code="NEW01", domain=AFFECTIVE | Fields updated |
| 3 | Click "Save" | Update succeeds |
| 4 | DB check: All fields updated | Values changed |

---

#### TC-P15: Update Competency — Change Parent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create root A → child B, and root C | Hierarchy: A/B, C |
| 2 | Edit B, change parent from A to C | Parent changed |
| 3 | DB check: `SELECT parent_id, level, path FROM slb_competencies WHERE id={B_id}` | parent_id=C.id; level=1; path=`/C_id/` |

---

#### TC-P16: View Competency Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency with all fields filled | Exists |
| 2 | Click "View" button | Detail page loads |
| 3 | Check all fields displayed | Code, name, domain, type, class, subject, NEP ref, NCF, learning outcome, description, path, status |

---

#### TC-P17: Drag-Drop Reparenting (Hierarchy Update)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create root A with child B, and root C | Competencies exist |
| 2 | Drag B from under A to under C | AJAX POST to `/syllabus/competency/update-hierarchy` |
| 3 | Check response | JSON success |
| 4 | DB check: `SELECT parent_id, level, path FROM slb_competencies WHERE id={B_id}` | parent_id=C.id; level=1; path=`/C_id/` |

---

#### TC-P18: Drag-Drop Make Root Competency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create root A with child B | B exists under A |
| 2 | Drag B to root level (no parent) | update-hierarchy processes |
| 3 | DB check: parent_id=NULL, level=0, path=`/` | Made root |

---

#### TC-P19: Soft Delete Competency (No Children)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency with no children: code="DEL_01" | Exists |
| 2 | Click delete button | SweetAlert "Are you sure?" |
| 3 | Confirm delete | Soft deleted |
| 4 | DB check: `SELECT deleted_at FROM slb_competencies WHERE code='DEL_01'` | `deleted_at` NOT NULL |
| 5 | Verify competency removed from tree | Not visible |

---

#### TC-P20: Trash Page Shows Deleted Competencies

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a competency | Competency trashed |
| 2 | Click "Trash" button | Navigates to trash view |
| 3 | Check table shows deleted competency | Record visible |
| 4 | Check "Restore" and "Force Delete" buttons | Both present |

---

#### TC-P21: Restore Competency From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash page, click "Restore" on a trashed competency | Restore succeeds |
| 2 | DB check: `deleted_at` = NULL | Restored |
| 3 | Navigate back to main list | Competency visible again |
| 4 | Activity log: "Restored" event logged | Event exists |

---

#### TC-P22: Force Delete Competency (Permanent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete a competency, then navigate to trash | Competency in trash |
| 2 | Click "Force Delete" | Confirmation dialog |
| 3 | Confirm | Record permanently removed |
| 4 | DB check: Record gone | Force deleted |
| 5 | Activity log: "Deleted" event logged | Event exists |

---

#### TC-P23: Toggle Status Active ↔ Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency with is_active=ON | Active |
| 2 | Click toggle switch | AJAX POST to toggle-status |
| 3 | DB check: is_active=0 | Toggled inactive |
| 4 | Click toggle again | is_active=1 |

---

#### TC-P24: Get Parent Competencies AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create root competencies | Root set exists |
| 2 | Call GET `/syllabus/competency/parents?level=1` | JSON of level-0 competencies for dropdown |
| 3 | Verify correct data returned | id, code, name present |

---

#### TC-P25: Get Competency Tree AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create hierarchy: root A → child B → grandchild C | Tree exists |
| 2 | Call GET `/syllabus/competency/tree` | Nested JSON structure |
| 3 | Verify A contains B, B contains C | Correct nesting |

---

#### TC-P26: Get By Filter AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competencies for Class 1 and Class 2 | Both scopes |
| 2 | Call GET `/syllabus/competency/by-filter?class_id=1` | Only Class 1 competencies returned |
| 3 | Add subject_id filter | Further narrowed |

---

#### TC-P27: Full Lifecycle: Create → Edit → Add Child → Toggle → Delete → Trash → Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create root competency "Scientific Thinking" | Created |
| 2 | Edit: change name to "Scientific Inquiry" | Updated |
| 3 | Add child "Hypothesis Testing" | Child created, level=1 |
| 4 | Toggle root inactive then active | Both toggles succeed |
| 5 | Soft delete root | deleted_at set |
| 6 | Navigate to trash, restore root | Restored |
| 7 | Verify activity logs for Stored, Updated, Restored | All logged |

---

#### TC-P28: Empty State — No Competencies For Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class+subject with zero competencies | No data |
| 2 | Verify tree area | Shows "No competencies found" message |
| 3 | Verify Add Competency button | Visible and enabled |

---

### 6.2 Negative TC Steps

#### TC-N01: Required — Missing `class_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Competency form | Form visible |
| 2 | Leave class_id empty | Empty |
| 3 | Fill all other required fields | Valid data |
| 4 | Click "Save" | HTTP 500: "Class is required." |

---

#### TC-N02: Required — Missing `subject_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Competency form, leave subject_id empty | Subject empty |
| 2 | Click "Save" | HTTP 500: "Subject is required." |

---

#### TC-N03: Required — Missing `code`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Competency form, leave code empty | Code empty |
| 2 | Click "Save" | HTTP 500: "The code field is required." |

---

#### TC-N04: Required — Missing `name`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Competency form, leave name empty | Name empty |
| 2 | Click "Save" | HTTP 500: "Competency name is required." |

---

#### TC-N05: Required — Missing `competency_type_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Competency form, leave type empty | Type empty |
| 2 | Click "Save" | HTTP 500: "Competency type is required." |

---

#### TC-N06: Required — Missing `domain`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Competency form, leave domain empty | Domain empty |
| 2 | Click "Save" | HTTP 500: "The domain field is required." |

---

#### TC-N07: Duplicate Code Within Same Class+Subject Scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency with code="DUP_01" for class=C1, subject=S1 | Exists |
| 2 | Create another competency with code="DUP_01" for same C1, S1 | HTTP 500 |
| 3 | Error: "This competency code already exists for the selected class and subject." | Unique scoped |

---

#### TC-N08: Same Code Allowed For Different Class+Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency code="SAME_01" for C1+S1 | Exists |
| 2 | Create competency code="SAME_01" for C2+S2 | Created (different scope) |
| 3 | DB check: Both records exist | No conflict |

---

#### TC-N09: Max Length — Code > 50 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code of 51 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500: "The code must not be greater than 50 characters." |

---

#### TC-N10: Max Length — Name > 255 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter name of 256 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500: "The name must not be greater than 255 characters." |

---

#### TC-N11: Max Length — Short Name > 50 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter short_name of 51 characters | Exceeds max |
| 2 | Click "Save" | HTTP 500: "The short name must not be greater than 50 characters." |

---

#### TC-N12: Max Length — NEP Alignment > 100 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter nep_alignment of 101 characters | Exceeds max |
| 2 | Click "Save" | "NEP alignment must not exceed 100 characters." |

---

#### TC-N13: Invalid Domain Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter domain="INVALID_DOMAIN" | Not in allowed list |
| 2 | Click "Save" | HTTP 500: "The selected domain is invalid." |

---

#### TC-N14: Invalid FK — Non-Existent `class_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set class_id=99999 | Invalid |
| 2 | Click "Save" | "Selected class is invalid." |

---

#### TC-N15: Invalid FK — Non-Existent `competency_type_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set competency_type_id=99999 | Invalid |
| 2 | Click "Save" | "The selected competency type id is invalid." |

---

#### TC-N16: Self-Parent Assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency "Test" with ID=X | Exists |
| 2 | Edit competency, set parent_id = X (own ID) | Self-parent |
| 3 | Click "Save" | 500: "A competency cannot be its own parent." |

---

#### TC-N17: Circular Parent-Child Relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create root A → child B | Hierarchy: A/B |
| 2 | Edit A, set parent_id = B | Circular: B's child tries to be B's parent |
| 3 | Click "Save" | 500: "Invalid parent-child relationship." |

---

#### TC-N18: Delete Competency With Children

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create root A with child B | Has children |
| 2 | Attempt to delete A | Controller checks `children()->exists()` |
| 3 | Error: "Cannot delete competency because it has child competencies." | 500 |
| 4 | DB check: A still exists | Not deleted |

---

#### TC-N19: View Competency With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open URL: `/syllabus/competency/99999` | HTTP 404 |

---

#### TC-N20: Edit/Update Competency With Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open URL: `/syllabus/competency/99999/edit` | HTTP 404 |

---

#### TC-N21: Permission 403 — No Competency Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without any `tenant.competencies.*` permissions | 403 on all endpoints |

---

#### TC-N22: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate to competencies tab | Redirected to login |

---

#### TC-N23: XSS Injection In Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency with XSS payload in name | Stored as-is |
| 2 | View on list | Blade escapes — no script execution |

---

#### TC-N24: Whitespace-Only Code/Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter name="   " (spaces only) | Required validation catches |

---

#### TC-N25: Restore Non-Deleted Competency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Try to restore an active (non-deleted) competency | 404: `onlyTrashed()` returns null |

---

#### TC-N26: Force Delete Non-Trashed Competency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Try to force delete an active competency | 404: `onlyTrashed()` returns null |

---

#### TC-N27: Invalid `is_active` Value (Non-Boolean)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter is_active = "not-a-boolean" | Validation fails or cast to boolean |

---

### 6.3 Dependency TC Steps

#### TC-D01: Create Root → Level Auto-0, Path Auto-/

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create root competency | Created |
| 2 | DB check: `level` = 0 | Root level |
| 3 | DB check: `path` = `/` | Root path |

---

#### TC-D02: Create Child → Level = Parent+1, Path Contains Parent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create root (id=P1) level=0 | Root |
| 2 | Create child under P1 | Child created with id=C1 |
| 3 | DB check: `SELECT level, path FROM slb_competencies WHERE id=C1` | level=1, path=`/P1/` |

---

#### TC-D03: Drag-Drop Parent Change → Level + Path Recalculated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Root A → Child B, Root C | Hierarchy |
| 2 | Drag B to under C | Reparenting |
| 3 | DB check B: parent_id=C.id, level=1, path=`/C_id/` | Updated |

---

#### TC-D04: Soft Delete Competency → Children Cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create root A with child B | Hierarchy |
| 2 | Soft delete A | `deleting` event fires |
| 3 | DB check: `SELECT deleted_at FROM slb_competencies WHERE id={A_id}` | `deleted_at` NOT NULL |
| 4 | DB check: B also has `deleted_at` set | Cascade successful |

---

#### TC-D05: Soft Delete Competency → TopicCompetency Cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency mapped to a topic | Junction record exists |
| 2 | Soft delete competency | `deleting` event fires |
| 3 | DB check: Junction record soft-deleted | TopicCompetency cascade |

---

#### TC-D06: Restore Competency → Children Remain Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Root A + child B, both soft-deleted | Both in trash |
| 2 | Restore A | A restored |
| 3 | DB check: B still has `deleted_at` set | No cascading restore |

---

#### TC-D07: Class Deletion Cascades To Competencies (CASCADE)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create class with competencies | Competencies reference class |
| 2 | Delete class | DDL CASCADE deletes competencies |
| 3 | DB check: No competencies for that class | Cascaded |

---

#### TC-D08: Subject Deletion Cascades To Competencies (CASCADE)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create subject with competencies | Competencies reference subject |
| 2 | Delete subject | DDL CASCADE deletes competencies |
| 3 | DB check: No competencies for that subject | Cascaded |

---

#### TC-D09: Global Competency Visible Across All Scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create global competency (class_id=null, subject_id=null) | Global |
| 2 | Filter by Class A, Subject X | Global competency appears |
| 3 | Filter by Class B, Subject Y | Global competency still appears |

---

#### TC-D10: Scoped Competency Only Visible For Its Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency for Class 10 only | Scoped to Class 10 |
| 2 | Filter by Class 10 | Competency visible |
| 3 | Filter by Class 9 | Competency NOT visible |

---

#### TC-D11: Same Ordinal Allowed Under Different Parents

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create ordinal=1 under parent A | Exists |
| 2 | Create ordinal=1 under parent B | Created (different parent) |
| 3 | DB check: Both ordinals = 1 | No conflict |

---

#### TC-D12: Concurrent Update — Two Users Edit Same Competency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A and B edit same competency | Both load same data |
| 2 | User A saves name="Version A" | Succeeds |
| 3 | User B saves name="Version B" | Succeeds (last save wins) |
| 4 | DB check: name = "Version B" | No corruption |

---

#### TC-D13: Activity Log — All Events Tracked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create, update, soft delete, restore, force delete a competency | Activity log entries for Stored, Updated, Trashed, Restored, Deleted |
| 2 | Verify each event has correct description and causer | All present |

---

#### TC-D14: Self-Referencing FK CASCADE — Parent Competency Deletion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create parent competency P with id=X | Parent exists |
| 2 | Create child competency C with parent_id=X | Child exists referencing parent |
| 3 | DB check: `SELECT parent_id FROM slb_competencies WHERE id=C_id` | parent_id = X |
| 4 | Delete parent competency P (force delete via destroy endpoint) | Parent deleted |
| 5 | DB check: `SELECT id FROM slb_competencies WHERE id=C_id` | Record gone — child cascaded |
| 6 | Verify: child no longer exists in DB | CASCADE worked at DB level |

---

#### TC-D15: Binary(16) UUID Format Validation — uuid Column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new competency | Competency created successfully |
| 2 | DB check: `SELECT LENGTH(uuid) FROM slb_competencies WHERE id={new_id}` | Length = 16 bytes (BINARY(16)) |
| 3 | DB check: `SELECT HEX(uuid) FROM slb_competencies WHERE id={new_id}` | Valid 32-char hex string |
| 4 | Verify uuid is unique across all `slb_competencies` records | No duplicate uuid exists |
| 5 | Attempt to insert a duplicate uuid directly via DB raw query | DB constraint violation (`uq_competency_uuid`) |

---

#### TC-D16: ENUM Field Validation — domain

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Competency form | Form visible |
| 2 | Enter domain = "INVALID_DOMAIN" | Invalid value not in ENUM |
| 3 | Fill all other required fields | Valid data |
| 4 | Click "Save" | HTTP 500: domain validation fails |
| 5 | Try domain = "cognitive" (lowercase) | Case-sensitive — also rejected |
| 6 | Verify only COGNITIVE, AFFECTIVE, PSYCHOMOTOR are accepted | ENUM enforced at validation layer |

---

#### TC-D17: FK CASCADE — competency_type_id Deletion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency type T with id=X in `slb_competency_types` | Type exists |
| 2 | Create competency with competency_type_id=X | Competency references type T |
| 3 | DB check: `SELECT competency_type_id FROM slb_competencies WHERE id={comp_id}` | = X |
| 4 | Delete competency type T (force delete via destroy endpoint) | Type deleted |
| 5 | DB check: `SELECT id FROM slb_competencies WHERE competency_type_id=X` | 0 rows — cascade deleted |
| 6 | Verify: all competencies referencing T are removed | FK CASCADE worked |

---

#### TC-D18: Multi-FK Dependency — Competency References 4 Tables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create parent competency P, class C, subject S, competency type T | All 4 dependencies exist |
| 2 | Create competency with parent_id=P, class_id=C, subject_id=S, competency_type_id=T | Competency created with all 4 FKs |
| 3 | Delete parent P | Competency cascaded (parent_id CASCADE) |
| 4 | Create new competency with all 4 FKs, then delete class C | Competency cascaded (class_id CASCADE) |
| 5 | Create new competency with all 4 FKs, then delete subject S | Competency cascaded (subject_id CASCADE) |
| 6 | Create new competency with all 4 FKs, then delete competency type T | Competency cascaded (competency_type_id CASCADE) |
| 7 | Verify: all 4 FKs enforce ON DELETE CASCADE | All cascading works as expected |

---

#### TC-D19: Model Mass Assignment — Fillable Attributes Guarded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency via `Competencie::create(['name' => 'Test', 'code' => 'MA_01', 'class_id' => 1, 'subject_id' => 1, 'competency_type_id' => 1, 'description' => 'Test', 'is_active' => true])` | Competency created; all fillable attributes saved |
| 2 | Attempt mass assignment of non-fillable attribute: `Competencie::create(['id' => 99999, 'uuid' => 'hacked', 'name' => 'Hack', 'code' => 'MA_02'])` | `id` and `uuid` silently ignored; competency created with auto-generated id and uuid |
| 3 | DB check: `SELECT id, uuid, name FROM slb_competencies WHERE code='MA_02'` | `id` is auto-increment (not 99999); `uuid` is auto-generated binary; `name` = "Hack" |
| 4 | Attempt to `fill()` non-fillable on existing model | Non-fillable attributes ignored; only fillable attributes updated |

---

#### TC-D20: SoftDeletes Trait — deleted_at Null on Active Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active competency `code='SD_01'` | `created_at` set, `deleted_at` = NULL |
| 2 | DB check: `SELECT deleted_at FROM slb_competencies WHERE code='SD_01'` | `deleted_at` IS NULL |
| 3 | Soft delete competency | `deleted_at` set |
| 4 | Use `Competencie::onlyTrashed()->where('code', 'SD_01')->first()` | Record returned |
| 5 | Use `Competencie::where('code', 'SD_01')->first()` | `null` (excluded by default global scope) |
| 6 | Restore competency | `deleted_at` = NULL again |

---

#### TC-D21: belongsTo competencyType Relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency type T with name "Analytical" in `slb_competency_types` | Type exists with id |
| 2 | Create competency C with `competency_type_id` = T's id | Competency references type |
| 3 | Call `$competency = Competencie::with('competencyType')->find(C_id)` then `$competency->competencyType->name` | Returns "Analytical" |
| 4 | Call `$competency->competencyType` without eager loading | Lazy loads; returns same related model |
| 5 | DB query log: Check only 2 queries total (1 for competency, 1 for type) with eager loading | N+1 prevented |

---

#### TC-D22: belongsTo parent Self-Reference Relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create root competency R | `parent_id` = NULL |
| 2 | Create child competency C with `parent_id` = R's id | Child references parent |
| 3 | Call `$child->parent` | Returns root competency R |
| 4 | Call `$root->parent` | Returns `null` |
| 5 | Eager load: `Competencie::with('parent')->find(C_id)` | Parent loaded in same query batch |

---

#### TC-D23: hasMany children Relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create root competency R | Root exists |
| 2 | Create child C1 under R | Direct child created |
| 3 | Create child C2 under R | Second direct child created |
| 4 | Call `$root->children` | Returns collection with C1 and C2 |
| 5 | Call `$root->children()->count()` | Returns 2 |
| 6 | Chain scope: `$root->children()->where('is_active', true)->get()` | Returns only active children |

---

#### TC-D24: hasMany topicCompetencies Relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency C and topic T; create junction record in `slb_topic_competencies` with `competency_id`=C.id, `topic_id`=T.id | Junction record exists |
| 2 | Call `Competencie::with('topicCompetencies')->find(C.id)->topicCompetencies` | Returns collection with junction records |
| 3 | Count: `$competency->topicCompetencies()->count()` | Matches number of linked topics |
| 4 | Soft delete competency C | `deleting` event fires |
| 5 | DB check: `SELECT deleted_at FROM slb_topic_competencies WHERE competency_id=C.id` | `deleted_at` NOT NULL — junction cascaded |

---

#### TC-D25: $casts is_active as Boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency with `is_active = true` | Saved |
| 2 | DB check: `SELECT is_active FROM slb_competencies WHERE id={id}` | Returns 1 (TINYINT) |
| 3 | PHP: `$competency->is_active` | Returns `true` (boolean) |
| 4 | PHP: `var_dump($competency->is_active)` | `bool(true)` |
| 5 | Update: `$competency->is_active = false; $competency->save()` | Saved |
| 6 | DB check: `SELECT is_active FROM slb_competencies WHERE id={id}` | Returns 0 |
| 7 | PHP: `$competency->refresh()->is_active` | Returns `false` (boolean) |

---

#### TC-D26: findOrFail on edit/update/show/destroy Returns 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/syllabus/competency/99999` (non-existent ID) | HTTP 404 `ModelNotFoundException` |
| 2 | Call GET `/syllabus/competency/99999/edit` | HTTP 404 |
| 3 | Call POST `/syllabus/competency/store` with `id=99999` (update on non-existent) | HTTP 404 |
| 4 | Call DELETE `/syllabus/competency/99999/destroy` | HTTP 404 |
| 5 | Call POST `/syllabus/competency/99999/restore` | HTTP 404 |
| 6 | Verify response body contains error message matching ModelNotFoundException | Proper error handling |

---

#### TC-D27: Gate::authorize Before Controller Actions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.competencie.viewAny` permission | Authenticated |
| 2 | Navigate to competency index page | 403 Forbidden |
| 3 | Login as user WITHOUT `tenant.competencie.view` permission | Authenticated |
| 4 | Access competency show or edit endpoint | 403 Forbidden |
| 5 | Login as user WITHOUT `tenant.competencie.create` permission | Authenticated |
| 6 | POST to store endpoint (no id — create mode) | 403 Forbidden |
| 7 | Login as user WITHOUT `tenant.competencie.update` permission | Authenticated |
| 8 | POST to store endpoint (with id — update mode) | 403 Forbidden |
| 9 | Login as user WITHOUT `tenant.competencie.delete` permission | Authenticated |
| 10 | DELETE to destroy endpoint | 403 Forbidden |

---

#### TC-D28: activityLog After CRUD Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency via store endpoint | Activity log: "Stored" event with `subject_type`=`Modules\Syllabus\Models\Competencie`, `causer_id`=current user |
| 2 | Update same competency | Activity log: "Updated" event |
| 3 | Soft delete competency | Activity log: "Trashed" event |
| 4 | Restore from trash | Activity log: "Restored" event |
| 5 | Force delete from trash | Activity log: "Deleted" event |
| 6 | DB check: `SELECT description, causer_id, subject_id FROM activity_log WHERE subject_type LIKE '%Competencie' ORDER BY created_at` | All 5 events present with correct causer and subject |

---

#### TC-D29: Controller Sets is_active=false Before Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active competency with `is_active=1` | Active |
| 2 | Call delete endpoint | Delete processed |
| 3 | DB check: `SELECT is_active, deleted_at FROM slb_competencies WHERE id={id}` | `is_active` = 0; `deleted_at` is set (NOT NULL) |
| 4 | Restore competency | `deleted_at` = NULL |
| 5 | DB check: `SELECT is_active FROM slb_competencies WHERE id={id}` | `is_active` may remain 0 (not auto-restored) |

---

#### TC-D30: CompetencyRequest Unique Code Validation on Update Ignores Own ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency A with `code='UNIQUE_01'` for class=C1, subject=S1 | Exists |
| 2 | Create competency B with `code='UNIQUE_02'` for class=C1, subject=S1 | Exists |
| 3 | Update competency B with `code='UNIQUE_01'` (currently owned by A) | HTTP 500: unique violation |
| 4 | Update competency A with same `code='UNIQUE_01'` (its own code) | 200 OK — ignored own ID |
| 5 | Update competency B with `code='UNIQUE_01'` for class=C2, subject=S2 (different scope) | 200 OK — scope different |

---

#### TC-D31: Required Fields Validation — name, competency_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit store request without `name` | HTTP 500: "The name field is required." |
| 2 | Submit store request without `competency_type_id` | HTTP 500: "Competency type is required." |
| 3 | Submit store request with `name=""` (empty string) | HTTP 500: same required error |
| 4 | Submit store request with `competency_type_id=""` | HTTP 500: same required error |
| 5 | Submit store request with both `name` and `competency_type_id` populated | Validation passes; other fields independently validated |

---

#### TC-D32: Nullable Fields — description, parent_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create competency with `description=null`, `parent_id=null` | Created as root |
| 2 | DB check: `SELECT description, parent_id FROM slb_competencies WHERE id={id}` | Both columns IS NULL |
| 3 | Create child competency with `description` omitted (not sent), `parent_id` set | `description` stored as NULL; `parent_id` set to parent ID |
| 4 | Update competency with `description=""` (empty string) | Stored as empty string or cast to null per mutator; no validation error |
| 5 | Update parent_id to null (make root) | `parent_id` = NULL; `level` = 0; `path` = `/` |

---

#### TC-D33: Max Length Enforcement — name:100, code:20, description:255

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit name with 101 characters | HTTP 500: "The name must not be greater than 100 characters." |
| 2 | Submit code with 21 characters | HTTP 500: "The code must not be greater than 20 characters." |
| 3 | Submit description with 256 characters | HTTP 500: "The description must not be greater than 255 characters." |
| 4 | Submit name with exactly 100 characters | Accepted (boundary) |
| 5 | Submit code with exactly 20 characters | Accepted (boundary) |
| 6 | Submit description with exactly 255 characters | Accepted (boundary) |

---

#### TC-D34: Empty string parent_id converted to null in prepareForValidation()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `CompetencyRequest::prepareForValidation()` method | Contains logic to convert empty string `parent_id` to null: `$this->merge(['parent_id' => $this->parent_id ?: null])` or equivalent |
| 2 | Open Add Competency form, fill all required fields | Valid data entered |
| 3 | Set parent_id field to "" (empty string) in the submitted payload | parent_id sent as empty string |
| 4 | Click "Save" | Store request succeeds (no validation error on parent_id) |
| 5 | DB check: `SELECT parent_id FROM slb_competencies WHERE code={code}` | parent_id = NULL (not empty string) |
| 6 | Create another competency with parent_id explicitly set to a valid existing competency ID | parent_id stored as the integer ID |
| 7 | Verify the model's parent_id attribute returns null (not empty string) when read from DB | `$competency->parent_id` is null, not "" |
