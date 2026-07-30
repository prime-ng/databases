# lms_QuestAllocation_TcList

## Module: LmsQuests → Quest Management → Quest Allocation

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuests |
| Tab Group | Quest Management |
| Feature | Quest Allocation |
| URL(s) | `/lms-quests/quest-allocation` (resource index/create/store/show/edit/update/destroy), `/lms-quests/quest-allocation/trash/view` (trashed), `/lms-quests/quest-allocation/{id}/restore` (restore), `/lms-quests/quest-allocation/{id}/force-delete` (forceDelete), `/lms-quests/quest-allocation/{quest_allocation}/toggle-status` (toggleStatus), `/lms-quests/quest-allocation/{id}/publish-recommendations` (publishRecommendations), `/lms-quests/quest-allocation/get-target-options` (AJAX getTargetOptions), `/lms-quests/quest-allocation/get-quests` (AJAX getQuests) |
| Controller | `Modules\LmsQuests\Http\Controllers\QuestAllocationController` |
| Model(s) | `QuestAllocation` (`Modules\LmsQuests\Models\QuestAllocation`) — table `lms_quest_allocations`, SoftDeletes |
| Validation (Create/Update) | `QuestAllocationRequest` (`Modules\LmsQuests\Http\Requests\QuestAllocationRequest`) — complex validation with date constraints, target resolution, SECTION handling |
| Permission Gates | `tenant.quest-allocation.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status`, `.bulkAllocate`, `.publish`, `.unpublish`, `.sendNotification`, `.viewStatistics`, `.export`, `.import`, `.extendDueDate`, `.viewAttempts` |
| Soft Deletes | Yes — `SoftDeletes` trait on QuestAllocation |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |
| Usage Guard | `QuestAllocationUsageCheckService` — blocks edit/delete/restore/forceDelete if `QuizQuestAttempt` records exist for the allocation |
| Auto-Publish | Result publish date prohibited unless auto-publish ON; enabling auto-publish publishes hidden recommendations |

---

## 2. Pre-conditions

- Required permissions: `tenant.quest-allocation.viewAny`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status`
- At least one active Quest must exist (`is_active=1`) in `lms_quests`
- For CLASS allocation: at least one active class in `sch_classes`
- For SECTION allocation: at least one active section in `sch_sections` and a valid `sch_class_section_jnt` record linking a class + section
- For GROUP allocation: at least one active entity group in `sch_entity_groups`
- For STUDENT allocation: at least one active student in `std_students` (`is_active=1`, `deleted_at IS NULL`)
- For usage constraint tests: `QuizQuestAttempt` records must exist referencing the allocation
- For recommendation tests: `StudentRecommendation` records with `is_published=false` linked to the quest/allocation

---

## 3. Default Data Load

When create page loads (GET `/lms-quests/quest-allocation/create`):

| Data | Source | Query | Pagination |
|------|--------|-------|------------|
| Quests | `Quest::where('is_active', '1')->whereDoesntHave('allocations')->orderBy('title')` | Active quests without existing allocations (default filter) | None |
| Classes | `SchoolClass::where('is_active', '1')` | Active classes | None |
| Sections | `Section::where('is_active', '1')->orderBy('name')` | Active sections | None |
| Groups | `EntityGroup::where('is_active', '1')->orderBy('name')` | Active groups | None |
| Students | `Student::where('is_active', '1')->map(fn => id + 'name (student_id)')` | Active students (formatted with ID) | None |

When index page loads (GET `/lms-quests/quest-allocation`):

| Data | Source | Notes |
|------|--------|-------|
| Allocations | `QuestAllocation::with(['quest', 'assigner'])->when(filters)->latest()->paginate(10)` | Filterable by quest_id, allocation_type, target_id, is_active, date_range |
| Quests | `Quest::where('is_active', true)->orderBy('title')->get()` | For filter dropdown |

---

## 4. Database Schema (BC-DB)

Table: `lms_quest_allocations`

| Column | Type | Constraints | Default | Notes |
|--------|------|-------------|---------|-------|
| id | int(10) unsigned | PK, AUTO_INCREMENT | | |
| quest_id | int(10) unsigned | NOT NULL, INDEX, FK → lms_quests.id (CASCADE) | | Parent quest |
| allocation_type | enum('CLASS','SECTION','GROUP','STUDENT') | NOT NULL | | Target type |
| target_table_name | varchar(60) | NOT NULL | | e.g. sch_classes, sch_class_section_jnt, sch_entity_groups, std_students |
| target_id | int(10) unsigned | NOT NULL, INDEX(allocation_type, target_id) | | Polymorphic FK (app-level) |
| assigned_by | int(10) unsigned | NULLABLE, FK → sys_users.id (SET NULL) | NULL | Null = system-assigned |
| published_at | datetime | NULLABLE | NULL | When quest becomes visible |
| due_date | datetime | NULLABLE | NULL | Recommended deadline |
| cut_off_date | datetime | NULLABLE | NULL | Hard deadline, defaults to due_date |
| is_auto_publish_result | tinyint(1) | NOT NULL | 0 | Auto-release results |
| result_publish_date | datetime | NULLABLE | NULL | When results become visible |
| is_active | tinyint(1) | NOT NULL | 1 | Status toggle |
| created_at | timestamp | NULLABLE | CURRENT_TIMESTAMP | |
| updated_at | timestamp | NULLABLE | ON UPDATE CURRENT_TIMESTAMP | |
| deleted_at | timestamp | NULLABLE | NULL | Soft delete |

Indexes: `idx_quest_alloc_target` (`allocation_type`, `target_id`)

DDL Source: `/home/shail/pgdatabase/2-DDL_Tenant_Consolidated/LMS_Quest_DDL_v2.sql` (lines 114-135)

---

## 5. Validation Rules (BC-VAL)

### 5.1 Create Validation (BC-VAL)

| BC-VAL ID | Field | Rule | Error Message |
|-----------|-------|------|---------------|
| BC-VAL-01 | quest_id | required, exists:lms_quests,id; custom closure checks is_active | "The selected quest is not active." |
| BC-VAL-02 | allocation_type | required, in:CLASS,SECTION,GROUP,STUDENT | "Invalid allocation type selected." |
| BC-VAL-03 | class_id | nullable, exists:sch_classes,id | "The selected class is invalid." |
| BC-VAL-04 | target_id | required, integer, min:1; Rule::exists(targetTable, id) where is_active=1 (and whereNull deleted_at for STUDENT) | "The selected {target} is invalid or not active." |
| BC-VAL-05 | published_at | nullable, date | "Invalid published date format." |
| BC-VAL-06 | due_date | nullable, date; closure: max 2 years in future | "Due date cannot be more than 2 years in the future." |
| BC-VAL-07 | cut_off_date | nullable, date; closure: max 2 years; after_or_equal:due_date | "Cut-off date must be on or after the due date." |
| BC-VAL-08 | is_auto_publish_result | boolean | "Invalid value for auto publish result." |
| BC-VAL-09 | result_publish_date | nullable, date; closure: max 2 years; after_or_equal:due_date; prohibited_unless:is_auto_publish_result,true | "Result publish date cannot be set when auto publish result is disabled." |
| BC-VAL-10 | is_active | boolean | "Invalid value for active status." |

### 5.2 Target Existence Validation (Dynamic)

| BC-VAL ID | Condition | Validation Rule |
|-----------|-----------|-----------------|
| BC-VAL-11 | allocation_type = SECTION | target_id exists in `sch_class_section_jnt` where class_id + section_id match AND is_active=1 |
| BC-VAL-12 | allocation_type = STUDENT | target_id exists in `std_students` where is_active=1 AND deleted_at IS NULL |
| BC-VAL-13 | allocation_type = CLASS | target_id exists in `sch_classes` where is_active=1 |
| BC-VAL-14 | allocation_type = GROUP | target_id exists in `sch_entity_groups` where is_active=1 |

### 5.3 Update Validation (BC-VAL-U)

Update uses the same `QuestAllocationRequest` rules as Create (BC-VAL-01 through BC-VAL-14) with these additional update-specific behaviours:

| BC-VAL-U ID | Condition | Behaviour |
|-------------|-----------|-----------|
| BC-VAL-U-01 | Usage guard pre-validation | Controller checks `$usageCheck->isUsed($id)` BEFORE Gate::authorize — if attempts exist, redirects back with error |
| BC-VAL-U-02 | SECTION re-resolution | Same logic as create: target_id re-resolved via ClassSection junction lookup |
| BC-VAL-U-03 | Auto-publish toggle | If `is_auto_publish_result` changed from OFF→ON, hidden recommendations published via `publishHiddenRecommendations()` |
| BC-VAL-U-04 | Change tracking | `$allocation->getChanges()` loop captures old/new values (excludes updated_at/created_at) |

### 5.4 prepareForValidation Transformations

| BC-VAL ID | Transformation | Description |
|-----------|---------------|-------------|
| BC-VAL-T01 | target_id resolution | SECTION→section_target_id, GROUP→group_target_id, STUDENT→student_target_id |
| BC-VAL-T02 | class_id fallback | If class_id empty, set from Quest's class_id |
| BC-VAL-T03 | Date null conversion | Empty strings → null for published_at, due_date, cut_off_date, result_publish_date |
| BC-VAL-T04 | Boolean casting | is_auto_publish_result, is_active → `$this->boolean()` |
| BC-VAL-T05 | validated() date format | All date fields formatted to `Y-m-d H:i:s` |

---

## 6. Authorization (BC-AUTH)

### 6.1 Gates Defined in QuestAllocationPolicy

| BC-AUTH ID | Gate | Method | Controller Usage | Notes |
|------------|------|--------|------------------|-------|
| BC-AUTH-01 | tenant.quest-allocation.viewAny | viewAny() | index(), getTargetOptions(), getQuests() | View list |
| BC-AUTH-02 | tenant.quest-allocation.view | view() | show() | View details |
| BC-AUTH-03 | tenant.quest-allocation.create | create() | create(), store() | Create allocation |
| BC-AUTH-04 | tenant.quest-allocation.update | update() | edit(), update(), toggleStatus(), publishRecommendations() | Edit/toggle/publish |
| BC-AUTH-05 | tenant.quest-allocation.delete | delete() | destroy() | Soft-delete |
| BC-AUTH-06 | tenant.quest-allocation.restore | restore() | trashed(), restore() | View trash + restore |
| BC-AUTH-07 | tenant.quest-allocation.forceDelete | forceDelete() | forceDelete() | Permanent delete |
| BC-AUTH-08 | tenant.quest-allocation.status | status() | — (not used in controller) | Toggle status (defined but unused) |
| BC-AUTH-09 | tenant.quest-allocation.bulkAllocate | bulkAllocate() | — | Bulk allocation |
| BC-AUTH-10 | tenant.quest-allocation.publish | publish() | — | Publish |
| BC-AUTH-11 | tenant.quest-allocation.unpublish | unpublish() | — | Unpublish |
| BC-AUTH-12 | tenant.quest-allocation.sendNotification | sendNotification() | — | Send notifications |
| BC-AUTH-13 | tenant.quest-allocation.viewStatistics | viewStatistics() | — | View stats |
| BC-AUTH-14 | tenant.quest-allocation.export | export() | — | Export |
| BC-AUTH-15 | tenant.quest-allocation.import | import() | — | Import |
| BC-AUTH-16 | tenant.quest-allocation.extendDueDate | extendDueDate() | — | Extend due dates |
| BC-AUTH-17 | tenant.quest-allocation.viewAttempts | viewAttempts() | — | View attempts |

### 6.2 Gate Enforcement Points

| BC-AUTH ID | Controller Method | Gate(s) Checked | Order |
|------------|-------------------|-----------------|-------|
| BC-AUTH-E01 | index() | viewAny | First line |
| BC-AUTH-E02 | show() | view | First line |
| BC-AUTH-E03 | create() | create | First line |
| BC-AUTH-E04 | store() | create | After DB::beginTransaction |
| BC-AUTH-E05 | edit() | update | First line |
| BC-AUTH-E06 | update() | update | After usage check |
| BC-AUTH-E07 | destroy() | delete | After usage check |
| BC-AUTH-E08 | trashed() | restore | First line |
| BC-AUTH-E09 | restore() | restore | After usage check |
| BC-AUTH-E10 | forceDelete() | forceDelete | After usage check |
| BC-AUTH-E11 | toggleStatus() | update | First line |
| BC-AUTH-E12 | publishRecommendations() | update | After findOrFail |
| BC-AUTH-E13 | getTargetOptions() | viewAny | First line |
| BC-AUTH-E14 | getQuests() | viewAny | First line |

### 6.3 Blade @can Usage (CR27)

| BC-AUTH-ID | View | @can Gate | Purpose |
|------------|------|-----------|---------|
| BC-AUTH-B01 | index | tenant.quest-allocation.create | Show/hide Create button |
| BC-AUTH-B02 | index | tenant.quest-allocation.update | Show/hide Edit/Status toggle buttons |
| BC-AUTH-B03 | index | tenant.quest-allocation.delete | Show/hide Delete button |
| BC-AUTH-B04 | index | tenant.quest-allocation.restore | Show/hide Restore button (in trash) |
| BC-AUTH-B05 | index | tenant.quest-allocation.forceDelete | Show/hide Force Delete button (in trash) |
| BC-AUTH-B06 | show | tenant.quest-allocation.view | Show detail view |

---

## 7. Business Logic (BC-BIZ)

### 7.1 Business Rules (BC-BIZ-BR)

| BC-BIZ ID | Rule ID | Description | Enforcement Point | Error / Behaviour |
|-----------|---------|-------------|-------------------|-------------------|
| BC-BIZ-BR-01 | BR-QST-021 | Quest must be active to be allocated | QuestAllocationRequest quest_id closure | "The selected quest is not active." |
| BC-BIZ-BR-02 | BR-QST-022 | Allocation type valid; target exists and active | Dynamic target existence validation | "The selected {target} is invalid or not active." |
| BC-BIZ-BR-03 | BR-QST-023 | Cut-off >= due when both set | cut_off_date closure | "Cut-off date must be on or after the due date." |
| BC-BIZ-BR-04 | BR-QST-024 | Result-publish date only with auto-publish; results released via publish/auto | prohibited_unless + controller store/update | "Result publish date cannot be set when auto publish result is disabled." |
| BC-BIZ-BR-05 | BR-QST-025 | Missing cut-off defaults to due date | Controller store/update logic | Auto-set in controller |
| BC-BIZ-BR-06 | BR-QST-026 | Allocation records assigner | Controller store: `assigned_by = Auth::user()->id` | System-assigned = NULL |

### 7.2 Usage Guard (BC-BIZ-USE)

| BC-BIZ ID | Action | Check Method | Behaviour |
|-----------|--------|-------------|-----------|
| BC-BIZ-USE-01 | edit() | `isUsed()` → `getUsageCount() > 0` | Blocked: "Cannot edit this allocation because students have already started attempts." |
| BC-BIZ-USE-02 | update() | `isUsed()` → `getUsageCount() > 0` | Blocked: "Cannot update this allocation because students have already started attempts." |
| BC-BIZ-USE-03 | destroy() | `isUsed()` → `getUsageCount() > 0` | Blocked: "Cannot delete this allocation because students have already started attempts." |
| BC-BIZ-USE-04 | restore() | `hasAttempts()` → `getUsageCount() > 0` | Blocked: "Cannot restore this allocation because students have already started attempts." |
| BC-BIZ-USE-05 | forceDelete() | `hasAttempts()` → `getUsageCount() > 0` | Blocked: "Cannot permanently delete this allocation because students have already attempted." |
| BC-BIZ-USE-06 | toggleStatus() | **No usage check** | Always allowed regardless of attempts |

### 7.3 Target Resolution (BC-BIZ-TGT)

| BC-BIZ ID | Allocation Type | target_table_name | target_id Reference | Resolution |
|-----------|----------------|-------------------|-------------------|------------|
| BC-BIZ-TGT-01 | CLASS | sch_classes | sch_classes.id | Direct class ID |
| BC-BIZ-TGT-02 | SECTION | sch_class_section_jnt | sch_class_section_jnt.id | Resolved from class_id + section_id → junction ID |
| BC-BIZ-TGT-03 | GROUP | sch_entity_groups | sch_entity_groups.id | Direct group ID |
| BC-BIZ-TGT-04 | STUDENT | std_students | std_students.id | Direct student ID |

### 7.4 Controller Business Logic (BC-BIZ-CTRL)

| BC-BIZ ID | Controller Method | Business Logic | Description |
|-----------|-------------------|----------------|-------------|
| BC-BIZ-CTRL-01 | store() | `cut_off_date = due_date` fallback | If cut_off_date empty and due_date set, defaults to due_date |
| BC-BIZ-CTRL-02 | store() | `result_publish_date = null` fallback | If auto-publish OFF, force result_publish_date to null |
| BC-BIZ-CTRL-03 | store() | `assigned_by = Auth::user()->id` | Records the assigner |
| BC-BIZ-CTRL-04 | store() | SECTION junction resolution | `ClassSection::where(class_id, section_id)->firstOrFail()` |
| BC-BIZ-CTRL-05 | store() | DB transaction + activity log | Wraps in DB::beginTransaction/commit/rollBack, logs 'Stored' event |
| BC-BIZ-CTRL-06 | update() | Auto-publish recommendation trigger | When is_auto_publish_result changes OFF→ON, publishes hidden recommendations |
| BC-BIZ-CTRL-07 | update() | Change tracking | `$allocation->getChanges()` loop captures old/new values |
| BC-BIZ-CTRL-08 | destroy() | Deactivate before delete | `$allocation->update(['is_active' => false])` BEFORE `$allocation->delete()` |
| BC-BIZ-CTRL-09 | restore() | Reactivate after restore | `$allocation->restore()` then `$allocation->update(['is_active' => true])` |
| BC-BIZ-CTRL-10 | forceDelete() | Activity log before deletion | Logs 'Deleted' event with quest title, then force-deletes |
| BC-BIZ-CTRL-11 | toggleStatus() | Inline validation + JSON response | Validates is_active as required boolean; returns `{success, is_active, message}` |
| BC-BIZ-CTRL-12 | publishRecommendations() | Auto-enable auto-publish | If `is_auto_publish_result` is OFF, turns it ON, then publishes hidden recommendations |

### 7.5 Model Methods (BC-BIZ-MDL)

| BC-BIZ ID | Method | Behaviour |
|-----------|--------|-----------|
| BC-BIZ-MDL-01 | isPublished() | Returns true when published_at <= now() AND published_at IS NOT NULL |
| BC-BIZ-MDL-02 | isOverdue() | Returns true when due_date < now() |
| BC-BIZ-MDL-03 | isBeforeCutoff() | Returns true when cut_off_date IS NULL OR now() <= cut_off_date |
| BC-BIZ-MDL-04 | getTargetNameAttribute() | Returns human-readable name based on allocation_type with graceful fallback |

---

## 8. Referential Integrity (BC-REF)

### 8.1 Database Foreign Keys (DDL Constraints)

| BC-REF ID | Column | Referenced Table | Referenced Column | ON DELETE | ON UPDATE |
|-----------|--------|-----------------|-------------------|-----------|-----------|
| BC-REF-01 | quest_id | lms_quests | id | CASCADE | — |
| BC-REF-02 | assigned_by | sys_users | id | SET NULL | — |

### 8.2 Implicit / Application-Level References

| BC-REF ID | Source | Target | Type | Notes |
|-----------|--------|--------|------|-------|
| BC-REF-03 | lms_quest_allocations.target_id | sch_classes.id (when allocation_type=CLASS) | Polymorphic app-level FK | No DB constraint; enforced by validation |
| BC-REF-04 | lms_quest_allocations.target_id | sch_class_section_jnt.id (when allocation_type=SECTION) | Polymorphic app-level FK | No DB constraint; enforced by validation |
| BC-REF-05 | lms_quest_allocations.target_id | sch_entity_groups.id (when allocation_type=GROUP) | Polymorphic app-level FK | No DB constraint; enforced by validation |
| BC-REF-06 | lms_quest_allocations.target_id | std_students.id (when allocation_type=STUDENT) | Polymorphic app-level FK | No DB constraint; enforced by validation |
| BC-REF-07 | sp_quiz_quest_attempts.quest_allocation_id | lms_quest_allocations.id | App-level FK | Used by UsageCheckService |
| BC-REF-08 | std_student_recommendations.triggered_by_quest_id | lms_quests.id | App-level FK | Used by publishHiddenRecommendations |

### 8.3 Cascade Behaviour

| BC-REF ID | Parent Action | Child Effect | Notes |
|-----------|--------------|--------------|-------|
| BC-REF-C01 | Quest soft-deleted | Allocation NOT deleted | FK CASCADE only fires on hard delete; soft-delete leaves allocation intact |
| BC-REF-C02 | Quest force-deleted (hard delete) | Allocation CASCADE deleted | FK ON DELETE CASCADE → allocation permanently removed |
| BC-REF-C03 | Assigner user deleted | assigned_by → NULL | FK ON DELETE SET NULL preserves allocation record |
| BC-REF-C04 | Target record deleted from source table | Allocation orphaned (target_id points to non-existent record) | No DB constraint protects against this; app handles via graceful fallback |

---

## 9. Test Data Strategy

- **Unique Suffix**: Use `now()->format('His') . random_int(100, 999)` for test data uniqueness
- **Quest Needed**: Each test requires a parent Quest with `is_active=1`
- **Target Data**: Ensure test data exists for all four allocation types:
  - CLASS: active `SchoolClass` record
  - SECTION: active `ClassSection` junction record (class + section combination)
  - GROUP: active `EntityGroup` record
  - STUDENT: active `Student` record with `deleted_at IS NULL`
- **Date Strategy**: Use `Carbon::now()` as base; add/subtract days for past/future dates; use `->addYears(2)->addDay()` for >2-years tests
- **Attempt Data**: For usage block tests, create `QuizQuestAttempt` records referencing the allocation with `quest_allocation_id`
- **Recommendation Data**: For publish tests, create `StudentRecommendation` records with `triggered_by_quest_id`, `student_id`, `is_published=false`

---

## 10. Test Case Steps

### 10.1 Positive TC Steps

#### TC-P01: Create — Allocate to CLASS type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with is_active=1 | Quest exists |
| 2 | Navigate to Quest Allocation → Create | Create form loads |
| 3 | Select Quest Q1 from dropdown | Quest selected |
| 4 | Select Allocation Type = CLASS | Class dropdown shown |
| 5 | Select target Class C1 (active) | Target selected |
| 6 | Set Published At = empty (immediate) | Published at stays null |
| 7 | Set Due Date = next week | Due date set |
| 8 | Leave Cut-off Date empty | Will default to due_date |
| 9 | Set Auto Publish Result = OFF | Result publish date field hidden/disabled |
| 10 | Set Is Active = ON (default) | Active |
| 11 | Click Submit | POST store |
| 12 | Verify redirect to allocation tab with success message | Redirected with "Quest allocated successfully!" |
| 13 | DB check: `lms_quest_allocations` | Record created: quest_id=Q1, allocation_type='CLASS', target_table_name='sch_classes', target_id=C1.id, assigned_by=logged-in-user, published_at=NULL, cut_off_date=due_date, is_auto_publish_result=0, result_publish_date=NULL, is_active=1 |

---

#### TC-P02: Create — Allocate to SECTION type with junction resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with class_id=C1, is_active=1 | Quest exists |
| 2 | Create ClassSection junction: class_id=C1, section_id=S1, is_active=1 | Junction J1 exists |
| 3 | Open create form, select Quest Q1 | Quest selected |
| 4 | Select Allocation Type = SECTION | Class + Section dropdowns shown |
| 5 | Class auto-fills to C1 (from Quest) | Class shown |
| 6 | Select Section = S1 | Section selected |
| 7 | Set dates and submit | POST store |
| 8 | DB check: target_id | J1.id (ClassSection junction ID, not section ID) |
| 9 | DB check: target_table_name | 'sch_class_section_jnt' |

---

#### TC-P03: Create — Allocate to GROUP type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active EntityGroup G1 | Group exists |
| 2 | Open create form, select Quest Q1 | Quest selected |
| 3 | Select Allocation Type = GROUP | Group dropdown shown |
| 4 | Select Group G1 | Target selected |
| 5 | Set dates and submit | Saved |
| 6 | DB check: target_id | G1.id |
| 7 | DB check: target_table_name | 'sch_entity_groups' |

---

#### TC-P04: Create — Allocate to STUDENT type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active Student St1 (is_active=1, deleted_at=NULL) | Student exists |
| 2 | Open create form, select Quest Q1 | Quest selected |
| 3 | Select Allocation Type = STUDENT | Student dropdown shown |
| 4 | Select Student St1 | Target selected |
| 5 | Set dates and submit | Saved |
| 6 | DB check: target_id | St1.id |
| 7 | DB check: target_table_name | 'std_students' |

---

#### TC-P05: Create — Allocate with result_publish_date when auto-publish ON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select Quest, Allocation Type and Target | Basics set |
| 3 | Set Due Date = 7 days from now | Due set |
| 4 | Set Auto Publish Result = ON | Result publish date field visible |
| 5 | Set Result Publish Date = 8 days from now (>= due) | Result date set |
| 6 | Submit | Saved |
| 7 | DB check: is_auto_publish_result | 1 (true) |
| 8 | DB check: result_publish_date | 8-days-from-now date stored |

---

#### TC-P06: Create — Allocate with auto-publish OFF forces result_publish_date NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill all required fields | Data entered |
| 3 | Set Auto Publish Result = OFF | Result date hidden |
| 4 | Set Result Publish Date = some value via dev tools (attempt injection) | Should be ignored/rejected |
| 5 | Submit | Saved |
| 6 | DB check: is_auto_publish_result | 0 (false) |
| 7 | DB check: result_publish_date | NULL (forced null by controller) |

---

#### TC-P07: Create — Cut-off auto-defaults to due_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set Due Date = 2026-08-01 | Due set |
| 3 | Leave Cut-off Date empty | Not provided |
| 4 | Submit | Saved |
| 5 | DB check: cut_off_date | 2026-08-01 (same as due_date) |

---

#### TC-P08: Create — Published At in the future

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set Published At = 30 days from now | Future publish date set |
| 3 | Submit | Saved |
| 4 | DB check: published_at | Future date stored |
| 5 | Verify `isPublished()` | Returns false (published_at > now) |
| 6 | Advance time to after published_at (or test model) | `isPublished()` returns true |

---

#### TC-P09: Show — View allocation details with usage info

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Allocation A1 (CLASS type, no attempts) | Allocation exists |
| 2 | Navigate to show page: GET `/lms-quests/quest-allocation/{A1}` | Show page loads |
| 3 | Verify quest info displayed | Quest title shown |
| 4 | Verify target info resolved | Class name shown (from polymorphic target) |
| 5 | Verify assigner info | Assigner name shown |
| 6 | Verify usage section shows "No attempts" | Usage details hidden/empty |
| 7 | Create a student attempt for A1 | Attempt exists |
| 8 | Reload show page | Usage section shows: Total Attempts, In Progress, Submitted, Timeout, Passed, Failed, Avg Score, Avg Percentage |

---

#### TC-P10: Edit — Update due_date (no attempts exist)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Allocation A1 with due_date=2026-08-01, no attempts | A1 exists |
| 2 | Navigate to edit page | Edit form loads with existing values |
| 3 | Change due_date to 2026-08-15 | New due date |
| 4 | Submit PUT update | Redirected with success |
| 5 | DB check: due_date | 2026-08-15 updated |

---

#### TC-P11: Edit — Enable auto-publish (was OFF) → recommendations published

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Allocation A1 with is_auto_publish_result=0, no attempts | A1 exists, auto-publish OFF |
| 2 | Create hidden StudentRecommendation records tied to A1's quest+students | is_published=0 |
| 3 | Navigate to edit page | Edit loads |
| 4 | Toggle Auto Publish Result = ON | Auto-publish enabled |
| 5 | Submit update | Updated |
| 6 | DB check: is_auto_publish_result | 1 |
| 7 | DB check: StudentRecommendation records | is_published flipped to 1 (published) |

---

#### TC-P12: Index — List allocations with filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocations A1 (CLASS), A2 (SECTION), A3 (GROUP) | Allocations exist |
| 2 | Navigate to index with filter: allocation_type=CLASS | Only A1 shown |
| 3 | Navigate to index with filter: quest_id=Q1 | Allocations for Q1 only |
| 4 | Navigate to index with filter: is_active=0 | Only inactive allocations |
| 5 | Navigate to index with date_range filter | Filtered by published_at range |
| 6 | Clear all filters | All allocations shown with pagination |

---

#### TC-P13: Destroy — Soft delete allocation (no attempts)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Allocation A1 with is_active=1, no attempts | A1 exists |
| 2 | Click delete icon on A1 | DELETE request |
| 3 | Verify redirect with success message | Redirected to tab |
| 4 | DB check: A1.deleted_at | NOT NULL (soft-deleted) |
| 5 | DB check: A1.is_active | 0 (set inactive before delete) |

---

#### TC-P14: Trashed — View soft-deleted allocations list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete Allocations A1, A2 | In trash |
| 2 | Navigate to trash page: GET `/lms-quests/quest-allocation/trash/view` | Trash page loads |
| 3 | Verify A1 and A2 shown | Both in list |
| 4 | Verify pagination: 10 per page | Paginated |

---

#### TC-P15: Restore — Restore soft-deleted allocation (no attempts)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete Allocation A1 (deleted_at set, is_active=0) | A1 in trash |
| 2 | Navigate to trash page | Trash shows A1 |
| 3 | Click Restore | GET restore |
| 4 | Verify redirect with success | Redirected |
| 5 | DB check: A1.deleted_at | NULL (restored) |
| 6 | DB check: A1.is_active | 1 (reactivated) |

---

#### TC-P16: Force Delete — Permanently delete allocation (no attempts)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete Allocation A1 with no student attempts | A1 in trash |
| 2 | Navigate to trash page | Trash shows A1 |
| 3 | Click Force Delete | DELETE forceDelete |
| 4 | Verify redirect with success | Redirected |
| 5 | DB check: `QuestAllocation::withTrashed()->find(A1.id)` | NULL (force-deleted, gone permanently) |

---

#### TC-P17: Toggle Status — Activate/deactivate allocation (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Allocation A1 with is_active=1 | A1 active |
| 2 | Send AJAX POST to toggleStatus: is_active=0 | AJAX call |
| 3 | Verify response | `{"success": true, "is_active": false}` |
| 4 | DB check: is_active | 0 |
| 5 | Send AJAX POST to toggleStatus: is_active=1 | AJAX call |
| 6 | Verify response | `{"success": true, "is_active": true}` |
| 7 | DB check: is_active | 1 |

---

#### TC-P18: Publish Recommendations — Publish hidden recommendations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Allocation A1 with is_auto_publish_result=0 | A1 exists, auto-publish OFF |
| 2 | Create student attempts for A1 | Attempts exist |
| 3 | Create hidden StudentRecommendation records (is_published=0) linked to quest+students | Hidden recs exist |
| 4 | POST to publishRecommendations(A1.id) | Endpoint called |
| 5 | Verify DB: is_auto_publish_result | 1 (auto-enabled if was off) |
| 6 | Verify DB: StudentRecommendation is_published | Flipped to 1 for matching records |
| 7 | Verify redirect with success | "Recommendations published for all students in this allocation." |

---

#### TC-P19: Get Target Options (AJAX) — CLASS type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have active classes C1(name="10"), C2(name="11") | Classes exist |
| 2 | Send AJAX GET to getTargetOptions: allocation_type=CLASS | AJAX call |
| 3 | Verify response | `{"success": true, "targets": [{"id": C1.id, "name": "10"}, {"id": C2.id, "name": "11"}]}` |
| 4 | Verify inactive classes excluded | Only active classes returned |

---

#### TC-P20: Get Target Options (AJAX) — SECTION type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have active sections S1, S2 | Sections exist |
| 2 | Send AJAX GET to getTargetOptions: allocation_type=SECTION | AJAX call |
| 3 | Verify response contains sections | Sections with name + code returned |
| 4 | Verify inactive sections excluded | Only active sections |

---

#### TC-P21: Get Target Options (AJAX) — GROUP type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have active groups G1, G2 | Groups exist |
| 2 | Send AJAX GET to getTargetOptions: allocation_type=GROUP | AJAX call |
| 3 | Verify response contains groups | Groups with name + code returned |
| 4 | Verify inactive groups excluded | Only active groups |

---

#### TC-P22: Get Target Options (AJAX) — STUDENT type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have active students St1, St2; inactive student St3; soft-deleted student St4 | Students exist |
| 2 | Send AJAX GET to getTargetOptions: allocation_type=STUDENT | AJAX call |
| 3 | Verify St1, St2 included | Active students returned |
| 4 | Verify St3 excluded | Inactive excluded |
| 5 | Verify St4 excluded | Soft-deleted excluded |

---

#### TC-P23: Get Quests (AJAX) — Unallocated only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have Quest Q1 (no allocations), Quest Q2 (has allocations) | Quests exist |
| 2 | Send AJAX GET to getQuests: unallocated_only=1 | AJAX call |
| 3 | Verify Q1 included | Unallocated quest returned |
| 4 | Verify Q2 excluded | Already allocated quest excluded |

---

#### TC-P24: Get Quests (AJAX) — All active quests

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have Quest Q1 (active, no allocations), Quest Q2 (active, has allocations) | Quests exist |
| 2 | Send AJAX GET to getQuests: unallocated_only=0 | AJAX call |
| 3 | Verify both Q1 and Q2 included | All active quests returned |
| 4 | Verify inactive quests excluded | Not returned |

---

### 10.2 Negative TC Steps

#### TC-N01: Create — Inactive quest rejected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with is_active=0 | Inactive quest |
| 2 | Open create form | Form loads |
| 3 | Q1 should NOT appear in quest dropdown | Already filtered out in create() |
| 4 | Attempt to POST with quest_id=Q1 directly | Validation error: "The selected quest is not active." |
| 5 | DB check: no allocation created | 0 records |

---

#### TC-N02: Create — Invalid allocation_type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select Quest Q1 | Valid quest |
| 3 | Set allocation_type = 'INVALID' | Invalid type |
| 4 | Submit | Validation error: "Invalid allocation type selected." |
| 5 | DB check: no allocation created | 0 records |

---

#### TC-N03: Create — Non-existent target_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select Quest Q1, Allocation Type = CLASS | Form ready |
| 3 | Set target_id = 99999 (non-existent) | Invalid target |
| 4 | Submit | Validation error: "The selected class is invalid or not active." |
| 5 | DB check: no allocation created | 0 records |

---

#### TC-N04: Create — Inactive target

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create SchoolClass C1 with is_active=0 | Inactive class |
| 2 | Open create form | Form loads |
| 3 | Select type=CLASS, target=C1.id | Inactive target |
| 4 | Submit | Validation error: target not active |
| 5 | DB check: no allocation created | 0 records |

---

#### TC-N05: Create — SECTION with invalid class+section combination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Class C1, Section S1, but NO ClassSection junction linking them | No junction |
| 2 | Open create form | Form loads |
| 3 | Select type=SECTION, class_id=C1, target_id=S1 | Invalid combo |
| 4 | Submit | Validation error: "The selected class and section combination does not exist or is inactive." |
| 5 | DB check: no allocation created | 0 records |

---

#### TC-N06: Create — cut_off_date before due_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set Due Date = 2026-08-10 | Due set |
| 3 | Set Cut-off Date = 2026-08-05 (before due) | Invalid order |
| 4 | Submit | Validation error: "Cut-off date must be on or after the due date." |
| 5 | DB check: no allocation created | 0 records |

---

#### TC-N07: Create — due_date > 2 years in future

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set Due Date = now + 2 years + 1 day | Beyond 2-year limit |
| 3 | Submit | Validation error: "Due date cannot be more than 2 years in the future." |
| 4 | DB check: no allocation created | 0 records |

---

#### TC-N08: Create — cut_off_date > 2 years in future

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set Due Date = now + 30 days | Valid due |
| 3 | Set Cut-off Date = now + 2 years + 1 day | Beyond limit |
| 4 | Submit | Validation error: "Cut-off date cannot be more than 2 years in the future." |
| 5 | DB check: no allocation created | 0 records |

---

#### TC-N09: Create — result_publish_date > 2 years in future

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set Auto Publish = ON | Enabled |
| 3 | Set Due Date = now + 30 days | Valid due |
| 4 | Set Result Publish Date = now + 2 years + 1 day | Beyond limit |
| 5 | Submit | Validation error: "Result publish date cannot be more than 2 years in the future." |
| 6 | DB check: no allocation created | 0 records |

---

#### TC-N10: Create — result_publish_date before due_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set Auto Publish = ON | Enabled |
| 3 | Set Due Date = 2026-08-10 | Due set |
| 4 | Set Result Publish Date = 2026-08-05 (before due) | Invalid order |
| 5 | Submit | Validation error: "Result publish date must be on or after the due date." |
| 6 | DB check: no allocation created | 0 records |

---

#### TC-N11: Create — result_publish_date set but auto-publish OFF

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set Auto Publish = OFF | Disabled |
| 3 | Set Result Publish Date = some value (injected) | Violates prohibited_unless |
| 4 | Submit | Validation error: "Result publish date cannot be set when auto publish result is disabled." |
| 5 | DB check: no allocation created | 0 records |

---

#### TC-N12: Create — Missing quest_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Leave quest_id empty | No quest selected |
| 3 | Fill other fields | Rest valid |
| 4 | Submit | Validation error: "Please select a quest." |
| 5 | DB check: no allocation created | 0 records |

---

#### TC-N13: Create — Missing target_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select Quest Q1, Allocation Type = CLASS | Valid type |
| 3 | Leave target_id empty | No target |
| 4 | Submit | Validation error: "Please select a target." |
| 5 | DB check: no allocation created | 0 records |

---

#### TC-N14: Edit — student attempts exist (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Allocation A1, create student attempt for A1 | Attempt exists |
| 2 | Navigate to edit page for A1 | Edit loads |
| 3 | Change any field | Changes made |
| 4 | Submit update | Redirect back with error: "Cannot update this allocation because students have already started attempts." |
| 5 | DB check: record unchanged | Original values preserved |

---

#### TC-N15: Destroy — student attempts exist (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Allocation A1 with student attempt | Attempt exists |
| 2 | Click delete on A1 | DELETE request |
| 3 | Verify blocked | Redirect with error: "Cannot delete this allocation because students have already started attempts." |
| 4 | DB check: deleted_at | NULL (not deleted) |

---

#### TC-N16: Restore — student attempts exist (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete Allocation A1 that has student attempts | A1 in trash, attempts exist |
| 2 | Navigate to trash page | Trash shows A1 |
| 3 | Click Restore | Blocked: "Cannot restore this allocation because students have already started attempts." |
| 4 | DB check: deleted_at | Still NOT NULL (not restored) |

---

#### TC-N17: Force Delete — student attempts exist (blocked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete Allocation A1 that has student attempts | A1 in trash, attempts exist |
| 2 | Navigate to trash page | Trash shows A1 |
| 3 | Click Force Delete | Blocked: "Cannot permanently delete this allocation because students have already attempted." |
| 4 | DB check: QuestAllocation::withTrashed()->find(A1.id) | Still exists (not force-deleted) |

---

#### TC-N18: View — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest-allocation.viewAny` permission | Authenticated |
| 2 | Navigate to Quest Allocation index | 403 Forbidden |

---

#### TC-N19: Create — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest-allocation.create` permission | Authenticated |
| 2 | Navigate to create page | 403 Forbidden |
| 3 | Send POST to store directly | 403 Forbidden |

---

#### TC-N20: Edit — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest-allocation.update` permission | Authenticated |
| 2 | Navigate to edit page directly | 403 Forbidden |
| 3 | Send PUT request directly | 403 Forbidden |
| 4 | Send POST to toggleStatus | 403 Forbidden |

---

#### TC-N21: Delete — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest-allocation.delete` permission | Authenticated |
| 2 | Send DELETE request directly | 403 Forbidden |

---

#### TC-N22: Restore — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest-allocation.restore` permission | Authenticated |
| 2 | Navigate to trash page | 403 Forbidden |
| 3 | Send GET to restore directly | 403 Forbidden |

---

#### TC-N23: Force Delete — without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest-allocation.forceDelete` permission | Authenticated |
| 2 | Send DELETE forceDelete directly | 403 Forbidden |

---

#### TC-N24: Toggle Status — invalid is_active value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX POST to toggleStatus: is_active=invalid | Invalid boolean |
| 2 | Verify response | 422 validation error or `{"success": false}` with 500 status |
| 3 | DB check: is_active unchanged | Original value preserved |

---

#### TC-N25: Update SECTION — Change class drops section selection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocations A1 with SECTION type, class_id=C1 | A1 exists |
| 2 | Navigate to edit, change class to C2 | Class changed |
| 3 | Section S1 only exists for C1, not C2 | Invalid combination |
| 4 | Submit | Validation error: "The selected class and section combination does not exist or is inactive." |

---

### 10.3 Dependency TC Steps

#### TC-D01: Cascade — Parent Quest soft-deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Allocation A1 linking to Quest Q1 | A1 exists |
| 2 | Soft-delete Quest Q1 | Q1 deleted |
| 3 | Check A1 in DB | A1 still exists (no cascade on soft-delete) |

---

#### TC-D02: Cascade — Parent Quest force-deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Allocation A1 linking to Quest Q1 (FK CASCADE) | A1 exists |
| 2 | Force-delete Quest Q1 | Q1 permanently deleted |
| 3 | Check A1 withTrashed | A1 cascade-deleted (FK ON DELETE CASCADE) |

---

#### TC-D03: Business — assigned_by recorded on create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as User U1 | Authenticated |
| 2 | Create allocation A1 | Saved |
| 3 | DB check: assigned_by | U1.id |
| 4 | Create allocation via system (no auth) | assigned_by = NULL |

---

#### TC-D04: Business — Activity log created on store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation | Saved |
| 2 | Check activity log | Entry exists: event='Stored', message='Quest allocated to Successfully', performed_by=current user |

---

#### TC-D05: Business — Activity log created on update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update allocation (change due_date) | Saved |
| 2 | Check activity log | Entry exists: event='Updated', message='Quest allocation updated Successfully', with old/new values in changes |

---

#### TC-D06: Business — Activity log created on destroy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete allocation (no attempts) | Deleted |
| 2 | Check activity log | Entry exists: event='Trashed', message='Quest allocation removed for Successfully' |

---

#### TC-D07: Business — Activity log created on restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore soft-deleted allocation | Restored |
| 2 | Check activity log | Entry exists: event='Restored', message='Quest allocation was restored successfully.' |

---

#### TC-D08: Business — Activity log created on forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete allocation (no attempts) | Permanently deleted |
| 2 | Check activity log | Entry exists: event='Deleted', message='Quest allocation for "{title}" was permanently deleted.' |

---

#### TC-D09: Business — Activity log created on toggleStatus

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle allocation status (AJAX) | Toggled |
| 2 | Check activity log | Entry exists: event='Toggled', message='Quest allocation status was updated successfully.' |

---

#### TC-D10: Business — isPublished() behaviour

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set published_at = now - 1 day (past) | Past publish |
| 2 | Check `$allocation->isPublished()` | Returns true |
| 3 | Set published_at = now + 1 day (future) | Future publish |
| 4 | Check `$allocation->isPublished()` | Returns false |
| 5 | Set published_at = NULL | Null publish |
| 6 | Check `$allocation->isPublished()` | Returns false |

---

#### TC-D11: Business — isOverdue() behaviour

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set due_date = now - 1 day (past) | Past due |
| 2 | Check `$allocation->isOverdue()` | Returns true |
| 3 | Set due_date = now + 1 day (future) | Future due |
| 4 | Check `$allocation->isOverdue()` | Returns false |
| 5 | Set due_date = NULL | Null due |
| 6 | Check `$allocation->isOverdue()` | Returns false |

---

#### TC-D12: Business — isBeforeCutoff() behaviour

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set cut_off_date = now + 1 day (future) | Future cutoff |
| 2 | Check `$allocation->isBeforeCutoff()` | Returns true |
| 3 | Set cut_off_date = now - 1 day (past) | Past cutoff |
| 4 | Check `$allocation->isBeforeCutoff()` | Returns false |
| 5 | Set cut_off_date = NULL | Null cutoff |
| 6 | Check `$allocation->isBeforeCutoff()` | Returns true (no cutoff = always before) |

---

#### TC-D13: Business — getTargetNameAttribute resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create CLASS allocation with known class | target_name = class name |
| 2 | Create SECTION allocation with known junction | target_name = "ClassName - SectionName" |
| 3 | Create GROUP allocation with known group | target_name = group name |
| 4 | Create STUDENT allocation with known student | target_name = student full_name |
| 5 | Create allocation with deleted target | target_name = "Target ID: {id}" (graceful fallback) |

---

#### TC-D14: Business — ToggleStatus does NOT check usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Allocation A1 with student attempts | Attempts exist |
| 2 | Send AJAX POST to toggleStatus: is_active=0 | AJAX call (no usage check) |
| 3 | Verify response | `{"success": true, "is_active": false}` |
| 4 | DB check: is_active | 0 (toggle succeeded despite attempts) |

---

#### TC-D15: Business — publishRecommendations enables auto-publish if OFF

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Allocation A1 with is_auto_publish_result=0 | Auto-publish OFF |
| 2 | POST to publishRecommendations(A1.id) | Endpoint called |
| 3 | DB check: is_auto_publish_result | 1 (auto-enabled) |
| 4 | Verify recommendations published | Hidden recs published |

---

### 10.4 Code Review TC Steps

#### TC-CR01: Request — quest_id validation (exists + active)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestAllocationRequest::rules()` quest_id closure | Checks `Quest::find($value)` |
| 2 | Verify quest existence check | `if (!$quest) $fail(...)` — returns early |
| 3 | Verify active check | `if (!$quest->is_active) $fail('The selected quest is not active.')` |
| 4 | Verify `exists:lms_quests,id` rule present | Base DB existence check |

---

#### TC-CR02: Request — allocation_type enum validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review allocation_type rule | `'required', 'in:CLASS,SECTION,GROUP,STUDENT'` |
| 2 | Verify all four types accepted | CLASS, SECTION, GROUP, STUDENT |
| 3 | Verify any other value rejected | `in` validation fails |

---

#### TC-CR03: Request — target_id dynamic existence by type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review target existence addition | Runs only if `$this->allocation_type && $this->target_id` |
| 2 | Verify `getTargetTable()` mapping | CLASS→sch_classes, SECTION→sch_class_section_jnt, GROUP→sch_entity_groups, STUDENT→std_students |
| 3 | Verify `Rule::exists(...)->where('is_active', true)` | All types filtered to active |
| 4 | Verify STUDENT extra condition | `whereNull('deleted_at')` for students |

---

#### TC-CR04: Request — SECTION class+section junction validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review SECTION-specific validation | Runs when `allocation_type === 'SECTION' && class_id` |
| 2 | Verify junction lookup | `ClassSection::where('class_id', $this->class_id)->where('section_id', $value)->where('is_active', true)->exists()` |
| 3 | Verify error message | "The selected class and section combination does not exist or is inactive." |

---

#### TC-CR05: Request — cut_off_date after_or_equal due_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review cut_off_date closure | Runs only if `$value` is provided |
| 2 | Verify 2-year max check | `$cutOffDate->gt(Carbon::now()->addYears(2))` → error |
| 3 | Verify due_date comparison | Only checks when `$dueDate` is present |
| 4 | Verify comparison: `$cutOffDate->lt($due)` | Error: "Cut-off date must be on or after the due date." |

---

#### TC-CR06: Request — result_publish_date prohibited_unless auto-publish

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review result_publish_date conditional rules | Base: nullable, date, closure (2yr max, after due) |
| 2 | Verify when auto-publish ON | Rules remain (nullable, date) |
| 3 | Verify when auto-publish OFF | Additional: `'prohibited_unless:is_auto_publish_result,true'` |
| 4 | Verify controller also enforces | `if (!$is_auto_publish_result) $data['result_publish_date'] = null` |

---

#### TC-CR07: Request — prepareForValidation target_id resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review prepareForValidation() | Mutates request before validation |
| 2 | Verify SECTION: uses `section_target_id` | `$resolvedTargetId = $this->section_target_id` |
| 3 | Verify GROUP: uses `group_target_id` | `$resolvedTargetId = $this->group_target_id` |
| 4 | Verify STUDENT: uses `student_target_id` | `$resolvedTargetId = $this->student_target_id` |
| 5 | Verify class_id resolution from Quest | `$questClassId = Quest::whereKey($quest_id)->value('class_id')` |
| 6 | Verify empty-date-to-null conversion | All date fields: empty string → null |
| 7 | Verify boolean casting | `is_auto_publish_result` and `is_active` → `$this->boolean()` |

---

#### TC-CR08: Request — validated() date formatting

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `validated()` override | Date fields formatted to `Y-m-d H:i:s` |
| 2 | Verify all date fields processed | published_at, due_date, cut_off_date, result_publish_date |
| 3 | Verify null propagation | Empty/falsy dates set to null |

---

#### TC-CR09: Controller store() — Target table resolution + SECTION junction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `getTargetTable()` | match(): CLASS→sch_classes, SECTION→sch_class_section_jnt, GROUP→sch_entity_groups, STUDENT→std_students |
| 2 | Verify SECTION junction resolution | `ClassSection::where('class_id', $classId)->where('section_id', $sectionId)->firstOrFail()` |
| 3 | Verify `target_table_name` is set | `$allocationData['target_table_name'] = $targetTable` |
| 4 | Verify `assigned_by` is set | `$allocationData['assigned_by'] = Auth::user()->id` |

---

#### TC-CR10: Controller store() — Date defaults + auto-publish logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review cut_off_date default | `if (empty($cut_off_date) && !empty($due_date)) $cut_off_date = $due_date` |
| 2 | Review auto-publish OFF logic | `if (!$is_auto_publish_result) $result_publish_date = null` |
| 3 | Verify DB transaction | Wrapped in `DB::beginTransaction/commit/rollBack` |
| 4 | Verify activity log | `activityLog($allocation, 'Stored', ...)` after create |
| 5 | Verify catch block | `DB::rollBack()`, Log::error, redirect with error |

---

#### TC-CR11: Controller edit() — Usage check before form load

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `edit()` method | `Gate::authorize('update')` first |
| 2 | Verify usage check | `$usageCheck->isUsed($id)` → back with error if used |
| 3 | Verify target data loading | `$this->getTargetData($allocation->allocation_type, $allocation->target_id)` |
| 4 | Verify view data | quests, classes, sections, groups, students, targetData passed |

---

#### TC-CR12: Controller update() — Usage guard + recommendation publish

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `update()` order | Usage check BEFORE Gate::authorize |
| 2 | Verify usage check | `$usageCheck->isUsed($id)` → back with error |
| 3 | Verify SECTION re-resolution | Same logic as store() |
| 4 | Verify auto-publish recommendation trigger | `if (!$wasAutoPublish && $allocation->is_auto_publish_result) → publishHiddenRecommendations()` |
| 5 | Verify change tracking | `$allocation->getChanges()` loop (excludes updated_at/created_at) |
| 6 | Verify activity log | `activityLog($allocation, 'Updated', ...)` with changes |

---

#### TC-CR13: Controller destroy() — Soft delete with usage check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `destroy()` order | Usage check BEFORE Gate::authorize |
| 2 | Verify deactivation | `$allocation->update(['is_active' => false])` BEFORE delete |
| 3 | Verify soft delete | `$allocation->delete()` |
| 4 | Verify activity log | `activityLog($allocation, 'Trashed', ...)` |

---

#### TC-CR14: Controller restore() — hasAttempts check, reactivation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `restore()` | Uses `hasAttempts()` (not `isUsed()`) for check |
| 2 | Verify `hasAttempts` behaviour | Both `hasAttempts` and `isUsed` call `getUsageCount() > 0` — functionally identical |
| 3 | Verify restore + reactivation | `$allocation->restore()` then `$allocation->update(['is_active' => true])` |
| 4 | Verify `onlyTrashed()` scope | `QuestAllocation::onlyTrashed()->with(['quest'])->findOrFail($id)` |

---

#### TC-CR15: Controller forceDelete() — hasAttempts check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `forceDelete()` | Uses `hasAttempts()` for check |
| 2 | Verify `hasAttempts` check BEFORE Gate | `$usageCheck->hasAttempts($id)` → back with error |
| 3 | Verify `withTrashed()` scope | `QuestAllocation::withTrashed()->...findOrFail($id)` |
| 4 | Verify activity log before deletion | `activityLog(...)` then `$allocation->forceDelete()` |
| 5 | Verify success message | "Quest allocation permanently deleted!" |

---

#### TC-CR16: Controller toggleStatus() — No usage check (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `toggleStatus()` | NO usage check — bypasses QuestAllocationUsageCheckService |
| 2 | Verify inline validation | `$request->validate(['is_active' => 'required|boolean'])` |
| 3 | Verify success JSON | `{'success': true, 'is_active': bool, 'message': ...}` |
| 4 | Verify error JSON on failure | `{'success': false, 'message': ...}` with 500 status |
| 5 | Verify activity log | `activityLog($allocation, 'Toggled', ...)` |

---

#### TC-CR17: Controller show() — Polymorphic target resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `show()` | Loads allocation with quest + assigner relations |
| 2 | Verify usage check loading | `QuestAllocationUsageCheckService` → isUsed, usageDetails, recentAttempts |
| 3 | Verify target resolution switch | CLASS→SchoolClass::find(), SECTION→ClassSection::find(), GROUP→EntityGroup::find(), STUDENT→Student::with('user')->find() |
| 4 | Verify dynamic relation attachment | `$allocation->setRelation('target', $target)` — no Blade changes needed |

---

#### TC-CR18: Controller publishRecommendations() — Endpoint behaviour

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `publishRecommendations()` | Finds allocation, gates for update |
| 2 | Verify auto-publish enable | `if (!$allocation->is_auto_publish_result) $allocation->update(['is_auto_publish_result' => true])` |
| 3 | Verify `publishHiddenRecommendations()` called | Private helper called with type='QUEST' |
| 4 | Verify recommendation query | `StudentRecommendation::where(triggered_by_quest_id, assessmentId)->whereIn(student_id, $studentIds)->where(is_published, false)->update(['is_published' => true])` |

---

#### TC-CR19: Controller getTargetOptions() — Active filtering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `getTargetOptions()` | Validates allocation_type: `required|in:CLASS,SECTION,GROUP,STUDENT` |
| 2 | Verify CLASS returns active classes | `SchoolClass::where('is_active', '1')->orderBy('name')` |
| 3 | Verify SECTION returns active sections | `Section::where('is_active', '1')->orderBy('name')` |
| 4 | Verify GROUP returns active groups | `EntityGroup::where('is_active', '1')->orderBy('name')` |
| 5 | Verify STUDENT returns active + not deleted | `Student::where('is_active', '1')->whereNull('deleted_at')->orderBy('name')` |
| 6 | Verify response format | `{"success": true, "targets": [{"id": ..., "name": ...}]}` |

---

#### TC-CR20: Controller getQuests() — Unallocated filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `getQuests()` | Gate: `tenant.quest-allocation.viewAny` |
| 2 | Verify base query: active quests | `Quest::where('is_active', '1')` |
| 3 | Verify unallocated filter | `->when($showUnallocatedOnly, fn($q) => $q->whereDoesntHave('allocations'))` |
| 4 | Verify response shape | `{"success": true, "quests": [{id, title, class_id, class_name}]}` |

---

#### TC-CR21: Controller index() — Filters and pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `index()` | Gates for `tenant.quest-allocation.viewAny` |
| 2 | Verify filter chain | quest_id, allocation_type, target_id, is_active, date_range |
| 3 | Verify date range parsing | `explode(' - ', $date_range)` → Carbon parse → startOfDay/endOfDay |
| 4 | Verify eager loading | `with(['quest', 'assigner'])` |
| 5 | Verify pagination | `paginate(10, ['*'], 'quest_allocation_page')->withQueryString()` |

---

#### TC-CR22: Controller helpers — getTargetData() for edit pre-fill

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `getTargetData()` | Returns model instance for edit form pre-fill |
| 2 | Verify CLASS: SchoolClass::find() | Returns class model |
| 3 | Verify SECTION: ClassSection::with(['class','section'])->find() | Returns junction with relations |
| 4 | Verify GROUP: EntityGroup::find() | Returns group model |
| 5 | Verify STUDENT: Student::find() | Returns student model |

---

#### TC-CR23: Request — FormRequest authorize() returns true unconditionally

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestAllocationRequest::authorize()` | Returns `true` unconditionally |
| 2 | Verify permission enforcement | Only in Controller via `Gate::authorize()` |
| 3 | Assess risk | Defence-in-depth gap — if controller Gate is ever removed, validation allows unauthorized access |

---

#### TC-CR24: Request — target_id min:1 validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review target_id base rule | `'required', 'integer', 'min:1'` |
| 2 | Test with target_id=0 | Validation error: "Invalid target selected." |
| 3 | Test with target_id=-5 | Validation error: "Invalid target selected." |
| 4 | Test with target_id=1.5 | Validation error (integer fails) |

---

#### TC-CR25: Controller — SECTION resolution uses firstOrFail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review SECTION resolution in store/update | `ClassSection::where('class_id', $classId)->where('section_id', $sectionId)->firstOrFail()` |
| 2 | Verify it throws ModelNotFoundException if junction missing | Exception caught → transaction rollback, error redirect |
| 3 | Note: Request validation should catch this before controller | BC-VAL-11 validates in request, but firstOrFail acts as safety net |

---

#### TC-CR26: Controller — Activity log target message uses getTargetLabel

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `getTargetLabel()` | match() for each type with fallback to "Target ID: {id}" |
| 2 | Verify CLASS label | `SchoolClass::find($targetId)?->name ?? "Class ID: {$targetId}"` |
| 3 | Verify SECTION label | `ClassSection::find($targetId)?->full_name ?? "Section ID: {$targetId}"` |
| 4 | Verify GROUP label | `EntityGroup::find($targetId)?->name ?? "Group ID: {$targetId}"` |
| 5 | Verify STUDENT label | `Student::find($targetId)?->name ?? "Student ID: {$targetId}"` |
| 6 | Verify graceful fallback on exception | Catches Exception → logs error → returns "Target ID: {id}" |

---

#### TC-CR27: Blade — @can checks in index view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review index.blade.php | @can('create') wraps Create button |
| 2 | Review index/blade for Edit button | @can('update') wraps Edit link for each allocation row |
| 3 | Review index/blade for Delete button | @can('delete') wraps Delete form for each allocation row |
| 4 | Review index/blade for Status toggle | @can('update') wraps toggleStatus button |
| 5 | Review trash view | @can('restore') wraps Restore button; @can('forceDelete') wraps Force Delete button |
| 6 | Verify unauthenticated user | All action buttons hidden, list still visible (viewAny) |

---

#### TC-CR28: Blade — Breadcrumb navigation in views

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review index.blade.php breadcrumb | Breadcrumb: Home → Quest Management → Quests → Quest Allocation |
| 2 | Review create.blade.php breadcrumb | Breadcrumb extends index with → Create |
| 3 | Review edit.blade.php breadcrumb | Breadcrumb: ... → Edit |
| 4 | Review show.blade.php breadcrumb | Breadcrumb: ... → Details / View |
| 5 | Review trash.blade.php breadcrumb | Breadcrumb: ... → Trash |
| 6 | Verify breadcrumb uses route helper | Each crumb links to correct named route |

---

#### TC-CR29: Blade — View isset / null safety checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review index view for null-safety | `$allocation->quest` accessed only after optional check or null-coalescing |
| 2 | Review show view for target null | `$allocation->target` may be null if target record deleted; view handles with fallback |
| 3 | Review show view for assigner null | `$allocation->assigner` may be null (system-assigned); view shows "System" fallback |
| 4 | Review edit view for targetData null | `$targetData` may be null if target record missing; form handles gracefully |
| 5 | Verify usage details null-safety | `$usageDetails` null when no attempts exist; view checks before accessing properties |

---

#### TC-CR30: Blade — Flash messages display in views

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review layout for flash message partial | `@include('partials.flash-messages')` or inline @if(session('success')) |
| 2 | Verify success flash displayed | `session('success')` renders green success banner |
| 3 | Verify error flash displayed | `session('error')` renders red error banner |
| 4 | Verify flash auto-dismiss | Flash messages include JavaScript auto-dismiss after X seconds (if applicable) |
| 5 | Verify flash on redirect after store | Store → redirect with `->with('success', ...)` → flash shown on index page |
| 6 | Verify flash on redirect after update | Update → redirect with success flash |
| 7 | Verify flash on error redirect | Catch block → `->with('error', ...)` → flash shown on form |
| 8 | Test flash with no session | Page loads without flash; no JS errors |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/lms-quests/quest-allocation` | lms-quests.quest-allocation.index | index() | tenant.quest-allocation.viewAny |
| GET | `/lms-quests/quest-allocation/create` | lms-quests.quest-allocation.create | create() | tenant.quest-allocation.create |
| POST | `/lms-quests/quest-allocation` | lms-quests.quest-allocation.store | store() | tenant.quest-allocation.create |
| GET | `/lms-quests/quest-allocation/{quest_allocation}` | lms-quests.quest-allocation.show | show() | tenant.quest-allocation.view |
| GET | `/lms-quests/quest-allocation/{quest_allocation}/edit` | lms-quests.quest-allocation.edit | edit() | tenant.quest-allocation.update |
| PUT | `/lms-quests/quest-allocation/{quest_allocation}` | lms-quests.quest-allocation.update | update() | tenant.quest-allocation.update |
| DELETE | `/lms-quests/quest-allocation/{quest_allocation}` | lms-quests.quest-allocation.destroy | destroy() | tenant.quest-allocation.delete |
| GET | `/lms-quests/quest-allocation/trash/view` | lms-quests.quest-allocation.trashed | trashed() | tenant.quest-allocation.restore |
| GET | `/lms-quests/quest-allocation/{id}/restore` | lms-quests.quest-allocation.restore | restore() | tenant.quest-allocation.restore |
| DELETE | `/lms-quests/quest-allocation/{id}/force-delete` | lms-quests.quest-allocation.forceDelete | forceDelete() | tenant.quest-allocation.forceDelete |
| POST | `/lms-quests/quest-allocation/{quest_allocation}/toggle-status` | lms-quests.quest-allocation.toggleStatus | toggleStatus() | tenant.quest-allocation.update |
| POST | `/lms-quests/quest-allocation/{id}/publish-recommendations` | lms-quests.quest-allocation.publishRecommendations | publishRecommendations() | tenant.quest-allocation.update |
| GET | `/lms-quests/quest-allocation/get-target-options` | lms-quests.quest-allocation.getTargetOptions | getTargetOptions() | tenant.quest-allocation.viewAny |
| GET | `/lms-quests/quest-allocation/get-quests` | lms-quests.quest-allocation.getQuests | getQuests() | tenant.quest-allocation.viewAny |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | `FormRequest::authorize()` returns `true` unconditionally | **High** | `QuestAllocationRequest::authorize()` returns `true` instead of checking `Gate::allows()`. Permission is enforced in the Controller via `Gate::authorize()`, but this bypasses the defence-in-depth pattern used by other modules. |
| KI-02 | `toggleStatus()` does NOT check usage guard | **Medium** | Unlike edit/destroy/restore/forceDelete, the AJAX toggleStatus method has no `QuestAllocationUsageCheckService` check. Teachers can activate/deactivate an allocation that already has student attempts. This may be intentional (for pausing assessments) but contrasts with the edit guard. |
| KI-03 | `destroy()` checks usage BEFORE Gate authorization | Low | `$usageCheck->isUsed($id)` runs before `Gate::authorize('tenant.quest-allocation.delete')`. If an unauthorized user triggers destroy on a non-existent ID, it would error on the usage check before the gate. The gate is still enforced, but order is inconsistent with other methods where Gate comes first. |
| KI-04 | `restore()` and `forceDelete()` use `hasAttempts()` vs `isUsed()` — functionally same | Low | Both methods call the same `getUsageCount() > 0`. The method name difference (`hasAttempts` vs `isUsed`) is cosmetic — they share the same underlying query. Consider consolidating to a single method for clarity. |
| KI-05 | No `index()` page filters paginate without respecting eager-loaded relations | Low | The index uses `paginate(10, ['*'], 'quest_allocation_page')` on the filtered query. The `with(['quest', 'assigner'])` eager loading is applied before paginate, so N+1 is avoided. Correct. |
| KI-06 | `getTargetOptions()` returns sections without class context | Low | For SECTION type, the endpoint returns all active sections — but the SECTION selection in the form requires a class+section combo. The class selection is handled separately in the UI. |
| KI-07 | `published_at` can be any date (past/present/future) with no restriction | Info | The business requirement explicitly states no restriction on published_at. It can be past (immediate), present, or future (scheduled). This is correct behaviour, not a bug. |
| KI-08 | `cut_off_date` default logic runs only when `due_date` is non-empty | Low | Controller logic: `if (empty($cut_off_date) && !empty($due_date)) $cut_off_date = $due_date`. If both are empty, cut-off stays null. This is correct — no due date means no default cut-off. |
| KI-09 | `result_publish_date` field still accepted in validated data even when auto-publish is OFF | Low | The request validation marks it as `prohibited_unless`, but the controller explicitly nullifies it: `if (!$is_auto_publish_result) $data['result_publish_date'] = null`. Double protection. |
| KI-10 | `assigned_by` foreign key uses ON DELETE SET NULL | Info | If the assigning user is deleted from `sys_users`, the allocation's `assigned_by` becomes NULL (not cascade-deleted). This preserves the allocation record. |

---

## 13. Test Case Summary

### 13.1 Test Case Count by Category

| Category | Code | Count | Coverage |
|----------|------|-------|----------|
| Positive (Happy Path) | TC-P | 24 | Create/Read/Update/Delete/AJAX flows |
| Negative (Validation/Error) | TC-N | 25 | Validation errors, permission denials, usage blocks |
| Dependency (Cascade/Business) | TC-D | 15 | FK cascade, activity logs, model behaviours |
| Code Review (Source Analysis) | TC-CR | 30 | Controller, Request, Policy, Model, Blade views |
| **Total** | | **94** | |

### 13.2 Test Case Breakdown by Feature Area

| Feature Area | TC-P | TC-N | TC-D | TC-CR | Total |
|-------------|------|------|------|-------|-------|
| Create — CLASS type | P01 | N01-N13 | D03-D04 | CR01-CR10, CR23-CR25 | 22 |
| Create — SECTION type | P02 | N05 | — | CR04, CR07, CR09, CR25 | 5 |
| Create — GROUP type | P03 | — | — | — | 1 |
| Create — STUDENT type | P04 | — | — | — | 1 |
| Create — Dates & Auto-publish | P05-P08 | N06-N11 | D10-D12 | CR05-CR06, CR08, CR10 | 16 |
| Show / View Details | P09 | N18 | — | CR17 | 3 |
| Edit / Update | P10-P11 | N14, N25 | D05 | CR11-CR12, CR22 | 7 |
| Index / List | P12 | — | — | CR21 | 2 |
| Soft Delete (Destroy) | P13 | N15 | D06 | CR13 | 4 |
| Trash View | P14 | — | — | — | 1 |
| Restore | P15 | N16 | D07 | CR14 | 4 |
| Force Delete | P16 | N17 | D08 | CR15 | 4 |
| Toggle Status (AJAX) | P17 | N24 | D09, D14 | CR16 | 5 |
| Publish Recommendations | P18 | — | D15 | CR18 | 3 |
| Get Target Options (AJAX) | P19-P22 | — | — | CR19 | 5 |
| Get Quests (AJAX) | P23-P24 | — | — | CR20 | 3 |
| Cascade / Referential | — | — | D01-D02 | — | 2 |
| Permission / Authorization | — | N18-N23 | — | CR23 | 7 |
| Model Methods | — | — | D10-D13 | — | 4 |
| Blade Views | — | — | — | CR27-CR30 | 4 |
| Activity Logs | — | — | D04-D09 | CR26 | 7 |

### 13.3 Test Execution Priority Matrix

| Priority | TCs | When to Run |
|----------|-----|-------------|
| P0 — Smoke | P01, P12, P13, N01, N18, N19 | Every build / CI commit |
| P1 — Core Functional | P02-P08, P10, P14-P18, N02-N13, N24 | Feature branch validation |
| P2 — Edge Cases | P09, P11, N14-N17, N20-N23, N25 | Pre-release regression |
| P3 — Code Review | CR01-CR30 | Static analysis / audit |
| P4 — Dependency | D01-D15 | Integration / E2E testing |
