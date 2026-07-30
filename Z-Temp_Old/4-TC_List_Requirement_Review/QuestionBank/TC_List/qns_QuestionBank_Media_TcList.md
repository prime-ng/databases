# qns_QuestionBank_Media_TcList

## Module: QuestionBank → Question Media Store → Media CRUD & Management

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | QuestionBank (QNS) |
| Tab Group | Question Media Store (Tabbed under Question Bank) |
| Feature | Media List, Create, View, Edit, Soft Delete/Restore/Force Delete, Status Toggle |
| URL(s) | `/question-media-store` (resource index/create/store/show/edit/update/destroy), `/question-media-store/trash/view` (trashed), `/question-media-store/{id}/restore` (restore), `/question-media-store/{id}/force-delete` (forceDelete), `/question-media-store/{question_media_store}/toggle-status` (toggleStatus) |
| Controller | `Modules\QuestionBank\Http\Controllers\QuestionMediaStoreController` |
| Model(s) | `QuestionMediaStore` (`Modules\QuestionBank\Models\QuestionMediaStore`) — `SoftDeletes` trait |
| Validation (Create/Update) | `QuestionMediaStoreRequest` (`Modules\QuestionBank\Http\Requests\QuestionMediaStoreRequest`) |
| Permission Gates (Policy) | `tenant.question-media-store.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status` |
| Soft Deletes | Yes — `SoftDeletes` trait on QuestionMediaStore |
| Activity Log Events | `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Status Toggled` |
| Auto-Generated Fields | `created_at`, `updated_at` (timestamps), `uuid` (generated on create) |

---

## 2. Pre-conditions

- Required permissions: `tenant.question-media-store.viewAny`, `.create`, `.update`, `.view`, `.delete`, `.restore`, `.forceDelete`, `.status`
- For file upload tests: Valid media file(s) of supported types (jpg/png for IMAGE, mp3/wav for AUDIO, mp4/avi for VIDEO, pdf for PDF)
- For unique uuid tests: At least one existing QuestionMediaStore record
- For cascade tests: At least one question in `qns_questions_bank` with junction records in `qns_question_media_jnt` (junction table exists in DB, no dedicated model)
- For trash/restore tests: At least one soft-deleted QuestionMediaStore
- For FK existence tests: Valid records in `sch_classes`, `sch_subjects`, `slb_lessons`, `slb_topics`

---

## 3. Default Data Load

When index tab loads (GET `/question-bank/question-media-store`):

| Data | Source | Query | Pagination |
|------|--------|-------|------------|
| Media Store Records | `QuestionMediaStore::orderBy('created_at', 'desc')->paginate(10)` | Ordered by created_at desc | 10 per page |

When create page loads (GET `/question-bank/question-media-store/create`):

| Data | Source | Notes |
|------|--------|-------|
| Form (empty) | New blank form | Fields: owner_type, class_id, subject_id, lesson_id, topic_id, media_type, file_name, file_path, mime_type, disk, size, checksum, ordinal, is_active, media_file |

When edit page loads (GET `/question-bank/question-media-store/{questionMediaStore}/edit`):

| Data | Source | Notes |
|------|--------|-------|
| QuestionMediaStore (existing) | `QuestionMediaStore::findOrFail($id)` | Pre-filled values |
| Status override | `old('is_active', $mediaStore->is_active)` | Preserved from old input |

When view page loads (GET `/question-bank/question-media-store/{questionMediaStore}`):

| Data | Source | Notes |
|------|--------|-------|
| QuestionMediaStore (with trashed) | `QuestionMediaStore::withTrashed()->findOrFail($id)` | Shows even soft-deleted |
| All attributes displayed | owner_type, media_type, file_name, disk, size, ordinal, status, Created At, Updated At | Read-only |

---

## 4. BC-DB — Database Schema

### `qns_media_store` — Question Media Store Table

| BC-DB ID | Column | Type | Nullable | Default | Constraints | Notes |
|----------|--------|------|----------|---------|-------------|-------|
| BC-DB-01 | id | INT UNSIGNED | NOT NULL | | PK, AUTO_INCREMENT | Surrogate primary key |
| BC-DB-02 | uuid | BINARY(16) | NOT NULL | | UNIQUE | UUID generated on create |
| BC-DB-03 | owner_type | ENUM('QUESTION','OPTION','EXPLANATION','RECOMMENDATION') | NOT NULL | | | Media owner type |
| BC-DB-04 | class_id | INT UNSIGNED | NULL | | FK → sch_classes.id | Nullable classification |
| BC-DB-05 | subject_id | INT UNSIGNED | NULL | | FK → sch_subjects.id | Nullable subject link |
| BC-DB-06 | lesson_id | INT UNSIGNED | NULL | | FK → slb_lessons.id | Nullable lesson link |
| BC-DB-07 | topic_id | INT UNSIGNED | NULL | | FK → slb_topics.id | Nullable topic link |
| BC-DB-08 | media_type | ENUM('IMAGE','AUDIO','VIDEO','PDF') | NOT NULL | | | Type of media |
| BC-DB-09 | file_name | VARCHAR(255) | NULL | | | Original file name |
| BC-DB-10 | file_path | VARCHAR(255) | NULL | | | Storage file path |
| BC-DB-11 | mime_type | VARCHAR(100) | NULL | | | MIME type of file |
| BC-DB-12 | disk | VARCHAR(50) | NOT NULL | | local/public | Storage disk |
| BC-DB-13 | size | INT UNSIGNED | NULL | | | File size in bytes |
| BC-DB-14 | checksum | CHAR(64) | NULL | | | SHA-256 checksum |
| BC-DB-15 | ordinal | SMALLINT UNSIGNED | NOT NULL | 1 | | Display order |
| BC-DB-16 | is_active | TINYINT(1) | NOT NULL | 1 | | Boolean status |
| BC-DB-17 | created_at | TIMESTAMP | NULL | CURRENT_TIMESTAMP | | |
| BC-DB-18 | updated_at | TIMESTAMP | NULL | ON UPDATE CURRENT_TIMESTAMP | | |
| BC-DB-19 | deleted_at | TIMESTAMP | NULL | NULL | | Soft delete marker |

Unique keys: `uuid` (unique).

### `qns_question_media_jnt` — Question Media Junction Table (DB-level, no dedicated model)

Junction table `qns_question_media_jnt` exists in DB with FK constraints (`fk_qms_media_id`, `fk_qms_question_bank`, `fk_qms_option`) but no dedicated Eloquent model (`QuestionMediaJnt`) exists in code. The table is referenced only via FK cascade relationships and raw DB operations.

---

## 5. BC-VAL — Validation Rules

### 5.1 Create & Update Validation — BC-VAL

Source: `Modules\QuestionBank\Http\Requests\QuestionMediaStoreRequest::rules()`

| BC-VAL ID | Field | Rule(s) | Error Message (Expected) |
|-----------|-------|---------|--------------------------|
| BC-VAL-01 | owner_type | required, in:QUESTION,OPTION,EXPLANATION,RECOMMENDATION | "Owner type is required." / "Selected owner type is invalid." |
| BC-VAL-02 | class_id | nullable, integer, exists:sch_classes,id | "Class ID must be a valid class." |
| BC-VAL-03 | subject_id | nullable, integer, exists:sch_subjects,id | "Subject ID must be a valid subject." |
| BC-VAL-04 | lesson_id | nullable, integer, exists:slb_lessons,id | "Lesson ID must be a valid lesson." |
| BC-VAL-05 | topic_id | nullable, integer, exists:slb_topics,id | "Topic ID must be a valid topic." |
| BC-VAL-06 | media_type | required, in:IMAGE,AUDIO,VIDEO,PDF | "Media type is required." / "Selected media type is invalid." |
| BC-VAL-07 | ordinal | nullable, integer, min:1 | "Ordinal must be at least 1." |
| BC-VAL-08 | disk | required, in:local,public | "Disk is required." / "Selected disk is invalid." |
| BC-VAL-09 | media_file | required_on:create, file, mimes:jpg,jpeg,png,gif,webp (IMAGE), mp3,wav,ogg (AUDIO), mp4,avi,mov,wmv (VIDEO), pdf (PDF), max:20480 | "Media file is required." / "Invalid file type." / "File too large." |

### 5.2 Authorization in Request

Source: `QuestionMediaStoreRequest::authorize()`

| BC-VAL ID | Method | Permission Check | Notes |
|-----------|--------|------------------|-------|
| BC-VAL-AUTH-01 | POST (create) | `Gate::allows('tenant.question-media-store.create')` | Create permission |
| BC-VAL-AUTH-02 | PUT/PATCH (update) | `Gate::allows('tenant.question-media-store.update')` | Update permission |

---

## 6. BC-AUTH — Authorization

### 6.1 Policy Gates

Source: `Modules\QuestionBank\Policies\QuestionMediaStorePolicy`

| BC-AUTH ID | Gate Name | Policy Method | Permission String | Scope |
|------------|-----------|---------------|-------------------|-------|
| BC-AUTH-01 | viewAny | `viewAny(User $user): bool` | `tenant.question-media-store.viewAny` | List all media |
| BC-AUTH-02 | view | `view(User $user, QuestionMediaStore $media): bool` | `tenant.question-media-store.view` | Single media show |
| BC-AUTH-03 | create | `create(User $user): bool` | `tenant.question-media-store.create` | Create new media |
| BC-AUTH-04 | update | `update(User $user, QuestionMediaStore $media): bool` | `tenant.question-media-store.update` | Edit/update/toggle |
| BC-AUTH-05 | delete | `delete(User $user, QuestionMediaStore $media): bool` | `tenant.question-media-store.delete` | Soft delete |
| BC-AUTH-06 | restore | `restore(User $user, QuestionMediaStore $media): bool` | `tenant.question-media-store.restore` | Restore from trash |
| BC-AUTH-07 | forceDelete | `forceDelete(User $user, QuestionMediaStore $media): bool` | `tenant.question-media-store.forceDelete` | Permanent delete |
| BC-AUTH-08 | update (toggleStatus) | Controller uses `tenant.question-media-store.update` | `tenant.question-media-store.update` | Toggle active status (no dedicated `status` gate used in controller) |

### 6.2 Controller Gate Calls

| BC-AUTH ID | Controller Method | Gate String Used | Expected (Policy) |
|------------|-------------------|------------------|-------------------|
| BC-AUTH-C-01 | index | `tenant.question-media-store.viewAny` | `tenant.question-media-store.viewAny` |
| BC-AUTH-C-02 | create | `tenant.question-media-store.create` | `tenant.question-media-store.create` |
| BC-AUTH-C-03 | store | `tenant.question-media-store.create` | `tenant.question-media-store.create` |
| BC-AUTH-C-04 | show | `tenant.question-media-store.view` | `tenant.question-media-store.view` |
| BC-AUTH-C-05 | edit | `tenant.question-media-store.update` | `tenant.question-media-store.update` |
| BC-AUTH-C-06 | update | `tenant.question-media-store.update` | `tenant.question-media-store.update` |
| BC-AUTH-C-07 | destroy | `tenant.question-media-store.delete` | `tenant.question-media-store.delete` |
| BC-AUTH-C-08 | trashed | `tenant.question-media-store.restore` | `tenant.question-media-store.restore` |
| BC-AUTH-C-09 | restore | `tenant.question-media-store.restore` | `tenant.question-media-store.restore` |
| BC-AUTH-C-10 | forceDelete | `tenant.question-media-store.forceDelete` | `tenant.question-media-store.forceDelete` |
| BC-AUTH-C-11 | toggleStatus | `tenant.question-media-store.update` | `tenant.question-media-store.update` (no dedicated status gate used in controller) |

### 6.3 Blade View Permission Checks

| BC-AUTH ID | View File | Directive | Permission | Purpose |
|------------|-----------|-----------|------------|---------|
| BC-AUTH-V-01 | `question-media-store/index.blade.php` | `@can('tenant.question-media-store.status')` | tenant.question-media-store.status | Shows Active column header |
| BC-AUTH-V-02 | `question-media-store/index.blade.php` | `@canany(['tenant.question-media-store.view', 'tenant.question-media-store.update', 'tenant.question-media-store.delete'])` | view/update/delete | Shows Action column header |
| BC-AUTH-V-03 | `question-media-store/index.blade.php` | `@can('tenant.question-media-store.status')` | tenant.question-media-store.status | Shows status switch per row |
| BC-AUTH-V-04 | `question-media-store/index.blade.php` | `@canany(['tenant.question-media-store.view', 'tenant.question-media-store.update', 'tenant.question-media-store.delete'])` | view/update/delete | Shows action buttons per row |
| BC-AUTH-V-05 | `question-media-store/view.blade.php` | `@can('tenant.question-media-store.update')` | tenant.question-media-store.update | Shows Edit button |
| BC-AUTH-V-06 | `question-media-store/trash.blade.php` | `@canany(['tenant.question-media-store.restore', 'tenant.question-media-store.forceDelete'])` | restore/forceDelete | Shows trash action column header |
| BC-AUTH-V-07 | `question-media-store/trash.blade.php` | `@canany(['tenant.question-media-store.restore', 'tenant.question-media-store.forceDelete'])` | restore/forceDelete | Shows restore/force-delete buttons per row |
| BC-AUTH-V-08 | `question-media-store/view.blade.php` | `@can('tenant.question-media-store.view')` | tenant.question-media-store.view | Shows file URL link |

---

## 7. BC-BIZ — Business Logic

### 7.1 Business Rules

| BC-BIZ ID | Rule | Description | Enforcement Point |
|-----------|------|-------------|-------------------|
| BC-BIZ-01 | UUID Auto-Generation | `uuid` is auto-generated as BINARY(16) on create via UUID helper | Model creating event or controller store() |
| BC-BIZ-02 | MIME Validation Per Type | IMAGE: jpg,jpeg,png,gif,webp; AUDIO: mp3,wav,ogg; VIDEO: mp4,avi,mov,wmv; PDF: pdf | `QuestionMediaStoreRequest` mimes rule scoped by media_type |
| BC-BIZ-03 | File Upload & Storage | Uploaded file stored on configured disk (local/public); file_name, file_path, mime_type, size, checksum populated | Controller store() and update() methods |
| BC-BIZ-04 | Soft Delete Deactivates | Soft delete sets `is_active = false` before calling `$media->delete()` | Controller `destroy()` method |
| BC-BIZ-05 | Force Delete Cascade | Force delete permanently removes media; cascade FK deletes junction records | Controller `forceDelete()` calls `$media->forceDelete()`; FK cascade handles `qns_question_media_jnt` |
| BC-BIZ-06 | Status Toggle (AJAX) | Toggle inverts `is_active` via AJAX POST; returns JSON response with new state | Controller `toggleStatus()` |
| BC-BIZ-07 | Activity Logging | Every action (Stored, Updated, Trashed, Restored, Deleted, Status Toggled, Downloaded, Previewed) creates activity log entry | Controller after each action via `activityLog()` helper |
| BC-BIZ-08 | View (no withTrashed) | `show()` uses `findOrFail()` — soft-deleted media NOT viewable via show() | Controller `show()` method |
| BC-BIZ-09 | No Cascade on Soft Delete | Soft delete does NOT cascade to junction table (junction records remain intact) | FK ON DELETE CASCADE only triggers on actual row deletion (force delete) |
| BC-BIZ-10 | Default is_active | New media records default to `is_active = 1` (active) | DDL default + migration boolean default(true) |
| BC-BIZ-11 | Default ordinal | New media records default to `ordinal = 1` | DDL default 1 |
| BC-BIZ-12 | File Cleanup on Force Delete | Physical file deleted from storage on force delete | Controller `forceDelete()` calls `Storage::disk(...)->delete($media->file_path)` |
| BC-BIZ-13 | File Cleanup on Update | Old physical file deleted from storage when media_file is replaced on update | Controller `update()` deletes old file before storing new one |
| BC-BIZ-14 | No Route Warning | `download()`, `preview()`, `getByOwner()`, `reorder()` controller methods exist but have NO routes defined in `web.php` — these endpoints are unreachable | Controller methods exist but no route registration |

### 7.2 Model Attributes

| BC-BIZ ID | Attribute | Type | Notes |
|-----------|-----------|------|-------|
| BC-BIZ-ATTR-01 | `$fillable` (QuestionMediaStore) | `['uuid', 'owner_type', 'class_id', 'subject_id', 'lesson_id', 'topic_id', 'media_type', 'file_name', 'file_path', 'mime_type', 'disk', 'size', 'checksum', 'ordinal', 'is_active']` | Mass-assignable fields |
| BC-BIZ-ATTR-02 | `$casts` (QuestionMediaStore) | `is_active => boolean`, timestamps => datetime | Attribute casting |
| BC-BIZ-ATTR-03 | `$table` (QuestionMediaStore) | `qns_media_store` | DB table name |
| BC-BIZ-ATTR-04 | `$primaryKey` (QuestionMediaStore) | `id` | Primary key |
| BC-BIZ-ATTR-NOTE | `qns_question_media_jnt` | Junction table exists in DB (`qns_question_media_jnt`) with FK constraints, but no dedicated Eloquent model (`QuestionMediaJnt`) exists in code | DB table used via FK only, not via model |

### 7.3 Model Scopes

| BC-BIZ ID | Scope | Logic (via BaseModel) |
|-----------|-------|----------------------|
| BC-BIZ-SCP-01 | `active` | `where('is_active', true)` |
| BC-BIZ-SCP-02 | `search` | Search file_name, mime_type, media_type |
| BC-BIZ-SCP-03 | `byOwnerType` | `where('owner_type', $ownerType)` |
| BC-BIZ-SCP-04 | `byMediaType` | `where('media_type', $mediaType)` |

---

## 8. BC-REF — Referential Integrity

### Foreign Keys on `qns_media_store`

| BC-REF ID | Column | FK Name | Referenced Table | Referenced Column | On Delete | Notes |
|-----------|--------|---------|------------------|-------------------|-----------|-------|
| BC-REF-01 | class_id | `fk_qms_class` | `sch_classes` | `id` | SET NULL | Nullable classification |
| BC-REF-02 | subject_id | `fk_qms_subject` | `sch_subjects` | `id` | SET NULL | Nullable subject link |
| BC-REF-03 | lesson_id | `fk_qms_lesson` | `slb_lessons` | `id` | SET NULL | Nullable lesson link |
| BC-REF-04 | topic_id | `fk_qms_topic` | `slb_topics` | `id` | SET NULL | Nullable topic link |

### Foreign Keys on `qns_question_media_jnt` (DB-level only)

| BC-REF ID | Column | FK Name | Referenced Table | Referenced Column | On Delete | Notes |
|-----------|--------|---------|------------------|-------------------|-----------|-------|
| BC-REF-05 | question_bank_id | `fk_qmj_question` | `qns_questions_bank` | `id` | CASCADE | Question link (DB FK only) |
| BC-REF-06 | question_option_id | `fk_qmj_option` | `qns_question_options` | `id` | CASCADE | Option link, nullable (DB FK only) |
| BC-REF-07 | media_id | `fk_qmj_media` | `qns_media_store` | `id` | CASCADE | Media link (DB FK only) |

### Unique Keys

| BC-REF ID | Table | Constraint Name | Column(s) | Purpose |
|-----------|-------|-----------------|-----------|---------|
| BC-REF-08 | `qns_media_store` | `uq_qms_uuid` | `uuid` | UUID uniqueness |

---

## 9. Test Case Summary

### 9.1 Positive TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-P01 | Create — Media with IMAGE type and required fields | Functional | Creation | High |
| TC-P02 | Create — Media with AUDIO type | Functional | Creation | High |
| TC-P03 | Create — Media with VIDEO type | Functional | Creation | High |
| TC-P04 | Create — Media with PDF type | Functional | Creation | High |
| TC-P05 | Create — Media with all nullable FKs filled (class, subject, lesson, topic) | Functional | Creation | Medium |
| TC-P06 | Create — Media with owner_type = QUESTION | Functional | Creation | Medium |
| TC-P07 | Create — Media with owner_type = OPTION | Functional | Creation | Medium |
| TC-P08 | Create — Media with owner_type = EXPLANATION | Functional | Creation | Medium |
| TC-P09 | Create — Media with owner_type = RECOMMENDATION | Functional | Creation | Medium |
| TC-P10 | Create — Media with custom ordinal value | Edge Case | Creation | Medium |
| TC-P11 | Show — View media details (active) | Functional | View | High |
| TC-P12 | Show — View media details (soft-deleted) | Functional | View | Medium |
| TC-P13 | Edit — Update file_name | Functional | Edit | High |
| TC-P14 | Edit — Replace media file with new file | Functional | Edit | High |
| TC-P15 | Edit — Update owner_type | Functional | Edit | Medium |
| TC-P16 | Edit — Update media_type | Functional | Edit | Medium |
| TC-P17 | Edit — Update is_active status via edit form | Functional | Edit | Medium |
| TC-P18 | Edit — Update disk value | Functional | Edit | Medium |
| TC-P19 | Destroy — Soft delete unused media | Functional | Soft Delete | High |
| TC-P20 | Trashed — View trash listing | Functional | Trash | Medium |
| TC-P21 | Restore — Restore soft-deleted media | Functional | Restore | High |
| TC-P22 | Force Delete — Permanently delete unused media | Functional | Force Delete | High |
| TC-P23 | Toggle Status — Activate/Deactivate media (AJAX) | Functional | Status | High |
| TC-P24 | Toggle Status — Inactive media hidden from active lists | Functional | Status | Medium |
| TC-P25 | Index — Paginated media list loads correctly | Functional | List | Medium |

### 9.2 Negative TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-N01 | Create — Missing required fields (owner_type, media_type, disk) | Validation | Creation | High |
| TC-N02 | Create — Missing media_file (required on create) | Validation | Creation | High |
| TC-N03 | Create — Invalid owner_type value | Validation | Creation | High |
| TC-N04 | Create — Invalid media_type value | Validation | Creation | High |
| TC-N05 | Create — Invalid disk value | Validation | Creation | High |
| TC-N06 | Create — Invalid MIME type for IMAGE (upload PDF when IMAGE expected) | Validation | Creation | High |
| TC-N07 | Create — Invalid MIME type for AUDIO (upload image when AUDIO expected) | Validation | Creation | High |
| TC-N08 | Create — Invalid MIME type for VIDEO (upload audio when VIDEO expected) | Validation | Creation | High |
| TC-N09 | Create — Invalid MIME type for PDF (upload image when PDF expected) | Validation | Creation | High |
| TC-N10 | Create — Non-existent class_id (does not exist in sch_classes) | Validation | Creation | High |
| TC-N11 | Create — Non-existent subject_id | Validation | Creation | High |
| TC-N12 | Create — Non-existent lesson_id | Validation | Creation | High |
| TC-N13 | Create — Non-existent topic_id | Validation | Creation | High |
| TC-N14 | Create — Ordinal less than 1 (ordinal = 0) | Validation | Creation | Medium |
| TC-N15 | Create — File exceeds maximum upload size | Validation | Creation | High |
| TC-N16 | Edit — Non-existent media ID (404) | Validation | Edit | High |
| TC-N17 | Show — Non-existent media ID (404) | Validation | View | High |
| TC-N18 | Destroy — Non-existent media ID (404) | Validation | Delete | High |
| TC-N19 | Restore — Non-existent or non-trashed media ID (404) | Validation | Restore | High |
| TC-N20 | Force Delete — Non-existent media ID (404) | Validation | Force Delete | High |
| TC-N21 | Toggle Status — Non-existent media ID (404) | Validation | Status | High |
| TC-N22 | Create — Without permission (tenant.question-media-store.create) | Auth | Permission | High |
| TC-N23 | Edit — Without permission (tenant.question-media-store.update) | Auth | Permission | High |
| TC-N24 | Delete — Without permission (tenant.question-media-store.delete) | Auth | Permission | High |
| TC-N25 | View Trash — Without permission (tenant.question-media-store.restore) | Auth | Permission | High |
| TC-N26 | Force Delete — Without permission (tenant.question-media-store.forceDelete) | Auth | Permission | High |
| TC-N27 | Toggle Status — Without permission (tenant.question-media-store.update) | Auth | Permission | High |
| TC-N28 | View — Without permission (tenant.question-media-store.view) | Auth | Permission | High |
| TC-N29 | Force Delete — Media linked to questions via junction (cascade test) | Integration | Force Delete | High |

### 9.3 Dependency TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-D01 | Cascade — Force delete cascades to `qns_question_media_jnt` | Integration | Cascade | High |
| TC-D02 | Cascade — Soft delete does NOT cascade to junction | Integration | Cascade | Medium |
| TC-D03 | File — Physical file deleted from storage on force delete | Integration | File Cleanup | High |
| TC-D04 | File — Old physical file deleted when replaced on update | Integration | File Cleanup | High |
| TC-D05 | Business — Activity log entry created on every action | Business Rule | Activity Log | High |
| TC-D06 | Business — is_active boolean cast in model | Business Rule | Model | Medium |
| TC-D07 | Business — UUID auto-generated and unique | Business Rule | UUID | High |
| TC-D08 | Business — File metadata auto-populated on upload | Business Rule | File Upload | High |
| TC-D09 | Cascade — Parent taxonomy deletion SET NULL (class/subject/lesson/topic) | Integration | SET NULL | Medium |


### 9.4 Code Review TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-CR01 | Controller store() — Media creation with file upload flow | Code Review | Controller | High |
| TC-CR02 | Controller show() — With trashed scope | Code Review | Controller | Medium |
| TC-CR03 | Controller edit() — Find or fail | Code Review | Controller | High |
| TC-CR04 | Controller update() — Update with file replacement logic | Code Review | Controller | High |
| TC-CR05 | Controller destroy() — Soft delete with deactivation | Code Review | Controller | High |
| TC-CR06 | Controller trashed() — Trash listing | Code Review | Controller | Medium |
| TC-CR07 | Controller restore() — Restore flow | Code Review | Controller | High |
| TC-CR08 | Controller forceDelete() — Permanent delete with file cleanup | Code Review | Controller | High |
| TC-CR09 | Controller toggleStatus() — AJAX status toggle | Code Review | Controller | High |
| TC-CR10 | Request QuestionMediaStoreRequest — rules() validation | Code Review | Request | High |
| TC-CR11 | Request QuestionMediaStoreRequest — authorize() with gate | Code Review | Request | High |
| TC-CR12 | Policy QuestionMediaStorePolicy — Permission methods | Code Review | Policy | High |
| TC-CR13 | Model QuestionMediaStore — SoftDeletes + fillable + casts | Code Review | Model | High |
| TC-CR14 | Blade @can Directives — Permission visibility | Code Review | View | Medium |
| TC-CR15 | Blade — isset()/null-safe checks for relationship variables | Code Review | View | Medium |
| TC-CR16 | Blade — Success flash messages after CRUD | Code Review | View | Medium |
| TC-CR17 | Storage — File storage/retrieval logic on local and public disks | Code Review | Storage | High |

### 9.5 Total TC Count

| Category | Count |
|----------|-------|
| Positive (TC-P) | 25 |
| Negative (TC-N) | 29 |
| Dependency (TC-D) | 9 |
| Code Review (TC-CR) | 17 |
| **Total** | **80** |

---

## 10. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/question-media-store` | question-media-store.index | index() | tenant.question-media-store.viewAny |
| GET | `/question-media-store/create` | question-media-store.create | create() | tenant.question-media-store.create |
| POST | `/question-media-store` | question-media-store.store | store() | tenant.question-media-store.create |
| GET | `/question-media-store/{question_media_store}` | question-media-store.show | show() | tenant.question-media-store.view |
| GET | `/question-media-store/{question_media_store}/edit` | question-media-store.edit | edit() | tenant.question-media-store.update |
| PUT/PATCH | `/question-media-store/{question_media_store}` | question-media-store.update | update() | tenant.question-media-store.update |
| DELETE | `/question-media-store/{question_media_store}` | question-media-store.destroy | destroy() | tenant.question-media-store.delete |
| GET | `/question-media-store/trash/view` | question-media-store.trashed | trashed() | tenant.question-media-store.restore |
| GET | `/question-media-store/{id}/restore` | question-media-store.restore | restore() | tenant.question-media-store.restore |
| DELETE | `/question-media-store/{id}/force-delete` | question-media-store.forceDelete | forceDelete() | tenant.question-media-store.forceDelete |
| POST | `/question-media-store/{question_media_store}/toggle-status` | question-media-store.toggleStatus | toggleStatus() | tenant.question-media-store.update |

---

## 11. Positive TC Steps

### 11.1 Media Creation (REQ-MEDIA-001)

#### TC-P01: Create — Media with IMAGE type and required fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Question Bank → Question Media Store tab | Tab loads with media list |
| 2 | Click "Add Media" button | Create form loads with empty fields |
| 3 | Select owner_type = "QUESTION" | Owner type selected |
| 4 | Select media_type = "IMAGE" | Media type selected |
| 5 | Select disk = "public" | Disk selected |
| 6 | Upload a valid image file (jpg, 500KB) | File attached |
| 7 | Leave ordinal at default (1) | Default ordinal = 1 |
| 8 | Click "Create Media" | POST store() |
| 9 | Verify redirect to media index with success | `success = flash('created.question_media_store')` |
| 10 | DB check: `qns_media_store` | Record created |
| 11 | DB check: `owner_type` | "QUESTION" |
| 12 | DB check: `media_type` | "IMAGE" |
| 13 | DB check: `disk` | "public" |
| 14 | DB check: `ordinal` | 1 |
| 15 | DB check: `is_active` | 1 (true) |
| 16 | DB check: `uuid` | Generated and non-null (BINARY(16)) |
| 17 | DB check: `file_name` | Original uploaded file name |
| 18 | DB check: `file_path` | Storage path set |
| 19 | DB check: `mime_type` | "image/jpeg" |
| 20 | DB check: `size` | File size in bytes |
| 21 | DB check: `checksum` | SHA-256 checksum set |
| 22 | DB check: `created_at` | Set to current timestamp |
| 23 | Verify activity log | `activityLog()` entry created with event 'Stored' |
| 24 | Verify file exists on storage disk | File present at file_path |

---

#### TC-P02: Create — Media with AUDIO type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Select owner_type = "OPTION" | Owner type selected |
| 3 | Select media_type = "AUDIO" | Media type selected |
| 4 | Select disk = "local" | Disk selected |
| 5 | Upload a valid audio file (mp3, 1MB) | File attached |
| 6 | Click "Create Media" | POST store() |
| 7 | DB check: `media_type` | "AUDIO" |
| 8 | DB check: `mime_type` | "audio/mpeg" |
| 9 | DB check: `disk` | "local" |
| 10 | Verify file exists on local disk | File present |

---

#### TC-P03: Create — Media with VIDEO type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Select owner_type = "EXPLANATION" | Owner type selected |
| 3 | Select media_type = "VIDEO" | Media type selected |
| 4 | Select disk = "public" | Disk selected |
| 5 | Upload a valid video file (mp4, 5MB) | File attached |
| 6 | Click "Create Media" | POST store() |
| 7 | DB check: `media_type` | "VIDEO" |
| 8 | DB check: `mime_type` | "video/mp4" |

---

#### TC-P04: Create — Media with PDF type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Select owner_type = "RECOMMENDATION" | Owner type selected |
| 3 | Select media_type = "PDF" | Media type selected |
| 4 | Select disk = "public" | Disk selected |
| 5 | Upload a valid PDF file (2MB) | File attached |
| 6 | Click "Create Media" | POST store() |
| 7 | DB check: `media_type` | "PDF" |
| 8 | DB check: `mime_type` | "application/pdf" |

---

#### TC-P05: Create — Media with all nullable FKs filled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Select owner_type = "QUESTION" | Owner type selected |
| 3 | Select media_type = "IMAGE" | Media type selected |
| 4 | Select disk = "public" | Disk selected |
| 5 | Select class_id = valid existing class | FK set |
| 6 | Select subject_id = valid existing subject | FK set |
| 7 | Select lesson_id = valid existing lesson | FK set |
| 8 | Select topic_id = valid existing topic | FK set |
| 9 | Upload a valid image file | File attached |
| 10 | Click "Create Media" | POST store() |
| 11 | DB check: `class_id` | Matches selected class |
| 12 | DB check: `subject_id` | Matches selected subject |
| 13 | DB check: `lesson_id` | Matches selected lesson |
| 14 | DB check: `topic_id` | Matches selected topic |

---

#### TC-P06: Create — Media with owner_type = QUESTION

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create media with owner_type = "QUESTION" | Media created |
| 2 | DB check: owner_type | "QUESTION" |

---

#### TC-P07: Create — Media with owner_type = OPTION

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create media with owner_type = "OPTION" | Media created |
| 2 | DB check: owner_type | "OPTION" |

---

#### TC-P08: Create — Media with owner_type = EXPLANATION

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create media with owner_type = "EXPLANATION" | Media created |
| 2 | DB check: owner_type | "EXPLANATION" |

---

#### TC-P09: Create — Media with owner_type = RECOMMENDATION

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create media with owner_type = "RECOMMENDATION" | Media created |
| 2 | DB check: owner_type | "RECOMMENDATION" |

---

#### TC-P10: Create — Media with custom ordinal value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Fill all required fields | Required fields set |
| 3 | Set ordinal = 5 | Ordinal = 5 |
| 4 | Upload image file | File attached |
| 5 | Click "Create Media" | POST store() |
| 6 | DB check: ordinal | 5 |

---

### 11.2 Media Show & View (REQ-MEDIA-002)

#### TC-P11: Show — View media details (active)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media M1 with owner_type="QUESTION", media_type="IMAGE", is_active=1 | M1 exists |
| 2 | Navigate to show page: GET `/question-media-store/{M1}` | Show page loads |
| 3 | Verify owner_type displayed | "QUESTION" shown |
| 4 | Verify media_type displayed | "IMAGE" shown |
| 5 | Verify file_name displayed | File name shown |
| 6 | Verify disk displayed | "public" shown |
| 7 | Verify size displayed | File size in KB/MB |
| 8 | Verify ordinal displayed | Ordinal value shown |
| 9 | Verify status badge | "Active" badge (green) |
| 10 | Verify created_at and updated_at | Timestamps displayed |
| 11 | Verify download button visible | Download link present |
| 12 | Verify preview button visible | Preview link present |

---

#### TC-P12: Show — View media details (soft-deleted)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete Media M1 (has no junction links) | M1 in trash, is_active=0 |
| 2 | Navigate to show page: GET `/question-media-store/{M1}` | 404 — show() uses `findOrFail()` which excludes soft-deleted records |
| 3 | Note: show() does NOT use `withTrashed()` — soft-deleted media are NOT viewable | Controller uses `QuestionMediaStore::findOrFail($id)` |

---

### 11.3 Media Edit & Update (REQ-MEDIA-003)

#### TC-P13: Edit — Update file_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media M1 with file_name="old_image.jpg" | M1 exists |
| 2 | Navigate to edit: GET `/question-media-store/{M1}/edit` | Edit form loads with pre-filled values |
| 3 | Change file_name to "updated_image.jpg" | File name changed |
| 4 | Submit (PUT) without uploading new file | Updated |
| 5 | DB check: file_name | "updated_image.jpg" |
| 6 | Verify activity log | event 'Updated' with changes logged |

---

#### TC-P14: Edit — Replace media file with new file

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media M1 with image file "img1.jpg" on disk | M1 exists with file |
| 2 | Navigate to edit form | Edit form loads |
| 3 | Upload a new image file "img2.jpg" | New file attached |
| 4 | Click Update | PUT store() |
| 5 | DB check: file_name | "img2.jpg" |
| 6 | DB check: file_path | New path for img2 |
| 7 | DB check: size | New file size |
| 8 | DB check: checksum | New checksum |
| 9 | Verify old file "img1.jpg" deleted from storage | Old file removed |
| 10 | Verify new file exists on disk | New file present |
| 11 | Verify activity log | event 'Updated' with changes |

---

#### TC-P15: Edit — Update owner_type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media M1 with owner_type="QUESTION" | M1 exists |
| 2 | Edit: Change owner_type to "OPTION" | Owner type changed |
| 3 | Submit (PUT) | Updated |
| 4 | DB check: owner_type | "OPTION" |

---

#### TC-P16: Edit — Update media_type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media M1 with media_type="IMAGE" | M1 exists |
| 2 | Edit: Change media_type to "PDF" | Media type changed |
| 3 | Submit (PUT) | Updated |
| 4 | DB check: media_type | "PDF" |

---

#### TC-P17: Edit — Update is_active status via edit form

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media M1 with is_active=1 | M1 active |
| 2 | Edit: Toggle is_active = OFF | Status switched |
| 3 | Submit | Updated |
| 4 | DB check: is_active | 0 |
| 5 | Edit again: Toggle is_active = ON | Status switched back |
| 6 | Submit | Updated |
| 7 | DB check: is_active | 1 |

---

#### TC-P18: Edit — Update disk value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media M1 with disk="public" | M1 exists on public disk |
| 2 | Edit: Change disk to "local" | Disk changed |
| 3 | Note: File should be moved/copied to new disk | File transfer expected |
| 4 | Submit (PUT) | Updated |
| 5 | DB check: disk | "local" |

---

### 11.4 Soft Delete, Trash, Restore, Force Delete (REQ-MEDIA-004)

#### TC-P19: Destroy — Soft delete unused media

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media M1 with no junction links | M1 unused |
| 2 | Click Delete on M1 | DELETE `/question-bank/question-media-store/{M1}` |
| 3 | Media is deactivated: `is_active = false; $media->save()` | Pre-save |
| 4 | Media is soft-deleted: `$media->delete()` | deleted_at set |
| 5 | Verify redirect with success | `success = flash('trashed.media_store')` |
| 6 | DB check: deleted_at | NOT NULL |
| 7 | DB check: is_active | 0 |
| 8 | Verify activity log | event 'Trashed' |

---

#### TC-P20: Trashed — View trash listing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete M1, M2 | Both in trash |
| 2 | Navigate to Trash: GET `/question-bank/question-media-store/trash/view` | Trash page loads |
| 3 | Verify M1 and M2 listed | Both shown |
| 4 | Verify only soft-deleted media shown | Active media not in list |
| 5 | DB check: query uses `QuestionMediaStore::onlyTrashed()` | Only trashed records |

---

#### TC-P21: Restore — Restore soft-deleted media

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete M1 | M1 in trash |
| 2 | Navigate to Trash | M1 shown |
| 3 | Click Restore on M1 | GET `/question-bank/question-media-store/{id}/restore` |
| 4 | Controller checks `tenant.question-media-store.restore` permission | Gate passed |
| 5 | `$media->restore()` called | deleted_at = NULL |
| 6 | Verify redirect with success | `success = flash('restored.media_store')` |
| 7 | DB check: deleted_at | NULL |
| 8 | Verify activity log | event 'Restored' |

---

#### TC-P22: Force Delete — Permanently delete unused media

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete M1 (no junction links) | M1 in trash |
| 2 | Navigate to Trash | M1 shown |
| 3 | Click Force Delete on M1 | DELETE `/question-bank/question-media-store/{id}/force-delete` |
| 4 | Controller checks `tenant.question-media-store.forceDelete` permission | Gate passed |
| 5 | `$media->forceDelete()` called | Media permanently removed |
| 6 | Physical file deleted from storage | `Storage::disk()->delete($media->file_path)` called |
| 7 | Verify redirect with success | `success = flash('force_deleted.media_store')` |
| 8 | DB check: M1 withTrashed() | Record gone (permanently deleted) |
| 9 | DB check: File system | File no longer exists on disk |
| 10 | Verify activity log | event 'Deleted' |

---

### 11.5 Status Toggle (REQ-MEDIA-005)

#### TC-P23: Toggle Status — Activate/Deactivate media (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media M1 with is_active=1 | M1 active |
| 2 | Send AJAX POST to toggleStatus | POST `/question-bank/question-media-store/{M1}/toggle-status` |
| 3 | Controller inverts: `is_active = !is_active` | Toggle logic |
| 4 | Verify JSON response | `{"success": true, "is_active": false, "message": ...}` |
| 5 | DB check: is_active | 0 |
| 6 | Send AJAX POST to toggleStatus again | Toggle back |
| 7 | Verify JSON response | `{"success": true, "is_active": true}` |
| 8 | DB check: is_active | 1 |
| 9 | Verify activity log | event 'Status Toggled' |

---

#### TC-P24: Toggle Status — Inactive media hidden from active lists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle M1 is_active = 0 | M1 inactive |
| 2 | Query with `QuestionMediaStore::where('is_active', 1)` | M1 excluded |
| 3 | Toggle M1 is_active = 1 | M1 active again |
| 4 | Query with `QuestionMediaStore::where('is_active', 1)` | M1 included |

---

### 11.6 Index & List (REQ-MEDIA-006)

#### TC-P25: Index — Paginated media list loads correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Question Bank → Question Media Store tab | Tab pane loads |
| 2 | Verify table headers | #, UUID, File Name, Media Type, Owner Type, Disk, Size, Ordinal, Active, Action |
| 3 | Verify search bar present | Search input for file_name / mime_type / media_type |
| 4 | Verify status filter present | All Status / Active / Inactive |
| 5 | Verify media type filter present | All / IMAGE / AUDIO / VIDEO / PDF |
| 6 | Verify pagination | `$media->appends(...)->links()` renders |

---

*Note: download(), preview(), getByOwner(), reorder() controller methods exist but have NO routes registered — these features are unreachable and not tested.*

## 12. Negative TC Steps

### 12.1 Media Creation — Validation Failures

#### TC-N01: Create — Missing required fields (owner_type, media_type, disk)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form with owner_type, media_type, disk empty | Validation errors |
| 2 | Verify `owner_type` error | "Owner type is required." |
| 3 | Verify `media_type` error | "Media type is required." |
| 4 | Verify `disk` error | "Disk is required." |
| 5 | DB check: no media created | 0 new records |

---

#### TC-N02: Create — Missing media_file (required on create)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill owner_type, media_type, disk with valid values | Fields filled |
| 2 | Leave media_file empty (no file uploaded) | No file |
| 3 | Submit create form | Validation error |
| 4 | Verify `media_file` error | "Media file is required." |
| 5 | DB check: no media created | 0 new records |

---

#### TC-N03: Create — Invalid owner_type value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set owner_type = "INVALID_TYPE" | Invalid value |
| 2 | Fill all other required fields valid | Valid other fields |
| 3 | Submit | Validation error: "Selected owner type is invalid." |
| 4 | DB check: no media created | 0 new records |

---

#### TC-N04: Create — Invalid media_type value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set media_type = "DOC" | Invalid value |
| 2 | Fill all other required fields valid | Valid other fields |
| 3 | Submit | Validation error: "Selected media type is invalid." |
| 4 | DB check: no media created | 0 new records |

---

#### TC-N05: Create — Invalid disk value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set disk = "s3" | Invalid value |
| 2 | Fill all other required fields valid | Valid other fields |
| 3 | Submit | Validation error: "Selected disk is invalid." |
| 4 | DB check: no media created | 0 new records |

---

#### TC-N06: Create — Invalid MIME type for IMAGE (upload PDF)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select media_type = "IMAGE" | IMAGE selected |
| 2 | Upload a PDF file (application/pdf) | Wrong MIME type |
| 3 | Submit | Validation error: "Invalid file type. Only jpg, jpeg, png, gif, webp allowed for IMAGE." |
| 4 | DB check: no media created | 0 new records |

---

#### TC-N07: Create — Invalid MIME type for AUDIO (upload image)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select media_type = "AUDIO" | AUDIO selected |
| 2 | Upload a JPG image file | Wrong MIME type |
| 3 | Submit | Validation error: "Invalid file type. Only mp3, wav, ogg allowed for AUDIO." |
| 4 | DB check: no media created | 0 new records |

---

#### TC-N08: Create — Invalid MIME type for VIDEO (upload audio)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select media_type = "VIDEO" | VIDEO selected |
| 2 | Upload an MP3 audio file | Wrong MIME type |
| 3 | Submit | Validation error: "Invalid file type. Only mp4, avi, mov, wmv allowed for VIDEO." |
| 4 | DB check: no media created | 0 new records |

---

#### TC-N09: Create — Invalid MIME type for PDF (upload image)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select media_type = "PDF" | PDF selected |
| 2 | Upload a PNG image file | Wrong MIME type |
| 3 | Submit | Validation error: "Invalid file type. Only pdf allowed for PDF." |
| 4 | DB check: no media created | 0 new records |

---

#### TC-N10: Create — Non-existent class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set class_id = 99999 (non-existent) | Invalid FK |
| 2 | Fill all other required fields valid | Valid other fields |
| 3 | Submit | Validation error: "Class ID must be a valid class." |
| 4 | DB check: no media created | 0 new records |

---

#### TC-N11: Create — Non-existent subject_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set subject_id = 99999 | Invalid FK |
| 2 | Fill all other required fields valid | Valid other fields |
| 3 | Submit | Validation error: "Subject ID must be a valid subject." |
| 4 | DB check: no media created | 0 new records |

---

#### TC-N12: Create — Non-existent lesson_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set lesson_id = 99999 | Invalid FK |
| 2 | Fill all other required fields valid | Valid other fields |
| 3 | Submit | Validation error: "Lesson ID must be a valid lesson." |
| 4 | DB check: no media created | 0 new records |

---

#### TC-N13: Create — Non-existent topic_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set topic_id = 99999 | Invalid FK |
| 2 | Fill all other required fields valid | Valid other fields |
| 3 | Submit | Validation error: "Topic ID must be a valid topic." |
| 4 | DB check: no media created | 0 new records |

---

#### TC-N14: Create — Ordinal less than 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set ordinal = 0 | Value < min:1 |
| 2 | Fill all other required fields valid | Valid other fields |
| 3 | Submit | Validation error: "Ordinal must be at least 1." |
| 4 | DB check: no media created | 0 new records |

---

#### TC-N15: Create — File exceeds maximum upload size

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload a file > 20MB (exceeds max:20480 KB) | Too large |
| 2 | Fill all other required fields valid | Valid other fields |
| 3 | Submit | Validation error: "File too large. Maximum 20MB allowed." |
| 4 | DB check: no media created | 0 new records |

---

### 12.2 Media Edit — Validation Failures

#### TC-N16: Edit — Non-existent media ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/question-media-store/99999/edit` | `QuestionMediaStore::findOrFail(99999)` throws ModelNotFoundException |
| 2 | Verify 404 response | 404 Not Found |

---

#### TC-N17: Show — Non-existent media ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/question-media-store/99999` | `QuestionMediaStore::findOrFail(99999)` throws 404 |
| 2 | Verify 404 response | 404 Not Found |

---

#### TC-N18: Destroy — Non-existent media ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send DELETE to `/question-media-store/99999` | `QuestionMediaStore::findOrFail(99999)` throws 404 |
| 2 | Verify 404 response | 404 Not Found |

---

#### TC-N19: Restore — Non-existent or non-trashed media ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/question-media-store/99999/restore` | `QuestionMediaStore::onlyTrashed()->findOrFail(99999)` throws 404 |
| 2 | Verify 404 response | 404 Not Found |
| 3 | Active media M1 (not trashed) | `onlyTrashed()` returns null (not found) |
| 4 | Attempt restore on M1 | 404 Not Found |

---

#### TC-N20: Force Delete — Non-existent media ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send DELETE to `/question-media-store/99999/force-delete` | `QuestionMediaStore::withTrashed()->findOrFail(99999)` throws 404 |
| 2 | Verify 404 response | 404 Not Found |

---

#### TC-N21: Toggle Status — Non-existent media ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `/question-media-store/99999/toggle-status` | `QuestionMediaStore::findOrFail(99999)` throws 404 |
| 2 | Verify 404 response | 404 Not Found |

---

### 12.3 Permission Gates

#### TC-N22: Create — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-media-store.create` | Authenticated |
| 2 | Navigate to create page | 403 Forbidden |
| 3 | Send POST store directly | 403 Forbidden |

---

#### TC-N23: Edit — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-media-store.update` | Authenticated |
| 2 | Navigate to edit page | 403 Forbidden |
| 3 | Send PUT update directly | 403 Forbidden |

---

#### TC-N24: Delete — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-media-store.delete` | Authenticated |
| 2 | Send DELETE directly | 403 Forbidden |

---

#### TC-N25: View Trash — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-media-store.restore` | Authenticated |
| 2 | Navigate to Trash page | 403 Forbidden |

---

#### TC-N26: Force Delete — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-media-store.forceDelete` | Authenticated |
| 2 | Send DELETE forceDelete directly | 403 Forbidden |

---

#### TC-N27: Toggle Status — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-media-store.update` | Authenticated |
| 2 | Send AJAX POST to toggleStatus | 403 Forbidden |

---

#### TC-N28: View — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-media-store.view` | Authenticated |
| 2 | Navigate to show page | 403 Forbidden |

---

### 12.4 Functional Edge Cases

#### TC-N29: Force Delete — Media linked to questions via junction (cascade test)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media M1, link it to Question Q1 via `qns_question_media_jnt` | Junction record exists |
| 2 | Soft-delete M1 | M1 in trash |
| 3 | Click Force Delete on M1 | `$media->forceDelete()` called |
| 4 | DB check: M1 withTrashed() | Record permanently removed |
| 5 | DB check: `qns_question_media_jnt` where media_id = M1 | Junction record also removed (FK CASCADE) |
| 6 | DB check: `qns_questions_bank` where id = Q1 | Question still exists |

---

## 13. Dependency TC Steps

#### TC-D01: Cascade — Force delete cascades to `qns_question_media_jnt`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media M1 with IMAGE type | M1 exists on disk |
| 2 | Link M1 to Question Q1 via `qns_question_media_jnt` (media_purpose = 'QUESTION') | Junction record exists |
| 3 | Create junction records: M1 linked to Q1 (2 records) | 2 junction records |
| 4 | Force delete M1 | `$media->forceDelete()` called |
| 5 | DB check: `qns_media_store` withTrashed() | M1 permanently gone |
| 6 | DB check: `qns_question_media_jnt` where media_id = M1 | 0 records (FK CASCADE removed) |
| 7 | DB check: `qns_questions_bank` where id = Q1 | Question still exists (FK only on media_id) |

---

#### TC-D02: Cascade — Soft delete does NOT cascade to junction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media M1, link to Q1, Q2 via junction | Junction records exist |
| 2 | Soft-delete M1 (destroy) | M1.deleted_at set |
| 3 | DB check: `qns_question_media_jnt` where media_id = M1 | Junction records still exist (NOT cascade-deleted) |
| 4 | Restore M1 | M1 restored, junction records still intact |

---

#### TC-D03: File — Physical file deleted from storage on force delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media M1 with file "test.jpg" on disk | File exists at file_path |
| 2 | Force delete M1 | M1 permanently removed |
| 3 | DB check: M1 record | Permanently gone |
| 4 | File system check: file at file_path | File no longer exists |
| 5 | Verify `Storage::disk($media->disk)->delete($media->file_path)` called | Controller code calls delete before forceDelete |

---

#### TC-D04: File — Old physical file deleted when replaced on update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media M1 with file "old.jpg" | Old file exists |
| 2 | Update M1 with new file "new.jpg" | New file uploaded |
| 3 | DB check: file_path | New path for "new.jpg" |
| 4 | File system check: old_path | "old.jpg" deleted |
| 5 | File system check: new_path | "new.jpg" exists |
| 6 | Update M1 again with "newer.jpg" | Another replacement |
| 7 | File system check: new_path | "new.jpg" deleted |
| 8 | File system check: newer_path | "newer.jpg" exists |

---

#### TC-D05: Business — Activity log entry created on every action

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media → event 'Stored' | Activity log created |
| 2 | Update Media → event 'Updated' | Activity log created |
| 3 | Soft-delete Media → event 'Trashed' | Activity log created |
| 4 | Restore Media → event 'Restored' | Activity log created |
| 5 | Force delete Media → event 'Deleted' | Activity log created |
| 6 | Toggle status → event 'Toggled' | Activity log created |

---

#### TC-D06: Business — is_active boolean cast in model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media M1 with is_active = 1 (as integer) | Saved |
| 2 | Access `M1->is_active` | Returns `true` (bool, not int) |
| 3 | DB raw value | 1 (TINYINT) |
| 4 | Create Media M2 with is_active = 0 | Saved |
| 5 | Access `M2->is_active` | Returns `false` (bool) |

---

#### TC-D07: Business — UUID auto-generated and unique

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Media M1 | M1.uuid set to BINARY(16) |
| 2 | Create Media M2 | M2.uuid set to different value |
| 3 | DB check: M1.uuid != M2.uuid | Both UUIDs unique |
| 4 | Attempt insert with duplicate M1.uuid manually | DB unique constraint violation |

---

#### TC-D08: Business — File metadata auto-populated on upload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload image file "photo.jpg" (size: 102400 bytes) | File uploaded |
| 2 | DB check: file_name | "photo.jpg" |
| 3 | DB check: mime_type | "image/jpeg" |
| 4 | DB check: size | 102400 |
| 5 | DB check: checksum | Non-null SHA-256 hash (64 chars) |
| 6 | DB check: file_path | Non-null storage path |
| 7 | Verify checksum matches actual file hash | `hash_file('sha256', $file)` matches |

---

#### TC-D09: Cascade — Parent taxonomy deletion SET NULL (class/subject/lesson/topic)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Media M1 references class=C1, subject=S1, lesson=L1, topic=T1 | All FK columns populated |
| 2 | Force delete each parent (C1, S1, L1, T1) individually | Parent deleted |
| 3 | Verify M1 still exists and each FK column = NULL | All SET NULL |

---

#### TC-D10: Cascade — Force delete option cascades to `qns_question_media_jnt`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Junction record J1 links Option O1 to Media M1 via `qns_question_media_jnt` | Junction exists |
| 2 | Force delete O1 from `qns_question_options` | O1 removed |
| 3 | DB check: `qns_question_media_jnt` where question_option_id = O1 | 0 records (FK CASCADE) |
| 4 | DB check: M1 still exists | Media preserved |

---

#### TC-D11: Cascade — Force delete media cascades to `qns_question_media_jnt`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Junction record J1 links Question Q1 to Media M1 via `qns_question_media_jnt` | Junction exists |
| 2 | Force delete M1 from `qns_media_store` | M1 removed |
| 3 | DB check: `qns_question_media_jnt` where media_id = M1 | 0 records (FK CASCADE) |
| 4 | DB check: Q1 still exists | Question preserved |

---

## 14. Code Review TC Steps

#### TC-CR01: Controller store() — Media creation with file upload flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` in `QuestionMediaStoreController` | Gate authorize, file upload, DB insert, activity log |
| 2 | Verify `Gate::authorize('tenant.question-media-store.create')` | Called before any logic |
| 3 | Verify `$request->validated()` | Uses `QuestionMediaStoreRequest` rules |
| 4 | Verify `$request->hasFile('media_file')` | File presence check |
| 5 | Verify file stored via `$request->file('media_file')->store('path', $disk)` | File persisted to disk |
| 6 | Verify `file_name`, `file_path`, `mime_type`, `size`, `checksum` populated from uploaded file | Metadata auto-set |
| 7 | Verify `uuid` generated (e.g., `Str::uuid()->getBytes()`) | BINARY(16) UUID |
| 8 | Verify `QuestionMediaStore::create($mediaData)` | Mass-assignment via fillable |
| 9 | Verify `activityLog($media, 'Stored', ...)` | Activity log created |
| 10 | Verify redirect with success flash | `redirect()->route(...)->with('success', ...)` |

---

#### TC-CR02: Controller show() — findOrFail (no withTrashed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `show()` method | Gate, findOrFail, view |
| 2 | Verify `QuestionMediaStore::findOrFail($id)` — does NOT use withTrashed | Soft-deleted media return 404 |
| 3 | Verify `Gate::authorize('tenant.question-media-store.view')` | Permission check |

---

#### TC-CR03: Controller edit() — Find or fail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `edit()` method | Finds media, loads form |
| 2 | Verify `QuestionMediaStore::findOrFail($id)` | 404 if not found |
| 3 | Verify `Gate::authorize('tenant.question-media-store.update')` | Permission check |

---

#### TC-CR04: Controller update() — Update with file replacement logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `update()` method | Gate, find, handle file replacement, update, activity log |
| 2 | Verify `Gate::authorize('tenant.question-media-store.update')` | Permission check |
| 3 | Verify `$media->getOriginal()` captured before update | Used for change tracking |
| 4 | Verify: if `$request->hasFile('media_file')`, old file deleted, new file stored | File replacement logic |
| 5 | Verify `Storage::disk($media->disk)->delete($media->file_path)` | Old file cleaned up |
| 6 | Verify new `file_name`, `file_path`, `mime_type`, `size`, `checksum` set | Metadata refreshed |
| 7 | Verify `$media->update($request->validated())` | Mass update |
| 8 | Verify `activityLog($media, 'Updated', ...)` | Logs with changes array |
| 9 | Verify redirect with success flash | `redirect()->route(...)` |

---

#### TC-CR05: Controller destroy() — Soft delete with deactivation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `destroy()` method | Gate, find, deactivate, soft delete |
| 2 | Verify `Gate::authorize('tenant.question-media-store.delete')` | Permission check |
| 3 | Verify `$media->is_active = false; $media->save()` | Deactivates before delete |
| 4 | Verify `$media->delete()` | Sets deleted_at |
| 5 | Verify `activityLog($media, 'Trashed', ...)` | Logs deactivation and trash |

---

#### TC-CR06: Controller trashed() — Trash listing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `trashed()` method | `Gate::authorize('tenant.question-media-store.restore')` |
| 2 | Verify `QuestionMediaStore::onlyTrashed()->paginate(10)` | Only soft-deleted records |
| 3 | Verify view returned | `questionbank::question-media-store.trash` |

---

#### TC-CR07: Controller restore() — Restore flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `restore()` method | Gate, find onlyTrashed, restore |
| 2 | Verify `Gate::authorize('tenant.question-media-store.restore')` | Permission check |
| 3 | Verify `QuestionMediaStore::onlyTrashed()->findOrFail($id)` | Finds trashed record |
| 4 | Verify `$media->restore()` | Clears deleted_at |
| 5 | Note: Restore resets is_active to 1 | Controller sets `$media->is_active = true` before `$media->restore()` |
| 6 | Verify `activityLog($media, 'Restored', ...)` | Logs restore |

---

#### TC-CR08: Controller forceDelete() — Permanent delete with file cleanup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `forceDelete()` method | Gate, find withTrashed, delete file, forceDelete |
| 2 | Verify `Gate::authorize('tenant.question-media-store.forceDelete')` | Permission check |
| 3 | Verify `QuestionMediaStore::withTrashed()->findOrFail($id)` | Finds even non-trashed |
| 4 | Verify `Storage::disk($media->disk)->delete($media->file_path)` | Physical file deleted before DB removal |
| 5 | Verify `$media->forceDelete()` | Permanent delete; FK CASCADE handles junction |
| 6 | Verify `activityLog($media, 'Deleted', ...)` | Logs permanent delete |

---

#### TC-CR09: Controller toggleStatus() — AJAX status toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `toggleStatus()` method | Gate, find, invert, save, response |
| 2 | Verify `Gate::authorize('tenant.question-media-store.update')` | Permission check (uses `update` gate, not `status`) |
| 3 | Verify `$media->is_active = !$media->is_active` | Simple boolean inversion |
| 4 | Verify success JSON response | `{"success": true, "is_active": bool, "message": ...}` |
| 5 | Verify `activityLog($media, 'Toggled', ...)` | Activity log |

---

#### TC-CR10: Request QuestionMediaStoreRequest — rules() validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `rules()` method | All field validation rules |
| 2 | Verify `owner_type: required|in:QUESTION,OPTION,EXPLANATION,RECOMMENDATION` | Valid enum values |
| 3 | Verify `class_id: nullable|integer|exists:sch_classes,id` | FK existence |
| 4 | Verify `subject_id: nullable|integer|exists:sch_subjects,id` | FK existence |
| 5 | Verify `lesson_id: nullable|integer|exists:slb_lessons,id` | FK existence |
| 6 | Verify `topic_id: nullable|integer|exists:slb_topics,id` | FK existence |
| 7 | Verify `media_type: required|in:IMAGE,AUDIO,VIDEO,PDF` | Valid enum values |
| 8 | Verify `ordinal: nullable|integer|min:1` | Min value check |
| 9 | Verify `disk: required|in:local,public` | Valid disk values |
| 10 | Verify `media_file: required_on:create|file|mimes:jpeg,png,...|max:20480` | File validation conditional on create |
| 11 | Verify conditional MIME rules based on media_type | IMAGE → jpg/jpeg/png/gif/webp; AUDIO → mp3/wav/ogg; VIDEO → mp4/avi/mov/wmv; PDF → pdf |

---

#### TC-CR11: Request QuestionMediaStoreRequest — authorize() with gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `authorize()` method | Conditional gate check |
| 2 | Verify POST method → `Gate::allows('tenant.question-media-store.create')` | Create permission |
| 3 | Verify PUT/PATCH → `Gate::allows('tenant.question-media-store.update')` | Update permission |

---

#### TC-CR12: Policy QuestionMediaStorePolicy — Permission methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestionMediaStorePolicy` | 8 permission methods |
| 2 | Verify `viewAny`: `tenant.question-media-store.viewAny` | List permission |
| 3 | Verify `view`: `tenant.question-media-store.view` | Show/download/preview permission |
| 4 | Verify `create`: `tenant.question-media-store.create` | Create permission |
| 5 | Verify `update`: `tenant.question-media-store.update` | Update/reorder permission |
| 6 | Verify `delete`: `tenant.question-media-store.delete` | Soft delete permission |
| 7 | Verify `restore`: `tenant.question-media-store.restore` | Restore permission |
| 8 | Verify `forceDelete`: `tenant.question-media-store.forceDelete` | Force delete permission |
| 9 | Verify `status`: `tenant.question-media-store.status` | Policy gate exists but controller toggleStatus() uses `tenant.question-media-store.update` instead |

---

#### TC-CR13: Model QuestionMediaStore — SoftDeletes + fillable + casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify model uses `SoftDeletes` trait | Trait imported |
| 2 | Verify `$fillable` includes all mass-assignable fields | `uuid`, `owner_type`, `class_id`, `subject_id`, `lesson_id`, `topic_id`, `media_type`, `file_name`, `file_path`, `mime_type`, `disk`, `size`, `checksum`, `ordinal`, `is_active` |
| 3 | Verify `$casts` includes `is_active => boolean` | Boolean cast |
| 4 | Verify `$table = 'qns_media_store'` | Correct table name |
| 5 | Verify `$primaryKey = 'id'` | Standard PK |
| 6 | Verify `$dates = ['deleted_at']` | Carbon date casting |
| 7 | Verify no boot events (creating/updating) | Model relies on request-level logic |

---

#### TC-CR14: Blade @can Directives — Permission visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `question-media-store/index.blade.php` — Index table header | `@can('tenant.question-media-store.status')` wraps Active column header; `@canany(['tenant.question-media-store.view', 'tenant.question-media-store.update', 'tenant.question-media-store.delete'])` wraps Action column header |
| 2 | Review `question-media-store/index.blade.php` — Per-row status switch | `@can('tenant.question-media-store.status')` wraps status switch (note: controller uses `update` gate, blade uses `status` — possible mismatch) |
| 3 | Review `question-media-store/index.blade.php` — Per-row action buttons | `@canany(['tenant.question-media-store.view', 'tenant.question-media-store.update', 'tenant.question-media-store.delete'])` wraps actions |
| 4 | Review `question-media-store/view.blade.php` — Edit button | `@can('tenant.question-media-store.update')` wraps Edit button |
| 5 | Review `question-media-store/view.blade.php` — File URL link | `@can('tenant.question-media-store.view')` wraps file URL button |
| 6 | Review `question-media-store/trash.blade.php` — Trash actions | `@canany(['tenant.question-media-store.restore', 'tenant.question-media-store.forceDelete'])` wraps restore and force-delete |
| 7 | Verify: User WITHOUT `tenant.question-media-store.status` | Active column and toggle hidden |
| 8 | Verify: User WITHOUT `tenant.question-media-store.update` | Edit button hidden |
| 9 | Verify: User WITH only `tenant.question-media-store.view` | Index shows only View button; no Edit/Delete |

---

#### TC-CR15: Blade — isset()/null-safe checks for relationship variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `question-media-store/index.blade.php` — Table row | `$media->file_name ?? 'No File'` — null-safe with fallback |
| 2 | Review `question-media-store/index.blade.php` — Owner Type | `$media->owner_type ?? '-'` — null coalescing |
| 3 | Review `question-media-store/index.blade.php` — Created At | `$media->created_at ? $media->created_at->format('Y-m-d') : '-'` — null check |
| 4 | Review `question-media-store/view.blade.php` — File Name | `$media->file_name ?? '-'` — null coalescing |
| 5 | Review `question-media-store/view.blade.php` — Size | `$media->size ? $media->size.' bytes' : 'N/A'` — null check |
| 6 | Review `question-media-store/view.blade.php` — Timestamps | `$media->created_at?->format(...)` — PHP 8 null-safe operator |
| 7 | Review `question-media-store/view.blade.php` — Checksum | `$media->checksum ?? '-'` — null coalescing |
| 8 | Review `question-media-store/trash.blade.php` — File Name | `$item->file_name ?? '-'` — null coalescing |
| 9 | Review `question-media-store/trash.blade.php` — Deleted At | `$item->deleted_at?->format(...)` — null-safe operator |
| 10 | Verify no blade file accesses `$media->relationship->field` without `??` or `?->` | All accesses guarded |

---

#### TC-CR16: Blade — Success flash messages after CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestionMediaStoreController::store()` | `->with('success', flash('created.media_store'))` |
| 2 | Review `QuestionMediaStoreController::update()` | `->with('success', flash('updated.media_store'))` |
| 3 | Review `QuestionMediaStoreController::destroy()` | `->with('success', flash('trashed.media_store'))` |
| 4 | Review `QuestionMediaStoreController::restore()` | `->with('success', flash('restored.media_store'))` |
| 5 | Review `QuestionMediaStoreController::forceDelete()` | `->with('success', flash('force_deleted.media_store'))` |
| 6 | Review `toggleStatus()` JSON response | `flash('status_updated.media_store')` — flashes in JSON message |
| 7 | Verify parent layout renders `session('success')` | Alert component renders flash message |
| 8 | Verify `flash('created.media_store')` resolves | Language key defined |
| 9 | Verify `flash('updated.media_store')` resolves | Language key defined |
| 10 | Verify `flash('trashed.media_store')` resolves | Language key defined |
| 11 | Verify `flash('restored.media_store')` resolves | Language key defined |
| 12 | Verify `flash('force_deleted.media_store')` resolves | Language key defined |

---

#### TC-CR17: Storage — File storage/retrieval logic on local and public disks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review store() file storage: `$request->file('media_file')->store($directory, $disk)` | File stored on correct disk |
| 2 | Review update() file replacement: old file deleted, new file stored | `Storage::disk($disk)->delete($oldPath)` before new upload |
| 3 | Review forceDelete() file cleanup: `Storage::disk($disk)->delete($path)` called | File removed from disk |
| 4 | Review download() file serving: `Storage::disk($disk)->download($path, $name)` | Correct disk and path used |
| 5 | Review preview() file serving: `Storage::disk($disk)->response($path, $name)` | Inline response |
| 6 | Verify disk configuration: `local` → `storage/app/...`, `public` → `storage/app/public/...` | Correct disk roots |
| 7 | Verify symbolic link for public disk | `php artisan storage:link` run |
| 8 | Verify file path is unique (e.g., UUID-based directory) | No filename collisions |

---

## 15. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | Ensure MIME validation rules in QuestionMediaStoreRequest correctly scope per media_type | **Medium** | The `mimes` validation rule must be conditionally applied based on the selected `media_type`. If using a single `mimes` rule for all types, validation may be too permissive. Each media_type should only allow its respective MIME types: IMAGE → jpg,jpeg,png,gif,webp; AUDIO → mp3,wav,ogg; VIDEO → mp4,avi,mov,wmv; PDF → pdf. |
| KI-02 | download, preview, getByOwner, reorder controller methods exist but have NO routes | **Medium** | `QuestionMediaStoreController::download()`, `preview()`, `getByOwner()`, `reorder()` methods exist in code but are unreachable — no routes are registered for them in `web.php`. These features are dead code. |
| KI-03 | toggleStatus() uses `tenant.question-media-store.update` not `tenant.question-media-store.status` | **Medium** | Controller uses `update` gate but the policy has a dedicated `status` gate. Blade views use `@can('tenant.question-media-store.status')` which may allow toggle button but controller will check `update` permission. |
| KI-04 | No QuestionMediaJnt model file exists | **Low** | Junction table `qns_question_media_jnt` exists in DB with FK constraints, but no dedicated Eloquent model class exists. The table is accessed only via FK cascade or raw DB operations. |
| KI-05 | show() does NOT use withTrashed() — soft-deleted media not viewable | **Low** | `show()` method uses `QuestionMediaStore::findOrFail($id)` without `withTrashed()`. Soft-deleted media return 404. |
