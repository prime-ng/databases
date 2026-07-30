# lms_GroupMember_TcList

## Module: LmsExam → Masters → Group Member

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Masters (Exam Master) |
| Feature | Exam Student Group Member |
| URL(s) | `GET lms-exam.masters.index?active_tab=exam_student_group_member` (index), `GET lms-exam.exam-group-member.create` (create), `POST lms-exam.exam-group-member.store` (store), `GET lms-exam.exam-group-member.show/{id}` (show), `GET lms-exam.exam-group-member.edit/{id}` (edit), `PUT lms-exam.exam-group-member.update/{id}` (update), `DELETE lms-exam.exam-group-member.destroy/{id}` (destroy), `GET lms-exam.exam-group-member.trashed` (trash), `POST lms-exam.exam-group-member.restore/{id}` (restore), `DELETE lms-exam.exam-group-member.forceDelete/{id}` (forceDelete), `POST lms-exam.exam-group-member.toggle-status/{id}` (toggleStatus), `GET lms-exam.exam-group-member.get-group-details` (getGroupDetails AJAX) |
| Controller | `Modules\LmsExam\Http\Controllers\ExamStudentGroupMemberController` |
| Model(s) | `Modules\LmsExam\Models\ExamStudentGroupMember`, `Modules\LmsExam\Models\ExamStudentGroup` |
| Validation (Create) | Inline in store() (no FormRequest for store — uses manual validation), `ExamStudentGroupMemberRequest` for update |
| Validation (Update) | `Modules\LmsExam\Http\Requests\ExamStudentGroupMemberRequest` |
| Permissions | `tenant.exam-group-member.viewAny`, `tenant.exam-group-member.view`, `tenant.exam-group-member.create`, `tenant.exam-group-member.update`, `tenant.exam-group-member.delete`, `tenant.exam-group-member.restore`, `tenant.exam-group-member.forceDelete`, `tenant.exam-group-member.status`, `tenant.exam-group-member.import`, `tenant.exam-group-member.export`, `tenant.exam-group-member.print` |
| Soft Deletes | Yes (`ExamStudentGroupMember` uses `SoftDeletes` trait; destroy() calls delete()) |
| Activity Log | Events: `Created` (per member), `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |

---

## 2. Pre-conditions

- Required permissions: `tenant.exam-group-member.viewAny`, `tenant.exam-group-member.view`, `tenant.exam-group-member.create`, `tenant.exam-group-member.update`, `tenant.exam-group-member.delete`, `tenant.exam-group-member.restore`, `tenant.exam-group-member.forceDelete`, `tenant.exam-group-member.status`
- Required seed data: At least one active `ExamStudentGroup`, at least one active `Student` with `currentClassSection`
- Test user must have all above permissions (default admin user)
- Tenant context via `tenancy()->initialize()`
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For usage-block tests: At least one `ExamAllocation` referencing the member's group
- Database tables: `lms_exam_student_group_members`, `lms_exam_student_groups`, `std_students`

---

## 3. Default Data Load

When the page loads via Masters tab `?active_tab=exam_student_group_member`, index() renders with:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Group Members Grid | queryBuilder() | ExamStudentGroupMember::with(['group', 'student'])->latest() | group_id, student_id, class_id filters; search | 10/page |
| Shared: Groups | MastersController | ExamStudentGroup::where('is_active',1)->get() | is_active=1 | None |
| Shared: Students | index() | Student::with('user')->get() (all for filter dropdown) | — | None |
| Shared: Classes | index() | SchoolClass::where('is_active',1)->get() | is_active=1 | None |

---

## 4. Test Data Strategy

- **Unique pair**: Composite UNIQUE KEY `uq_esgm_member` on `(group_id, student_id)` at DB level
- **Duplicate prevention**: store() checks `ExamStudentGroupMember::where('group_id',$groupId)->where('student_id',$studentId)->exists()` before insert
- **store() uses inline validation**: No FormRequest for bulk store; takes group_id + student_ids array
- **Bulk add**: store() loops over student_ids array, creates each non-duplicate member with individual activity log
- **Pre-test cleanup**: Delete created members before/after tests
- **Usage check**: `ExamStudentGroupMemberUsageCheckService` checks group allocations

---

## 5. Business Conditions

### 4.1 Database Schema — `lms_exam_student_group_members`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | group_id | INT UNSIGNED | NOT NULL, FK → `lms_exam_student_groups.id` ON DELETE CASCADE |
| BC-DB-03 | student_id | INT UNSIGNED | NOT NULL, FK → `std_students.id` |
| BC-DB-04 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-05 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-06 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 4.2 Validation Rules — `store()` (Create / Bulk Inline)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | group_id | required in request | "Group is required" (controller checks) |
| BC-VAL-02 | student_ids | required as array | "Students are required" (controller checks) |
| BC-VAL-03 | student_id (each) | unique within group_id | If exists → skip (not error) |

### 4.3 Validation Rules — `ExamStudentGroupMemberRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | group_id | required, exists:lms_exam_student_groups,id | "Group is required" |
| BC-VAL-U02 | student_id | required, exists:std_students,id, unique scoped (group_id, student_id) ignore own ID | "Student is required" / "This student is already a member of this group" |
| BC-VAL-U03 | student_id unique scoped | Rule::unique('lms_exam_student_group_members','student_id')->where('group_id', $this->group_id)->ignore($memberId) | "This student is already a member of this group" |

### 4.4 Authorization

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.exam-group-member.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.exam-group-member.create | create(), store() | Without → 403 |
| BC-AUTH-03 | tenant.exam-group-member.view | show() | Without → 403 |
| BC-AUTH-04 | tenant.exam-group-member.update | edit(), update(), toggleStatus() | Without → 403 |
| BC-AUTH-05 | tenant.exam-group-member.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.exam-group-member.restore | trashed(), restore() | Without → 403 |
| BC-AUTH-07 | tenant.exam-group-member.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.exam-group-member.status | Status toggle | Without → hidden |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create single member | store() loops student_ids; skips duplicates; creates new; activityLog('Created') per member |
| BC-BIZ-02 | Skip duplicate on bulk add | If member exists for (group_id, student_id), skip without error |
| BC-BIZ-03 | Count returned in response | $count variable tracks how many were actually added |
| BC-BIZ-04 | Update member | Blocked if usageCheck->isUsed(); findOrFail; check duplicate for other members; update; activityLog('Updated') |
| BC-BIZ-05 | Delete (soft) member | Blocked if isUsed(); delete(); activityLog('Trashed') |
| BC-BIZ-06 | Restore member | Blocked if isUsed(); onlyTrashed()->findOrFail(); restore(); activityLog('Restored') |
| BC-BIZ-07 | Force delete member | Blocked if isUsed(); withTrashed()->findOrFail(); forceDelete(); activityLog('Deleted') |
| BC-BIZ-08 | Toggle status | AJAX; validates is_active required+boolean; DB transaction; JSON response |
| BC-BIZ-09 | Create form loads groups | ExamStudentGroup::where('is_active', 1)->get() |
| BC-BIZ-10 | Create form with student filtering | If group_id selected, determine class_id/section_id from group; fetch students via currentClassSection |
| BC-BIZ-11 | Create form marks existing members | $existingMemberIds = ExamStudentGroupMember::where('group_id',$id)->pluck('student_id')->toArray() |
| BC-BIZ-12 | getGroupDetails AJAX | Returns group's class_id, section_id, class list, section list as JSON |
| BC-BIZ-13 | Index dynamic filters | AJAX for student and group dropdowns dependent on class_id selection |
| BC-BIZ-14 | Show page with usage | Uses ExamStudentGroupMemberUsageCheckService; passes isUsed, usageDetails |
| BC-BIZ-15 | Trash view | ExamStudentGroupMember::onlyTrashed()->with(['group','student'])->paginate(10) |
| BC-BIZ-16 | Transaction rollback | All write operations wrapped in DB::beginTransaction/commit/rollback |
| BC-BIZ-17 | Unique composite (group_id, student_id) | UNIQUE KEY uq_esgm_member at DB level |
| BC-BIZ-18 | Cascade on group delete | DDL FK fk_esgm_group has ON DELETE CASCADE |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | group_id | lms_exam_student_groups (id) | CASCADE |
| BC-REF-02 | student_id | std_students (id) | RESTRICT (no ON DELETE CASCADE) |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Group Members Tab Loads With All UI Elements | Tab loads with search, class/student/group filters, table with Group/Student/Class/Added On/Action | — | — | ⬜ |
| TC-P02 | Filter Members By Class | Class filter dynamically loads students and groups | — | — | ⬜ |
| TC-P03 | Filter Members By Student | Filters grid by selected student | — | — | ⬜ |
| TC-P04 | Filter Members By Group | Filters grid by selected group | — | — | ⬜ |
| TC-P05 | Create Form Loads With Group Selection | Create form shows group dropdown; selecting group filters students | — | — | ⬜ |
| TC-P06 | Create Form With Group Selection Filters Students | When group selected, class/section determined from group; only matching students shown | — | — | ⬜ |
| TC-P07 | Create Form Shows Existing Members | Existing member IDs passed to view; marked in UI | — | — | ⬜ |
| TC-P08 | Add Single Student To Group | Member created; activity logged | — | — | ⬜ |
| TC-P09 | Add Multiple Students To Group (Bulk) | Multiple members created; count returned in flash message | — | — | ⬜ |
| TC-P10 | Skip Duplicate On Bulk Add | Existing member skipped; only new members added | — | — | ⬜ |
| TC-P11 | getGroupDetails AJAX Returns Group Info | JSON response with class_id, section_id, classes, sections | — | — | ⬜ |
| TC-P12 | Edit Member Loads Pre-Filled Data | Edit form shows group and student pre-selected | — | — | ⬜ |
| TC-P13 | Update Member Group And Student | Member's group_id and student_id updated | — | — | ⬜ |
| TC-P14 | View Member Details Page | Detail page shows group code/name, student name | — | — | ⬜ |
| TC-P15 | Soft Delete Member | Member moved to trash; activity Trashed | — | — | ⬜ |
| TC-P16 | View Trashed Members | Trash page lists deleted members with group/student | — | — | ⬜ |
| TC-P17 | Restore Soft-Deleted Member | Restored; activity Restored | — | — | ⬜ |
| TC-P18 | Force Delete Member | Permanently removed; activity Deleted | — | — | ⬜ |
| TC-P19 | Full Lifecycle: Create → View → Edit → Delete → Restore → Force Delete | All transitions succeed | — | — | ⬜ |
| TC-P20 | Empty State — No Members | Table shows "No group members found" | — | — | ⬜ |
| TC-P21 | Index Class-Student-Group Dynamic Dropdowns | Change class → AJAX loads students and groups | — | — | ⬜ |
| TC-P22 | Toggle Status (if applicable) | Toggle member status via AJAX | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | store() Without group_id | Logic error — group_id missing | — | — | ⬜ |
| TC-N02 | store() Without student_ids | No members added; count=0 | — | — | ⬜ |
| TC-N03 | store() With Empty student_ids Array | Loop does nothing; 0 members added | — | — | ⬜ |
| TC-N04 | Update With Missing group_id | "Group is required" | — | — | ⬜ |
| TC-N05 | Update With Missing student_id | "Student is required" | — | — | ⬜ |
| TC-N06 | Update With Duplicate (group_id, student_id) | "This student is already a member of this group" | — | — | ⬜ |
| TC-N07 | Update With Invalid group_id | "The selected group id is invalid." | — | — | ⬜ |
| TC-N08 | Update With Invalid student_id | "The selected student id is invalid." | — | — | ⬜ |
| TC-N09 | Edit Blocked When Group Is Allocated | "Cannot edit this member because the group is allocated to exams." | — | — | ⬜ |
| TC-N10 | Update Blocked When Group Is Allocated | Same error | — | — | ⬜ |
| TC-N11 | Delete Blocked When Group Is Allocated | "Cannot delete this member because the group is allocated to exams." | — | — | ⬜ |
| TC-N12 | Restore Blocked When Group Is Allocated | "Cannot restore this member because the group is allocated to exams." | — | — | ⬜ |
| TC-N13 | Force Delete Blocked When Group Is Allocated | "Cannot permanently delete this member because the group is allocated to exams." | — | — | ⬜ |
| TC-N14 | View/Edit/Update/Delete/Restore/ForceDelete With Invalid ID (404) | 404 on all | — | — | ⬜ |
| TC-N15 | Permission 403 — No Group Member Permissions | 403 on all endpoints | — | — | ⬜ |
| TC-N16 | Guest Access Redirect | Redirect to /login | — | — | ⬜ |
| TC-N17 | Duplicate (group_id, student_id) At DB Level | Integrity constraint violation | — | — | ⬜ |
| TC-N18 | DB Error During Bulk Add — Transaction Rollback | Rollback; no partial adds | — | — | ⬜ |
| TC-N19 | Toggle Without is_active | Validation error | — | — | ⬜ |
| TC-N20 | Toggle With Invalid ID | JSON 500 | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Store Members → Activity Logged Per Member | Each created member gets 'Created' activity log entry | — | — | ⬜ |
| TC-D02 | B | Update Member → Activity Logged | 'Updated' event logged | — | — | ⬜ |
| TC-D03 | C | Delete Member → Activity Logged | 'Trashed' event logged | — | — | ⬜ |
| TC-D04 | D | Restore Member → Activity Logged | 'Restored' event logged | — | — | ⬜ |
| TC-D05 | E | Force Delete → Activity Logged | 'Deleted' event logged | — | — | ⬜ |
| TC-D06 | F | Usage Check Blocks edit/update/destroy/restore/forceDelete | All protected | — | — | ⬜ |
| TC-D07 | G | getGroupDetails AJAX → JSON With Group Class/Section | Returns class_id, section_id, classes, sections arrays | — | — | ⬜ |
| TC-D08 | H | Create Form — Existing Member IDs Passed | $existingMemberIds array passed to view; UI disables already-added students | — | — | ⬜ |
| TC-D09 | I | ExamStudentGroupMemberPolicy — All Gates | 11 gates defined | — | — | ⬜ |
| TC-D10 | J | ExamStudentGroupMemberRequest — authorize() per HTTP | POST→create, PUT→update, DELETE→delete, GET→view | — | — | ⬜ |
| TC-D11 | K | SoftDeletes Trait | onlyTrashed/withTrashed work | — | — | ⬜ |
| TC-D12 | L | Model — group() BelongsTo | $member->group returns ExamStudentGroup | — | — | ⬜ |
| TC-D13 | M | Model — student() BelongsTo | $member->student returns Student | — | — | ⬜ |
| TC-D14 | N | Model — scopeByGroup, scopeByStudent | Scopes filter correctly | — | — | ⬜ |
| TC-D15 | O | Controller — findOrFail Valid/Invalid IDs | Valid→model; Invalid→404 | — | — | ⬜ |
| TC-D16 | P | Controller — Gate::authorize Before Actions | All methods call Gate | — | — | ⬜ |
| TC-D17 | Q | Controller — activityLog After CRUD | Each write logs | — | — | ⬜ |
| TC-D18 | R | Controller — DB Transactions | All writes wrapped | — | — | ⬜ |
| TC-D19 | S | Routes — Resourceful + Custom + getGroupDetails | All routes map correctly | — | — | ⬜ |
| TC-D20 | T | Blade @can Directives — Permission Visibility | Action columns wrapped | — | — | ⬜ |
| TC-D21 | U | View — isset()/null-safe Checks | ?? and ?-> used | — | — | ⬜ |
| TC-D22 | V | View — Added On Date Format | d M Y format with h:i A time | — | — | ⬜ |
| TC-D23 | W | Controller — Redirect/JSON After CRUD | Redirect with flash or JSON | — | — | ⬜ |
| TC-D24 | X | Unique Composite (group_id, student_id) At DB | Constraint violation on duplicate | — | — | ⬜ |
| TC-D25 | Y | CASCADE — Deleting Group Cascades To Members | DDL fk_esgm_group has CASCADE | — | — | ⬜ |
| TC-D26 | Z | RESTRICT — Deleting Student With Members | FK fk_esgm_student has no CASCADE; RESTRICT | — | — | ⬜ |
| TC-D27 | AA | Store Count Returned In Flash Message | "$count members added successfully." shown | — | — | ⬜ |
| TC-D28 | AB | Skip Duplicate In store() — No Error, Just Skip | Duplicate not created; no error; count unaffected | — | — | ⬜ |
| TC-D29 | AC | Update Checks Duplicate For Other Members | Controller checks existing (same group+student, different id) → error | — | — | ⬜ |
| TC-D30 | AD | ToggleStatus Returns 500 On Exception | Catch returns JSON 500 | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Blade @can Directives — Permission visibility | @canany action columns, @canany restore/forceDelete in trash | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Breadcrumb Config | Routes registered | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — DB Transactions in All Writes | store/update/destroy/restore/forceDelete/toggleStatus use DB::transaction | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | View — isset()/null-safe Checks | ?? and ?-> used; no undefined property errors | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — Redirect/JSON After CRUD | Redirect with flash or JSON response | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | store() Uses Inline Logic Without FormRequest | store() reads group_id + student_ids directly; no FormRequest for create | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | Activity Log Per Member In Bulk Add | Each member created logs individual 'Created' event inside foreach loop | — | — | ◌ |
| TC-CR09 | CR | Code Review | P1 | Index AJAX Dynamic Dropdowns | class_id change loads students and groups via AJAX | — | — | ◌ |

---

## 7. Detailed Test Steps

### 6.1 Positive TC Steps

#### TC-P01: Group Members Tab Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads |
| 2 | Expand "Exam" → "Masters" → "Group Members" tab | Page loads with `active_tab=exam_student_group_member` |
| 3 | Check search input | Placeholder "Search student, group..." |
| 4 | Check class filter | "All Classes" dropdown |
| 5 | Check student filter | "All Students" dropdown (populated dynamically) |
| 6 | Check group filter | "All Groups" dropdown (populated dynamically) |
| 7 | Check table headers | Group, Student, Class, Added On, Action |
| 8 | Check Add Member button | If create permission |

---

#### TC-P02: Filter Members By Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a class from dropdown | AJAX loads students for that class into student dropdown |
| 2 | AJAX loads groups for that class into group dropdown | Both dropdowns updated |
| 3 | Submit filter | Table shows only members in that class |

---

#### TC-P03 to TC-P04: Filter By Student/Group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a student from dropdown | Table shows only that student's memberships |
| 2 | Select a group from dropdown | Table shows only members of that group |

---

#### TC-P05: Create Form Loads With Group Selection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add Member" | Create form at /exam-group-member/create |
| 2 | Check group dropdown | All active groups listed |
| 3 | Check student listing | Initially empty (no class selected) |

---

#### TC-P06: Create Form With Group Filters Students

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a group that has class_id=9, section_id=5 | Form auto-selects class and section |
| 2 | Check student list | Only students in class 9, section 5 shown |
| 3 | Students paginated (50/page) | Pagination present if many students |

---

#### TC-P07: Create Form Shows Existing Members

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a group with existing members | existingMemberIds array populated |
| 2 | Check UI for already-added students | Students shown as disabled or marked (depends on UI implementation) |

---

#### TC-P08: Add Single Student To Group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a group | Group selected |
| 2 | Select one student from list | student_id selected |
| 3 | Click "Add Members" | POST to store |
| 4 | Redirect with success | Flash: "1 members added successfully." |
| 5 | DB check: ExamStudentGroupMember record | group_id=X, student_id=Y |
| 6 | Check activity log | 'Created' event logged for this member |

---

#### TC-P09: Add Multiple Students (Bulk)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a group | Group selected |
| 2 | Select 3 students from list | 3 student_ids checked |
| 3 | Click "Add Members" | POST with array of 3 IDs |
| 4 | Flash: "3 members added successfully." | 3 records created |
| 5 | DB check: 3 records | All present |

---

#### TC-P10: Skip Duplicate On Bulk Add

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Group already has student A as member | Existing | 
| 2 | Try adding student A again + student B (new) | Student A skipped, Student B added |
| 3 | Flash message | "1 members added successfully." (only new count) |

---

#### TC-P11: getGroupDetails AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to /exam-group-member/get-group-details with group_id=X | JSON response |
| 2 | Check response | {status:"success", classes:[], sections:[], selected_class_id:X, selected_section_id:Y} |

---

#### TC-P12: Edit Member Pre-Filled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a member | Member exists |
| 2 | Click "Edit" (if available) | Edit form pre-filled with group and student |

---

#### TC-P13: Update Member Group/Student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit member, change group or student | Updated |
| 2 | DB check | New group_id/student_id saved |

---

#### TC-P14: View Member Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "View" on member row | Detail page |
| 2 | Check group code/name | Displayed |
| 3 | Check student name | Displayed |

---

#### TC-P15: Soft Delete Member

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete member (not used in allocations) | Redirect with success |
| 2 | DB: deleted_at IS NOT NULL | Soft deleted |
| 3 | Activity: 'Trashed' | Logged |

---

#### TC-P16: View Trashed Members

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash | /exam-group-member/trashed |
| 2 | Check table | Shows deleted members with group/student |

---

#### TC-P17: Restore Member

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore from trash | deleted_at=NULL; activity 'Restored' |

---

#### TC-P18: Force Delete Member

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force delete | Permanently removed; activity 'Deleted' |

---

#### TC-P19: Full Lifecycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create → View → Edit → Delete → Restore → Force Delete | All transitions succeed |

---

#### TC-P20: Empty State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No members | "No group members found" |

---

#### TC-P21: Dynamic Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class from index filter | $.GET to /lms-exam/students with class_id returns JSON |
| 2 | Student dropdown populated | Options appear |
| 3 | Group dropdown also populated | $.GET to /lms-exam/exam-groups with class_id |

---

### 6.2 Negative TC Steps

#### TC-N01: store() Without group_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to store without group_id | foreach over student_ids fails or produces 0 count |
| 2 | Error handling | Exception caught; redirect back with error |

---

#### TC-N02: store() Without student_ids

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST without student_ids | $studentIds is null; foreach fails |
| 2 | Redirect back with error | "Failed to add exam group members" |

---

#### TC-N03: Empty student_ids Array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with student_ids=[] | Loop does nothing; count=0 |
| 2 | Flash: "0 members added successfully." | Zero count message |

---

#### TC-N04 to TC-N05: Update Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT without group_id | "Group is required" |
| 2 | PUT without student_id | "Student is required" |

---

#### TC-N06: Update Duplicate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Member A exists: (group=1, student=1) | Exists |
| 2 | Member B exists: (group=1, student=2) | Exists |
| 3 | Edit Member B, change student to 1 → tries to set (group=1, student=1) | "This student is already a member of this group" |

---

#### TC-N07 to TC-N08: Invalid FKs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT with group_id=99999 | "The selected group id is invalid." |
| 2 | PUT with student_id=99999 | "The selected student id is invalid." |

---

#### TC-N09 to TC-N13: Usage Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation referencing member's group | isUsed=true |
| 2 | Edit/update/destroy/restore/forceDelete | All blocked with same error message |

---

#### TC-N14: Invalid ID 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access any action with ID=99999 | HTTP 404 |

---

#### TC-N15 to TC-N16: Auth

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without permissions | 403 on all endpoints |
| 2 | Guest access | Redirect to /login |

---

#### TC-N17: DB-Level Duplicate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | INSERT duplicate (group_id, student_id) | Integrity constraint violation on uq_esgm_member |

---

#### TC-N18: Transaction Rollback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force DB failure during bulk add | Transaction rolled back; no partial insert |

---

#### TC-N19 to TC-N20: Toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle without is_active | Validation error |
| 2 | Toggle with invalid ID | JSON 500 |

---

### 6.3 Dependency TC Steps

#### TC-D01: Store → Activity Per Member

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add 2 members | 2 'Created' activity log entries |
| 2 | Each entry has message 'Student added to exam group' | Message matches |

---

#### TC-D02 to TC-D05: Activity On All CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update member | 'Updated' logged |
| 2 | Delete member | 'Trashed' logged |
| 3 | Restore member | 'Restored' logged |
| 4 | Force delete | 'Deleted' logged |

---

#### TC-D06: Usage Check Protects

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | edit/update/destroy/restore/forceDelete with allocated group | All blocked |

---

#### TC-D07: getGroupDetails JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request with valid group_id | {status:"success", classes:[], sections:[], selected_class_id, selected_section_id} |
| 2 | Request with invalid group_id | {status:"error", message:"Group not found"} |

---

#### TC-D08: Create Form Passes existingMemberIds

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load create form with group_id | existingMemberIds array populated from ExamStudentGroupMember::pluck('student_id') |

---

#### TC-D09: ExamStudentGroupMemberPolicy — All Gates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open policy file | 11 gates: viewAny..print |

---

#### TC-D10: Request authorize() Per Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST → create gate | allowIf create |
| 2 | PUT → update gate | allowIf update |

---

#### TC-D11: SoftDeletes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | onlyTrashed() | Deleted only |
| 2 | withTrashed() | All records |

---

#### TC-D12 to TC-D14: Model Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $member->group | Returns ExamStudentGroup |
| 2 | $member->student | Returns Student |
| 3 | ExamStudentGroupMember::byGroup($id) | Where group_id=$id |
| 4 | ExamStudentGroupMember::byStudent($id) | Where student_id=$id |

---

#### TC-D15 to TC-D18: Controller Patterns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | findOrFail valid | Model loaded |
| 2 | findOrFail invalid | 404 |
| 3 | Gate::authorize | Before each action |
| 4 | activityLog | After each write |
| 5 | DB::transaction | Wraps writes |

---

#### TC-D19: Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check route:list | All routes present; get-group-details mapped |

---

#### TC-D20: Blade @can

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Index action column | @canany(['view','update','delete']) |

---

#### TC-D21: View Null-safe

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check view files | ?? and ?-> used throughout |

---

#### TC-D22: Added On Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check date format | "d M Y" with "h:i A" below |

---

#### TC-D23: Response Types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | CRUD ops | Redirect with flash |
| 2 | Toggle | JSON |

---

#### TC-D24: Unique Composite At DB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | INSERT duplicate (group_id, student_id) | Constraint violation |

---

#### TC-D25: Cascade On Group Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete group that has members | Members cascade deleted |

---

#### TC-D26: Restrict On Student Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete student that is a member | FK constraint blocks (no CASCADE) |

---

#### TC-D27: Store Count In Flash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add 5 members | Flash: "5 members added successfully." |
| 2 | Verify message translation | flash('created.exam-group-member', "$count members added successfully.") |

---

#### TC-D28: Skip Duplicate In store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Existing member in group | Duplicate found |
| 2 | Try adding same student again | exists() check → skip; no error thrown |

---

#### TC-D29: Update Checks Duplicate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update member to group+student combo that exists on another member | "Student is already a member of this group" |

---

#### TC-D30: Toggle Exception

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force exception during toggle | JSON 500 error with success:false |

---

### 6.4 Code Review TC Steps

#### TC-CR01: Blade @can Directives

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php | @canany action column wraps view/edit/delete |
| 2 | Inspect trash.blade.php | @canany for restore/forceDelete |

#### TC-CR02: Breadcrumb

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check breadcrumb config | Group member routes registered |

#### TC-CR04: DB Transactions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() | DB::beginTransaction; foreach create; commit; catch rollback |
| 2 | Inspect update() | DB::beginTransaction; update; commit; catch rollback |
| 3 | Inspect destroy/restore/forceDelete/toggleStatus | All use transaction pattern |

#### TC-CR05: View Null-safe

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Scan view files | $member->group->code ?? '-', $member->student->full_name ?? '-', $member->created_at->format(...) |

#### TC-CR06: Response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | store() | Redirect with flash |
| 2 | update() | Redirect with flash |
| 3 | destroy/restore/forceDelete | Redirect with flash |
| 4 | toggleStatus | JSON response |

#### TC-CR07: store() Uses Inline Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller store() | No FormRequest used; reads $request->group_id and $request->student_ids directly |
| 2 | Verify authorization | Gate::authorize('tenant.exam-group-member.create') called |
| 3 | Verify skip-duplicate logic | exists() check before create() |

#### TC-CR08: Activity Per Member In Bulk

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller store() | Inside foreach: activityLog($examGroupMember, 'Created', ...) for each member |
| 2 | Verify message | 'Student added to exam group' |

#### TC-CR09: Index AJAX Dynamic Dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open index.blade.php | Script section with loadIndexStudents() and loadIndexGroups() functions |
| 2 | Verify jQuery AJAX calls | $.get to /lms-exam/students and /lms-exam/exam-groups with class_id |
| 3 | Verify change handler | $('#index_class_id').on('change', ...) triggers both load functions |

### Additional Detailed Integration Test Steps

#### INT-TC01: Bulk Add Members With Mixed Valid/Invalid Student IDs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select group with existing members | Group selected |
| 2 | Submit student_ids: [existing_id_1, new_student_id_1, new_student_id_2] | existing_id_1 skipped |
| 3 | Only 2 new members added | Flash: "2 members added successfully." |
| 4 | DB: only 2 new records | Exactly 2 records created |

#### INT-TC02: Bulk Add With No Students Selected (Empty Array)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select group | Group selected |
| 2 | Do not select any students | student_ids = [] or absent |
| 3 | Submit form | Exception caught (cannot iterate null) |
| 4 | Redirect back with error | "Failed to add exam group members. Please try again." |

#### INT-TC03: Create Form — Dynamic Student Loading By Class/Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select a group that has class_id=9, section_id=5 | Form sets selectedClassId=9, selectedSectionId=5 |
| 3 | Student query uses whereHas('currentClassSection') with class_id=9, section_id=5 | Only matching students shown |
| 4 | Students paginated at 50 per page | query->paginate(50) |

#### INT-TC04: Create Form — Group Without Class/Section (All Students)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | If group has no class_id or section_id (null) | selectedClassId/sectionId remain from request or null |
| 2 | No class/section forced | Student query may not filter (all students shown) |

#### INT-TC05: Update Member — Full Update Cycle With Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create member with (group_id=A, student_id=1) | Record exists |
| 2 | Edit: change to (group_id=B, student_id=2) | Updated |
| 3 | DB check: group_id=B, student_id=2 | Updated correctly |
| 4 | Check activity log | 'Updated' event logged |
| 5 | Old member (group=A, student=1) no longer exists | Only new combination exists |

#### INT-TC06: Update Member — Duplicate Check Prevents Conflict

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Member X: (group=1, student=1) id=10 | Record exists |
| 2 | Member Y: (group=1, student=2) id=20 | Record exists |
| 3 | Edit Member Y (id=20), set student_id=1 | Controller checks: existing where(group=1, student=1, id != 20) → finds id=10 |
| 4 | Error: "Student is already a member of this group" | Update blocked |

#### INT-TC07: View Member — With Group Allocated To Exams

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create member, group allocated to exam | isUsed=true |
| 2 | Navigate to show page | Usage details shown (if implemented in view) |
| 3 | Check usage data | $usageDetails passed to view |

#### INT-TC08: Index Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 12+ members | Multiple records |
| 2 | Load index page | paginate(10) returns 10 items |
| 3 | Navigate to page 2 | Remaining items shown |
| 4 | Verify appends on pagination | active_tab param preserved in pagination links |

#### INT-TC09: Index Filter Persistence Across Pages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply group_id filter | Filtered results |
| 2 | Navigate to page 2 | group_id param preserved in URL |
| 3 | Verify table shows filtered results | Still filtered by same group |

#### INT-TC10: Soft Delete — Record Remains In DB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete member | Success |
| 2 | Query lms_exam_student_group_members with trashed | Record found with deleted_at set |
| 3 | Query without trashed | Record not found |

#### TC-P23: Toggle Status (If is_active Column Exists)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggle-status with is_active=0 | JSON {success:true, is_active:false} |
| 2 | Verify DB | is_active=0 |
| 3 | POST back to is_active=1 | JSON {success:true, is_active:true} |

#### TC-P24: Add Members To Group And Verify In Show Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add 3 members to group | Members created |
| 2 | Navigate to group show page | Members displayed (via show() member query) |

#### TC-P25: Member Count Returned In Flash Message

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add 5 members | Flash: "5 members added successfully." |
| 2 | Add 0 members (all duplicates) | Flash: "0 members added successfully." |

#### TC-P26: getGroupDetails — Group Not Found

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to get-group-details with group_id=99999 | JSON {status:"error", message:"Group not found"} |

#### TC-P27: View Member With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET /exam-group-member/99999 | HTTP 404 |
| 2 | Verify | ModelNotFoundException |

#### TC-N21: Create Form With No Groups Available

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no active groups exist | Empty groups table |
| 2 | Load create form | $groups collection empty |
| 3 | Group dropdown shows no options | No groups selectable |

#### TC-N22: Update With Same Values (No Change)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit member, submit same group_id and student_id | Update succeeds |
| 2 | Verify no duplicate error | OK — update with same values allowed |

#### TC-N23: Force Delete Already Deleted Member

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete member (soft) | deleted_at set |
| 2 | Force delete same member | forceDelete succeeds; permanently removed |
| 3 | Try force delete again | 404 — already gone |

#### TC-N24: Restore Already Active Member

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active member (deleted_at=null) | Not trashed |
| 2 | POST restore | 404 — onlyTrashed() cannot find it |

#### TC-N25: Store With Invalid group_id (Non-Existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST store with group_id=99999, student_ids=[1] | No FK validation inline; but member created with invalid FK |
| 2 | DB would succeed if no FK constraint? | Actually group_id FK exists; DB would throw |

#### TC-D31: Model — No is_active Column (Compared To Other Entities)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open lms_exam_student_group_members DDL | No is_active column defined |
| 2 | Check model fillable | No is_active in fillable array |
| 3 | ToggleStatus exists but may not be used | Feature may exist for future; current DDL doesn't have is_active |

#### TC-D32: Show Page — Relationships Eager Loaded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open show() | with(['group.schoolClass', 'student.user']) used |
| 2 | Verify eager loading | N+1 query prevented |

#### TC-D33: Trash Page — Relationships Loaded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect trashed() | onlyTrashed()->with(['group', 'student'])->paginate(10) |
| 2 | Verify eager loading | group and student relationships loaded |

#### TC-D34: Store Method — No FormRequest (Inline)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() | No ExamStudentGroupMemberRequest used |
| 2 | Read group_id directly | $request->group_id |
| 3 | Read student_ids directly | $request->student_ids |
| 4 | No validation before foreach | Relies on Gate::authorize only for incoming validation |

#### TC-D35: Activity Log Per Member In Bulk — Individual Entries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add 3 members | 3 activity_log entries |
| 2 | Each entry: event='Created', message='Student added to exam group' | All have correct format |
| 3 | Each entry has different model reference | Different member IDs referenced |

#### TC-CR10: Controller — store() Loop Safety

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open store() method | foreach ($studentIds as $studentId) wraps each member creation |
| 2 | Verify skip logic | if (!$exists) { create; activityLog; $count++ } |
| 3 | Verify count returned | flash message uses $count variable |
| 4 | Verify transaction | All creates inside single DB::transaction |

#### TC-CR11: Blade — Action Column Hides Show/Edit For Members

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php | x-backend.table.action with :show="false" :edit="false" |
| 2 | Verify only delete action shown | Show and edit actions hidden |
| 3 | Check reasoning | Members are typically managed via bulk add, not individual edit |

#### TC-CR12: JavaScript — Dynamic Dropdown Load Functions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect index.blade.php script | loadIndexStudents() and loadIndexGroups() defined |
| 2 | Verify AJAX endpoints | /lms-exam/students and /lms-exam/exam-groups |
| 3 | Verify pre-selected values on load | If class_id in URL, initial load triggers both functions |
| 4 | Verify student text format | value.name + (value.code ? ' (' + value.code + ')' : '') |