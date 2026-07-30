# ntf_Templates_TcList

## Module: Notification → Notification Management → Templates

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Notification |
| Tab Group | Notification Management |
| Feature | Templates |
| URL(s) | `GET /notification-mgt` (tab-index), `GET /templates` (index), `POST /templates` (store), `GET /templates/create` (create), `GET /templates/{template}` (show), `GET /templates/{template}/edit` (edit), `PUT /templates/{template}` (update), `DELETE /templates/{template}` (destroy), `POST /templates/{template}/toggle-status` (toggleStatus), `POST /templates/{id}/approve` (approve), `POST /templates/{id}/duplicate` (duplicate), `POST /templates/{id}/submit-for-approval` (submitForApproval), `POST /templates/{id}/reject` (reject — via inline `reject()` method in controller), `POST /templates/{id}/create-version` (createVersion), `GET /templates/trash/view` (trashed), `GET /templates/{id}/restore` (restore), `DELETE /templates/{id}/force-delete` (forceDelete) |
| Controller | `Modules\Notification\Http\Controllers\TemplateController` |
| Model(s) | `Modules\Notification\Models\NotificationTemplate` (table: `ntf_templates`) |
| Validation | Inline `validateTemplate()` method in `TemplateController` |
| Permissions | `tenant.notification.viewAny`, `.create`, `.view`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.approve` |
| Pagination | **15** records per page (`TemplateController@index` line 62 — `$templates = $templateQuery->latest()->paginate(15)`) |
| Soft Deletes | Yes (SoftDeletes trait); `destroy()` also sets `is_active=false` before `delete()` |
| Activity Log | Events: Trashed, Restored, Deleted, Toggled, Submitted, Approved, Rejected, Version Created |

---

## 2. Pre-conditions

- Required permissions: `tenant.notification.viewAny` for index, `.create` for store/create/createVersion, `.view` for show, `.update` for edit/update/toggleStatus/submitForApproval, `.delete` for destroy, `.restore` for restore/trashed, `.forceDelete` for forceDelete, `.approve` for approve/reject
- Seed data required: At least one `ntf_channel_master` record for `channel_id`
- Test user must have `tenant.notification.*` permissions (default admin user)
- Tenant context must be initialized
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For approval workflow: Users with `.approve` permission for approve/reject actions
- For system templates: BR-NTF-004 — only Prime Super Admin can manage system templates

---

## 3. Default Data Load

When the page loads via `TemplateController@index()` (or via tab), the following data is loaded:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Templates | `TemplateController@index()` lines 32-62 | `NotificationTemplate::with(['channel','creator','tenant'])` | search (template_code, template_name, subject), channel_id, approval_status, language_code, tenant_id, status (is_active) | **15/page** |
| Notifications | Side-loaded | `Notification::with(['priority','confidentialityLevel','notificationStatus','tenant','creator','approver','template'])->latest()` | — | 10/page |
| Channels | Side-loaded | `ChannelMaster::query()` | search, status | 10/page |
| Providers | Side-loaded | `ProviderMaster::with('channel')` | search, channel_id, provider_type, status | 10/page |
| Target Groups | Side-loaded | `TargetGroup::with('creator')` | search, group_type, system, status | 10/page |
| Targets | Side-loaded | `NotificationTarget::with(['notification','targetType','targetGroup'])` | search, notification_id, target_type_id, has_group, status | 10/page |
| User Preferences | Side-loaded | `UserPreference::with(['user','channel','priorityThreshold'])` | search, user_id, channel_id, is_enabled, is_opted_in, daily_digest, has_quiet_hours, status | 10/page |
| Threads | Side-loaded | `NotificationThread::with(['parentThread','rootNotification'])` | search, thread_type, has_parent, status | 10/page |
| Thread Members | Side-loaded | `NotificationThreadMember::with(['thread','notification'])->ordered()` | search, thread_id, notification_id | 10/page |

---

## 4. Test Data Strategy

- **Code uniqueness**: `template_code` must be unique per tenant per version — suffix test data with timestamp
- **Approval workflow**: DRAFT → PENDING → APPROVED/REJECTED → ARCHIVED — test all transitions
- **Versioning**: `createVersion()` replicates template with version+1 and resets to DRAFT
- **Duplicate**: `duplicate()` creates a copy — test that it creates a new record
- **System templates (BR-NTF-004)**: Only Prime Super Admin can manage system templates
- **BR-NTF-005**: Only Approved templates can be dispatched
- **canBeEdited()**: Returns false for APPROVED and ARCHIVED statuses
- **Pre-test cleanup**: Delete created templates by `template_code` before/after tests
- **Pagination**: Use 15-record page size (unique among features)
- **Approval transitions**: Verify only valid transitions are allowed (DRAFT→PENDING, PENDING→APPROVED/REJECTED, APPROVED→ARCHIVED)

---

## 5. Business Conditions

### 5.1 Database Schema — `ntf_templates`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | tenant_id | VARCHAR(255) | FK → tenants.id, NULLABLE |
| BC-DB-03 | template_code | VARCHAR(50) | NOT NULL, UNIQUE(tenant_id, template_code, template_version) |
| BC-DB-04 | template_name | VARCHAR(100) | NOT NULL |
| BC-DB-05 | channel_id | BIGINT UNSIGNED | FK → ntf_channel_master.id, NOT NULL |
| BC-DB-06 | template_version | INT | NOT NULL DEFAULT 1 |
| BC-DB-07 | subject | VARCHAR(255) | NULLABLE |
| BC-DB-08 | body | TEXT | NOT NULL |
| BC-DB-09 | alt_body | TEXT | NULLABLE |
| BC-DB-10 | placeholders | JSON | NULLABLE |
| BC-DB-11 | language_code | VARCHAR(10) | NOT NULL DEFAULT 'en' |
| BC-DB-12 | media_id | BIGINT UNSIGNED | FK → sys_media.id, NULLABLE |
| BC-DB-13 | is_system_template | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-14 | approval_status | ENUM('DRAFT','PENDING','APPROVED','REJECTED','ARCHIVED') | NOT NULL DEFAULT 'DRAFT' |
| BC-DB-15 | approved_by | BIGINT UNSIGNED | FK → sys_users.id, NULLABLE |
| BC-DB-16 | approved_at | DATETIME | NULLABLE |
| BC-DB-17 | effective_from | DATETIME | NULLABLE |
| BC-DB-18 | effective_to | DATETIME | NULLABLE |
| BC-DB-19 | is_active | BOOLEAN | NOT NULL DEFAULT true |
| BC-DB-20 | created_by | BIGINT UNSIGNED | FK → sys_users.id, NULLABLE |
| BC-DB-21 | created_at | TIMESTAMP | NULLABLE |
| BC-DB-22 | updated_at | TIMESTAMP | NULLABLE |
| BC-DB-23 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules — `validateTemplate()` (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | template_code | required, string, max:100, unique:ntf_templates per (tenant_id, template_version) | — |
| BC-VAL-02 | template_name | required, string, max:255 | — |
| BC-VAL-03 | channel_id | required, integer, exists:ntf_channel_master,id | — |
| BC-VAL-04 | template_version | nullable, integer, min:1 | — |
| BC-VAL-05 | subject | nullable, string, max:255 | — |
| BC-VAL-06 | body | required, string | — |
| BC-VAL-07 | alt_body | nullable, string | — |
| BC-VAL-08 | placeholders | nullable, json | — |
| BC-VAL-09 | language_code | nullable, string, max:10 | — |
| BC-VAL-10 | media_id | nullable, integer, exists:sys_media,id | — |
| BC-VAL-11 | is_system_template | nullable, boolean | — |
| BC-VAL-12 | approval_status | nullable, in:DRAFT,PENDING,APPROVED,REJECTED,ARCHIVED | — |
| BC-VAL-13 | effective_from | nullable, date | — |
| BC-VAL-14 | effective_to | nullable, date, after:effective_from | — |
| BC-VAL-15 | is_active | nullable, boolean | — |
| BC-VAL-16 | tenant_id | required|string|exists:tenants,id (only when tenant() is null — central context) | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `tenant.notification.viewAny` | index — without → 403 |
| BC-AUTH-02 | `tenant.notification.create` | create, store, createVersion — without → 403 |
| BC-AUTH-03 | `tenant.template.view` | show — without → 403 |
| BC-AUTH-04 | `tenant.notification.update` | edit, update, toggleStatus, submitForApproval — without → 403 |
| BC-AUTH-05 | `tenant.notification.delete` | destroy — without → 403 |
| BC-AUTH-06 | `tenant.notification.restore` | trashed, restore — without → 403 |
| BC-AUTH-07 | `tenant.notification.forceDelete` | forceDelete — without → 403 |
| BC-AUTH-08 | `tenant.notification.approve` | approve, reject — without → 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with templates tab | Paginated grid at **15 records/page**, ordered by latest, with channel/creator/tenant relationships loaded |
| BC-BIZ-02 | Search by template_code | Filters where template_code contains search term |
| BC-BIZ-03 | Search by template_name | Filters where template_name contains search term |
| BC-BIZ-04 | Search by subject | Filters where subject contains search term |
| BC-BIZ-05 | Filter by channel_id | Exact match on channel_id |
| BC-BIZ-06 | Filter by approval_status | Exact match on approval_status (DRAFT/PENDING/APPROVED/REJECTED/ARCHIVED) |
| BC-BIZ-07 | Filter by language_code | Exact match on language_code |
| BC-BIZ-08 | Filter by tenant_id | Exact match on tenant_id |
| BC-BIZ-09 | Filter by status | Filters by is_active |
| BC-BIZ-10 | Create template — DRAFT status | Template created with approval_status = DRAFT |
| BC-BIZ-11 | Create template with all fields | All fields saved correctly |
| BC-BIZ-12 | Template code auto-uppercased | `setTemplateCodeAttribute()` mutator converts to uppercase |
| BC-BIZ-13 | Create template with placeholders.json | Placeholders saved as JSON array |
| BC-BIZ-14 | Edit template — DRAFT | Edit form loads (canBeEdited() == true) |
| BC-BIZ-15 | Edit template — APPROVED blocked | Redirect with error: "Template cannot be edited in its current approval status" |
| BC-BIZ-16 | Edit template — ARCHIVED blocked | Same error as APPROVED (canBeEdited() returns false) |
| BC-BIZ-17 | Update template — DRAFT | Update succeeds |
| BC-BIZ-18 | Update template — APPROVED blocked | Redirect with error |
| BC-BIZ-19 | submitForApproval — DRAFT or REJECTED | Status changed to PENDING, JSON success |
| BC-BIZ-20 | submitForApproval — non-DRAFT/REJECTED blocked | Error: "Template cannot be submitted for approval" (400) |
| BC-BIZ-21 | approve — PENDING | Status changed to APPROVED, approved_by and approved_at set, JSON success |
| BC-BIZ-22 | approve — non-PENDING blocked | Error: "Template is not pending approval" (400) |
| BC-BIZ-23 | reject — PENDING | Status changed to REJECTED, optional reason, JSON success |
| BC-BIZ-24 | reject — non-PENDING blocked | Error: "Template is not pending approval" (400) |
| BC-BIZ-25 | createVersion from APPROVED template | New version created with version+1, status=DRAFT, approved_by=null |
| BC-BIZ-26 | createVersion from DRAFT template | New version created with version+1 |
| BC-BIZ-27 | Duplicate template | New copy created as DRAFT with same content |
| BC-BIZ-28 | BR-NTF-005: Only Approved templates can be dispatched | If template is not APPROVED, dispatch operations should fail |
| BC-BIZ-29 | BR-NTF-004: System templates managed only by Prime Super Admin | Non-super-admin users cannot modify system templates |
| BC-BIZ-30 | Toggle status active→inactive | AJAX toggles is_active, activity logged |
| BC-BIZ-31 | Soft delete template | Template moved to trash, is_active set to false |
| BC-BIZ-32 | View trashed templates | Trash page lists soft-deleted records filtered by tenant |
| BC-BIZ-33 | Restore trashed template | Template restored |
| BC-BIZ-34 | Force delete template | Permanently removed with error handling |
| BC-BIZ-35 | Empty state — no templates | Grid shows empty state |
| BC-BIZ-36 | Pagination — 15 per page | Page 1 shows up to 15 templates |
| BC-BIZ-37 | Show page with relationships | Channel, media, creator, approver, tenant displayed; placeholders rendered as JSON |
| BC-BIZ-38 | validateTemplate conditional tenant_id rule | tenant_id required only when tenant() is null (central context) |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | tenant_id | tenants (id) | CASCADE |
| BC-REF-02 | channel_id | ntf_channel_master (id) | CASCADE |
| BC-REF-03 | media_id | sys_media (id) | SET NULL |
| BC-REF-04 | approved_by | sys_users (id) | SET NULL |
| BC-REF-05 | created_by | sys_users (id) | SET NULL |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Templates page loads with all UI elements | Page loads with search bar, filters (channel, approval_status, language_code, status), Add button, grid (15/page) | — | — | ⬜ |
| TC-P02 | Search by template_code | Grid filtered to matching code | — | — | ⬜ |
| TC-P03 | Search by template_name | Grid filtered to matching name | — | — | ⬜ |
| TC-P04 | Search by subject | Grid filtered to matching subject | — | — | ⬜ |
| TC-P05 | Filter by channel_id | Grid shows templates for selected channel | — | — | ⬜ |
| TC-P06 | Filter by approval_status = DRAFT | Grid shows only DRAFT templates | — | — | ⬜ |
| TC-P07 | Filter by approval_status = PENDING | Grid shows only PENDING templates | — | — | ⬜ |
| TC-P08 | Filter by approval_status = APPROVED | Grid shows only APPROVED templates | — | — | ⬜ |
| TC-P09 | Filter by approval_status = REJECTED | Grid shows only REJECTED templates | — | — | ⬜ |
| TC-P10 | Filter by approval_status = ARCHIVED | Grid shows only ARCHIVED templates | — | — | ⬜ |
| TC-P11 | Filter by language_code | Grid shows templates for selected language | — | — | ⬜ |
| TC-P12 | Filter by tenant_id | Grid shows templates for selected tenant | — | — | ⬜ |
| TC-P13 | Filter by active status | Grid shows only active templates | — | — | ⬜ |
| TC-P14 | Filter by inactive status | Grid shows only inactive templates | — | — | ⬜ |
| TC-P15 | Create template — DRAFT with all fields | Template created with approval_status=DRAFT | — | — | ⬜ |
| TC-P16 | Create template with placeholders JSON | Placeholders saved as JSON array | — | — | ⬜ |
| TC-P17 | Create template — code auto-uppercased | Code stored uppercase via mutator | — | — | ⬜ |
| TC-P18 | Create template with language_code = 'en' | Default language is 'en' | — | — | ⬜ |
| TC-P19 | View template show page | Show page renders channel, media, creator, approver, placeholders | — | — | ⬜ |
| TC-P20 | Edit DRAFT template | Edit form loads | — | — | ⬜ |
| TC-P21 | Update DRAFT template | Update succeeds | — | — | ⬜ |
| TC-P22 | submitForApproval — from DRAFT | Status changes to PENDING | — | — | ⬜ |
| TC-P23 | submitForApproval — from REJECTED | Status changes to PENDING | — | — | ⬜ |
| TC-P24 | approve — from PENDING | Status changes to APPROVED, approved_by and approved_at set | — | — | ⬜ |
| TC-P25 | reject — from PENDING (with reason) | Status changes to REJECTED, reason logged | — | — | ⬜ |
| TC-P26 | createVersion from APPROVED template | New version created with version+1, status=DRAFT | — | — | ⬜ |
| TC-P27 | createVersion from DRAFT template | New version created with version+1 | — | — | ⬜ |
| TC-P28 | Duplicate template | Copy created as DRAFT | — | — | ⬜ |
| TC-P29 | Full approval workflow: DRAFT → PENDING → APPROVED | All transitions succeed | — | — | ⬜ |
| TC-P30 | Full approval workflow: DRAFT → PENDING → REJECTED → PENDING → APPROVED | Resubmission from REJECTED works | — | — | ⬜ |
| TC-P31 | Toggle status active to inactive | AJAX success, is_active flipped | — | — | ⬜ |
| TC-P32 | Soft delete template | Template moved to trash, is_active=false | — | — | ⬜ |
| TC-P33 | View trashed templates | Trash page with tenant filter | — | — | ⬜ |
| TC-P34 | Restore trashed template | Template restored | — | — | ⬜ |
| TC-P35 | Force delete template | Permanently removed | — | — | ⬜ |
| TC-P36 | Full lifecycle with versioning: create→submit→approve→version→edit new version | All succeed | — | — | ⬜ |
| TC-P37 | Pagination — first page 15 records | Page 1 shows up to 15 | — | — | ⬜ |
| TC-P38 | Pagination — second page | Page 2 shows records 16+ | — | — | ⬜ |
| TC-P39 | Empty state — no templates | Grid shows empty state | — | — | ⬜ |
| TC-P40 | Create template with effective dates | effective_from and effective_to saved | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — missing `template_code` | Validation error | — | — | ⬜ |
| TC-N02 | Required — missing `template_name` | Validation error | — | — | ⬜ |
| TC-N03 | Required — missing `channel_id` | Validation error | — | — | ⬜ |
| TC-N04 | Required — missing `body` | Validation error | — | — | ⬜ |
| TC-N05 | Duplicate template_code per tenant+version | Unique validation error | — | — | ⬜ |
| TC-N06 | Invalid channel_id (non-existent) | Exists validation error | — | — | ⬜ |
| TC-N07 | Invalid media_id (non-existent) | Exists validation error | — | — | ⬜ |
| TC-N08 | Invalid approval_status value | In validation error | — | — | ⬜ |
| TC-N09 | effective_to before effective_from | After validation error | — | — | ⬜ |
| TC-N10 | Edit APPROVED template (blocked) | Redirect: "Template cannot be edited in its current approval status" | — | — | ⬜ |
| TC-N11 | Edit ARCHIVED template (blocked) | Same error as above | — | — | ⬜ |
| TC-N12 | Update APPROVED template (blocked) | Redirect with error | — | — | ⬜ |
| TC-N13 | submitForApproval from APPROVED | 400 error: "Template cannot be submitted for approval" | — | — | ⬜ |
| TC-N14 | approve from DRAFT | 400 error: "Template is not pending approval" | — | — | ⬜ |
| TC-N15 | approve from REJECTED | 400 error: "Template is not pending approval" | — | — | ⬜ |
| TC-N16 | approve from ARCHIVED | 400 error | — | — | ⬜ |
| TC-N17 | reject from DRAFT | 400 error | — | — | ⬜ |
| TC-N18 | reject from APPROVED | 400 error | — | — | ⬜ |
| TC-N19 | View non-existent template | 404 Not Found | — | — | ⬜ |
| TC-N20 | Edit non-existent template | 404 Not Found | — | — | ⬜ |
| TC-N21 | Update non-existent template | 404 Not Found | — | — | ⬜ |
| TC-N22 | Delete non-existent template | 404 Not Found | — | — | ⬜ |
| TC-N23 | Unauthorized access without permission | 403 Forbidden | — | — | ⬜ |
| TC-N24 | Max length — template_code > 100 | Validation error on max:100 | — | — | ⬜ |
| TC-N25 | Max length — template_name > 255 | Validation error on max:255 | — | — | ⬜ |
| TC-N26 | Max length — subject > 255 | Validation error on max:255 | — | — | ⬜ |
| TC-N27 | Invalid JSON in placeholders | Validation error on json | — | — | ⬜ |
| TC-N28 | template_version < 1 | Validation error on min:1 | — | — | ⬜ |
| TC-N29 | language_code > 10 chars | Validation error on max:10 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-D01 | Create notification referencing template | Notification-template relationship works | — | — | ⬜ |
| TC-D02 | Delete channel with templates | Templates referencing channel remain (SET NULL or CASCADE?) | — | — | ⬜ |
| TC-D03 | Create resolved recipient with template | Template referenced from resolved recipient | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-CR01 | `validateTemplate()` rules | All 16(15+1) field rules enforced as per section 5.2 | — | — | ◌ |
| TC-CR02 | `canBeEdited()` logic | Returns false for APPROVED; true for DRAFT/PENDING/REJECTED | — | — | ◌ |
| TC-CR03 | Approval workflow transitions | Store/set: DRAFT; submitForApproval: DRAFT/REJECTED→PENDING; approve: PENDING→APPROVED; reject: PENDING→REJECTED | — | — | ◌ |
| TC-CR04 | createVersion replication | `$oldTemplate->replicate()` with version+1 and reset approval | — | — | ◌ |
| TC-CR05 | Template code uppercase mutator | `setTemplateCodeAttribute()` in model converts to uppercase | — | — | ◌ |
| TC-CR06 | Conditional tenant_id validation | `if (!$tenantId)` block adds tenant_id rules | — | — | ◌ |
| TC-CR07 | Pagination — 15 per page | `paginate(15)` used in index() | — | — | ◌ |
| TC-CR08 | Approve/reject check for PENDING only | `$template->isPending()` guard before status change | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Templates page loads
1. Login as admin user with `tenant.notification.viewAny`
2. Navigate to `GET /templates`
3. Verify page loads (200 OK) with search bar, filters (channel_id, approval_status, language_code, status), "Add Template" button, grid with 15 records per page

#### TC-P02 through TC-P14: Search and filter tests
1. Apply each search/filter and verify grid data

#### TC-P15: Create template — DRAFT
1. Click "Add Template"
2. Fill template_code="WELCOME_EMAIL", template_name="Welcome Email", channel_id=1 (EMAIL), subject="Welcome {{name}}!", body="Hello {{name}}, welcome to our platform!", placeholders=`[{"key":"name","type":"string"}]`
3. Submit
4. Verify 302 redirect with success message
5. Verify template appears in grid with approval_status = DRAFT

#### TC-P16: Create with placeholders
1. Submit with JSON placeholders
2. Verify stored as JSON array in DB

#### TC-P17: Code auto-uppercased
1. Create with template_code="test_code"
2. Verify displayed as "TEST_CODE"

#### TC-P18: Default language 'en'
1. Create without setting language_code
2. Verify language_code saved as 'en'

#### TC-P19: Show page
1. View a template
2. Verify channel, media, creator, approver, tenant, and placeholders displayed

#### TC-P20 through TC-P21: Edit/Update DRAFT
1. Edit DRAFT template
2. Update content
3. Verify changes saved

#### TC-P22: submitForApproval from DRAFT
1. Create DRAFT template
2. POST to `/templates/{id}/submit-for-approval`
3. Verify JSON: `{"success": true, "message": "Template submitted for approval"}`
4. Verify approval_status = PENDING

#### TC-P23: submitForApproval from REJECTED
1. Reject a PENDING template first
2. Submit for approval again from REJECTED
3. Verify status becomes PENDING

#### TC-P24: approve from PENDING
1. Have a PENDING template
2. POST to `/templates/{id}/approve`
3. Verify JSON: `{"success": true, "message": "Template approved successfully"}`
4. Verify approval_status = APPROVED, approved_by set, approved_at set

#### TC-P25: reject from PENDING (with reason)
1. Have a PENDING template
2. POST to `/templates/{id}/reject` with `{"reason": "Body needs revision"}`
3. Verify JSON: `{"success": true, "message": "Template rejected successfully"}`
4. Verify approval_status = REJECTED

#### TC-P26: createVersion from APPROVED
1. APPROVED template exists
2. POST to `/templates/{id}/create-version`
3. Verify new template created with version+1, status=DRAFT
4. Verify redirect to edit the new version

#### TC-P27: createVersion from DRAFT
1. Same as above but starting from DRAFT

#### TC-P28: Duplicate template
1. POST to `/templates/{id}/duplicate`
2. Verify new copy created as DRAFT

#### TC-P29 through TC-P30: Full approval workflows
1. Execute full approval cycle chains

#### TC-P31: Toggle status
1. POST to `/templates/{template}/toggle-status`
2. Verify JSON success

#### TC-P32 through TC-P35: Soft delete, trash, restore, force delete
1. Standard CRUD tests

#### TC-P36: Full lifecycle with versioning
1. Create → submit → approve → create version → edit new version → verify old version preserved

#### TC-P37 through TC-P39: Pagination and empty state
1. Standard tests (note: 15 per page)

#### TC-P40: Effective dates
1. Create template with effective_from and effective_to
2. Verify dates saved

### 7.2 Negative TC Steps

#### TC-N01 through TC-N09: Validation errors
1. Test each required field, max lengths, invalid FK values, bad JSON, and effective_to before effective_from

#### TC-N10 through TC-N12: Edit/update blocked for APPROVED/ARCHIVED
1. Set template to APPROVED
2. Try to edit — verify redirect with error "Template cannot be edited in its current approval status"
3. Try to update — same error

#### TC-N13 through TC-N18: Invalid approval transitions
1. Test approve/reject/submit from wrong current status — verify 400 errors

#### TC-N19 through TC-N23: 404 and 403
1. Standard error tests

#### TC-N24 through TC-N29: Validation edge cases
1. Max length, min values, JSON format

### 7.3 Dependency TC Steps

#### TC-D01: Notification referencing template
1. Create template
2. Create notification with template_id
3. Verify relationship

#### TC-D02: Delete channel with templates
1. Create channel and template referencing it
2. Delete channel
3. Verify template still exists (SET NULL or CASCADE — check DDL)

#### TC-D03: Resolved recipient with template
1. Create template
2. Create resolved recipient with template_id
3. Verify relationship

### 7.4 Code Review TC Steps

#### TC-CR01: validateTemplate rules
1. Review `TemplateController@validateTemplate()` lines 693-732
2. Verify all 16 rule entries
3. Verify conditional tenant_id validation (`if (!$tenantId) { ... }`)

#### TC-CR02: canBeEdited() logic
1. Review `NotificationTemplate::canBeEdited()` (model line 126-129)
2. Verify `return $this->approval_status !== self::APPROVAL_STATUS_APPROVED` — note: ARCHIVED also not handled? Check if should return false for ARCHIVED too
3. Verify usage in edit() and update()

#### TC-CR03: Approval workflow state machine
1. Review submitForApproval(): only from DRAFT or REJECTED
2. Review approve(): only from PENDING
3. Review reject(): only from PENDING

#### TC-CR04: createVersion replication
1. Review createVersion() lines 669-691
2. Verify `$oldTemplate->replicate()` used
3. Verify version incremented via `$oldTemplate->getNextVersion()`
4. Verify approvals reset: `$newTemplate->approval_status = DRAFT; $newTemplate->approved_by = null; $newTemplate->approved_at = null;`

#### TC-CR05: Template code mutator
1. Review `NotificationTemplate::setTemplateCodeAttribute()` (model line 168-171)
2. Verify `$this->attributes['template_code'] = strtoupper($value)`

#### TC-CR06: Conditional tenant_id
1. Review validateTemplate() lines 723-728
2. Verify tenant_id rules only added when `!$tenantId`

#### TC-CR07: Pagination 15
1. Review index() line 62
2. Verify `$templates = $templateQuery->latest()->paginate(15)`

#### TC-CR08: isPending() guard
1. Review approve() line 614: `if ($template->isPending())`
2. Review reject() line 647: `if ($template->isPending())`
