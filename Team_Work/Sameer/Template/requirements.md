# Requirements Document: Cognitive Skills Tab (Controller-Accurate)

## Files Used
- /home/hp/Documents/laravel/database/migrations/tenant/2026_01_06_161741_create_cognitive_skills_table.php
- /home/hp/Documents/laravel/Modules/Syllabus/app/Models/CognitiveSkill.php
- /home/hp/Documents/laravel/Modules/Syllabus/app/Http/Requests/CognitiveSkillRequest.php
- /home/hp/Documents/laravel/Modules/Syllabus/app/Http/Controllers/CognitiveSkillController.php
- /home/hp/Documents/laravel/Modules/Syllabus/resources/views/lesson-management/partials/cognitive-skill/index.blade.php
- /home/hp/Documents/laravel/Modules/Syllabus/resources/views/lesson-management/partials/cognitive-skill/create.blade.php
- /home/hp/Documents/laravel/Modules/Syllabus/resources/views/lesson-management/partials/cognitive-skill/edit.blade.php
- /home/hp/Documents/laravel/Modules/Syllabus/resources/views/lesson-management/partials/cognitive-skill/view.blade.php
- /home/hp/Documents/laravel/Modules/Syllabus/resources/views/lesson-management/partials/cognitive-skill/trash.blade.php
- /home/hp/Documents/laravel/resources/views/components/backend/tab/search-bar.blade.php
- /home/hp/Documents/laravel/resources/views/components/backend/table/action.blade.php
- /home/hp/Documents/laravel/app/View/Components/Backend/Table/Action.php
- /home/hp/Documents/laravel/resources/views/components/backend/table/status-switch.blade.php
- /home/hp/Documents/laravel/app/View/Components/Backend/Table/StatusSwitch.php
- /home/hp/Documents/laravel/resources/views/components/backend/table/action-trashed.blade.php
- /home/hp/Documents/laravel/routes/tenant.php

## 1) Feature Overview
- The Cognitive Skills feature manages cognitive skills, optionally linked to a Bloom Taxonomy.
- It is shown as a tab inside Lesson Management and includes create, edit, view, trash, restore, force delete, and status toggle.

## 2) Exact Routes and Endpoints
All routes are under prefix /syllabus and name prefix syllabus.

Resource routes:
- GET /syllabus/cognitive-skill - name syllabus.cognitive-skill.index - CognitiveSkillController@index
- GET /syllabus/cognitive-skill/create - name syllabus.cognitive-skill.create - CognitiveSkillController@create
- POST /syllabus/cognitive-skill - name syllabus.cognitive-skill.store - CognitiveSkillController@store
- GET /syllabus/cognitive-skill/{cognitive_skill} - name syllabus.cognitive-skill.show - CognitiveSkillController@show
- GET /syllabus/cognitive-skill/{cognitive_skill}/edit - name syllabus.cognitive-skill.edit - CognitiveSkillController@edit
- PUT /syllabus/cognitive-skill/{cognitive_skill} - name syllabus.cognitive-skill.update - CognitiveSkillController@update
- PATCH /syllabus/cognitive-skill/{cognitive_skill} - name syllabus.cognitive-skill.update - CognitiveSkillController@update
- DELETE /syllabus/cognitive-skill/{cognitive_skill} - name syllabus.cognitive-skill.destroy - CognitiveSkillController@destroy

Additional routes:
- GET /syllabus/cognitive-skill/trash/view - name syllabus.cognitive-skill.trashed - CognitiveSkillController@trashed
- GET /syllabus/cognitive-skill/{id}/restore - name syllabus.cognitive-skill.restore - CognitiveSkillController@restore
- DELETE /syllabus/cognitive-skill/{id}/force-delete - name syllabus.cognitive-skill.forceDelete - CognitiveSkillController@forceDelete
- POST /syllabus/cognitive-skill/{section}/toggle-status - name syllabus.cognitive-skill.toggleStatus - CognitiveSkillController@toggleStatus

## 3) Permissions, Policies, Guards
- All routes are under auth and verified middleware.
- Controller uses tenant.subject.* permissions:
  - index: tenant.subject.viewAny
  - create, store: tenant.subject.create
  - edit, update, toggleStatus: tenant.subject.update
  - show: tenant.subject.view
  - destroy: tenant.subject.delete
  - trashed, restore: tenant.subject.restore
  - forceDelete: tenant.subject.forceDelete

View-level permissions:
- Status column in tab is shown under @can('tenant.cognitive-skill.status').
- Action column is shown under @canany(['tenant.cognitive-skill.view','tenant.cognitive-skill.edit','tenant.cognitive-skill.delete']).
- Edit button on view page is guarded by @can('tenant.cognitive-skill.edit').
- Create/Trash buttons in search-bar are always visible because permission checks are commented out.

## 4) Validation Rules (CognitiveSkillRequest)
- bloom_id nullable.
- code required, string, max 20, alpha only, unique in slb_cognitive_skill.code (ignore current id).
- name required, string, max 100.
- description nullable string max 255.
- is_active nullable boolean.

PrepareForValidation:
- code is uppercased.
- is_active set to true only if input exists and equals 'on'; otherwise false.

## 5) DB Behavior (Migration + Model)
Table: slb_cognitive_skill.

Columns:
- id bigint primary key.
- bloom_id nullable FK to slb_bloom_taxonomy, null on delete.
- code string(20) unique.
- name string(100).
- description string(255) nullable.
- is_active boolean default true.
- timestamps and soft deletes.

Model behavior:
- SoftDeletes enabled.
- Fillable: bloom_id, code, name, description, is_active.
- Casts bloom_id to integer and is_active to boolean.
- Relationship: bloomTaxonomy belongsTo BloomTaxonomy by bloom_id.
- Scopes: active(), byCode(), forBloom().

## 6) UI Behavior from Views
Tab list (index.blade.php):
- Search bar with search input and bloom_id dropdown; submits GET to syllabus.lesson.index.
- Table columns: code, name, bloom taxonomy badge, description, status, action.
- Status toggle uses x-backend.table.status-switch with permission tenant.cognitive-skill.status.
- Action buttons use x-backend.table.action.
- Empty state: No Cognitive Skills Found.
- Pagination shown.

Create view:
- Breadcrumb: Cognitive Skills -> Add New Cognitive Skill.
- Validation errors shown in red alert list.
- Fields: bloom_id (optional), code, name, description, status switch.
- Submit button: Add Cognitive Skill.

Edit view:
- Breadcrumb: Cognitive Skills -> Edit Cognitive Skill.
- Fields same as create, prefilled.
- Submit button: Update Cognitive Skill.

View page:
- Breadcrumb: Cognitive Skill Management -> View Cognitive Skill.
- Back button always visible.
- Edit button visible if tenant.cognitive-skill.edit.
- Shows code, name, bloom taxonomy badge (or N/A), description, status, created/updated timestamps.

Trash view:
- Breadcrumb: Cognitive Skill Management -> Trashed Cognitive Skills.
- Table shows code, name, bloom taxonomy badge, description, action.
- Empty state: No Trashed Cognitive Skills Found.
- Pagination shown.

## 7) Positive Scenarios
- User with tenant.subject.viewAny opens index and sees paginated list.
- User creates a cognitive skill with valid code/name and optional bloom_id, then is redirected with success.
- User edits a cognitive skill and is redirected with success.
- User views a cognitive skill detail page.
- User soft deletes a cognitive skill and is redirected with success.
- User restores a trashed cognitive skill and is redirected with success.
- User force deletes a trashed cognitive skill and is redirected with success.
- User toggles status and receives JSON success response.

## 8) Negative Scenarios
- Access index without tenant.subject.viewAny returns 403.
- Create fails validation when code is missing, non-alpha, or longer than 20.
- Create fails validation when code duplicates an existing record.
- Create fails validation when name is missing or longer than 100.
- Description longer than 255 fails validation.
- Edit/update with invalid id returns 404.
- Restore/force delete with invalid id returns 404.

## 9) Response Expectations
- index returns the tab partial view with cognitiveSkills paginated.
- create/edit/show/trash return HTML views with HTTP 200.
- store redirects to syllabus.lesson.index with success flash.
- update redirects to syllabus.lesson.index with success flash.
- destroy redirects to syllabus.lesson.index with success flash.
- restore redirects to syllabus.lesson.index with success flash.
- forceDelete redirects to syllabus.lesson.index with success flash.
- toggleStatus returns JSON:
  - {success:true, is_active:boolean, message:flash('status_updated.cognitive_skill')}

## 10) Audit / Logging
- store logs activity: Stored with message and performed_by.
- update logs activity: Updated with changes and performed_by.
- destroy logs activity: Trashed with message and performed_by.
- restore logs activity: Restored with message and performed_by.
- forceDelete logs activity: Deleted with message and performed_by.
- toggleStatus logs activity: Toggled with message and performed_by.

## 11) Edge Cases and Constraints
- Controller uses tenant.subject.* permissions while UI uses tenant.cognitive-skill.* permissions.
- Index controller does not apply search or bloom_id filters from the UI.
- bloom_id is nullable in validation and DB; no exists rule is enforced in request.
- toggle-status route parameter is {section} but controller expects $id.

## 12) Not Defined in Code
- Search and bloom_id filters in tab UI are not applied in the controller index query.
- The Action component does not use the permissions attribute passed from the view.
