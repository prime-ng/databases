# hmw_Homework_TcList

## Module: LmsHomework → Homework Master → Homework Management

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsHomework |
| Tab Group | Homework Master |
| Feature | Homework Management (CRUD) |
| URL(s) | `/lms-home-work` (index via tab), `/lms-home-work/home-works/create` (create), `/lms-home-work/home-works` (store), `/lms-home-work/home-works/{id}` (show), `/lms-home-work/home-works/{id}/edit` (edit), `/lms-home-work/home-works/{id}` (update), `/lms-home-work/home-works/{id}` (destroy), `/lms-home-work/home-works/trash/view` (trash), `/lms-home-work/home-works/{id}/restore` (restore), `/lms-home-work/home-works/{id}/force-delete` (forceDelete), `/lms-home-work/home-works/{id}/toggle-status` (toggleStatus), `/lms-home-work/home-works/{id}/publish` (publish), `/lms-home-work/home-works/{id}/clone` (clone) |
| Controller | `Modules\LmsHomework\Http\Controllers\LmsHomeworkController` |
| Model(s) | `Modules\LmsHomework\Models\Homework` (table: `lms_homework`) |
| Validation (Create) | `Modules\LmsHomework\Http\Requests\HomeworkRequest` |
| Validation (Update) | `Modules\LmsHomework\Http\Requests\HomeworkRequest` |
| Permissions | `tenant.home-work.viewAny`, `tenant.home-work.view`, `tenant.home-work.create`, `tenant.home-work.update`, `tenant.home-work.delete`, `tenant.home-work.restore`, `tenant.home-work.forceDelete` |
| Soft Deletes | Yes (`Homework` uses `SoftDeletes` trait) |
| Activity Log | Events: `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted` |
| Media | Spatie Media Library (`homework_files` collection) + JSON-based `hw_attachment_media_id` |

---

## 2. Pre-conditions

- Required permissions: `tenant.home-work.*` (viewAny, view, create, update, delete, restore, forceDelete)
- Required seed data: At least one active `SchoolClass`, one active `Subject`, one active `Section`, one active `OrganizationAcademicSession`
- Required dropdown seed: Submission types and homework statuses in `sys_dropdown_table` with correct keys
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For publish tests: At least one active student enrolled in target class/section
- For clone tests: At least 2 sections for the same class
- For attachment tests: Sample files (PDF, DOCX, JPG, ZIP) under 10MB

---

## 3. Default Data Load

When the page loads via `LmsHomeworkController@index()` with `tab=home_work`, the following data is fetched:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: Classes | `index()` | `SchoolClass::where('is_active', 1)->get()` | is_active=1 | None |
| Shared: Sections | `index()` | `Section::where('is_active', 1)->get()` | is_active=1 | None |
| Shared: Subjects | `index()` | `Subject::where('is_active', 1)->get()` | is_active=1 | None |
| Shared: Academic Sessions | `index()` | `OrganizationAcademicSession::get()` | None | None |
| Homework Grid | `queryService->homeworkData()` | `Homework::with(class, subject, section, status, ...)` | search(title), class_id, subject_id, status, due_date range | 10/page |

---

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Title**: String max 255, no uniqueness constraint
- **Homework statuses**: Uses `sys_dropdown_table` with key `HOMEWORK_STATUS` (DRAFT, PUBLISHED, ARCHIVED)
- **Submission types**: Uses `sys_dropdown_table` with key `SUBMISSION_TYPE`
- **Release condition**: ENUM `IMMEDIATE`, `ON_TOPIC_COMPLETE`, `ON_SCHEDULED_DATE`
- **Attachment files**: Stored via Spatie Media Library or JSON column; allowed types: pdf,doc,docx,txt,jpg,jpeg,png,zip; max 10MB
- **Pre-test cleanup**: Delete created homework by ID after tests
- **Publish test**: Requires enrolled students via `std_students` + `sch_class_section_jnt`

---

## 5. Business Conditions

### 5.1 Database Schema — `lms_homework`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | academic_session_id | SMALLINT UNSIGNED FK | NOT NULL |
| BC-DB-03 | class_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-04 | section_id | INT UNSIGNED FK | NULLABLE |
| BC-DB-05 | subject_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-06 | lesson_id | INT UNSIGNED FK | NULLABLE |
| BC-DB-07 | topic_id | INT UNSIGNED FK | NULLABLE |
| BC-DB-08 | schedule_id | INT UNSIGNED FK | NULLABLE |
| BC-DB-09 | title | VARCHAR(255) | NOT NULL |
| BC-DB-10 | description | LONGTEXT | NOT NULL |
| BC-DB-11 | hw_attachment_media_id | JSON | NULLABLE |
| BC-DB-12 | submission_type_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-13 | is_gradable | BOOLEAN | DEFAULT true |
| BC-DB-14 | max_marks | DECIMAL(5,2) | NULLABLE |
| BC-DB-15 | passing_marks | DECIMAL(5,2) | NULLABLE |
| BC-DB-16 | difficulty_level_id | INT UNSIGNED FK | NULLABLE |
| BC-DB-17 | assign_date | DATETIME | NOT NULL |
| BC-DB-18 | due_date | DATETIME | NOT NULL |
| BC-DB-19 | allow_late_submission | BOOLEAN | DEFAULT false |
| BC-DB-20 | auto_publish_score | BOOLEAN | DEFAULT false |
| BC-DB-21 | release_condition | ENUM('IMMEDIATE','ON_TOPIC_COMPLETE','ON_SCHEDULED_DATE') | DEFAULT 'ON_TOPIC_COMPLETE' |
| BC-DB-22 | release_scheduled_date | DATETIME | NULLABLE |
| BC-DB-23 | status_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-24 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-25 | created_by | INT UNSIGNED FK | NOT NULL |
| BC-DB-26 | updated_by | INT UNSIGNED FK | NULLABLE |
| BC-DB-27 | created_at | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-28 | updated_at | TIMESTAMP | NULL DEFAULT NULL |
| BC-DB-29 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules — `HomeworkRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | class_id | required, exists:sch_classes,id | "Please select a class." |
| BC-VAL-02 | subject_id | required, exists:sch_subjects,id | "Please select a subject." |
| BC-VAL-03 | section_id | nullable, exists:sch_sections,id | — |
| BC-VAL-04 | lesson_id | nullable, exists:slb_lessons,id | — |
| BC-VAL-05 | topic_id | nullable, exists:slb_topics,id | — |
| BC-VAL-06 | schedule_id | nullable, exists:slb_syllabus_schedule,id | — |
| BC-VAL-07 | title | required, string, max:255 | "The homework title is required." |
| BC-VAL-08 | description | required, string | "Please provide a description." |
| BC-VAL-09 | submission_type_id | required, exists:sys_dropdown_table,id scoped by key | "Please select a submission type." |
| BC-VAL-10 | is_gradable | boolean | — |
| BC-VAL-11 | max_marks | required_if:is_gradable,1, numeric, min:0, max:999.99 | — |
| BC-VAL-12 | passing_marks | required_if:is_gradable,1, numeric, min:0, max:999.99, lte:max_marks | "Passing marks must be less than or equal to maximum marks." |
| BC-VAL-13 | difficulty_level_id | nullable, exists:slb_complexity_level,id | — |
| BC-VAL-14 | assign_date | required, date, after_or_equal:today (if changed on update) | "Assign date is required." |
| BC-VAL-15 | due_date | required, date, after:assign_date | "Due date must be after assign date." |
| BC-VAL-16 | allow_late_submission | boolean | — |
| BC-VAL-17 | auto_publish_score | boolean | — |
| BC-VAL-18 | release_condition | required, in:IMMEDIATE,ON_TOPIC_COMPLETE,ON_SCHEDULED_DATE | — |
| BC-VAL-19 | release_scheduled_date | required_if:release_condition,ON_SCHEDULED_DATE, nullable, date, after_or_equal:assign_date | "The release scheduled date is required when the release condition is set to scheduled date." |
| BC-VAL-20 | status_id | required, exists:sys_dropdown_table,id scoped by key | — |
| BC-VAL-21 | is_active | boolean | — |
| BC-VAL-22 | hw_attachments.* | file, max:10240, mimes:pdf,doc,docx,txt,jpg,jpeg,png,zip | "The file may not be greater than 10240 kilobytes." |

### 5.3 Validation Rules — `HomeworkRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | assign_date | If changed, must be after_or_equal:today | Prevents backdating |
| BC-VAL-U02 | passing_marks | Still checked against max_marks | Same as create |
| BC-VAL-U03 | Status only changes via publish/archive | Status field preserved; controller enforces rules | — |

### 5.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.home-work.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.home-work.create | create(), store() | Without → 403 |
| BC-AUTH-03 | tenant.home-work.view | show() | Without → 403 |
| BC-AUTH-04 | tenant.home-work.update | edit(), update(), toggleStatus(), publish(), clone() | Without → 403 |
| BC-AUTH-05 | tenant.home-work.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.home-work.restore | trashed(), restore() | Without → 403 |
| BC-AUTH-07 | tenant.home-work.forceDelete | forceDelete() | Without → 403 |

### 5.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Store sets status to DRAFT | On create, `status_id` is forced to DRAFT dropdown value |
| BC-BIZ-02 | Only Draft homework editable | `isEditable()` checks if status value === 'draft' |
| BC-BIZ-03 | Publishing creates assignments | `publish()` creates one `HomeworkAssignment` per enrolled student |
| BC-BIZ-04 | Publishing is idempotent | Re-publishing does not create duplicate assignments |
| BC-BIZ-05 | Cannot delete with submissions | `isDeletable()` checks `submission_count == 0` |
| BC-BIZ-06 | Clone creates new Draft | `clone()` copies all fields to target section as Draft |
| BC-BIZ-07 | Clone section must be different | Cannot clone to the same section |
| BC-BIZ-08 | Soft delete sets is_active=false | Controller flips `is_active` to 0 before `delete()` |
| BC-BIZ-09 | Restore sets is_active=true | After restore, `is_active` set back to 1 |
| BC-BIZ-10 | Due date must be after assign date | Validation: `after:assign_date` |
| BC-BIZ-11 | Passing marks <= Max marks | Custom validation rule |
| BC-BIZ-12 | Activity logging on all CRUD | Stored, Updated, Trashed, Restored, Deleted logged |
| BC-BIZ-13 | Attachment sync on create/update | `syncHomeworkAttachments()` handles file uploads and removals |
| BC-BIZ-14 | Academic session auto-set | Current session used; error if not set |
| BC-BIZ-15 | Release condition ENUM | Only IMMEDIATE, ON_TOPIC_COMPLETE, ON_SCHEDULED_DATE allowed |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | academic_session_id | sch_org_academic_sessions_jnt | RESTRICT |
| BC-REF-02 | class_id | sch_classes | RESTRICT |
| BC-REF-03 | section_id | sch_sections | SET NULL |
| BC-REF-04 | subject_id | sch_subjects | RESTRICT |
| BC-REF-05 | lesson_id | slb_lessons | SET NULL |
| BC-REF-06 | topic_id | slb_topics | SET NULL |
| BC-REF-07 | schedule_id | slb_syllabus_schedule | SET NULL |
| BC-REF-08 | submission_type_id | sys_dropdown_table | RESTRICT |
| BC-REF-09 | difficulty_level_id | slb_complexity_level | SET NULL |
| BC-REF-10 | status_id | sys_dropdown_table | RESTRICT |
| BC-REF-11 | created_by | sys_users | RESTRICT |
| BC-REF-12 | updated_by | sys_users | SET NULL |

### 5.7 DDL Conditions

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-CON-01 | release_condition = ON_SCHEDULED_DATE requires release_scheduled_date | App must enforce release_scheduled_date is required when release_condition = ON_SCHEDULED_DATE |
| BC-CON-02 | release_condition = ON_TOPIC_COMPLETE requires schedule_id | App must enforce schedule_id is required when release_condition = ON_TOPIC_COMPLETE |
| BC-CON-03 | is_gradable = 1 requires max_marks and passing_marks | max_marks and passing_marks are required when is_gradable = 1 |
| BC-CON-04 | passing_marks must be <= max_marks | App must enforce passing_marks cannot exceed max_marks |
| BC-CON-05 | DRAFT → PUBLISHED triggers bulk assignment creation | App bulk-creates lms_homework_assignment rows for all active students in the class+section+subject |
| BC-CON-06 | allow_late_submission is default for all students | Per-student override in lms_homework_assignment takes precedence |
| BC-CON-07 | schedule_id topic completion triggers auto-release | When linked schedule topic is completed, app sets is_released=1 for matching assignments |
| BC-CON-08 | release_condition = IMMEDIATE releases on publish | Assignments created with is_released=1, status=ASSIGNED immediately |
| BC-CON-09 | release_condition = ON_SCHEDULED_DATE releases on scheduled date | Assignments created with is_released=0, released when scheduled date arrives (batch job) |
| BC-CON-10 | release_condition = ON_TOPIC_COMPLETE releases on topic completion | Assignments created with is_released=0, released when teacher marks topic completed |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Homework List Loads With All UI Elements | Page loads with search bar, class filter, subject filter, Add Homework button, paginated table | — | — | ⬜ |
| TC-P02 | Create Homework With All Required Fields | Homework created with class, subject, title, description, submission_type, assign_date, due_date, release_condition, status | — | — | ⬜ |
| TC-P03 | Create Homework With Gradable + Marks | `is_gradable=true`, `max_marks=20`, `passing_marks=10` saved correctly | — | — | ⬜ |
| TC-P04 | Create Homework With Non-Gradable | `is_gradable=false`, max_marks and passing_marks nullable | — | — | ⬜ |
| TC-P05 | Create Homework With Scheduled Release | `release_condition=ON_SCHEDULED_DATE` with valid `release_scheduled_date` | — | — | ⬜ |
| TC-P06 | Create Homework With Topic Release | `release_condition=ON_TOPIC_COMPLETE` with `schedule_id` set | — | — | ⬜ |
| TC-P07 | Create Homework With All Optional Fields | Section, lesson, topic, difficulty_level_id, attachments, auto_publish_score all saved | — | — | ⬜ |
| TC-P08 | Create Homework With File Attachments | PDF/DOCX files uploaded and stored via Spatie Media/JSON; accessible on edit | — | — | ⬜ |
| TC-P09 | Create Homework Sets Status To Draft | New homework always saved with DRAFT status regardless of status_id input | — | — | ⬜ |
| TC-P10 | Create Homework Auto-Sets Academic Session | Current `is_current=1` session used; saved in `academic_session_id` | — | — | ⬜ |
| TC-P11 | Edit Homework Loads Pre-Filled Data | Edit form shows existing values for all fields; attachments listed | — | — | ⬜ |
| TC-P12 | Update Homework Title, Description, Dates | Title, description, assign_date, due_date updated successfully | — | — | ⬜ |
| TC-P13 | Update Homework From Non-Gradable To Gradable | `is_gradable` toggled, max_marks and passing_marks now required | — | — | ⬜ |
| TC-P14 | Update Homework Attachments — Add New Files | New files uploaded; old files preserved | — | — | ⬜ |
| TC-P15 | Update Homework Attachments — Remove Existing | Existing files removed; new files retained | — | — | ⬜ |
| TC-P16 | View Homework Details Page | All fields displayed: title, description, class, subject, dates, marks, status, attachments | — | — | ⬜ |
| TC-P17 | Publish Homework Creates Assignments | Click Publish on Draft; assignments created for all enrolled students; status changes to Published | — | — | ⬜ |
| TC-P18 | Re-Publish Is Idempotent | Click Publish again; no duplicate assignments; success message with count | — | — | ⬜ |
| TC-P19 | Clone Homework To Another Section | Clone to different section; new Draft created with same fields; original unchanged | — | — | ⬜ |
| TC-P20 | Toggle Status Active/Inactive | AJAX toggle flips `is_active`; JSON 200 success | — | — | ⬜ |
| TC-P21 | Soft Delete Homework (No Submissions) | `deleted_at` set; `is_active=false`; removed from list | — | — | ⬜ |
| TC-P22 | Trash Page Shows Deleted Homework | Trash page lists soft-deleted homework with restore + force delete buttons | — | — | ⬜ |
| TC-P23 | Restore Homework From Trash | `deleted_at=NULL`; `is_active=true`; visible in list again | — | — | ⬜ |
| TC-P24 | Force Delete Homework (Permanent) | Record permanently removed from DB; activity logged | — | — | ⬜ |
| TC-P25 | Filter Homework By Class | Selecting class filters list to show only that class's homework | — | — | ⬜ |
| TC-P26 | Filter Homework By Subject | Selecting subject filters list to show only that subject's homework | — | — | ⬜ |
| TC-P27 | Search Homework By Title | Typing title in search box finds matching homework | — | — | ⬜ |
| TC-P28 | Search Homework By Description | Typing description text finds matching homework | — | — | ⬜ |
| TC-P29 | Full Lifecycle: Create → Edit → Publish → Clone → Toggle → Delete → Trash → Restore | All transitions successful; activity logged at each step | — | — | ⬜ |
| TC-P30 | Empty State — No Homework For Filter | Table shows "No records found" when no homework match | — | — | ⬜ |
| TC-P31 | Filter Homework By Section | Selecting section filters list to show only that section's homework | — | — | ⬜ |
| TC-P32 | Filter Homework By Date Range | Selecting from/to dates filters list to show homework within date range | — | — | ⬜ |
| TC-P33 | Filter Homework By Active/Inactive Status | Selecting Active/Inactive/All toggles grid to show matching homework | — | — | ⬜ |
| TC-P34 | Create Homework With Rich Text Description | Description with bold, bullet points, formatted text saved correctly and rendered as HTML | — | — | ⬜ |
| TC-P35 | Create Homework With allow_late_submission=true | Homework created with allow_late_submission=1; field saved as true in DB | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `class_id` | "Please select a class." | — | — | ⬜ |
| TC-N02 | Required — Missing `subject_id` | "Please select a subject." | — | — | ⬜ |
| TC-N03 | Required — Missing `title` | "The homework title is required." | — | — | ⬜ |
| TC-N04 | Required — Missing `description` | "Please provide a description." | — | — | ⬜ |
| TC-N05 | Required — Missing `submission_type_id` | "Please select a submission type." | — | — | ⬜ |
| TC-N06 | Required — Missing `assign_date` | "Assign date is required." | — | — | ⬜ |
| TC-N07 | Required — Missing `due_date` | "Due date is required." | — | — | ⬜ |
| TC-N08 | Due Date Before Assign Date | "Due date must be after assign date." | — | — | ⬜ |
| TC-N09 | Passing Marks > Max Marks | "Passing marks must be less than or equal to maximum marks." | — | — | ⬜ |
| TC-N10 | Missing `release_scheduled_date` when ON_SCHEDULED_DATE | "The release scheduled date is required when the release condition is set to scheduled date." | — | — | ⬜ |
| TC-N11 | Release Scheduled Date Before Assign Date | "The release scheduled date must be after or equal to the assign date." | — | — | ⬜ |
| TC-N12 | Max Length — Title > 255 Characters | Validation fails on title.max | — | — | ⬜ |
| TC-N13 | Max Marks > 999.99 | Validation fails on max_marks.max | — | — | ⬜ |
| TC-N14 | Invalid FK — Non-Existent `class_id` | Validation error on class_id.exists | — | — | ⬜ |
| TC-N15 | Invalid FK — Non-Existent `subject_id` | Validation error on subject_id.exists | — | — | ⬜ |
| TC-N16 | Invalid FK — Non-Existent `submission_type_id` | Validation error on submission_type_id.exists | — | — | ⬜ |
| TC-N17 | Invalid Release Condition Value | Validation error on release_condition.in | — | — | ⬜ |
| TC-N18 | File Upload — Invalid Type (.exe) | "The file must be a file of type: pdf, doc, docx, txt, jpg, jpeg, png, zip." | — | — | ⬜ |
| TC-N19 | File Upload — Exceeds 10MB | "The file may not be greater than 10240 kilobytes." | — | — | ⬜ |
| TC-N20 | Publish Already Published Homework | "Only draft homework can be published." | — | — | ⬜ |
| TC-N21 | Delete Homework With Existing Submissions | "Cannot delete homework with existing submissions." | — | — | ⬜ |
| TC-N22 | Clone To Same Section | "Clone target must be a different section of the same class." | — | — | ⬜ |
| TC-N23 | Edit Published Homework | Edit button hidden; direct URL access shows 403 or prevents save | — | — | ⬜ |
| TC-N24 | View Invalid ID (404) | `/lms-home-work/home-works/99999` returns HTTP 404 | — | — | ⬜ |
| TC-N25 | Edit Invalid ID (404) | `/lms-home-work/home-works/99999/edit` returns HTTP 404 | — | — | ⬜ |
| TC-N26 | Permission 403 — No Homework Permissions | User without `tenant.home-work.*` sees 403 on all CRUD endpoints | — | — | ⬜ |
| TC-N27 | Guest Access Redirect | Logged-out user redirected to /login for all homework routes | — | — | ⬜ |
| TC-N28 | XSS Injection In Title | Stored as literal string; Blade `{{ }}` escapes output; no script execution | — | — | ⬜ |
| TC-N29 | Restore Non-Deleted Homework | `onlyTrashed()->find()` returns null → 404 | — | — | ⬜ |
| TC-N30 | Force Delete Non-Trashed Homework | `onlyTrashed()->find()` returns null → 404 | — | — | ⬜ |
| TC-N31 | No Active Academic Session Set | "Current Academic Session is not set." error on store | — | — | ⬜ |
| TC-N32 | Assign Date Backdated On Update | If assign_date changed, new date must be >= today | — | — | ⬜ |
| TC-N33 | View-Only User Can View But Cannot Create/Edit/Delete | User with only viewAny+view can see list/view but gets 403 on create/update/delete | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create → Status forced to DRAFT | DB check: status_id maps to dropdown value 'DRAFT' | — | — | ⬜ |
| TC-D02 | A | Create → Academic session auto-set | `academic_session_id` = current session's ID | — | — | ⬜ |
| TC-D03 | B | Publish → Assignments created per student | `lms_homework_assignment` count = enrolled student count | — | — | ⬜ |
| TC-D04 | B | Publish → Homework status changes to PUBLISHED | `status_id` maps to dropdown value 'PUBLISHED' | — | — | ⬜ |
| TC-D05 | C | Clone → New Draft created with same fields | Clone has same title, description, marks, dates; status=DRAFT; different section_id | — | — | ⬜ |
| TC-D06 | D | Soft delete → is_active set to false | `SELECT is_active FROM lms_homework WHERE id={id}` = 0 | — | — | ⬜ |
| TC-D07 | D | Soft delete → deleted_at set | `deleted_at` IS NOT NULL | — | — | ⬜ |
| TC-D08 | E | Restore → is_active set to true | `is_active` = 1 after restore | — | — | ⬜ |
| TC-D09 | F | Clone → Attachments copied | Attachment files/media copied to new homework | — | — | ⬜ |
| TC-D10 | G | Toggle → is_active flips | AJAX response contains `is_active` = opposite of previous | — | — | ⬜ |
| TC-D11 | H | Activity Log — All CRUD events tracked | Stored, Updated, Trashed, Restored, Deleted events in `activity_log` table | — | — | ⬜ |
| TC-D12 | I | ForceDelete → Assignments and Submissions cascade | Related assignments and submissions also permanently deleted | — | — | ⬜ |
| TC-D13 | J | `is_gradable` cast as boolean | DB stores 0/1; model returns `true`/`false` | — | — | ⬜ |
| TC-D14 | K | `max_marks` and `passing_marks` decimal precision | Stored as DECIMAL(5,2); values like 99.99 saved correctly | — | — | ⬜ |
| TC-D15 | L | `assign_date` and `due_date` datetime casting | Stored as DATETIME; model returns Carbon instance | — | — | ⬜ |
| TC-D16 | M | `findOrFail` — non-existent ID returns 404 | All controller methods (edit, update, show, destroy) return HTTP 404 | — | — | ⬜ |
| TC-D17 | N | `Gate::authorize` before controller actions | Each method gates appropriate permission string; missing permission → 403 | — | — | ⬜ |
| TC-D18 | O | Model mass assignment — fillable guarded | Non-fillable attributes (id, created_at, etc.) silently ignored on create | — | — | ⬜ |
| TC-D19 | P | Create → created_by set to auth user | `created_by` = current authenticated user's ID after store | — | — | ⬜ |
| TC-D20 | Q | ON DELETE RESTRICT — FK parent delete rejected | Deleting a class/subject/session used by homework returns DB FK error | — | — | ⬜ |
| TC-D21 | R | ON DELETE SET NULL — section/lesson/topic/schedule set to NULL on parent delete | Delete section → homework.section_id becomes NULL; delete lesson → homework.lesson_id becomes NULL | — | — | ⬜ |
| TC-D22 | S | ENUM validation — invalid release_condition rejected at DB | INSERT with release_condition='INVALID' → DB error | — | — | ⬜ |
| TC-D23 | T | DEFAULT values applied on insert | New homework has is_gradable=1, is_active=1, allow_late_submission=0, auto_publish_score=0 by default | — | — | ⬜ |
| TC-D24 | U | INDEX exists for query performance | EXPLAIN SELECT on class_id+subject_id, status_id, assign_date, due_date shows index usage | — | — | ⬜ |
| TC-D25 | V | BC-CON-02 — schedule_id required when ON_TOPIC_COMPLETE | Create homework with release_condition=ON_TOPIC_COMPLETE without schedule_id → app validation error | — | — | ⬜ |
| TC-D26 | W | BC-CON-06 — allow_late_submission inheritance | Set homework.allow_late_submission=0; student override to 1 takes precedence via assignment record | — | — | ⬜ |
| TC-D27 | X | BC-CON-07 — topic completion triggers auto-release | Mark slb_syllabus_schedule topic as completed → linked ON_TOPIC_COMPLETE homework assignments released | — | — | ⬜ |
| TC-D28 | Y | Syllabus Mark Done → Observer releases ON_TOPIC_COMPLETE homework | POST to syllabus-schedule/{id}/mark-complete → observer flips pending releases to is_released=1, sends notifications | — | — | ⬜ |
| TC-D29 | Z | `tenant:homework:release-scheduled` cron releases ON_SCHEDULED_DATE homework | Run `Artisan::call('tenant:homework:release-scheduled')` → pending scheduled homework assignments get is_released=1 | — | — | ⬜ |
| TC-D30 | AA | `tenant:syllabus:release-resources` cron releases by configured syllabus level | Run cron → SchConfig level-matched schedules trigger homework assignment release | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can checks for create, view, update, delete, restore, forceDelete | — | — | ◌ |
| TC-CR02 | CR | P1 | DB Transactions in store/update/publish | `store()` wraps create + attachment sync in `DB::transaction()` | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller exception handling with try-catch | Store and update use try-catch; errors returned with `withErrors()` | — | — | ◌ |
| TC-CR04 | CR | P1 | View — isset()/null-safe checks for relationships | Blade expressions use `$record?->relation?->field` to avoid undefined errors | — | — | ◌ |
| TC-CR05 | CR | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | `lms-home-work.home-works.*` keys defined in breadcrumb config | — | — | ◌ |
| TC-CR06 | CR | P1 | Activity logging after CRUD | Every create/update/delete/restore calls `activityLog()` | — | — | ◌ |
| TC-CR07 | CR | P1 | Hub page tab integration — each tab loads with correct permission | @can('tenant.home-work.*.viewAny') wraps each tab; default tab = homework_analytics | — | — | ◌ |
| TC-CR08 | CR | P1 | Tab persistence on create/edit redirect | After create/edit, redirect includes ?tab=home_work | — | — | ◌ |
| TC-CR09 | CR | P1 | SyllabusScheduleObserver registered in LmsHomework EventServiceProvider | `$observers = [SyllabusSchedule::class => SyllabusScheduleObserver::class]` defined | — | — | ◌ |
| TC-CR10 | CR | P1 | Observer matches homework by topic_id + section_id for ON_TOPIC_COMPLETE | `updated()` checks `isDirty('is_completed')`; queries Homework where `topic_id`, `section_id`, `release_condition='ON_TOPIC_COMPLETE'` | — | — | ◌ |
| TC-CR11 | CR | P1 | `tenant:homework:release-scheduled` command registered in console.php | `Schedule::command('tenant:homework:release-scheduled')->everyMinute()` present | — | — | ◌ |
| TC-CR12 | CR | P1 | `tenant:syllabus:release-resources` command registered in console.php | `Schedule::command('tenant:syllabus:release-resources')->everyFiveMinutes()` present | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-P02: Create Homework With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to LMS → Homework → Homework tab | Homework list loads |
| 3 | Click "Add Homework" button | Create form loads with dropdowns populated |
| 4 | Select Class from dropdown | Class selected |
| 5 | Select Subject from dropdown | Subject selected |
| 6 | Enter title: "Chapter 5 Test Homework" | Title filled |
| 7 | Enter description: "Complete all questions" | Description filled |
| 8 | Select Submission Type: "Text" | Type selected |
| 9 | Set Assign Date: tomorrow | Date set |
| 10 | Set Due Date: 7 days from assign date | Date set |
| 11 | Select Release Condition: "Immediate" | Condition set |
| 12 | Select Status: "Draft" | Status set (overridden to DRAFT by controller) |
| 13 | Click "Save" | POST to store(); redirects to list |
| 14 | Verify success message | Flash message shown |
| 15 | DB check: `SELECT * FROM lms_homework WHERE title='Chapter 5 Test Homework'` | Record exists; `status_id` = DRAFT value; `academic_session_id` set |

#### TC-P17: Publish Homework Creates Assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Draft homework for Class 8-A (35 enrolled students) | Homework exists with DRAFT status |
| 2 | Click "Publish" button on that homework | Confirmation dialog: "Publish Homework? This will create assignments..." |
| 3 | Click "Yes" to confirm | POST to `/lms-home-work/home-works/{id}/publish` |
| 4 | Check success message | "Homework published successfully! 35 assignments created." |
| 5 | DB check: `SELECT COUNT(*) FROM lms_homework_assignment WHERE homework_id={id}` | Count = 35 (one per student) |
| 6 | DB check: `SELECT status_id FROM lms_homework WHERE id={id}` | Status changed to PUBLISHED |
| 7 | Verify list shows homework with "Published" badge | Badge visible |

#### TC-N20: Publish Already Published Homework

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Follow TC-P17 to publish a homework | Homework is Published |
| 2 | Click "Publish" again on same homework | Server rejects: "Only draft homework can be published." |
| 3 | DB check: No duplicate assignments | Assignment count unchanged |

#### TC-D03: Publish → Assignments Created Per Student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure Class 8-A has 35 active enrolled students | Students exist |
| 2 | Create and publish homework for Class 8-A | Published |
| 3 | DB check: `SELECT COUNT(*) FROM lms_homework_assignment WHERE homework_id={id}` | 35 records |
| 4 | DB check: Each record has correct student_id, homework_id, class_id, section_id | All fields match |
| 5 | Add 2 new students to Class 8-A | 37 total |
| 6 | Click Publish again | Idempotent — no duplicates; 2 new assignments created |
| 7 | DB check: `COUNT(*)` now = 37 | Correct |

#### TC-P01: Homework List Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to LMS → Homework → Homework tab | Homework list loads |
| 3 | Verify search bar is visible | Search input displayed |
| 4 | Verify class filter dropdown is present | Class dropdown visible |
| 5 | Verify subject filter dropdown is present | Subject dropdown visible |
| 6 | Verify "Add Homework" button is present | Button visible |
| 7 | Verify paginated table is displayed | Table with columns (Title, Class, Subject, Due Date, Status, Actions) present |

#### TC-P03: Create Homework With Gradable + Marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Fill all required fields (class, subject, title, description, submission_type, assign_date, due_date, release_condition) | Fields filled |
| 4 | Set is_gradable = Yes | Max marks and Passing marks fields appear |
| 5 | Enter max_marks = 20, passing_marks = 10 | Values entered |
| 6 | Click "Save" | Homework created |
| 7 | DB check: `is_gradable=1`, `max_marks=20.00`, `passing_marks=10.00` | Values saved correctly |

#### TC-P04: Create Homework With Non-Gradable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Fill all required fields | Fields filled |
| 4 | Set is_gradable = No | Max marks and Passing marks fields hidden/disabled |
| 5 | Click "Save" | Homework created |
| 6 | DB check: `is_gradable=0`, `max_marks=NULL`, `passing_marks=NULL` | Values saved correctly |

#### TC-P05: Create Homework With Scheduled Release

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Fill all required fields | Fields filled |
| 4 | Set Release Condition = "On Scheduled Date" | Release scheduled date field appears |
| 5 | Set release_scheduled_date to a future date after assign_date | Date selected |
| 6 | Click "Save" | Homework created |
| 7 | DB check: `release_condition='ON_SCHEDULED_DATE'`, `release_scheduled_date` set correctly | Values saved |

#### TC-P06: Create Homework With Topic Release

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Select a Class → a Subject → a Lesson | Lesson loaded |
| 4 | Select a Topic (schedule_id) | Topic selected |
| 5 | Set Release Condition = "On Topic Complete" | Release condition set |
| 6 | Fill remaining required fields | Fields filled |
| 7 | Click "Save" | Homework created |
| 8 | DB check: `release_condition='ON_TOPIC_COMPLETE'`, `schedule_id` set | Values saved correctly |

#### TC-P07: Create Homework With All Optional Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Select Class, Subject, Section, Lesson, Topic | All selections populated |
| 4 | Select Difficulty Level | Level selected |
| 5 | Enable auto_publish_score | Toggle ON |
| 6 | Fill title, description, submission_type, dates, release_condition | All filled |
| 7 | Upload an attachment file | File uploaded |
| 8 | Click "Save" | Homework created |
| 9 | DB check: All optional fields including section_id, lesson_id, topic_id, difficulty_level_id saved | All values present |

#### TC-P08: Create Homework With File Attachments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Fill all required fields | Fields filled |
| 4 | Upload a PDF file (2MB) | File uploaded successfully |
| 5 | Upload a DOCX file (3MB) | File uploaded successfully |
| 6 | Upload a JPG image (1MB) | File uploaded successfully |
| 7 | Click "Save" | Homework created |
| 8 | Navigate to edit form | Files listed as attached |
| 9 | DB/Media check: Files stored via Spatie Media or JSON column | Attachments accessible |

#### TC-P09: Create Homework Sets Status To Draft

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Fill all required fields; explicitly select Status = "Published" from dropdown | Status set to Published in UI |
| 4 | Click "Save" | Homework created |
| 5 | DB check: `SELECT status_id FROM lms_homework WHERE id={id}` | Status maps to 'DRAFT' dropdown value regardless of input |
| 6 | Verify list shows homework with "Draft" badge | Draft badge visible |

#### TC-P10: Create Homework Auto-Sets Academic Session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure one academic session has `is_current=1` | Current session exists |
| 2 | Login as admin/teacher | Dashboard loads |
| 3 | Create a new homework with all required fields | Homework created |
| 4 | DB check: `academic_session_id` in `lms_homework` | Equals the current session's ID |
| 5 | Set a different session as current, create another homework | New homework gets new session ID |

#### TC-P11: Edit Homework Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Click "Edit" on an existing Draft homework | Edit form loads |
| 3 | Verify title field shows existing value | Title pre-filled |
| 4 | Verify description field shows existing value | Description pre-filled |
| 5 | Verify class, subject, section dropdowns show correct selections | Selections match saved data |
| 6 | Verify dates display correctly | Assign date and due date filled |
| 7 | Verify attached files are listed | Attachments shown with remove option |

#### TC-P12: Update Homework Title, Description, Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Edit an existing Draft homework | Edit form loads |
| 3 | Change title to "Updated Homework Title" | Title updated |
| 4 | Change description to "Updated description" | Description updated |
| 5 | Change assign_date to +2 days, due_date to +9 days | Dates updated |
| 6 | Click "Update" | PUT request sent |
| 7 | DB check: title, description, assign_date, due_date updated | All changes saved |

#### TC-P13: Update Homework From Non-Gradable To Gradable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with is_gradable = No | Non-gradable homework exists |
| 2 | Login as admin/teacher | Dashboard loads |
| 3 | Edit the non-gradable homework | Edit form loads; max_marks fields hidden |
| 4 | Set is_gradable = Yes | Max marks and Passing marks fields appear, marked required |
| 5 | Enter max_marks = 50, passing_marks = 25 | Values entered |
| 6 | Click "Update" | Homework updated |
| 7 | DB check: `is_gradable=1`, `max_marks=50.00`, `passing_marks=25.00` | Values saved |

#### TC-P14: Update Homework Attachments — Add New Files

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with 2 attached files | Homework with existing files |
| 2 | Login as admin/teacher | Dashboard loads |
| 3 | Edit the homework | Existing files listed |
| 4 | Upload 2 new files (PDF + JPG) | New files uploaded |
| 5 | Click "Update" | Homework updated |
| 6 | Verify edit form shows all 4 files | 2 old + 2 new files retained |

#### TC-P15: Update Homework Attachments — Remove Existing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with 3 attached files | Homework with 3 files |
| 2 | Login as admin/teacher | Dashboard loads |
| 3 | Edit the homework | 3 files listed with remove buttons |
| 4 | Click "Remove" on first file | File marked for deletion |
| 5 | Upload 1 new file | New file added |
| 6 | Click "Update" | Homework updated |
| 7 | Verify: removed file gone, new file present, remaining 2 old files retained | Correct file state |

#### TC-P16: View Homework Details Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Click on a homework title in the list | Show page loads |
| 3 | Verify title displayed | Title visible |
| 4 | Verify description displayed | Description visible |
| 5 | Verify class, subject, section labels | Labels correct |
| 6 | Verify assign date, due date displayed | Dates formatted correctly |
| 7 | Verify is_gradable, max_marks, passing_marks (if gradable) | Marks displayed |
| 8 | Verify status badge and attachment links | Status + attachments visible |
| 9 | Verify action buttons (Edit, Publish, Delete, etc.) shown per permissions | Buttons visible |

#### TC-P18: Re-Publish Is Idempotent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Follow TC-P17 to publish homework for Class 8-A | Homework is Published with 35 assignments |
| 2 | Enroll 2 more students | 37 total enrolled |
| 3 | Click "Publish" again | Request succeeds |
| 4 | Verify success message | "Homework published successfully! 2 assignments created." |
| 5 | DB check: `SELECT COUNT(*) FROM lms_homework_assignment WHERE homework_id={id}` | Count = 37 (no duplicates) |
| 6 | DB check: No duplicate (student_id, homework_id) pairs | All unique |

#### TC-P19: Clone Homework To Another Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Draft homework for Class 8, Section A | Source homework exists |
| 2 | Login as admin/teacher | Dashboard loads |
| 3 | Click "Clone" button on the homework | Modal/dropdown shows section selector |
| 4 | Select "Section B" (different section, same class) | Target selected |
| 5 | Click "Clone" | POST to clone() |
| 6 | Verify success message | "Homework cloned successfully!" |
| 7 | Verify new homework in list with "(Clone)" suffix or note | New Draft appears |
| 8 | DB check: New record has same title, description, marks, dates; different section_id; status = DRAFT | Clone correct |

#### TC-P20: Toggle Status Active/Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Locate an active homework in the list | Row visible |
| 3 | Click the toggle status button/icon | AJAX POST to toggleStatus() |
| 4 | Verify JSON response | `{"status":200,"is_active":0}` |
| 5 | Verify row now shows "Inactive" badge | Badge updated |
| 6 | Click toggle again | `is_active` flips back to 1 |
| 7 | DB check: `is_active` value alternates | Correct |

#### TC-P21: Soft Delete Homework (No Submissions)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Draft homework with 0 submissions | Deletable homework |
| 2 | Login as admin/teacher | Dashboard loads |
| 3 | Click "Delete" button on that homework | Confirmation dialog appears |
| 4 | Confirm deletion | POST to destroy() |
| 5 | Verify success message | "Homework deleted successfully!" |
| 6 | Verify homework removed from active list | Record hidden |
| 7 | DB check: `deleted_at` IS NOT NULL, `is_active=0` | Soft deleted |

#### TC-P22: Trash Page Shows Deleted Homework

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Follow TC-P21 to soft delete 2 homework records | 2 records in trash |
| 2 | Login as admin/teacher | Dashboard loads |
| 3 | Navigate to "Trash" tab/view | Trash page loads |
| 4 | Verify deleted homework records listed | Both records visible |
| 5 | Verify "Restore" button present per record | Restore button visible |
| 6 | Verify "Force Delete" button present per record | Force delete button visible |

#### TC-P23: Restore Homework From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Follow TC-P21 to soft delete a homework | Deleted homework exists |
| 2 | Login as admin/teacher | Dashboard loads |
| 3 | Navigate to Trash page | Trash loads |
| 4 | Click "Restore" on the deleted homework | POST to restore() |
| 5 | Verify success message | "Homework restored successfully!" |
| 6 | Verify homework visible in active list again | Restored record appears |
| 7 | DB check: `deleted_at=NULL`, `is_active=1` | Restored correctly |

#### TC-P24: Force Delete Homework (Permanent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Follow TC-P21 to soft delete a homework | Deleted homework exists |
| 2 | Login as admin/teacher | Dashboard loads |
| 3 | Navigate to Trash page | Trash loads |
| 4 | Click "Force Delete" on the deleted homework | Confirmation: "Permanently delete?" |
| 5 | Confirm | DELETE to forceDelete() |
| 6 | Verify success message | "Homework permanently deleted!" |
| 7 | DB check: `SELECT * FROM lms_homework WHERE id={id}` | No record found (permanently removed) |

#### TC-P25: Filter Homework By Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework list | List loads with all classes |
| 3 | Select a specific class from the class filter dropdown | Page reloads with filtered results |
| 4 | Verify table only shows homework for selected class | No other class's homework visible |
| 5 | Clear filter | All records shown again |

#### TC-P26: Filter Homework By Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework list | List loads |
| 3 | Select a specific subject from the subject filter dropdown | Page reloads with filtered results |
| 4 | Verify table only shows homework for selected subject | No other subject's homework visible |
| 5 | Clear filter | All records shown again |

#### TC-P27: Search Homework By Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework list | List loads |
| 3 | Type a unique title keyword in search box | List filters as you type |
| 4 | Verify table shows only matching homework | Only records with keyword in title shown |
| 5 | Verify non-matching records excluded | Correct filtering |

#### TC-P28: Search Homework By Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework list | List loads |
| 3 | Type a keyword found only in a homework's description | Search returns results |
| 4 | Verify matching homework displayed | Description-based match works |
| 5 | Clear search | Full list restored |

#### TC-P29: Full Lifecycle: Create → Edit → Publish → Clone → Toggle → Delete → Trash → Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Create homework with all required fields | Homework created with Draft status |
| 3 | Edit the homework title and description | Updated successfully |
| 4 | Publish the homework | Assignments created; status changes to Published |
| 5 | Clone the homework to a different section | New Draft cloned copy created |
| 6 | Toggle the cloned homework's status inactive then active | is_active flips correctly |
| 7 | Delete the cloned homework (soft) | Moves to trash |
| 8 | Restore the deleted homework | Back in active list; is_active=1 |
| 9 | Verify activity log for each transition | All events (Stored, Updated, Published, Cloned, Trashed, Restored) logged |

#### TC-P30: Empty State — No Homework For Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework list | List loads |
| 3 | Select a class that has no homework assigned | Filter applied |
| 4 | Verify empty state message | "No records found" displayed |
| 5 | Verify table shows empty row or message without error | Graceful empty state |

#### TC-P31: Filter Homework By Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework list | List loads with all sections |
| 3 | Select a specific section from the section filter dropdown | Page reloads with filtered results |
| 4 | Verify table only shows homework for selected section | No other section's homework visible |
| 5 | Clear filter | All records shown again |

#### TC-P32: Filter Homework By Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework list | List loads |
| 3 | Enter a from_date and to_date in the date range filter | Page reloads with filtered results |
| 4 | Verify table only shows homework with due_date within range | All displayed homework has due_date between from_date and to_date |
| 5 | Clear date range filter | All records shown again |

#### TC-P33: Filter Homework By Active/Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework list | List loads |
| 3 | Select "Active" from status filter dropdown | Grid shows only active (is_active=1) homework |
| 4 | Select "Inactive" from status filter dropdown | Grid shows only inactive (is_active=0) homework |
| 5 | Select "All" to clear filter | All homework shown regardless of status |

#### TC-P34: Create Homework With Rich Text Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Fill all required fields | Fields filled |
| 4 | Enter description with rich text: bold text, bullet list items using the rich text editor | Formatted content visible in editor |
| 5 | Click "Save" | Homework created |
| 6 | DB check: `SELECT description FROM lms_homework WHERE id={id}` | Description stored as HTML string with tags preserved |
| 7 | View the homework show page | Rich text rendered correctly (bold text, bullet list displayed) |

#### TC-P35: Create Homework With allow_late_submission=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Fill all required fields | Fields filled |
| 4 | Set allow_late_submission toggle to "Yes" | Toggle set to true |
| 5 | Click "Save" | Homework created |
| 6 | DB check: `SELECT allow_late_submission FROM lms_homework WHERE id={id}` | allow_late_submission = 1 (true) |

#### TC-N01: Required — Missing `class_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Leave class dropdown unselected | Class not selected |
| 4 | Fill all other required fields | Other fields filled |
| 5 | Click "Save" | Validation error |
| 6 | Verify error message | "Please select a class." displayed |

#### TC-N02: Required — Missing `subject_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Select class, leave subject unselected | Subject not selected |
| 4 | Fill all other required fields | Other fields filled |
| 5 | Click "Save" | Validation error |
| 6 | Verify error message | "Please select a subject." displayed |

#### TC-N03: Required — Missing `title`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Leave title field empty | Title blank |
| 4 | Fill all other required fields | Other fields filled |
| 5 | Click "Save" | Validation error |
| 6 | Verify error message | "The homework title is required." displayed |

#### TC-N04: Required — Missing `description`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Leave description field empty | Description blank |
| 4 | Fill all other required fields | Other fields filled |
| 5 | Click "Save" | Validation error |
| 6 | Verify error message | "Please provide a description." displayed |

#### TC-N05: Required — Missing `submission_type_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Leave submission type unselected | Submission type not selected |
| 4 | Fill all other required fields | Other fields filled |
| 5 | Click "Save" | Validation error |
| 6 | Verify error message | "Please select a submission type." displayed |

#### TC-N06: Required — Missing `assign_date`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Leave assign date empty | Assign date blank |
| 4 | Fill all other required fields | Other fields filled |
| 5 | Click "Save" | Validation error |
| 6 | Verify error message | "Assign date is required." displayed |

#### TC-N07: Required — Missing `due_date`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Set assign date, leave due date empty | Due date blank |
| 4 | Fill all other required fields | Other fields filled |
| 5 | Click "Save" | Validation error |
| 6 | Verify error message | "Due date is required." displayed |

#### TC-N08: Due Date Before Assign Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Set assign date = tomorrow | Date set |
| 4 | Set due date = yesterday (before assign date) | Date set |
| 5 | Fill all other required fields | Other fields filled |
| 6 | Click "Save" | Validation error |
| 7 | Verify error message | "Due date must be after assign date." displayed |

#### TC-N09: Passing Marks > Max Marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Fill all required fields; set is_gradable = Yes | Gradable fields visible |
| 4 | Set max_marks = 20, passing_marks = 30 | Passing marks > max marks |
| 5 | Click "Save" | Validation error |
| 6 | Verify error message | "Passing marks must be less than or equal to maximum marks." displayed |

#### TC-N10: Missing `release_scheduled_date` when ON_SCHEDULED_DATE

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Set Release Condition = "On Scheduled Date" | Release scheduled date field appears |
| 4 | Leave release_scheduled_date empty | Date blank |
| 5 | Fill all other required fields | Other fields filled |
| 6 | Click "Save" | Validation error |
| 7 | Verify error message | "The release scheduled date is required when the release condition is set to scheduled date." displayed |

#### TC-N11: Release Scheduled Date Before Assign Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Set assign_date = tomorrow | Assign date set |
| 4 | Set Release Condition = "On Scheduled Date" | Scheduled date field appears |
| 5 | Set release_scheduled_date = today (before assign_date) | Date set |
| 6 | Fill all other required fields | Other fields filled |
| 7 | Click "Save" | Validation error |
| 8 | Verify error message | Error: scheduled date must be after or equal to assign date |

#### TC-N12: Max Length — Title > 255 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Enter a title of 256+ characters | Title exceeds limit |
| 4 | Fill all other required fields | Other fields filled |
| 5 | Click "Save" | Validation error |
| 6 | Verify error message | Title validation fails (max:255) |

#### TC-N13: Max Marks > 999.99

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Fill all required fields; set is_gradable = Yes | Gradable fields visible |
| 4 | Enter max_marks = 1000 | Value exceeds max |
| 5 | Click "Save" | Validation error |
| 6 | Verify error message | Validation fails on max_marks.max |

#### TC-N14: Invalid FK — Non-Existent `class_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Intercept/manipulate POST to send class_id = 99999 | Invalid ID sent |
| 4 | Fill all other required fields | Other fields filled |
| 5 | Submit the form | Validation error |
| 6 | Verify error message | "The selected class is invalid." |

#### TC-N15: Invalid FK — Non-Existent `subject_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Intercept/manipulate POST to send subject_id = 99999 | Invalid ID sent |
| 4 | Fill all other required fields | Other fields filled |
| 5 | Submit the form | Validation error |
| 6 | Verify error message | "The selected subject is invalid." |

#### TC-N16: Invalid FK — Non-Existent `submission_type_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Intercept/manipulate POST to send submission_type_id = 99999 | Invalid ID sent |
| 4 | Fill all other required fields | Other fields filled |
| 5 | Submit the form | Validation error |
| 6 | Verify error message | "The selected submission type is invalid." |

#### TC-N17: Invalid Release Condition Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Intercept/manipulate POST to send release_condition = "INVALID_VALUE" | Invalid value sent |
| 4 | Fill all other required fields | Other fields filled |
| 5 | Submit the form | Validation error |
| 6 | Verify error message | Validation fails on release_condition.in |

#### TC-N18: File Upload — Invalid Type (.exe)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Fill all required fields | Fields filled |
| 4 | Try to upload a .exe file | File rejected |
| 5 | Verify error message | "The file must be a file of type: pdf, doc, docx, txt, jpg, jpeg, png, zip." |

#### TC-N19: File Upload — Exceeds 10MB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Fill all required fields | Fields filled |
| 4 | Upload a file larger than 10MB | File rejected |
| 5 | Verify error message | "The file may not be greater than 10240 kilobytes." |

#### TC-N21: Delete Homework With Existing Submissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create and publish homework for Class 8-A | Homework published with submissions |
| 2 | Login as admin/teacher | Dashboard loads |
| 3 | Navigate to the homework's show page or list | Homework visible |
| 4 | Verify Delete button is hidden/disabled | No delete option available |
| 5 | Direct POST to destroy() endpoint | Server returns error: "Cannot delete homework with existing submissions." |

#### TC-N22: Clone To Same Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Draft homework for Class 8, Section A | Source homework exists |
| 2 | Login as admin/teacher | Dashboard loads |
| 3 | Click "Clone" | Clone modal/interface shows |
| 4 | Select the same Section A as target | Target = same section |
| 5 | Submit clone | Validation error |
| 6 | Verify error message | "Clone target must be a different section of the same class." |

#### TC-N23: Edit Published Homework

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Publish a homework (follow TC-P17) | Homework is Published |
| 2 | Login as admin/teacher | Dashboard loads |
| 3 | Verify Edit button is hidden on Published homework | No edit button in list |
| 4 | Direct URL access: `/lms-home-work/home-works/{id}/edit` | 403 Forbidden or redirect |
| 5 | Direct PUT to update endpoint | Request rejected |

#### TC-N24: View Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to `/lms-home-work/home-works/99999` | HTTP 404 page returned |
| 3 | Verify error page shows "Not Found" | 404 error displayed |

#### TC-N25: Edit Invalid ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to `/lms-home-work/home-works/99999/edit` | HTTP 404 page returned |
| 3 | Verify error page shows "Not Found" | 404 error displayed |

#### TC-N26: Permission 403 — No Homework Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as a user without `tenant.home-work.*` permissions | Dashboard loads |
| 2 | Navigate to `/lms-home-work` | 403 Forbidden |
| 3 | Direct POST to store() | 403 Forbidden |
| 4 | Direct access to show/edit/delete endpoints | 403 Forbidden on all |

#### TC-N27: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out of the application | Redirected to login |
| 2 | Navigate to `/lms-home-work/home-works` | Redirected to `/login` |
| 3 | Navigate to `/lms-home-work/home-works/create` | Redirected to `/login` |
| 4 | Navigate to any homework route | Always redirected to login |

#### TC-N28: XSS Injection In Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Create homework with title: `<script>alert('XSS')</script>` | Created successfully |
| 3 | View the homework in list | Title displayed as literal text; no script execution |
| 4 | View the homework show page | Title displayed as literal text; no script execution |
| 5 | Verify no alert box triggered | XSS prevented by Blade `{{ }}` escaping |

#### TC-N29: Restore Non-Deleted Homework

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a homework (not deleted) | Active homework exists |
| 2 | Login as admin/teacher | Dashboard loads |
| 3 | Direct POST to `/lms-home-work/home-works/{id}/restore` | HTTP 404 returned |
| 4 | Verify `onlyTrashed()->find()` returns null | Record not in trash |

#### TC-N30: Force Delete Non-Trashed Homework

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a homework (not deleted) | Active homework exists |
| 2 | Login as admin/teacher | Dashboard loads |
| 3 | Direct DELETE to `/lms-home-work/home-works/{id}/force-delete` | HTTP 404 returned |
| 4 | Verify `onlyTrashed()->find()` returns null | Record not in trash |

#### TC-N31: No Active Academic Session Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no academic session has `is_current=1` | No current session |
| 2 | Login as admin/teacher | Dashboard loads |
| 3 | Navigate to Homework create form | Create form loads |
| 4 | Fill all required fields and click "Save" | Store fails |
| 5 | Verify error | "Current Academic Session is not set." |

#### TC-N32: Assign Date Backdated On Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with assign_date = today | Homework exists |
| 2 | Wait or set system context to next day | Day advanced |
| 3 | Login as admin/teacher | Dashboard loads |
| 4 | Edit the homework; change assign_date to yesterday | Backdated date |
| 5 | Click "Update" | Validation error |
| 6 | Verify error message | Assign date must be after or equal to today |

#### TC-N33: View-Only User Can View But Cannot Create/Edit/Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as a user with only `tenant.home-work.viewAny` and `tenant.home-work.view` permissions (no create/update/delete) | Dashboard loads |
| 2 | Navigate to Homework list | List loads successfully; Add Homework button hidden |
| 3 | Click on a homework title to view | Show page loads successfully |
| 4 | Navigate to `/lms-home-work/home-works/create` | HTTP 403 Forbidden |
| 5 | Direct POST to `/lms-home-work/home-works` (store) | HTTP 403 Forbidden |
| 6 | Navigate to `/lms-home-work/home-works/{id}/edit` | HTTP 403 Forbidden |
| 7 | Direct PUT to `/lms-home-work/home-works/{id}` (update) | HTTP 403 Forbidden |
| 8 | Direct DELETE to `/lms-home-work/home-works/{id}` (destroy) | HTTP 403 Forbidden |

#### TC-D01: Create → Status forced to DRAFT

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with any status_id value | Homework created |
| 2 | DB check: `SELECT d.value FROM lms_homework h JOIN sys_dropdown_table d ON h.status_id=d.id WHERE h.id={id}` | d.value = 'DRAFT' |
| 3 | Verify regardless of input status, DB stores DRAFT | Status forced to Draft |

#### TC-D02: Create → Academic session auto-set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify `sch_org_academic_sessions` has one record with `is_current=1` | Current session known |
| 2 | Create new homework | Homework created |
| 3 | DB check: `SELECT academic_session_id FROM lms_homework WHERE id={id}` | Matches current session's ID |

#### TC-D04: Publish → Homework status changes to PUBLISHED

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create and publish a Draft homework | Published |
| 2 | DB check: `SELECT d.value FROM lms_homework h JOIN sys_dropdown_table d ON h.status_id=d.id WHERE h.id={id}` | d.value = 'PUBLISHED' |

#### TC-D05: Clone → New Draft created with same fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Draft homework with title "Math HW", max_marks=50, assign_date=tomorrow, due_date=+7d | Source homework exists |
| 2 | Clone to a different section | Clone created |
| 3 | DB check: cloned record has same title, description, max_marks, passing_marks, assign_date, due_date | Fields match |
| 4 | DB check: cloned record has different `section_id` | Section differs |
| 5 | DB check: cloned record status maps to 'DRAFT' | New record is Draft |

#### TC-D06: Soft delete → is_active set to false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create an active homework (is_active=1) | Active homework exists |
| 2 | Perform soft delete on the homework | Delete succeeds |
| 3 | DB check: `SELECT is_active FROM lms_homework WHERE id={id}` | is_active = 0 |

#### TC-D07: Soft delete → deleted_at set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a homework | Homework exists |
| 2 | Perform soft delete on the homework | Delete succeeds |
| 3 | DB check: `SELECT deleted_at FROM lms_homework WHERE id={id}` | deleted_at IS NOT NULL (timestamp present) |

#### TC-D08: Restore → is_active set to true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete a homework | deleted_at set, is_active=0 |
| 2 | Restore the homework | Restore succeeds |
| 3 | DB check: `SELECT is_active FROM lms_homework WHERE id={id}` | is_active = 1 |

#### TC-D09: Clone → Attachments copied

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with 2 file attachments | Source homework has attachments |
| 2 | Clone to a different section | Clone created |
| 3 | Verify cloned homework's edit page shows same files | Attachments present |
| 4 | DB/Media check: Attachment records exist for cloned homework | Attachments copied |

#### TC-D10: Toggle → is_active flips

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note current `is_active` value of homework (e.g., 1) | Known state |
| 2 | Click toggle status | AJAX call |
| 3 | Inspect JSON response | `is_active` field = 0 (opposite) |
| 4 | DB check: `SELECT is_active FROM lms_homework WHERE id={id}` | Value flipped (0) |
| 5 | Click toggle again | Flips back to 1 |

#### TC-D11: Activity Log — All CRUD events tracked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Perform Create, Read, Update, Delete operations on homework | Operations completed |
| 2 | Perform soft delete, restore, force delete | All operations done |
| 3 | DB check: `SELECT * FROM activity_log WHERE subject_type='Homework'` | Events: Stored, Updated, Trashed, Restored, Deleted all present |
| 4 | Verify each event has correct subject_id, description, causer_id | Log entries complete |

#### TC-D12: ForceDelete → Assignments and Submissions cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create and publish homework with assignments | Assignments exist |
| 2 | Soft delete then force delete the homework | Force delete succeeds |
| 3 | DB check: `SELECT * FROM lms_homework WHERE id={id}` | No record |
| 4 | DB check: `SELECT * FROM lms_homework_assignment WHERE homework_id={id}` | No assignment records |
| 5 | DB check: Related submissions also deleted | Cascade complete |

#### TC-D13: `is_gradable` cast as boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with is_gradable = true | Homework created |
| 2 | DB check: `SELECT is_gradable FROM lms_homework WHERE id={id}` | Value = 1 (TINYINT) |
| 3 | Model check: `$homework->is_gradable` | Returns `true` (boolean) |
| 4 | Create homework with is_gradable = false | DB value = 0; model returns `false` |

#### TC-D14: `max_marks` and `passing_marks` decimal precision

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with max_marks = 99.99, passing_marks = 49.99 | Homework created |
| 2 | DB check: `SELECT max_marks, passing_marks FROM lms_homework WHERE id={id}` | Values = 99.99, 49.99 (DECIMAL(5,2)) |
| 3 | Verify no rounding occurred | Precision preserved |

#### TC-D15: `assign_date` and `due_date` datetime casting

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with assign_date = "2026-07-20 10:00:00", due_date = "2026-07-27 23:59:00" | Homework created |
| 2 | DB check: `SELECT assign_date, due_date FROM lms_homework WHERE id={id}` | Stored as DATETIME |
| 3 | Model check: `$homework->assign_date instanceof Carbon` | Returns true (Carbon instance) |

#### TC-D16: `findOrFail` — non-existent ID returns 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Access show/edit/update/delete for ID = 99999 | HTTP 404 for all methods |
| 3 | Verify `findOrFail` behavior | ModelNotFoundException → 404 |

#### TC-D17: `Gate::authorize` before controller actions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review controller code for index() | `Gate::authorize('tenant.home-work.viewAny')` present |
| 2 | Review store() | `Gate::authorize('tenant.home-work.create')` present |
| 3 | Review update() | `Gate::authorize('tenant.home-work.update')` present |
| 4 | Review destroy() | `Gate::authorize('tenant.home-work.delete')` present |
| 5 | Review restore()/forceDelete() | Corresponding gate checks present |

#### TC-D18: Model mass assignment — fillable guarded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Modules\LmsHomework\Models\Homework` model | `$fillable` or `$guarded` defined |
| 2 | Attempt to set `id`, `created_at`, `deleted_at` via mass assignment | These fields are guarded |
| 3 | Verify non-fillable attributes silently ignored on create/update | No mass assignment error, but values not saved |

#### TC-D19: Create → created_by set to auth user

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as a specific user (e.g., admin ID = 1) | Dashboard loads |
| 2 | Create a new homework | Homework created |
| 3 | DB check: `SELECT created_by FROM lms_homework WHERE id={id}` | created_by = 1 (current user ID) |

#### TC-CR01: Blade @can Directives — Permission-based visibility for all action buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review index.blade.php | @can('tenant.home-work.create') wraps Add button |
| 2 | Review show.blade.php | @can('tenant.home-work.update') wraps Edit button |
| 3 | Review list views | @can('tenant.home-work.delete') wraps Delete button |
| 4 | Review trash views | @can('tenant.home-work.restore') and @can('tenant.home-work.forceDelete') present |
| 5 | Verify all action buttons gated by corresponding @can | No button visible without permission |

#### TC-CR02: DB Transactions in store/update/publish

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` method in controller | Wrapped in `DB::transaction()` |
| 2 | Review `update()` method | Wrapped in `DB::transaction()` |
| 3 | Review `publish()` method | Wrapped in `DB::transaction()` |
| 4 | Verify attachment sync inside transaction | All DB ops atomic |

#### TC-CR03: Controller exception handling with try-catch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` method | try-catch block present |
| 2 | Review `update()` method | try-catch block present |
| 3 | Verify catch block returns `withErrors()` or flash error | Errors handled gracefully |
| 4 | Check `publish()` and other mutating methods | try-catch pattern consistent |

#### TC-CR04: View — isset()/null-safe checks for relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review blade files for relationship access | Uses `$record?->relation?->field` syntax |
| 2 | Check show.blade.php for optional lesson/topic/section display | Null-safe operators used |
| 3 | Verify no undefined property errors possible | All optional relations guarded |

#### TC-CR05: Breadcrumb Config — Route registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | File exists |
| 2 | Search for `lms-home-work.home-works.*` keys | Keys defined for index, create, show, edit |
| 3 | Verify breadcrumb labels match page titles | Consistent naming |

#### TC-CR06: Activity logging after CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` method | `activityLog()` called after DB commit |
| 2 | Review `update()` method | `activityLog()` called after DB commit |
| 3 | Review `destroy()` method | `activityLog()` called for Trashed event |
| 4 | Review `restore()` method | `activityLog()` called for Restored event |
| 5 | Review `forceDelete()` method | `activityLog()` called for Deleted event |

#### TC-CR07: Hub page tab integration — each tab loads with correct permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review hub page blade | @can('tenant.home-work.*.viewAny') wraps each tab |
| 2 | Verify default tab = homework_analytics | Default tab loads analytics |
| 3 | Click Homework tab | Tab loads with homework list |
| 4 | Verify other tabs similarly gated | Each tab checks its permission |

#### TC-CR08: Tab persistence on create/edit redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review controller's store() return | Redirect includes `?tab=home_work` |
| 2 | Review controller's update() return | Redirect includes `?tab=home_work` |
| 3 | Verify after create, Homework tab is active | Tab persists |
| 4 | Verify after update, Homework tab is active | Tab persists |

#### TC-D21: ON DELETE RESTRICT — FK Parent Delete Rejected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a homework referencing Class A (id=X) | Homework record exists with class_id=X |
| 2 | Attempt to DELETE Class A from sch_classes table | DB throws foreign key constraint error (RESTRICT) |
| 3 | Repeat for subject_id, academic_session_id, submission_type_id, status_id, created_by | Each parent delete rejected |

#### TC-D22: ON DELETE SET NULL — Section/Lesson/Topic/Schedule Set to NULL on Parent Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework referencing Section A (section_id=X), Lesson A, Topic A, Schedule A | All FKs populated |
| 2 | Delete Section A from sch_sections | homework.section_id becomes NULL |
| 3 | Verify other FKs (class_id, subject_id) unchanged | Still have original values |
| 4 | Repeat with lesson, topic, schedule FKs | Each set to NULL on parent delete |

#### TC-D23: ENUM Validation — Invalid release_condition Rejected at DB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt direct DB INSERT with release_condition='INVALID' | MySQL rejects: "Incorrect ENUM value" |
| 2 | Verify valid values IMMEDIATE, ON_TOPIC_COMPLETE, ON_SCHEDULED_DATE are accepted | Insert succeeds |

#### TC-D24: DEFAULT Values Applied on Insert

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with only required fields (omit is_gradable, is_active, etc.) | Record created |
| 2 | DB check: is_gradable=1, is_active=1, allow_late_submission=0, auto_publish_score=0 | All defaults applied |
| 3 | DB check: release_condition='ON_TOPIC_COMPLETE' | Default ENUM value applied |

#### TC-D25: INDEX Exists for Query Performance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run EXPLAIN SELECT on lms_homework WHERE class_id=? AND subject_id=? | Query uses idx_hw_class_sub index |
| 2 | Run EXPLAIN SELECT on lms_homework WHERE status_id=? | Uses idx_hw_status index |
| 3 | Run EXPLAIN SELECT on lms_homework WHERE assign_date BETWEEN ? AND ? | Uses idx_hw_assign_date index |
| 4 | Run EXPLAIN SELECT on lms_homework WHERE academic_session_id=? | Uses idx_hw_session index |

#### TC-D26: BC-CON-02 — schedule_id Required When ON_TOPIC_COMPLETE

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin/teacher | Dashboard loads |
| 2 | Navigate to Homework create form | Create form loads |
| 3 | Fill all required fields (class, subject, title, description, submission_type, assign_date, due_date) | Fields filled |
| 4 | Set Release Condition = "On Topic Complete" | Release condition set |
| 5 | Leave schedule_id (topic schedule) unselected | schedule_id blank |
| 6 | Click "Save" | Validation error |
| 7 | Verify error message | App enforces schedule_id is required when release_condition = ON_TOPIC_COMPLETE |

#### TC-D27: BC-CON-06 — allow_late_submission Inheritance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a draft homework with allow_late_submission = 0 | Homework created with default late-submission policy = deny |
| 2 | Publish the homework for Class 8-A (35 enrolled students) | 35 lms_homework_assignment records created |
| 3 | DB check: `SELECT allow_late_submission FROM lms_homework_assignment WHERE homework_id={id}` | All 35 records have allow_late_submission = NULL (inheriting from homework default of 0) |
| 4 | Direct DB update: set one student's assignment allow_late_submission = 1 | Per-student override applied |
| 5 | Verify that student can submit after due_date | Override takes precedence; late submission allowed for that student |
| 6 | Verify other 34 students still blocked from late submission | Inheritance from homework default (0) still applies |

#### TC-D28: BC-CON-07 — Topic Completion Triggers Auto-Release

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with release_condition = ON_TOPIC_COMPLETE and a valid schedule_id linking to a syllabus topic | Homework created with schedule_id set |
| 2 | Publish the homework | Assignments created with is_released = 0, status = PENDING_RELEASE |
| 3 | DB check: `SELECT is_released FROM lms_homework_assignment WHERE homework_id={id}` | All records have is_released = 0 |
| 4 | Teacher marks the slb_syllabus_schedule topic as completed (e.g., via syllabus management UI) | Topic completion triggers event |
| 5 | Verify system sets is_released = 1 for all matching assignments | App automatically releases assignments |
| 6 | DB check: `SELECT is_released, released_at FROM lms_homework_assignment WHERE homework_id={id}` | is_released = 1, released_at timestamp populated |
| 7 | Verify students can now view/submit the homework in their portal | Homework visible to students |

#### TC-D28: Syllabus Mark Done → Observer Releases ON_TOPIC_COMPLETE Homework

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with release_condition = ON_TOPIC_COMPLETE, link to syllabus schedule via schedule_id, same section as schedule | Homework published with pending releases |
| 2 | Verify assignments exist with is_released = 0, status_id = PENDING_RELEASE | Prerequisite met |
| 3 | POST to /syllabus-schedule/{schedule_id}/mark-complete as teacher | SyllabusSchedule updated: is_completed=true, completed_at set |
| 4 | Verify observer fires: `SyllabusScheduleObserver@updated` detects isDirty('is_completed') | Observer executes releaseHomeworkForTopic() |
| 5 | DB check: SELECT is_released, released_at, status_id FROM lms_homework_assignment WHERE homework_id={id} | All matching assignments: is_released=1, released_at=now, status_id=ASSIGNED |
| 6 | Verify HOMEWORK_RELEASED notification created for each student | Notification records present |

#### TC-D29: `tenant:homework:release-scheduled` Cron Releases ON_SCHEDULED_DATE Homework

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with release_condition = ON_SCHEDULED_DATE, release_scheduled_date = yesterday | Homework published, assignments exist with is_released=0 |
| 2 | Run `Artisan::call('tenant:homework:release-scheduled')` | Command executes |
| 3 | DB check: is_released, released_at, status_id on assignments | is_released=1, released_at=now, status_id=ASSIGNED |
| 4 | Verify future-dated homework NOT affected | Homework with release_scheduled_date = tomorrow remains is_released=0 |

#### TC-D30: `tenant:syllabus:release-resources` Cron Releases by Syllabus Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure SchConfig `homework_released_on_syllabus_level` = 'Topic' | Config set |
| 2 | Create SyllabusSchedule with topicLevelType.name = 'Topic', scheduled_start_date <= today, is_active = true | Schedule ready |
| 3 | Create homework ON_TOPIC_COMPLETE matching schedule's class_id + subject_id + topic_id, publish it | Assignments in PENDING_RELEASE |
| 4 | Run `Artisan::call('tenant:syllabus:release-resources')` | Cron iterates schedules, calls syncHomeworkPublic() |
| 5 | DB check: matching assignments now have is_released=1 | Cron-level release works |
| 6 | Verify non-matching schedules (wrong level/wrong topic) untouched | Only correct assignments released |

#### TC-CR09: SyllabusScheduleObserver Registered in EventServiceProvider

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect LmsHomework EventServiceProvider | `$observers = [SyllabusSchedule::class => SyllabusScheduleObserver::class]` present |
| 2 | Verify observer file exists at LmsHomework/Observers/SyllabusScheduleObserver.php | File present with `updated()` method |

#### TC-CR10: Observer Matching Logic for ON_TOPIC_COMPLETE Homework

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect SyllabusScheduleObserver@updated | Checks `$syllabusSchedule->isDirty('is_completed') && $syllabusSchedule->is_completed` |
| 2 | Inspect releaseHomeworkForTopic() | Query: Homework where `topic_id` = schedule.topic_id, `section_id` = schedule.section_id, `release_condition` = 'ON_TOPIC_COMPLETE', status = PUBLISHED |
| 3 | Verify assignments loop sets is_released=true, released_at=now, status_id=ASSIGNED | Release logic correct |

#### TC-CR11: `tenant:homework:release-scheduled` Registered in Console

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect routes/console.php | `Schedule::command('tenant:homework:release-scheduled')->everyMinute()->withoutOverlapping()` present |
| 2 | Inspect LmsHomework/Console/ReleaseScheduledHomework.php | Command queries ON_SCHEDULED_DATE homework where release_scheduled_date <= today, creates/updates assignments |

#### TC-CR12: `tenant:syllabus:release-resources` Registered in Console

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect routes/console.php | `Schedule::command('tenant:syllabus:release-resources')->everyFiveMinutes()->withoutOverlapping()` present |
| 2 | Inspect Syllabus/Console/ReleaseLmsResources.php | Command reads SchConfig `homework_released_on_syllabus_level`, matches topicLevelType.name, calls syncHomeworkPublic() |
