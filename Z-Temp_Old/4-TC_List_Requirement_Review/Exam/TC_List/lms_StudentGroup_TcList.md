# lms_StudentGroup_TcList

## Module: LmsExam → Masters → Student Group

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Masters (Exam Master) |
| Feature | Exam Student Group |
| URL(s) | `GET lms-exam.masters.index?active_tab=exam_student_group` (index), `GET lms-exam.exam-student-group.create` (create), `POST lms-exam.exam-student-group.store` (store), `GET lms-exam.exam-student-group.show/{id}` (show), `GET lms-exam.exam-student-group.edit/{id}` (edit), `PUT lms-exam.exam-student-group.update/{id}` (update), `DELETE lms-exam.exam-student-group.destroy/{id}` (destroy), `GET lms-exam.exam-student-group.trashed` (trash), `POST lms-exam.exam-student-group.restore/{id}` (restore), `DELETE lms-exam.exam-student-group.forceDelete/{id}` (forceDelete), `POST lms-exam.exam-student-group.toggle-status/{id}` (toggleStatus) |
| Controller | `Modules\LmsExam\Http\Controllers\ExamStudentGroupController` |
| Model(s) | `Modules\LmsExam\Models\ExamStudentGroup` |
| Validation (Create) | `Modules\LmsExam\Http\Requests\ExamStudentGroupRequest` |
| Validation (Update) | `Modules\LmsExam\Http\Requests\ExamStudentGroupRequest` |
| Permissions | `tenant.exam-student-group.viewAny`, `tenant.exam-student-group.view`, `tenant.exam-student-group.create`, `tenant.exam-student-group.update`, `tenant.exam-student-group.delete`, `tenant.exam-student-group.restore`, `tenant.exam-student-group.forceDelete`, `tenant.exam-student-group.status`, `tenant.exam-student-group.import`, `tenant.exam-student-group.export`, `tenant.exam-student-group.print` |
| Soft Deletes | Yes (`ExamStudentGroup` uses `SoftDeletes` trait; destroy() sets is_active=false before delete()) |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |
| Auto Code | `generateCode()` method: `GRP_{CLASS_CODE}_{SECTION_CODE}_{RANDOM4}` with dedup suffix |

---

## 2. Pre-conditions

- Required permissions: `tenant.exam-student-group.viewAny`, `tenant.exam-student-group.view`, `tenant.exam-student-group.create`, `tenant.exam-student-group.update`, `tenant.exam-student-group.delete`, `tenant.exam-student-group.restore`, `tenant.exam-student-group.forceDelete`, `tenant.exam-student-group.status`
- Required seed data: At least one active `SchoolClass` and one active `Section` for group creation
- At least one active `ExamStudentGroup` record for list/show/edit
- Test user must have all above permissions (default admin user)
- Tenant context via `tenancy()->initialize()`
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For usage-block tests: At least one `ExamAllocation` record referencing the group via `exam_group_id`
- Database tables: `lms_exam_student_groups`, `sch_classes`, `sch_sections`, `lms_exam_allocations`

---

## 3. Default Data Load

When the page loads via Masters tab `?active_tab=exam_student_group`, index() fetches:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Student Groups Grid | queryBuilder() | ExamStudentGroup::with(['class','section'])->latest() | search(code,name,description,class name); class_id filter; section_id filter; is_active filter | 10/page |
| Shared: Classes | index() | SchoolClass::where('is_active',1)->get() | is_active=1 | None |
| Shared: Sections | index() | Section::where('is_active',1)->get() | is_active=1 | None |

---

## 4. Test Data Strategy

- **Unique suffix**: Use `now()->format('His') . random_int(100, 999)` for unique code/name
- **Code uniqueness**: Composite UNIQUE KEY on `(class_id, section_id, code)` at DB level
- **Auto code generation**: `generateCode()` uses `GRP_{CLASS_CODE}_{SECTION_CODE}_{RANDOM4}` pattern; appends `_N` suffix if collision
- **Pre-test cleanup**: Delete created groups by unique code suffix
- **Usage check**: `ExamStudentGroupUsageCheckService` checks `ExamAllocation::where('exam_group_id', $id)->count()`
- **Boolean casting**: `is_active` stored as TINYINT(1), cast to boolean
- **Relationships**: `class()` belongsTo SchoolClass, `section()` belongsTo Section, `allocations()` hasMany ExamAllocation

---

## 5. Business Conditions

### 4.1 Database Schema — `lms_exam_student_groups`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | class_id | INT UNSIGNED | NOT NULL, FK → `sch_classes.id` ON DELETE CASCADE |
| BC-DB-03 | section_id | INT UNSIGNED | NOT NULL, FK → `sch_sections.id` ON DELETE CASCADE |
| BC-DB-04 | code | VARCHAR(50) | NOT NULL, UNIQUE (composite: class_id, section_id, code) |
| BC-DB-05 | name | VARCHAR(100) | NOT NULL |
| BC-DB-06 | description | VARCHAR(255) | DEFAULT NULL |
| BC-DB-07 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-08 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-09 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-10 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules — `ExamStudentGroupRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | class_id | required, exists:sch_classes,id | "Class is required" |
| BC-VAL-02 | section_id | required, exists:sch_sections,id | "Section is required" |
| BC-VAL-03 | code | required, string, max:100 | "Group code is required" / "This group code already exists for this class, and section" |
| BC-VAL-04 | name | required, string, max:100 | "Group name is required" |
| BC-VAL-05 | description | nullable, string, max:255 | — |
| BC-VAL-06 | is_active | boolean | — |
| BC-VAL-07 | is_active (prepare) | merged via `$this->boolean('is_active')` | — |

### 4.3 Validation Rules — `ExamStudentGroupRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | class_id | required, exists:sch_classes,id | "Class is required" |
| BC-VAL-U02 | section_id | required, exists:sch_sections,id | "Section is required" |
| BC-VAL-U03 | code | required, string, max:100; if empty, auto-generated | "Group code is required" |
| BC-VAL-U04 | name | required, string, max:100 | "Group name is required" |
| BC-VAL-U05 | description | nullable, string, max:255 | — |
| BC-VAL-U06 | is_active | boolean | — |

### 4.4 Authorization

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.exam-student-group.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.exam-student-group.create | create(), store() | Without → 403 |
| BC-AUTH-03 | tenant.exam-student-group.view | show() | Without → 403 |
| BC-AUTH-04 | tenant.exam-student-group.update | edit(), update(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.exam-student-group.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.exam-student-group.restore | trashed(), restore() | Without → 403 |
| BC-AUTH-07 | tenant.exam-student-group.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.exam-student-group.status | Status switch toggle | Without → toggle hidden |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create student group | $groupData validated; ExamStudentGroup::create(); activityLog('Stored') |
| BC-BIZ-02 | Update student group | Blocked if usageCheck->isUsed(); auto-generate code if empty; getChanges() tracked; activityLog('Updated') |
| BC-BIZ-03 | Delete (soft) | Blocked if isUsed(); set is_active=false; save; delete(); activityLog('Trashed') |
| BC-BIZ-04 | Restore | Blocked if isUsed(); model->restore(); set is_active=true; activityLog('Restored') |
| BC-BIZ-05 | Force delete | Blocked if isUsed(); model->forceDelete(); activityLog('Deleted') |
| BC-BIZ-06 | Toggle status | AJAX; validates is_active required+boolean; transaction; JSON response; activityLog('Toggled') |
| BC-BIZ-07 | Auto-generate code on update | If $groupData['code'] is empty, calls ExamStudentGroup::generateCode(class_id, section_id) |
| BC-BIZ-08 | Index query builder | Filters: class_id, section_id, is_active; search on code/name/description/class name via orWhereHas |
| BC-BIZ-09 | Show page with usage | Uses ExamStudentGroupUsageCheckService; passes isUsed, usageDetails, groupMembers (limit 20) |
| BC-BIZ-10 | Show page loads members | ExamStudentGroupMember::with('student.user','student.currentAcademicSession.classSection.class')->where('group_id',$id)->limit(20) |
| BC-BIZ-11 | Create with classes/sections | create() loads classes and sections for dropdown |
| BC-BIZ-12 | Edit with classes/sections | edit() loads classes and sections for dropdown |
| BC-BIZ-13 | Trash view | ExamStudentGroup::onlyTrashed()->with(['class','section'])->paginate(10) |
| BC-BIZ-14 | Transaction rollback | All write operations wrapped in DB::beginTransaction/commit/rollback |
| BC-BIZ-15 | Unique composite key | (class_id, section_id, code) unique enforced at DB and validation level |
| BC-BIZ-16 | Cascade on class/section delete | DDL FK CASCADE; deleting class/section cascades to groups |
| BC-BIZ-17 | Generate code on demand | generateCode() uses SchoolClass/Section lookups; Str::random(4); dedup loop |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | class_id | sch_classes (id) | CASCADE |
| BC-REF-02 | section_id | sch_sections (id) | CASCADE |
| BC-REF-03 | exam_group_id (lms_exam_allocations) | lms_exam_student_groups (id) | SET NULL? (no explicit DDL found; likely RESTRICT) |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Student Groups Tab Loads With All UI Elements | Tab loads with search, class/section/is_active filters, table with Code/Name/Class-Section/Description/Active/Action | — | — | ⬜ |
| TC-P02 | Search Groups By Code | Table filters by group code | — | — | ⬜ |
| TC-P03 | Search Groups By Name | Table filters by group name | — | — | ⬜ |
| TC-P04 | Search Groups By Class Name | Table filters by class name via orWhereHas | — | — | ⬜ |
| TC-P05 | Filter Groups By Class | Selecting class shows only groups for that class | — | — | ⬜ |
| TC-P06 | Filter Groups By Section | Selecting section shows only groups for that section | — | — | ⬜ |
| TC-P07 | Filter Groups By Active Status | Active/Inactive filter works | — | — | ⬜ |
| TC-P08 | Create Student Group With Code, Class, Section | Group created with code, class_id, section_id, name, is_active=true | — | — | ⬜ |
| TC-P09 | Create Student Group With Description | Group created with description saved | — | — | ⬜ |
| TC-P10 | Create Student Group With Inactive Status | is_active=false when toggle off | — | — | ⬜ |
| TC-P11 | Edit Group Loads Pre-Filled Data | Edit form shows existing class, section, code, name, description, is_active | — | — | ⬜ |
| TC-P12 | Update Group Code And Name | Code and name updated | — | — | ⬜ |
| TC-P13 | Update Group Class/Section | class_id and section_id changed | — | — | ⬜ |
| TC-P14 | Update Group With Auto-Generated Code | If code left empty, auto-generated via generateCode() | — | — | ⬜ |
| TC-P15 | View Group Details Page | Detail page shows code, name, class-section badges, description, is_active, timestamps | — | — | ⬜ |
| TC-P16 | View Group With Usage Details | Show page displays warning if group is allocated to exams | — | — | ⬜ |
| TC-P17 | View Group With Members | Show page lists up to 20 group members with student name/class | — | — | ⬜ |
| TC-P18 | Toggle Group Status (Active to Inactive) | AJAX toggle; JSON success | — | — | ⬜ |
| TC-P19 | Toggle Group Status (Inactive to Active) | AJAX toggle back | — | — | ⬜ |
| TC-P20 | Soft Delete Group (Not Used) | Moved to trash; is_active=false | — | — | ⬜ |
| TC-P21 | View Trashed Groups | Trash page lists deleted groups with class/section | — | — | ⬜ |
| TC-P22 | Restore Soft-Deleted Group | Restored; is_active=true | — | — | ⬜ |
| TC-P23 | Force Delete Group | Permanently removed | — | — | ⬜ |
| TC-P24 | Full Lifecycle: Create → View → Toggle → Edit → Delete → Restore → Force Delete | All transitions succeed | — | — | ⬜ |
| TC-P25 | Empty State — No Groups | Table shows "No student groups found" | — | — | ⬜ |
| TC-P26 | Auto-Generate Unique Code | generateCode() returns unique GRP pattern; dedup suffix if needed | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `class_id` | "Class is required" | — | — | ⬜ |
| TC-N02 | Required — Missing `section_id` | "Section is required" | — | — | ⬜ |
| TC-N03 | Required — Missing `code` | "Group code is required" | — | — | ⬜ |
| TC-N04 | Required — Missing `name` | "Group name is required" | — | — | ⬜ |
| TC-N05 | Invalid FK — Non-Existent `class_id` | "The selected class id is invalid." | — | — | ⬜ |
| TC-N06 | Invalid FK — Non-Existent `section_id` | "The selected section id is invalid." | — | — | ⬜ |
| TC-N07 | Max Length — Code > 100 | Validation fails on code.max | — | — | ⬜ |
| TC-N08 | Max Length — Name > 100 | Validation fails on name.max | — | — | ⬜ |
| TC-N09 | Max Length — Description > 255 | Validation fails on description.max | — | — | ⬜ |
| TC-N10 | Edit Blocked When Group Is Allocated | "Cannot edit this group because it is allocated to exams." | — | — | ⬜ |
| TC-N11 | Update Blocked When Group Is Allocated | Same error message | — | — | ⬜ |
| TC-N12 | Delete Blocked When Group Is Allocated | "Cannot delete this group because it is allocated to exams." | — | — | ⬜ |
| TC-N13 | Restore Blocked When Group Is Allocated | "Cannot restore this group because it is allocated to exams." | — | — | ⬜ |
| TC-N14 | Force Delete Blocked When Group Is Allocated | "Cannot permanently delete this group because it is allocated to exams." | — | — | ⬜ |
| TC-N15 | View/Edit/Delete With Invalid ID (404) | 404 on all | — | — | ⬜ |
| TC-N16 | Toggle Without is_active | Validation error | — | — | ⬜ |
| TC-N17 | Toggle With Non-Boolean is_active | Validation error | — | — | ⬜ |
| TC-N18 | Permission 403 — No Group Permissions | 403 on all endpoints | — | — | ⬜ |
| TC-N19 | Guest Access Redirect | Redirect to /login | — | — | ⬜ |
| TC-N20 | XSS In Code/Name/Description | Blade escapes output | — | — | ⬜ |
| TC-N21 | Whitespace-Only Code | Required validation catches | — | — | ⬜ |
| TC-N22 | Duplicate (class_id, section_id, code) At DB Level | Integrity constraint violation | — | — | ⬜ |
| TC-N23 | Restore Non-Trashed | 404 from onlyTrashed() | — | — | ⬜ |
| TC-N24 | Toggle With Invalid ID | JSON 500 | — | — | ⬜ |
| TC-N25 | DB Error — Transaction Rollback | Rollback, no partial record | — | — | ⬜ |
| TC-N26 | Invalid Boolean For is_active | Validation error | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create Group → Activity Logged 'Stored' | activity_logs has entry | — | — | ⬜ |
| TC-D02 | B | Update Group → Changes Tracked | Activity log has changes JSON | — | — | ⬜ |
| TC-D03 | C | Soft Delete → Is_Active False Before Delete | DB: is_active=0, deleted_at NOT NULL | — | — | ⬜ |
| TC-D04 | D | Restore → Is_Active True | DB: is_active=1, deleted_at=NULL | — | — | ⬜ |
| TC-D05 | E | Usage Check Blocks All Protected Operations | edit/update/destroy/restore/forceDelete all blocked | — | — | ⬜ |
| TC-D06 | F | Show Page Loads Members (limit 20) | $groupMembers collection has max 20 records | — | — | ⬜ |
| TC-D07 | G | Code Auto-Generation Uses Proper Pattern | GRP_{CLASS_CODE}_{SECTION_CODE}_{RANDOM4} | — | — | ⬜ |
| TC-D08 | H | Index Query Builder — All Filters | class_id, section_id, is_active, search all work | — | — | ⬜ |
| TC-D09 | I | ExamStudentGroupPolicy — All Gates | 11 gates defined | — | — | ⬜ |
| TC-D10 | J | ExamStudentGroupRequest — authorize() per HTTP | POST→create, PUT→update, DELETE→delete, GET→view | — | — | ⬜ |
| TC-D11 | K | SoftDeletes Trait | onlyTrashed/withTrashed work | — | — | ⬜ |
| TC-D12 | L | Model $casts Boolean | is_active accessed as boolean | — | — | ⬜ |
| TC-D13 | M | Model — class() and section() BelongsTo | $group->class returns SchoolClass; $group->section returns Section | — | — | ⬜ |
| TC-D14 | N | Model — allocations() HasMany | $group->allocations returns ExamAllocation records | — | — | ⬜ |
| TC-D15 | O | Model — scopeActive, scopeByClass, scopeBySection | Scopes filter correctly | — | — | ⬜ |
| TC-D16 | P | Controller — findOrFail Valid/Invalid IDs | Valid: model; Invalid: 404 | — | — | ⬜ |
| TC-D17 | Q | Controller — Gate::authorize Before All Actions | Every method calls Gate::authorize | — | — | ⬜ |
| TC-D18 | R | Controller — activityLog After CRUD | Each write logs | — | — | ⬜ |
| TC-D19 | S | Controller — DB Transactions | All writes wrapped | — | — | ⬜ |
| TC-D20 | T | Routes — Resourceful + Custom | All routes map correctly | — | — | ⬜ |
| TC-D21 | U | Blade @can Directives — Permission Visibility | Status toggle, action buttons wrapped | — | — | ⬜ |
| TC-D22 | V | View — isset()/null-safe Checks | ?? and ?-> used throughout | — | — | ⬜ |
| TC-D23 | W | View — Class and Section Badges | Badge bg-info for class, bg-secondary for section | — | — | ⬜ |
| TC-D24 | X | Controller — Redirect/JSON After CRUD | Redirect with flash or JSON | — | — | ⬜ |
| TC-D25 | Y | Composite Unique Key (class_id, section_id, code) | DB constraint prevents duplicate combo | — | — | ⬜ |
| TC-D26 | Z | CASCADE — Deleting Class Cascades to Groups | DDL fk_esg_class has CASCADE | — | — | ⬜ |
| TC-D27 | AA | CASCADE — Deleting Section Cascades to Groups | DDL fk_esg_section has CASCADE | — | — | ⬜ |
| TC-D28 | AB | generateCode Dedup Logic | Collision generates _1, _2 suffix | — | — | ⬜ |
| TC-D29 | AC | Update With Empty Code Triggers Auto-Generate | update() calls generateCode if code empty | — | — | ⬜ |
| TC-D30 | AD | ToggleStatus Returns 500 On Exception | Catch returns JSON error 500 | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission-based visibility | @canany status/action, @canany restore/forceDelete in trash | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config | Routes registered in breadcrumb config | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — DB Transactions in All Write Operations | All use DB::beginTransaction/commit/rollback | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks | ?? and ?-> operators used; no undefined errors | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — Response After CRUD | Redirect with flash or JSON | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Usage Check Service Used In Protected Methods | edit/update/destroy/restore/forceDelete all use service | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | Code Auto-Generation On Update | update() checks empty code and calls generateCode() | — | — | ◌ |

---

## 7. Detailed Test Steps

### 6.1 Positive TC Steps

#### TC-P01: Student Groups Tab Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Expand "Exam" → "Masters" → "Student Groups" tab | Page loads with `active_tab=exam_student_group` |
| 3 | Check search input | Placeholder "Search group code, name..." |
| 4 | Check class filter dropdown | "All Classes" plus list of classes |
| 5 | Check section filter dropdown | "All Sections" plus list of sections |
| 6 | Check is_active filter | All Status, Active, Inactive |
| 7 | Check table headers | Group Code, Group Name, Class-Section, Description, Active, Action |

---

#### TC-P02 to TC-P04: Search By Code/Name/Class Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create groups with code="GRP-A", name="Group Alpha", class="Class 9" | Records exist |
| 2 | Search "GRP-A" | Only GRP-A shown |
| 3 | Search "Alpha" | Group Alpha shown |
| 4 | Search "Class 9" | Groups from Class 9 shown (via orWhereHas) |

---

#### TC-P05 to TC-P07: Filter By Class/Section/Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create groups in Class 9 Section A and Class 10 Section B | Mixed records |
| 2 | Select class_id=9 | Only Class 9 groups shown |
| 3 | Select section_id=5 (Section B) | Only Section B groups shown |
| 4 | Filter is_active=1 | Only active shown |

---

#### TC-P08: Create Student Group With All Required

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Student Groups tab | Page loads |
| 2 | Click "Add Student Group" | Create form opens |
| 3 | Select class from dropdown | Class selected |
| 4 | Select section from dropdown | Section selected |
| 5 | Enter code: "GRP_9A_ADV" | Code filled |
| 6 | Enter name: "Class 9 Advanced Math" | Name filled |
| 7 | is_active checked | Switch ON |
| 8 | Click "Create Student Group" | POST to store |
| 9 | Redirect with success | Flash: "Student group created successfully" |
| 10 | DB check: code, class_id, section_id, name | Record exists |

---

#### TC-P09: Create With Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all fields plus description="Advanced math students" | Description saved |

---

#### TC-P10: Create With Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with is_active unchecked | is_active=0 |

---

#### TC-P11: Edit Group Loads Pre-Filled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create group | Record exists |
| 2 | Click "Edit" | Form pre-filled with class, section, code, name, description, is_active |

---

#### TC-P12: Update Code And Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit group, change code and name | Updated |
| 2 | DB check | New values saved |

---

#### TC-P13: Update Class/Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit group, change class_id and section_id | Updated |
| 2 | DB check | New FK values |

---

#### TC-P14: Update With Auto-Generated Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit group, clear code field | Code becomes empty in request |
| 2 | update() calls generateCode() | Auto-generated code saved |
| 3 | DB check | code is non-empty, follows GRP pattern |

---

#### TC-P15: View Group Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "View" on group row | Detail page loads |
| 2 | Check code, name | Displayed |
| 3 | Check class-section badges | Badges shown |
| 4 | Check description, status | Shown |
| 5 | Check timestamps | Created, updated |

---

#### TC-P16: View With Usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation referencing group | isUsed=true |
| 2 | Navigate to show page | Warning alert with usage details |

---

#### TC-P17: View With Members

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add members to group | Members exist |
| 2 | Navigate to show page | Members list displayed (max 20) |
| 3 | Check member info | Student name, class shown |

---

#### TC-P18 to TC-P19: Toggle Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle ON→OFF | JSON {success:true, is_active:false} |
| 2 | Toggle OFF→ON | JSON {success:true, is_active:true} |

---

#### TC-P20: Soft Delete (Not Used)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete unused group | Redirect with success |
| 2 | DB: is_active=0, deleted_at NOT NULL | Soft deleted |

---

#### TC-P21: View Trashed Groups

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash | /exam-student-group/trashed |
| 2 | Check table | Shows deleted records with class/section |

---

#### TC-P22: Restore Group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore from trash | is_active=1, deleted_at=NULL |

---

#### TC-P23: Force Delete Group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force delete | Permanently removed |

---

#### TC-P24: Full Lifecycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create → View → Toggle inactive → Toggle active → Edit → Delete → Restore → Force Delete | All succeed |

---

#### TC-P25: Empty State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No records | "No student groups found" |

---

#### TC-P26: Auto-Generate Unique Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call ExamStudentGroup::generateCode($classId, $sectionId) | Returns format GRP_CLS_SEC_RAND |
| 2 | Call with class code "9" and section code "A" | Returns "GRP_9_A_XXXX" |
| 3 | Generate code that collides | Appends _1, _2 suffix |

---

### 6.2 Negative TC Steps

#### TC-N01 to TC-N04: Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit without class_id | "Class is required" |
| 2 | Submit without section_id | "Section is required" |
| 3 | Submit without code | "Group code is required" |
| 4 | Submit without name | "Group name is required" |

---

#### TC-N05 to TC-N06: Invalid FKs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with class_id=99999 | "The selected class id is invalid." |
| 2 | Submit with section_id=99999 | "The selected section id is invalid." |

---

#### TC-N07 to TC-N09: Max Length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | code > 100 chars | Validation fails |
| 2 | name > 100 chars | Validation fails |
| 3 | description > 255 chars | Validation fails |

---

#### TC-N10 to TC-N14: Usage Check Blocks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation referencing group | isUsed=true |
| 2 | Edit | "Cannot edit this group because it is allocated to exams." |
| 3 | Update | Same error |
| 4 | Delete | "Cannot delete this group because it is allocated to exams." |
| 5 | Restore | "Cannot restore this group because it is allocated to exams." |
| 6 | Force delete | "Cannot permanently delete this group because it is allocated to exams." |

---

#### TC-N15: Invalid ID 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access any action with ID=99999 | HTTP 404 |

---

#### TC-N16 to TC-N17: Toggle Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST toggle without is_active | "The is active field is required" |
| 2 | POST toggle with non-boolean | "must be true or false" |

---

#### TC-N18: Permission 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without permissions | 403 on all endpoints |

---

#### TC-N19: Guest Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, access any route | Redirect to /login |

---

#### TC-N20: XSS

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Store <script> in code/name | Blade escapes |

---

#### TC-N21: Whitespace Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit code as whitespace | Required validation catches |

---

#### TC-N22: DB-Level Duplicate Composite Key

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | INSERT duplicate (class_id, section_id, code) | Integrity constraint violation |

---

#### TC-N23: Restore Non-Trashed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore active record | 404 |

---

#### TC-N24: Toggle Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle with ID=99999 | JSON 500 |

---

#### TC-N25: DB Error Rollback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force DB failure | Transaction rolled back |

---

#### TC-N26: Invalid Boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit is_active="invalid" | Validation error |

---

### 6.3 Dependency TC Steps

#### TC-D01: Create → Activity Logged

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create group | 'Stored' event logged |

---

#### TC-D02: Update → Changes Tracked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update name | 'Updated' event with JSON diff |

---

#### TC-D03: Soft Delete → Is_Active False

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete | is_active=0, deleted_at set |

---

#### TC-D04: Restore → Is_Active True

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore | is_active=1, deleted_at NULL |

---

#### TC-D05: Usage Check Protects

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Allocated group | edit/update/destroy/restore/forceDelete blocked |

---

#### TC-D06: Show Loads Members (limit 20)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 25 members for group | show() loads max 20 |
| 2 | Check $groupMembers count | ≤ 20 |

---

#### TC-D07: Code Auto-Generation Pattern

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | generateCode(9A class, A section) | Returns GRP_9A_A_XXXX |

---

#### TC-D08: All Index Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply each filter | Query modified correctly |

---

#### TC-D09: ExamStudentGroupPolicy Gates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open policy file | 11 gates: viewAny..print |

---

#### TC-D10: Request authorize() Per Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST → create gate | allowIf create |
| 2 | PUT → update gate | allowIf update |
| 3 | DELETE → delete gate | allowIf delete |

---

#### TC-D11 to TC-D15: Model Features

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | SoftDeletes trait | onlyTrashed/withTrashed work |
| 2 | $casts boolean | is_active accessed as bool |
| 3 | class() relation | Returns SchoolClass |
| 4 | section() relation | Returns Section |
| 5 | allocations() | Returns ExamAllocation |
| 6 | scopeActive | where is_active=1 |

---

#### TC-D16 to TC-D19: Controller Patterns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | findOrFail valid | Model loaded |
| 2 | findOrFail invalid | 404 |
| 3 | Gate::authorize | Before each action |
| 4 | activityLog | After each write |
| 5 | DB::transaction | Wraps all writes |

---

#### TC-D20: Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check route:list | All present |

---

#### TC-D21: Blade @can

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Index status column | @canany(['tenant.exam-student-group.status']) |
| 2 | Index action column | @canany(['view','update','delete']) |

---

#### TC-D22: View Null-safe

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check view files | ?? and ?-> used |

---

#### TC-D23: Class/Section Badges

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Render group row | bg-info for class, bg-secondary for section |

---

#### TC-D24: Response Types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | CRUD ops | Redirect with flash |
| 2 | Toggle | JSON |

---

#### TC-D25: Composite Unique

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | INSERT duplicate combo | Constraint violation |

---

#### TC-D26 to TC-D27: Cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete class with groups | Groups cascade deleted |
| 2 | Delete section with groups | Groups cascade deleted |

---

#### TC-D28: generateCode Dedup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create code collision | While loop appends _1, _2 until unique |

---

#### TC-D29: Update Auto-Generate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update with empty code | generateCode() called; code saved |

---

#### TC-D30: Toggle Exception

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force exception | 500 JSON error |

---

### 6.4 Code Review TC Steps

#### TC-CR01: Blade @can Directives

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php | @canany status/action present |
| 2 | Inspect trash.blade.php | @canany restore/forceDelete present |
| 3 | User with all permissions | All buttons visible |
| 4 | User with viewAny only | No action buttons |

#### TC-CR02: Breadcrumb

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check breadcrumb config | Routes registered |

#### TC-CR04: DB Transactions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect all write methods | DB::beginTransaction/commit/rollback |

#### TC-CR05: Null-safe View

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Scan view files | ?? and ?-> operators |

#### TC-CR06: Response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create/update/delete/restore/forceDelete | Redirect with flash |
| 2 | Toggle | JSON |

#### TC-CR07: Usage Check Service

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect edit/update/destroy/restore/forceDelete | All use ExamStudentGroupUsageCheckService |

#### TC-CR08: Code Auto-Generation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect update() | If empty($groupData['code']), calls generateCode() |
| 2 | Verify generateCode() | Uses class/section lookups; random 4 chars; dedup while loop |

### Additional Detailed Integration Test Steps

#### INT-TC01: Create Group With Auto-Generated Code Flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamStudentGroupController update() method | Controller found at Modules/LmsExam/Http/Controllers/ |
| 2 | Locate code generation logic | if (empty($groupData['code'])) block triggers ExamStudentGroup::generateCode() |
| 3 | Call generateCode with class_id=1, section_id=1 | Returns string starting with "GRP_" |
| 4 | Call generateCode with same params again | Different random suffix appended; no collision |
| 5 | Verify dedup loop increments _N suffix | If collision found, code becomes GRP_CLS_SEC_RAND_1 |

#### INT-TC02: Show Page Data Loading Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamStudentGroupController show() method | Controller found |
| 2 | Inspect ExamStudentGroup::findOrFail($id) | Model loaded with eager loading |
| 3 | Inspect usage check | ExamStudentGroupUsageCheckService instantiated; isUsed() called |
| 4 | Inspect groupMembers query | ExamStudentGroupMember::with('student.user','student.currentAcademicSession.classSection.class')->where('group_id',$id)->limit(20) |
| 5 | Verify limit(20) | Only first 20 members loaded |
| 6 | Create group with 25 members | show() loads only 20 members |

#### INT-TC03: Index Query Builder Filter Combinations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply class_id=5 and section_id=3 together | WHERE class_id=5 AND section_id=3 |
| 2 | Apply is_active=0 and search="test" | WHERE is_active=0 AND (code LIKE '%test%' OR name LIKE '%test%') |
| 3 | Apply all four filters together | All WHERE conditions combined with AND |
| 4 | No filters applied | query()->latest() with no WHERE |

#### INT-TC04: Toggle Status Complete Cycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create group with is_active=1 | Record exists |
| 2 | POST to toggle-status with is_active=0 | JSON {success:true, is_active:false} |
| 3 | Verify DB is_active=0 | Updated |
| 4 | POST to toggle-status with is_active=1 | JSON {success:true, is_active:true} |
| 5 | Verify DB is_active=1 | Updated |
| 6 | Check activity_logs table | 'Toggled' event logged twice |

#### INT-TC05: Trash View Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete 12 groups | 12 records in trash |
| 2 | Navigate to trashed() | onlyTrashed()->with(['class','section'])->paginate(10) |
| 3 | Check page 1 | 10 groups on page 1 |
| 4 | Check page 2 | 2 groups on page 2 |
| 5 | Verify eager loading | class and section relationships loaded |

#### INT-TC06: Permission Check Order (Gate Before Business Logic)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect edit() | Gate::authorize('tenant.exam-student-group.update') called AFTER findOrFail but usage check is before gate |
| 2 | Inspect update() | Usage check first, then findOrFail, then Gate::authorize |
| 3 | Inspect destroy() | Usage check first, then findOrFail, then Gate::authorize |
| 4 | Verify user without update permission | 403 returned before usage check or DB operations |

#### INT-TC07: Flash Message Translation Keys

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() success | flash('created.exam-student-group') used |
| 2 | Inspect update() success | flash('updated.exam-student-group') used |
| 3 | Inspect destroy() success | flash('trashed.exam-student-group') used |
| 4 | Inspect restore() success | flash('restored.exam-student-group') used |
| 5 | Inspect forceDelete() success | flash('force_deleted.exam-student-group') used |
| 6 | Inspect toggleStatus() success | flash('status_updated.exam-student-group') used |

#### INT-TC08: Data Integrity After Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create group with code="ORIG", name="Original" | Record exists |
| 2 | Update code to "UPDATED", name to "Updated" | Updated |
| 3 | Verify code and name in DB | "UPDATED" and "Updated" |
| 4 | Verify timestamps updated | updated_at reflects current time |
| 5 | Verify other fields unchanged | class_id, section_id same |

#### INT-TC09: Concurrent Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Two users simultaneously edit same group | Last update wins; no data corruption |
| 2 | User A deletes group while User B views | User B sees 404 on refresh |
| 3 | User A restores group while User B views trash | User B sees restored group removed from trash |

#### INT-TC10: Controller Error Handling — All Exceptions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force QueryException in store() | Caught; redirect back with error; rollback |
| 2 | Force ModelNotFoundException in show() | Laravel renders 404 page |
| 3 | Force AuthorizationException in index() | Laravel renders 403 page |
| 4 | Force Throwable in forceDelete() | Caught; redirect back with error; rollback |

#### TC-P27: Create Group And Verify Relationships Load In Index

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create group with class="Class 9" and section="Section A" | Record exists |
| 2 | Load index page | queryBuilder() uses with(['class','section']) |
| 3 | Verify class name shown in table | Class badge shows "Class 9" |
| 4 | Verify section name shown in table | Section badge shows "Section A" |

#### TC-P28: Pagination On Index Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 12+ groups | Multiple records |
| 2 | Load index page | paginate(10) returns page 1 with 10 items |
| 3 | Check pagination links | Links rendered |
| 4 | Click page 2 | Remaining groups displayed |

#### TC-P29: Reset Button Clears All Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply class, section, is_active filters and search | Filtered view |
| 2 | Click reset button | URL resets to base; all filters cleared |
| 3 | All groups displayed | No filters applied |

#### TC-P30: Create Group Without is_active Checkbox

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Do not touch is_active checkbox | Default: checked (true) |
| 3 | Submit form | is_active=1 (default true when checked) |

#### TC-N27: Create Group With Non-Existent Class/Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with class_id=99999 | "The selected class id is invalid." |
| 2 | POST with section_id=99999 | "The selected section id is invalid." |

#### TC-N28: Update Group With Duplicate Code In Same Class+Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Group A exists: (class=1, section=1, code="GRP-A") | Record exists |
| 2 | Group B exists: (class=1, section=1, code="GRP-B") | Record exists |
| 3 | Edit Group B, change code to "GRP-A" | DB composite unique prevents; validation fails |

#### TC-N29: Update Group To Different Class+Section With Existing Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Group A: (class=1, section=1, code="SAME") | Record exists |
| 2 | Group B: (class=2, section=2, code="OTHER") | Record exists |
| 3 | Edit Group B, change to (class=1, section=1) keeping "OTHER" | OK — composite (1,1,"OTHER") is unique |
| 4 | Edit Group B, change to (class=1, section=1, code="SAME") | Conflict with Group A |

#### TC-N30: DB Error During Force Delete — Transaction Rollback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force DB error during forceDelete | Catch block; rollback; error message |
| 2 | Verify record still exists | Not deleted |

#### TC-D31: Cascade — Deleting Class With Groups

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find class that has groups | Groups exist |
| 2 | DELETE from sch_classes WHERE id=X | Groups with class_id=X auto-deleted (CASCADE) |

#### TC-D32: Cascade — Deleting Section With Groups

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find section that has groups | Groups exist |
| 2 | DELETE from sch_sections WHERE id=X | Groups with section_id=X auto-deleted (CASCADE) |

#### TC-D33: Model student() Relationship With ExamStudentGroup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamStudentGroup model | student() belongsTo method exists |
| 2 | Verify relationship | $group->student returns Student model (for member queries) |

#### TC-D34: FormRequest authorize() Returns Boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ExamStudentGroupRequest | authorize() returns Gate::allows() boolean |
| 2 | Test with user having create permission | Returns true |
| 3 | Test with user lacking create permission | Returns false |

#### TC-D35: ToggleStatus AJAX Frontend Integration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Successful toggle | Frontend receives {success:true, is_active:bool, message:string} |
| 2 | Failed toggle (save returns false) | Frontend receives {success:false, message:string} |
| 3 | Exception during toggle | Frontend receives {success:false, message:string} with HTTP 500 |

#### TC-CR09: Controller — All Methods Handle Empty Search Results Gracefully

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index() with no results | view receives empty paginator; "No student groups found" displayed |
| 2 | Inspect trashed() with no results | view receives empty paginator; "No Trashed Exam Types Found" displayed |
| 3 | Verify no 500 errors when collections empty | Empty state messages shown |

#### TC-CR10: Controller — getChanges() Excludes updated_at

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect update() | foreach $changes skips 'updated_at' field |
| 2 | Update group | Activity log shows only relevant changed fields, not updated_at |

#### TC-CR11: View — Description Truncation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php | Str::limit($group->description, 60) used |
| 2 | Create group with long description (>60 chars) | Table shows truncated text with "..." |
| 3 | Show page — no truncation | Full description displayed |

#### TC-CR12: View — Status Badge Color

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect trash.blade.php | Badge bg-success for Active, bg-secondary for Inactive |
| 2 | Verify active group shows green badge | bg-success |
| 3 | Verify inactive group shows grey badge | bg-secondary |