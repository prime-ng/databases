# std_MedicalIncidents — Business Requirements

## What This Screen Does

The Medical Incidents screen provides a complete record-keeping system for tracking and managing all medical incidents that occur involving students within the school premises. It enables school staff to log incidents, attach medications administered, schedule follow-ups, upload supporting documents, and maintain a comprehensive audit trail of every medical event.

This feature serves as the centralized repository for student health and safety events, ensuring that every incident — from minor first-aid cases to serious medical emergencies — is documented with full traceability. The module supports a complete lifecycle: creation, viewing, editing, soft-deletion, restoration, and permanent removal, along with CSV/PDF export capabilities for reporting purposes.

---

## When This Screen Is Used

- Incident Recording when a student experiences a medical incident on school premises and staff need to log the details including location, description, first aid given, and actions taken
- Medication Tracking when prescribed or administered medications need to be recorded as part of the incident documentation
- Follow-up Management when a medical incident requires future follow-up actions to monitor the student's recovery
- Parent Communication when staff need to document whether parents have been notified about the incident
- Audit and Review when administrators need to review past incidents, analyze patterns, or generate reports for regulatory compliance
- Record Cleanup when outdated or incorrect incident records need to be soft-deleted, restored, or permanently removed
- Data Export when the school needs to export incident data to CSV or PDF for external reporting or archival purposes

## Default Data Load

This screen is accessed within the Student Profile module under the `/student-profile/medical-incidents` URL prefix. When the user navigates to the Medical Incidents index page, `MedicalIncidentController@index()` loads a paginated list of all incident records (excluding soft-deleted) with filters for student, date range, incident type, and severity. The create screen additionally loads dropdown data including students (via `ajaxGetStudents` filtered by class section), incident types from the system dropdown table, users for the reporter field, and class sections for student filtering. Each record in the listing displays the student name, incident date, type, location (truncated to 30 characters), parent notification badge, follow-up required badge, and closure date (dash when null).

---

## Key Fields at a Glance

**Incident Identification**
The Student ID links the incident to a specific student record via foreign key to `std_students.id`. The Incident Date captures when the incident occurred as a datetime value. The Incident Type ID categorizes the incident by referencing a system dropdown table entry. The Location field records where on school premises the incident happened (string, max 255 characters).

**Medical Details**
The Description field provides a detailed narrative of what happened. First Aid Given documents any first aid that was administered (nullable string, max 512 characters). Action Taken records what steps were taken to address the incident (nullable string, max 512 characters).

**Reporting and Closure**
The Reported By field links to the staff member (user) who reported the incident via foreign key to `sys_users.id` (store) or `users.id` (update — known inconsistency). The Parent Notified field is a boolean toggle indicating whether the student's parents were informed. The Closure Date captures when the incident was formally closed as a date value (nullable, must be after or equal to incident date).

**Follow-up Management**
The Follow-up Required field is a boolean indicating whether the incident needs future follow-up monitoring. This can be toggled inline via a dedicated toggle endpoint without opening the edit form.

---

## Business Rules and Conditions

**Referential Integrity**
The system enforces strict foreign key relationships. The `student_id` must reference an existing record in `std_students`. The `incident_type_id` must reference an existing entry in the system dropdown table. The `reported_by` must reference an existing user — though notably the store validation checks `sys_users` while update validation checks `users`, which is a confirmed inconsistency.

**Date Constraints**
The `closure_date` when provided must be on or after the `incident_date` via the `after_or_equal` validation rule. The `incident_date` is stored as a datetime, while `closure_date` is stored as a date only. Multiple incidents can be recorded for the same student on different dates.

**Boolean Handling**
Both `parent_notified` and `follow_up_required` are boolean fields with casts applied in the model. The toggle endpoints (`toggleFollowUp`, `toggleParentNotified`) accept a POST request and flip the boolean value, returning a JSON response with the new state.

**Soft Delete Lifecycle**
The system supports a complete soft-delete lifecycle. Destroying a record sets `deleted_at` and logs a 'Deleted' activity. Trashed records are viewable in a dedicated trash view. Restored records have their `deleted_at` set to null and log a 'Restored' activity. Force-deleted records are permanently removed from the database and log a 'Force Deleted' activity.

**Activity Logging**
All significant actions generate activity log entries: Updates log field-level changes with a diff, Deletes log 'Deleted', Restores log 'Restored', Force Deletes log 'Force Deleted', and toggle actions log 'Toggled'. Notably, the store action does not log an activity entry — this is a confirmed gap.

**Filter Limitation**
The index page declares filter controls for search, student, incident type, and date range in the view, but the controller does not implement the corresponding filter query logic. Filters are presentational only — this is a confirmed defect.

---

## Workflow Steps

**Recording a New Medical Incident**
A staff member witnesses or is notified of a student medical incident. They navigate to Student Profile → Medical Incidents and click "Add New". The multi-step creation form guides them through entering header information (student, date, type, location, description), adding medications administered, and scheduling follow-up actions if needed. They select the reporter (defaulting to the current user) and indicate whether parents have been notified. On submission, the system validates all fields, saves the record, and optionally attaches uploaded medical documents to the media collection. The system then redirects to the attendance bulk page.

**Managing an Existing Incident**
Staff can view incident details in a modal or full page, edit any field, toggle parent notification and follow-up status inline, or delete the record. The edit form pre-fills all existing data for modification. Updates log field-level changes for audit purposes.

**Trash and Recovery**
If an incident record is no longer relevant, authorized staff can soft-delete it, sending it to the trash. The trash view lists all soft-deleted records. From there, staff can restore a record (bringing it back to active status) or force-delete it (permanently removing it from the database).

---

## Example Scenario

A student named Aarav Patel falls during recess and sustains a minor knee injury. The PE teacher witnesses the incident and immediately takes Aarav to the school nurse.

The nurse logs into the system, navigates to Student Profile → Medical Incidents, and clicks "Add New." She selects Aarav Patel as the student, sets the incident date to the current date and time, selects "Injury — Minor" as the incident type, enters "Playground — Southwest Corner" as the location, and describes the incident: "Student tripped while running near the swings. Minor abrasion on right knee."

She documents the first aid given: "Cleaned wound with antiseptic, applied bandage." Since this is a minor injury, she sets parent_notified to true (the PE teacher called Aarav's mother) and leaves follow_up_required unchecked. She selects herself as the reporter and submits the form.

Later that day, Aarav's class teacher checks the system and sees the incident logged. She uses the toggle endpoint to mark follow-up as required, wanting to check on Aarav the next day. The system updates the record and returns a success JSON response. The next day, after confirming Aarav is fine, she toggles follow-up back to off.

At the end of the term, the school administrator exports a CSV report of all medical incidents for the quarterly safety review. The report shows that 85% of incidents occurred on the playground, prompting the school to invest in new safety surfacing.

---

## Related Screens

- **Student Profile (Index/Show)** — The parent context where the incident is associated with a specific student record
- **System Dropdown Configuration** — Supplies the `incident_type_id` values for categorizing incidents
- **Attendance Bulk** — The redirect target after successfully storing a new incident record
- **User Management** — Supplies the `reported_by` user records for reporter assignment

---

## Requirements

- The system MUST serve the Medical Incidents feature under the URL prefix `/student-profile/medical-incidents` with routes for index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleFollowUp, toggleParentNotified, and ajaxGetStudents.
- The system MUST authorize access via `Gate::authorize()` using the following permissions:
  - `tenant.medical-incident.viewAny` for index
  - `tenant.medical-incident.create` for create
  - `tenant.medical-incident.store` for store
  - `tenant.medical-incident.view` for show and ajaxGetStudents
  - `tenant.medical-incident.update` for edit, update, toggleFollowUp, and toggleParentNotified
  - `tenant.medical-incident.delete` for destroy
  - `tenant.medical-incident.restore` for trashed and restore
  - `tenant.medical-incident.forceDelete` for forceDelete
- The system MUST enforce validation rules on store:
  - `student_id`: required, exists:std_students,id
  - `incident_date`: required, date
  - `incident_type_id`: required, exists:sys_dropdown_table,id
  - `location`: required, string, max:255
  - `description`: required, string
  - `first_aid_given`: nullable, string, max:512
  - `action_taken`: nullable, string, max:512
  - `reported_by`: required, exists:sys_users,id
  - `parent_notified`: nullable, boolean
  - `closure_date`: nullable, date, after_or_equal:incident_date
  - `follow_up_required`: nullable, boolean
- The system MUST enforce validation rules on update — same as store except `reported_by` uses `exists:users,id` (known inconsistency, DEV-MI-02).
- The system MUST paginate the index listing with server-side pagination.
- The system MUST support soft deletes via the `SoftDeletes` trait on the `MedicalIncident` model.
- The system MUST support media uploads via the `InteractsWithMedia` trait with a `medical_documents` media collection (singleFile).
- The system MUST log activities for: Updated (field-level diff), Deleted, Restored, Force Deleted, and Toggled.
- The system MUST redirect to `student-profile.attendance.bulk` with a success flash message after store.
- The system MUST return JSON responses from toggleFollowUp and toggleParentNotified endpoints.
- The system MUST render the show view for both AJAX and full page requests.
- The system MUST provide an `ajaxGetStudents` endpoint that filters students by `class_section_id`.
- The system MUST apply CSV and PDF export functionality with filter support on the index page.
- The system MUST cast `incident_date` as datetime, `closure_date` as date, `parent_notified` as boolean, and `follow_up_required` as boolean in the model.
- The system MUST use `findOrFail` for all single-record lookups, returning 404 for non-existing IDs.
- The system MUST use `onlyTrashed()->findOrFail` for force-delete operations, returning 404 if the record is not trashed.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.medical-incident.*` (all permissions) | Full CRUD + trash + restore + forceDelete + toggle + export |
| School Administrator | `tenant.medical-incident.viewAny` + `.view` + `.create` + `.store` + `.update` + `.delete` | Create, Edit, Delete, View (cannot restore force-deleted records) |
| Nurse / Medical Staff | `tenant.medical-incident.viewAny` + `.view` + `.create` + `.store` + `.update` | Create and Edit incidents (cannot delete or restore) |
| Class Teacher | `tenant.medical-incident.viewAny` + `.view` + `.update` | Read-only + can toggle follow-up and parent notified |
| Parent / Guardian | No explicit permission | No access (student data privacy) |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user navigates to Student Profile → Medical Incidents. The `index()` controller fires, `Gate::authorize()` checks `tenant.medical-incident.viewAny`, and the system fetches all non-deleted incident records with student and type relationships, paginated with filter controls (though filters are presentational only — confirmed defect).
2. The user clicks "Add New" to open the creation form. The `create()` controller loads dropdown data: students (via class-section filtering), incident types, users, and class sections.
3. The user fills in the multi-step form: header information (student, date, type, location, description), then optionally adds medications and follow-up entries. They may also upload a medical document.
4. On form submission, the `store()` controller validates all fields against the defined rules. If valid, the record is saved, any uploaded file is attached to the `medical_documents` media collection, and the system redirects to the attendance bulk page with a success message.
5. The user can click any incident row to view full details via the `show()` controller, which loads the incident with its student and type relationships. The view renders the same content for both AJAX modal requests and full page navigation.
6. To modify an incident, the user clicks Edit. The `edit()` controller pre-fills the form with the existing record's data. On update, the `update()` controller validates and saves changes, then logs an 'Updated' activity with a field-level diff.
7. For quick status changes, the user can click the toggle buttons for follow-up or parent notification. These send a POST request to `toggleFollowUp` or `toggleParentNotified`, which flip the boolean and return a JSON response with the new state.
8. Deleting an incident soft-deletes it by setting `deleted_at`. The record disappears from the active list but remains in the database. The trash view (`trashed()`) lists all soft-deleted records.
9. From the trash, authorized users can restore a record (reversing the soft delete) or force-delete it (permanently removing it from the database). Both actions are logged.
10. For reporting, users can export the incident list as CSV or PDF with optional filters applied.

---

## Validate Before Save (Multiple Conditions)

1. **Student ID Required** — `student_id` must not be empty. Error: "The student id field is required."
2. **Student ID Exists** — `student_id` must reference an existing student in `std_students` table. Error: "The selected student id is invalid."
3. **Incident Date Required** — `incident_date` must not be empty. Error: "The incident date field is required."
4. **Incident Date Format** — `incident_date` must be a valid date. Error: "The incident date is not a valid date."
5. **Incident Type Required** — `incident_type_id` must not be empty. Error: "The incident type id field is required."
6. **Incident Type Exists** — `incident_type_id` must reference an existing entry in the system dropdown. Error: "The selected incident type id is invalid."
7. **Location Required** — `location` must not be empty. Error: "The location field is required."
8. **Location Max Length** — `location` must not exceed 255 characters. Error: "The location must not be greater than 255 characters."
9. **Description Required** — `description` must not be empty. Error: "The description field is required."
10. **First Aid Given Max Length** — `first_aid_given` must not exceed 512 characters. Error: "The first aid given must not be greater than 512 characters."
11. **Action Taken Max Length** — `action_taken` must not exceed 512 characters. Error: "The action taken must not be greater than 512 characters."
12. **Reported By Required** — `reported_by` must not be empty. Error: "The reported by field is required."
13. **Reported By Exists** — `reported_by` must reference an existing user. Error: "The selected reported by is invalid."
14. **Closure Date Format** — `closure_date` must be a valid date. Error: "The closure date is not a valid date."
15. **Closure Date After Incident** — `closure_date` must be on or after `incident_date`. Error: "The closure date must be a date after or equal to incident date."
16. **Parent Notified Boolean** — `parent_notified` must be a boolean value. Error: "The parent notified field must be true or false."
17. **Follow-up Required Boolean** — `follow_up_required` must be a boolean value. Error: "The follow up required field must be true or false."
18. **Authorization** — `Gate::authorize()` checks the user has the required permission before any operation. Error: "This action is unauthorized."

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Student ID is empty | "The student id field is required." | 422 |
| Student ID does not exist (invalid FK) | "The selected student id is invalid." | 422 |
| Incident date is empty | "The incident date field is required." | 422 |
| Incident date is not a valid date | "The incident date is not a valid date." | 422 |
| Incident type is empty | "The incident type id field is required." | 422 |
| Incident type does not exist (invalid FK) | "The selected incident type id is invalid." | 422 |
| Location is empty | "The location field is required." | 422 |
| Location exceeds 255 characters | "The location must not be greater than 255 characters." | 422 |
| Description is empty | "The description field is required." | 422 |
| First aid given exceeds 512 characters | "The first aid given must not be greater than 512 characters." | 422 |
| Action taken exceeds 512 characters | "The action taken must not be greater than 512 characters." | 422 |
| Reported by is empty | "The reported by field is required." | 422 |
| Reported by does not exist (invalid FK) | "The selected reported by is invalid." | 422 |
| Closure date is not a valid date | "The closure date is not a valid date." | 422 |
| Closure date is before incident date | "The closure date must be a date after or equal to incident date." | 422 |
| Parent notified is not boolean | "The parent notified field must be true or false." | 422 |
| Follow-up required is not boolean | "The follow up required field must be true or false." | 422 |
| Toggle missing required field | "The follow up required field is required." | 422 |
| Unauthorized access (missing permission) | "This action is unauthorized." | 403 |
| Non-existing incident ID | 404 Not Found | 404 |
| Force delete on non-trashed record | 404 Not Found | 404 |
| Guest user (not authenticated) | Redirected to /login | 302 |

---

## Success Scenarios

**SC-001: Recording a New Medical Incident**
1. Staff member navigates to Student Profile → Medical Incidents → clicks "Add New".
2. Selects the student (filtered by class section), enters incident date, selects incident type (e.g., "Injury — Minor"), enters location and description.
3. Optionally adds first aid given, action taken, uploads a medical document, sets parent_notified to true, and leaves follow_up_required unchecked.
4. System validates all fields, saves the record with correct FK references.
5. System attaches the uploaded document to the `medical_documents` media collection.
6. System redirects to the attendance bulk page with a success flash message. The new incident appears in the active listing.

**SC-002: Toggling Follow-up Status**
1. Staff member views the incident list and clicks the follow-up toggle button on an existing incident.
2. System sends a POST request to `toggleFollowUp` with the updated boolean value.
3. System validates authorization via `tenant.medical-incident.update`, flips the `follow_up_required` boolean, logs 'Toggled' in activity.
4. System returns JSON `{success: true, follow_up_required: true, message: "Follow-up status updated successfully"}`.
5. The UI badge updates instantly to reflect the new state.

**SC-003: Full Lifecycle — Delete, Restore, Force Delete**
1. Staff member deletes an incident record. System sets `deleted_at` timestamp, logs 'Deleted' activity. Record disappears from active list.
2. Staff navigates to the Trash view. The soft-deleted record is listed.
3. Staff clicks "Restore". System sets `deleted_at` to null, logs 'Restored' activity. Record reappears in active list.
4. Staff deletes it again, returns to Trash, and clicks "Force Delete".
5. System permanently removes the record from the database, logs 'Force Deleted' activity. Record is gone entirely.

**SC-004: Exporting Incident Data to CSV**
1. Staff member navigates to the Medical Incidents index page with desired filters applied.
2. Clicks the "Export CSV" button.
3. System generates a CSV file containing all matching incident records with selected columns.
4. File is downloaded to the user's machine for external reporting or archival.

---

## Failure Scenarios

**FC-001: Invalid Foreign Key Rejected**
1. Staff attempts to create an incident with a non-existing `student_id` (e.g., 999999).
2. System validation fails with error: "The selected student id is invalid."
3. Record is not saved. The form remains open with the entered data preserved for correction.

**FC-002: Closure Date Before Incident Date**
1. Staff enters incident date as "2026-07-15" but accidentally enters closure date as "2026-07-10".
2. System validation fails with error: "The closure date must be a date after or equal to incident date."
3. Record is not saved. Staff must correct the closure date to a valid value.

**FC-003: Unauthorized Access Attempt**
1. A staff member who lacks `tenant.medical-incident.viewAny` navigates to the Medical Incidents index URL.
2. `Gate::authorize()` throws an authorization exception.
3. System returns HTTP 403 with message: "This action is unauthorized."

**FC-004: Force Delete on Non-Trashed Record**
1. Staff navigates directly to force-delete URL for an active (non-deleted) incident.
2. Controller uses `onlyTrashed()->findOrFail($id)` which finds no matching record.
3. System returns 404 Not Found.

**FC-005: Empty Toggle Request**
1. Staff clicks toggle follow-up without sending the required field.
2. Validation fails with error: "The follow up required field is required."
3. System returns 422 with validation error. No state change occurs.

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Primary Table | `std_medical_incidents` | `id`, `student_id` FK, `incident_date` DATETIME, `incident_type_id` FK, `location` VARCHAR(255), `description` TEXT, `first_aid_given` VARCHAR(512), `action_taken` VARCHAR(512), `reported_by` FK (sys_users/users), `parent_notified` TINYINT(1), `closure_date` DATE, `follow_up_required` TINYINT(1), `created_at`, `updated_at`, `deleted_at` (SoftDeletes) |
| Related Table | `std_medical_incident_medications` | Linked to `std_medical_incidents.id` for medications administered during the incident |
| Related Table | `std_medical_incident_followups` | Linked to `std_medical_incidents.id` for follow-up actions and scheduling |
| Related Table | `std_students` | FK `std_medical_incidents.student_id` REFERENCES `std_students.id` |
| Related Table | `sys_users` | FK `std_medical_incidents.reported_by` REFERENCES `sys_users.id` ON DELETE SET NULL (store) |
| Related Table | `users` | FK `std_medical_incidents.reported_by` REFERENCES `users.id` (update — inconsistency DEV-MI-02) |
| Related Table | `sys_dropdown_table` | FK `std_medical_incidents.incident_type_id` REFERENCES `sys_dropdown_table.id` (for incident type categorization) |
| Media Collection | `medical_documents` | SingleFile media collection registered via `InteractsWithMedia` trait for uploading medical documents |
| Module Dependency | Student Profile Module | Core module where incidents are managed under `/student-profile/medical-incidents` route prefix |
| Module Dependency | User & Permission Module | `Gate::authorize()` checks `tenant.medical-incident.*` permissions |
| Module Dependency | Attendance Module | Store redirects to `student-profile.attendance.bulk` post-creation |
