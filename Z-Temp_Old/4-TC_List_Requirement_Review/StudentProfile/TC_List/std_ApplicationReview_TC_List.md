# std_ApplicationReview — Test Case List & Business Conditions

**Module:** StudentProfile (CODE `STD`, prefix `std_`) · **Feature:** Leave Application Review (Decision Workflow)
**DB scope:** TENANT-side (`std_*` → tenant DB) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary table:** `std_leave_applications` · **Module URL prefix:** `/student-profile`
**Test file:** `std_ApplicationReview_TestCas.php`
**Checklists applied:** `Gaurav_list.md` + `Shailesh_list.md`

Routes:
- `GET     /student-profile/student-leave?tab=application-review` — StdLeaveController@index (review list)
- `GET     /student-profile/student-leave/{id}/review`              — StdLeaveController@review
- `PUT     /student-profile/student-leave/{id}/update-review`        — StdLeaveController@updateReview
- `GET     /student-profile/student-leave?tab=leave-remarks`        — StdLeaveController@index (remarks tab)
- `POST    /student-profile/student-leave/remarks/store`            — StdLeaveController@storeRemark
- `GET     /student-profile/student-leave?tab=documents`            — StdLeaveController@index (documents tab)
- `GET     /student-profile/student-leave/ajax/students`            — StdLeaveController@getStudentsBySection
- `GET     /student-profile/student-leave/ajax/applications`        — StdLeaveController@getApplicationsByStudent

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `std_leave_applications` has columns: id, student_id, academic_session_id, class_section_id, leave_type_id, from_date, to_date, total_days, is_half_day, half_day_slot, reason, status, is_active, applied_by, reviewed_by, reviewed_at, approved_days, review_remarks, deleted_at, created_at, updated_at | DDL |
| BC-DB-02 | Model `LeaveApplication`: table `std_leave_applications`, SoftDeletes, fillable includes 18 fields | LeaveApplication.php:35-53 |
| BC-DB-03 | Casts: from_date, to_date (date); reviewed_at (datetime); is_half_day, is_active (boolean); total_days, approved_days (integer) | LeaveApplication.php:55-63 |
| BC-DB-04 | Status constants: Draft, Submitted, Under Review, Info Requested, Doc Requested, Approved, Rejected, Cancelled | LeaveApplication.php:19-26 |
| BC-DB-05 | Table `std_leave_application_remarks` stores status-change log rows (old_status, new_status, remark_type='status_change') | LeaveService.php:665-673 |
| BC-DB-06 | Table `std_leave_application_remarks` has columns: id, leave_application_id, remark_type, message, is_from_teacher, remarked_by, parent_remark_id, is_resolved, resolved_at, old_status, new_status, is_active, created_at, updated_at | Remark.php:14-34 |
| BC-DB-07 | Model `LeaveApplicationRemark`: no SoftDeletes (permanent audit trail), fillable includes 11 fields, casts is_from_teacher/is_resolved (boolean), resolved_at (datetime) | Remark.php:12-40 |
| BC-DB-08 | Remark type constants: comment, info_request, doc_request, response, status_change | Remark.php:16-20 |
| BC-DB-09 | Relationships: leaveApplication (BelongsTo), remarkedBy (BelongsTo User), parentRemark (BelongsTo self), childRemarks (HasMany self), responseDocuments (HasMany LeaveApplicationDocument via request_remark_id) | Remark.php:42-65 |
| BC-DB-10 | Table `std_leave_application_documents` has columns: id, leave_application_id, document_name, document_type_id, description, file_name, media_id, uploaded_by, is_in_response_to_request, request_remark_id, is_active, deleted_at, created_at, updated_at | Doc.php:21-32 |
| BC-DB-11 | Model `LeaveApplicationDocument`: SoftDeletes + InteractsWithMedia, fillable includes 10 fields, casts is_in_response_to_request (boolean) | Doc.php:15-36 |
| BC-DB-12 | Media collection `leave-documents` on disk `public`, single file, accepts pdf/jpeg/png only, no conversions | Doc.php:38-53 |
| BC-DB-13 | Relationships: leaveApplication (BelongsTo), uploadedBy (BelongsTo User), documentType (BelongsTo Dropdown), requestRemark (BelongsTo LeaveApplicationRemark) | Doc.php:55-73 |

### BC-VAL — Validation (Source: `updateReview` / `storeRemark` request validation)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `status` required, must be one of: Under Review, Approved, Rejected, Info Requested, Doc Requested | Ctrl:272 |
| BC-VAL-02 | `review_remarks` nullable string max:1000 | Ctrl:273 |
| BC-VAL-03 | `approved_days` nullable integer min:0 max:application->total_days | Ctrl:274-279 |
| BC-VAL-04 | `leave_application_id` required, exists:std_leave_applications,id | Ctrl:189 |
| BC-VAL-05 | `message` nullable string (for remark) | Ctrl:190 |
| BC-VAL-06 | `attachments.*` nullable file, max 5120 KB (5MB) | Ctrl:191 |
| BC-VAL-07 | `document_type_id` nullable integer, exists:sys_dropdown_table,id | Ctrl:192 |
| BC-VAL-08 | `description` nullable string, max:255 | Ctrl:193 |
| BC-VAL-09 | At least one of `message` or `attachments` must be provided for remark | Ctrl:202-204 |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index() gate `tenant.student-leave.viewAny` | Ctrl:25 |
| BC-AUTH-02 | review() gate `tenant.student-leave.review` | Ctrl:255 |
| BC-AUTH-03 | updateReview() gate `tenant.student-leave.update` | Ctrl:268 |
| BC-AUTH-04 | storeRemark() gate `tenant.student-leave.update` | Ctrl:187 |
| BC-AUTH-05 | getStudentsBySection() gate `tenant.student-leave.view` | Ctrl:147 |
| BC-AUTH-06 | getApplicationsByStudent() gate `tenant.student-leave.view` | Ctrl:167 |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | index() defaults `tab=leave-type` when no tab param given; `tab=application-review` renders review list | Ctrl:26 |
| BC-BIZ-02 | index() loads classes, sections for filter dropdowns; default class_id for class teachers | Ctrl:39-55 |
| BC-BIZ-03 | index() filters by search (student name/email/admission_no), class_id, section_id, status | Ctrl:99-126 |
| BC-BIZ-04 | index() returns paginated results (default 15 per page) with query string | Ctrl:128 |
| BC-BIZ-05 | review() loads application with student.user, leaveType, classSection, reviewedBy, appliedBy relationships | Ctrl:257-258 |
| BC-BIZ-06 | updateReview() calls LeaveService::review() which updates review_remarks, approved_days, reviewed_by, reviewed_at in a transaction | Ctrl:282, Service:563-569 |
| BC-BIZ-07 | updateReview() transitions status via LeaveService::transition() which updates status + auto-creates status_change remark | Service:572, 659-674 |
| BC-BIZ-08 | When status is Approved, LeaveService::markAttendanceOnApproval() upserts `std_student_attendance` rows (status='Leave') for approved_days | Service:574-576, 586-612 |
| BC-BIZ-09 | updateReview() writes 'Reviewed' activity log | Ctrl:284 |
| BC-BIZ-10 | updateReview() redirects to `student-leave.index?tab=application-review` with success flash | Ctrl:286-289 |
| BC-BIZ-11 | index() loads remarks data when `tab=leave-remarks`: students, applications, remarks based on filter params (remarks_class_section_id, remarks_student_id, remarks_application_id) | Ctrl:60-89 |
| BC-BIZ-12 | index() loads documents data when `tab=documents`: students, applications, documents based on filter params (doc_class_section_id, doc_student_id, doc_application_id) | Ctrl:92-121 |
| BC-BIZ-13 | storeRemark() creates LeaveApplicationRemark with TYPE_COMMENT, is_from_teacher=true, links attachments via LeaveApplicationDocument with request_remark_id | Ctrl:208-234 |
| BC-BIZ-14 | storeRemark() rejects when application status is Approved/Rejected/Cancelled (chat disabled) | Ctrl:198-200 |
| BC-BIZ-15 | storeRemark() writes 'Remark Added' activity log | Ctrl:237 |
| BC-BIZ-16 | storeRemark() returns JSON with rendered _chat_item HTML for AJAX requests | Ctrl:239-244 |
| BC-BIZ-17 | getStudentsBySection() AJAX returns students filtered by class_section_id | Ctrl:145-159 |
| BC-BIZ-18 | getApplicationsByStudent() AJAX returns applications filtered by student_id | Ctrl:164-180 |
| BC-BIZ-19 | Remarks tab cascade: select class section → loads student dropdown → select student → loads application dropdown | View + _js |
| BC-BIZ-20 | Documents tab cascade: select class section → loads student dropdown → select student → loads application dropdown | View + _js |
| BC-BIZ-21 | Remarks tab chat input hidden when no application selected; locked with disabled message for Approved/Rejected/Cancelled statuses | View:148-153 |
| BC-BIZ-22 | Remarks tab send via Enter key; Shift+Enter inserts newline; auto-resizing textarea | _js |
| BC-BIZ-23 | Documents tab file icon determined by extension (pdf→danger, jpg/png→primary, doc/docx→info, other→gray) | View:61-66 |
| BC-BIZ-24 | Documents tab each card has View (new tab) and Download actions, plus "Open Related Application" footer link | View:105-116 |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Non-existing id for review()/updateReview() → 404 (findOrFail) | Ctrl:257,269 |
| BC-EDG-02 | approved_days > application->total_days → validation rejection (max rule) | Ctrl:278-279 |
| BC-EDG-03 | approved_days = 0 → no attendance rows created | Service:574-576,588 |
| BC-EDG-04 | approved_days < total_days → attendance marked for approved_days only | Service:588-597 |
| BC-EDG-05 | Status `Submitted` exists as valid filterable value but is NOT in updateReview allowed list (cannot be set via review) | Ctrl:272 vs index filter:30 |
| BC-EDG-06 | Cancelled status cannot be set via updateReview (not in allowed list) | Ctrl:272 |
| BC-EDG-07 | storeRemark() with both message and attachments → both saved, files linked to remark | Ctrl:206-234 |
| BC-EDG-08 | storeRemark() with no message + no attachments → 422 | Ctrl:202-204 |
| BC-EDG-09 | storeRemark() with only attachments, no message → auto-generates "Attached N file(s)" as message | Ctrl:206 |
| BC-EDG-10 | storeRemark() with file > 5MB → rejected (max:5120) | Ctrl:191 |
| BC-EDG-11 | storeRemark() on non-existing leave_application_id → 422 (exists validation) | Ctrl:189 |
| BC-EDG-12 | storeRemark() on soft-deleted leave_application_id → 422 (exists ignores soft-deletes) | Ctrl:189 |
| BC-EDG-13 | storeRemark() for application in Approved/Rejected/Cancelled status → 403 | Ctrl:198-200 |
| BC-EDG-14 | Chat message box disabled and locked icon shown for Approved/Rejected/Cancelled applications | View:148-153 |
| BC-EDG-15 | Remarks tab empty state when no application selected: "Select a student and application to begin" | View:138-143 |
| BC-EDG-16 | Remarks tab empty state when application selected but no remarks: "No remarks yet — start the conversation below" | View:133-137 |
| BC-EDG-17 | Documents tab empty state when no documents match: "No documents found" | View:120-125 |
| BC-EDG-18 | AJAX getStudentsBySection with invalid section_id → empty JSON array | Ctrl:149-156 |
| BC-EDG-19 | AJAX getApplicationsByStudent with invalid student_id → empty JSON array | Ctrl:168-177 |
| BC-EDG-20 | Document with unsupported file extension → falls back to generic icon (fa-file-alt) | View:61-66 |

---

## 2. Test Case List

### Screen 1: Application Review Index (GET /student-leave?tab=application-review)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-REV-P10 | Positive | Ctrl | Review tab renders with search bar, class/section/status filters, and results table | Page rendered | test_review_10 | Automated |
| TC-REV-P11 | Positive | Ctrl | Search by student name filters results | Filtered | test_review_11 | Automated |
| TC-REV-P12 | Positive | Ctrl | Search by admission_no filters results | Filtered | test_review_12 | Automated |
| TC-REV-P13 | Positive | Ctrl | Filter by class_id narrows results | Filtered | test_review_13 | Automated |
| TC-REV-P14 | Positive | Ctrl | Filter by section_id narrows results | Filtered | test_review_14 | Automated |
| TC-REV-P15 | Positive | Ctrl | Filter by status narrows results | Filtered | test_review_15 | Automated |
| TC-REV-P16 | Positive | Ctrl | Combined filters (class + section + status) work together | Filtered | test_review_16 | Automated |
| TC-REV-P17 | Positive | Ctrl | Clear filter link resets all filters | Filters cleared | test_review_17 | Automated |
| TC-REV-P18 | Positive | Ctrl | Result set is paginated (default 15 per page) | Paginated | test_review_18 | Automated |
| TC-REV-P19 | Positive | View | Each row displays: Student (name + admission_no), Class/Section, Leave Type, From-To, Days, Half Day, Applied By, Status, Actions | All columns visible | test_review_19 | Automated |
| TC-REV-P20 | Positive | View | Action buttons per row: Edit, Review, Add Remark, View Documents | 4 buttons visible | test_review_20 | Automated |
| TC-REV-P21 | Positive | Ctrl | Class teacher sees default class_id filter pre-selected when no filter set | Pre-filtered | test_review_21 | Automated |
| TC-REV-P22 | Positive | View | Non-class-teacher user sees all classes/sections available | Full list | test_review_22 | Automated |
| TC-REV-P23 | Positive | View | Empty state message shown when no applications match filters | "No leave applications found" | test_review_23 | Planned |
| TC-REV-P24 | Positive | View | Status badge uses correct color class per status | Color matches | test_review_24 | Planned |

### Screen 2: Review Page (GET /student-leave/{id}/review)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-REV-P30 | Positive | View | Review page renders breadcrumb: Student Profile > Student Leave > Review | Breadcrumb correct | test_review_30 | Automated |
| TC-REV-P31 | Positive | View | Sidebar shows student avatar, name, ID, class/section, leave type, total days, half day, applied by, requested period | All sidebar data correct | test_review_31 | Automated |
| TC-REV-P32 | Positive | View | Application summary card shows reason for leave with quote styling | Reason displayed | test_review_32 | Automated |
| TC-REV-P33 | Positive | View | Review actions card has 5 status radio buttons: Under Review, Approved, Rejected, Info Requested, Doc Requested | 5 options present | test_review_33 | Automated |
| TC-REV-P34 | Positive | View | Current application status radio button is pre-checked | Pre-selected | test_review_34 | Automated |
| TC-REV-P35 | Positive | View | Review remarks textarea is present with placeholder | Textarea rendered | test_review_35 | Automated |
| TC-REV-P36 | Positive | View | Approved days input shows default value = total_days, min=0, max=total_days | Input with limits | test_review_36 | Automated |
| TC-REV-P37 | Positive | View | Last action shows reviewed_by name and reviewed_at timestamp | Last action visible | test_review_37 | Automated |
| TC-REV-P38 | Positive | View | Cancel button links back to application-review tab | Links back | test_review_38 | Automated |
| TC-REV-P39 | Positive | View | Apply Decision submit button is present | Button present | test_review_39 | Automated |
| TC-REV-N40 | Negative | Ctrl | Invalid leave application id → 404 | 404 | test_review_40 | Automated |
| TC-REV-N41 | Negative | Ctrl | Soft-deleted leave application id → 404 | 404 | test_review_41 | Planned |

### Screen 3: Update Review — Submit Decision (PUT /student-leave/{id}/update-review)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-REV-P50 | Positive | Ctrl | Approve application → status changes to Approved, success flash, redirect | Approved + flash | test_review_50 | Automated |
| TC-REV-P51 | Positive | Ctrl | Reject application → status changes to Rejected, success flash, redirect | Rejected + flash | test_review_51 | Automated |
| TC-REV-P52 | Positive | Ctrl | Mark Under Review → status changes to Under Review, redirect | Under Review | test_review_52 | Automated |
| TC-REV-P53 | Positive | Ctrl | Request Info → status changes to Info Requested, redirect | Info Requested | test_review_53 | Automated |
| TC-REV-P54 | Positive | Ctrl | Request Doc → status changes to Doc Requested, redirect | Doc Requested | test_review_54 | Automated |
| TC-REV-P55 | Positive | Ctrl | Submit review with review_remarks → remarks saved and displayed | Remarks saved | test_review_55 | Automated |
| TC-REV-P56 | Positive | Ctrl | Submit review with custom approved_days (< total_days) → approved_days saved | approved_days saved | test_review_56 | Automated |
| TC-REV-P57 | Positive | Ctrl | Approve with approved_days = total_days (or omitted) → attendance marked for all days | Attendance rows inserted | test_review_57 | Automated |
| TC-REV-P58 | Positive | Ctrl | Approve with approved_days < total_days → attendance marked only for approved_days | Partial attendance | test_review_58 | Automated |
| TC-REV-P59 | Positive | Ctrl | Approve with approved_days = 0 → no attendance rows created | No attendance | test_review_59 | Automated |
| TC-REV-P60 | Positive | Ctrl | Each status transition auto-creates a status_change remark with old/new status | Remark logged | test_review_60 | Automated |
| TC-REV-P61 | Positive | Ctrl | 'Reviewed' activity log written for each updateReview action | Activity logged | test_review_61 | Automated |
| TC-REV-P62 | Positive | Ctrl | Re-approve an already-approved application → status remains Approved, re-logged | Re-approved | test_review_62 | Planned |
| TC-REV-P63 | Positive | Ctrl | Change from Approved to Rejected → status changes, no attendance removal | Status changed | test_review_63 | Planned |
| TC-REV-N70 | Negative | Ctrl | status field missing → 422 validation error | 422 | test_review_70 | Automated |
| TC-REV-N71 | Negative | Ctrl | status value invalid (not in allowed list) → 422 | 422 | test_review_71 | Automated |
| TC-REV-N72 | Negative | Ctrl | review_remarks exceeds 1000 chars → 422 | 422 | test_review_72 | Automated |
| TC-REV-N73 | Negative | Ctrl | approved_days negative → 422 | 422 | test_review_73 | Automated |
| TC-REV-N74 | Negative | Ctrl | approved_days exceeds application total_days → 422 | 422 | test_review_74 | Automated |
| TC-REV-N75 | Negative | Ctrl | Non-existing application id → 404 | 404 | test_review_75 | Automated |
| TC-REV-N76 | Negative | Ctrl | Soft-deleted application id → 404 | 404 | test_review_76 | Planned |

### Screen 4: Leave Remarks Tab — Chat (GET /student-leave?tab=leave-remarks)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-REV-P100 | Positive | View | Remarks tab renders with cascading filters: class section, student, application | 3 dropdowns visible | test_review_100 | Automated |
| TC-REV-P101 | Positive | JSON | AJAX getStudentsBySection returns students for selected class section | JSON list | test_review_101 | Automated |
| TC-REV-P102 | Positive | JSON | AJAX getApplicationsByStudent returns applications for selected student | JSON list | test_review_102 | Automated |
| TC-REV-P103 | Positive | Ctrl | Filter cascading works: select section → populate student → select student → populate application | Cascade correct | test_review_103 | Automated |
| TC-REV-P104 | Positive | View | Clear filter link resets all filters on remarks tab | Filters cleared | test_review_104 | Automated |
| TC-REV-P105 | Positive | View | Header shows selected application student avatar, name, leave type, status badge | Header renders | test_review_105 | Automated |
| TC-REV-P106 | Positive | View | Header has links to Review page and Edit page for selected application | 2 icon buttons | test_review_106 | Automated |
| TC-REV-P107 | Positive | View | Header shows empty state when no application selected: "Select an application to view conversation" | Empty header | test_review_107 | Automated |
| TC-REV-P108 | Positive | View | Chat body shows date dividers between remarks grouped by day | Date dividers | test_review_108 | Planned |
| TC-REV-P109 | Positive | View | Chat items: teacher remarks right-aligned (blue), other remarks left-aligned (green), remark type badge, name + timestamp | Correct alignment | test_review_109 | Automated |
| TC-REV-P110 | Positive | View | Chat body shows empty state when no remarks for selected application: "No remarks yet" | Empty state | test_review_110 | Automated |
| TC-REV-P111 | Positive | View | Chat body shows prompt when no application selected: "Select a student and application to begin" | Prompt visible | test_review_111 | Automated |
| TC-REV-P112 | Positive | View | Chat footer has file attach button, textarea, send button when application is open for chat | Input present | test_review_112 | Automated |
| TC-REV-P113 | Positive | View | Chat footer shows locked message when application status is Approved/Rejected/Cancelled | Locked message | test_review_113 | Automated |
| TC-REV-P114 | Positive | Ctrl | Send remark with message only → remark created, appended to chat, activity logged | Remark saved | test_review_114 | Automated |
| TC-REV-P115 | Positive | Ctrl | Send remark with message + attachment files → remark + documents created, files stored in media library | Remark + docs saved | test_review_115 | Automated |
| TC-REV-P116 | Positive | Ctrl | Send remark with attachments only, no message → auto-generates "Attached N file(s)" as message | Auto message | test_review_116 | Automated |
| TC-REV-P117 | Positive | Ctrl | Enter key submits remark; Shift+Enter inserts newline | Submit behavior | test_review_117 | Planned |
| TC-REV-P118 | Positive | Ctrl | File attachment accepts .png, .jpg, .jpeg, .pdf (accept attribute) | Accepted types | test_review_118 | Automated |
| TC-REV-N120 | Negative | Ctrl | storeRemark with empty message and no attachments → 422 | 422 | test_review_120 | Automated |
| TC-REV-N121 | Negative | Ctrl | storeRemark with file > 5MB → 422 | 422 | test_review_121 | Automated |
| TC-REV-N122 | Negative | Ctrl | storeRemark on Approved application → 403 "Chat is disabled" | 403 | test_review_122 | Automated |
| TC-REV-N123 | Negative | Ctrl | storeRemark on Rejected application → 403 "Chat is disabled" | 403 | test_review_123 | Automated |
| TC-REV-N124 | Negative | Ctrl | storeRemark on Cancelled application → 403 "Chat is disabled" | 403 | test_review_124 | Automated |
| TC-REV-N125 | Negative | Ctrl | storeRemark with invalid leave_application_id → 422 | 422 | test_review_125 | Automated |
| TC-REV-N126 | Negative | Ctrl | storeRemark with invalid document_type_id → 422 | 422 | test_review_126 | Automated |
| TC-REV-N127 | Negative | Ctrl | storeRemark description exceeds 255 chars → 422 | 422 | test_review_127 | Automated |

### Screen 5: Documents Tab (GET /student-leave?tab=documents)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-REV-P130 | Positive | View | Documents tab renders with cascading filters: class section, student, application | 3 dropdowns visible | test_review_130 | Automated |
| TC-REV-P131 | Positive | Ctrl | Filter cascading works: select section → populate student → select student → populate application | Cascade correct | test_review_131 | Automated |
| TC-REV-P132 | Positive | View | Clear filter link resets all filters on documents tab | Filters cleared | test_review_132 | Automated |
| TC-REV-P133 | Positive | View | Document cards show file icon matching extension (pdf→red, jpg/png→blue, doc/docx→teal, other→gray) | Correct icon | test_review_133 | Automated |
| TC-REV-P134 | Positive | View | Document card shows document_name, student name + date, uploader name | All meta visible | test_review_134 | Automated |
| TC-REV-P135 | Positive | View | Document card shows document_type badge and description when present | Extras visible | test_review_135 | Automated |
| TC-REV-P136 | Positive | View | Document card shows "Response" badge when is_in_response_to_request is true | Response badge | test_review_136 | Automated |
| TC-REV-P137 | Positive | View | Document dropdown has View (new tab) and Download actions | 2 actions | test_review_137 | Automated |
| TC-REV-P138 | Positive | View | "Open Related Application" footer link navigates to review page for that application | Link correct | test_review_138 | Automated |
| TC-REV-P139 | Positive | View | Empty state when no documents match filters: "No documents found" | Empty state | test_review_139 | Automated |
| TC-REV-P140 | Positive | View | Documents display when filters yield results | Cards rendered | test_review_140 | Automated |

### Cross-Cutting — Schema, Auth, Tenancy, Security

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-REV-P01 | Schema | DDL/Model | Migration, model, table, fillable, casts, SoftDeletes, status constants for LeaveApplication | All pass | test_review_01 | Automated |
| TC-REV-P02 | Schema | Routes | All routes registered (index+4 tabs, review, update-review, storeRemark, AJAX students/applications) | All present | test_review_02 | Automated |
| TC-REV-P03 | Schema | DDL/Model | LeaveApplicationRemark model: table, fillable, casts, no SoftDeletes, remark type constants | All pass | test_review_03 | Automated |
| TC-REV-P04 | Schema | DDL/Model | LeaveApplicationDocument model: table, fillable, casts, SoftDeletes, InteractsWithMedia, media collection | All pass | test_review_04 | Automated |
| TC-REV-P05 | Auth | Middleware | Guest redirected to /login | /login | test_review_05 | Automated |
| TC-REV-P06 | Auth | Policy | Policy permission mapping for student-leave.viewAny, student-leave.review, student-leave.update, student-leave.view | Mapped | test_review_06 | Automated |
| TC-REV-P07 | Auth | Ctrl | Gate authorization present on index, review, updateReview, storeRemark, getStudentsBySection, getApplicationsByStudent | Gates present | test_review_07 | Automated |
| TC-REV-N08 | Auth | Ctrl | User without student-leave.viewAny → 403 on index | 403 | test_review_08 | Automated |
| TC-REV-N09 | Auth | Ctrl | User without student-leave.review → 403 on review page | 403 | test_review_09 | Automated |
| TC-REV-N10 | Auth | Ctrl | User without student-leave.update → 403 on updateReview | 403 | test_review_10 | Automated |
| TC-REV-N11 | Auth | Ctrl | User without student-leave.update → 403 on storeRemark | 403 | test_review_11 | Automated |
| TC-REV-N12 | Auth | Ctrl | User without student-leave.view → 403 on AJAX students/applications endpoints | 403 | test_review_12 | Automated |
| TC-REV-T90 | Tenancy | Tenant | Leave application records scoped to current tenant | Scoped | test_review_90 | Automated |
| TC-REV-P91 | Security | View | Stored XSS in reason/review_remarks/remark message escaped on render | Escaped | test_review_91 | Automated |
| TC-REV-P92 | Security | Ctrl | reviewed_by not spoofable via request body (set by auth()->id()) | Ignored | test_review_92 | Automated |
| TC-REV-P93 | Security | Ctrl | remarked_by/uploaded_by not spoofable via request body (set by auth()->id()) | Ignored | test_review_93 | Automated |

---

## 3. Test Method Index

### File: `std_ApplicationReview_TestCas.php` (97 methods)
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_review_01_leave_application_schema_and_constants | TC-REV-P01 | Schema | 01-04 |
| 2 | test_review_02_all_routes_are_registered | TC-REV-P02 | Schema | 01-04 |
| 3 | test_review_03_leave_application_remark_schema | TC-REV-P03 | Schema | 01-04 |
| 4 | test_review_04_leave_application_document_schema | TC-REV-P04 | Schema | 01-04 |
| 5 | test_review_05_guest_redirected_to_login | TC-REV-P05 | Auth | 05-09 |
| 6 | test_review_06_policy_permission_mapping_is_correct | TC-REV-P06 | Auth | 05-09 |
| 7 | test_review_07_controller_gate_authorization_is_present | TC-REV-P07 | Auth | 05-09 |
| 8 | test_review_08_user_without_viewAny_permission_gets_403 | TC-REV-N08 | Auth | 05-09 |
| 9 | test_review_09_user_without_review_permission_gets_403 | TC-REV-N09 | Auth | 05-09 |
| 10 | test_review_10_user_without_update_permission_gets_403 | TC-REV-N10 | Auth | 05-09 |
| 11 | test_review_11_user_without_update_permission_gets_403_on_store_remark | TC-REV-N11 | Auth | 05-09 |
| 12 | test_review_12_user_without_view_permission_gets_403_on_ajax | TC-REV-N12 | Auth | 05-09 |
| 13 | test_review_10_review_tab_renders_with_filters_and_table | TC-REV-P10 | List | 10-29 |
| 14 | test_review_11_search_by_student_name_filters_results | TC-REV-P11 | List | 10-29 |
| 15 | test_review_12_search_by_admission_no_filters_results | TC-REV-P12 | List | 10-29 |
| 16 | test_review_13_filter_by_class_id_narrows_results | TC-REV-P13 | List | 10-29 |
| 17 | test_review_14_filter_by_section_id_narrows_results | TC-REV-P14 | List | 10-29 |
| 18 | test_review_15_filter_by_status_narrows_results | TC-REV-P15 | List | 10-29 |
| 19 | test_review_16_combined_filters_work_together | TC-REV-P16 | List | 10-29 |
| 20 | test_review_17_clear_filter_resets_all_filters | TC-REV-P17 | List | 10-29 |
| 21 | test_review_18_results_are_paginated | TC-REV-P18 | List | 10-29 |
| 22 | test_review_19_table_displays_all_columns | TC-REV-P19 | List | 10-29 |
| 23 | test_review_20_action_buttons_per_row | TC-REV-P20 | List | 10-29 |
| 24 | test_review_21_class_teacher_sees_default_class_filter | TC-REV-P21 | List | 10-29 |
| 25 | test_review_22_non_class_teacher_sees_all_classes | TC-REV-P22 | List | 10-29 |
| 26 | test_review_23_empty_state_shown_when_no_results | TC-REV-P23 | List | 10-29 |
| 27 | test_review_24_status_badge_color_is_correct | TC-REV-P24 | List | 10-29 |
| 28 | test_review_30_review_page_renders_breadcrumb | TC-REV-P30 | ReviewPg | 30-49 |
| 29 | test_review_31_sidebar_shows_student_information | TC-REV-P31 | ReviewPg | 30-49 |
| 30 | test_review_32_application_summary_shows_reason | TC-REV-P32 | ReviewPg | 30-49 |
| 31 | test_review_33_five_status_radio_buttons_present | TC-REV-P33 | ReviewPg | 30-49 |
| 32 | test_review_34_current_status_is_pre_checked | TC-REV-P34 | ReviewPg | 30-49 |
| 33 | test_review_35_review_remarks_textarea_present | TC-REV-P35 | ReviewPg | 30-49 |
| 34 | test_review_36_approved_days_input_has_correct_limits | TC-REV-P36 | ReviewPg | 30-49 |
| 35 | test_review_37_last_action_info_displayed | TC-REV-P37 | ReviewPg | 30-49 |
| 36 | test_review_38_cancel_button_links_back | TC-REV-P38 | ReviewPg | 30-49 |
| 37 | test_review_39_apply_decision_button_present | TC-REV-P39 | ReviewPg | 30-49 |
| 38 | test_review_40_review_invalid_id_returns_404 | TC-REV-N40 | ReviewPg | 30-49 |
| 39 | test_review_41_review_soft_deleted_id_returns_404 | TC-REV-N41 | ReviewPg | 30-49 |
| 40 | test_review_50_approve_application | TC-REV-P50 | Decision | 50-69 |
| 41 | test_review_51_reject_application | TC-REV-P51 | Decision | 50-69 |
| 42 | test_review_52_mark_under_review | TC-REV-P52 | Decision | 50-69 |
| 43 | test_review_53_request_info | TC-REV-P53 | Decision | 50-69 |
| 44 | test_review_54_request_doc | TC-REV-P54 | Decision | 50-69 |
| 45 | test_review_55_review_remarks_are_saved | TC-REV-P55 | Decision | 50-69 |
| 46 | test_review_56_custom_approved_days_saved | TC-REV-P56 | Decision | 50-69 |
| 47 | test_review_57_approve_marks_full_attendance | TC-REV-P57 | Decision | 50-69 |
| 48 | test_review_58_approve_marks_partial_attendance | TC-REV-P58 | Decision | 50-69 |
| 49 | test_review_59_approve_with_zero_days_no_attendance | TC-REV-P59 | Decision | 50-69 |
| 50 | test_review_60_status_change_remark_auto_logged | TC-REV-P60 | Decision | 50-69 |
| 51 | test_review_61_reviewed_activity_log_written | TC-REV-P61 | Decision | 50-69 |
| 52 | test_review_62_re_approve_already_approved | TC-REV-P62 | Decision | 50-69 |
| 53 | test_review_63_change_from_approved_to_rejected | TC-REV-P63 | Decision | 50-69 |
| 54 | test_review_70_status_field_missing_422 | TC-REV-N70 | Val | 70-89 |
| 55 | test_review_71_invalid_status_value_422 | TC-REV-N71 | Val | 70-89 |
| 56 | test_review_72_review_remarks_exceeds_1000_chars_422 | TC-REV-N72 | Val | 70-89 |
| 57 | test_review_73_approved_days_negative_422 | TC-REV-N73 | Val | 70-89 |
| 58 | test_review_74_approved_days_exceeds_total_days_422 | TC-REV-N74 | Val | 70-89 |
| 59 | test_review_75_update_review_invalid_id_404 | TC-REV-N75 | Val | 70-89 |
| 60 | test_review_76_update_review_soft_deleted_id_404 | TC-REV-N76 | Val | 70-89 |
| 61 | test_review_100_remarks_tab_renders_with_cascading_filters | TC-REV-P100 | Remarks | 100-119 |
| 62 | test_review_101_ajax_get_students_by_section | TC-REV-P101 | Remarks | 100-119 |
| 63 | test_review_102_ajax_get_applications_by_student | TC-REV-P102 | Remarks | 100-119 |
| 64 | test_review_103_filter_cascade_works_on_remarks_tab | TC-REV-P103 | Remarks | 100-119 |
| 65 | test_review_104_clear_filter_on_remarks_tab | TC-REV-P104 | Remarks | 100-119 |
| 66 | test_review_105_header_shows_selected_application_info | TC-REV-P105 | Remarks | 100-119 |
| 67 | test_review_106_header_links_to_review_and_edit_pages | TC-REV-P106 | Remarks | 100-119 |
| 68 | test_review_107_header_empty_state_when_no_application | TC-REV-P107 | Remarks | 100-119 |
| 69 | test_review_108_chat_body_shows_date_dividers | TC-REV-P108 | Remarks | 100-119 |
| 70 | test_review_109_chat_items_alignment_and_badges | TC-REV-P109 | Remarks | 100-119 |
| 71 | test_review_110_chat_empty_state_no_remarks | TC-REV-P110 | Remarks | 100-119 |
| 72 | test_review_111_chat_prompt_no_application_selected | TC-REV-P111 | Remarks | 100-119 |
| 73 | test_review_112_chat_footer_input_elements_present | TC-REV-P112 | Remarks | 100-119 |
| 74 | test_review_113_chat_footer_locked_for_finalized_statuses | TC-REV-P113 | Remarks | 100-119 |
| 75 | test_review_114_send_remark_with_message_only | TC-REV-P114 | Remarks | 100-119 |
| 76 | test_review_115_send_remark_with_message_and_attachments | TC-REV-P115 | Remarks | 100-119 |
| 77 | test_review_116_send_remark_with_attachments_only | TC-REV-P116 | Remarks | 100-119 |
| 78 | test_review_117_enter_key_submits_remark | TC-REV-P117 | Remarks | 100-119 |
| 79 | test_review_118_file_attachment_accepted_types | TC-REV-P118 | Remarks | 100-119 |
| 80 | test_review_120_store_remark_empty_message_and_no_attachments_422 | TC-REV-N120 | Remarks | 120-129 |
| 81 | test_review_121_store_remark_file_exceeds_5mb_422 | TC-REV-N121 | Remarks | 120-129 |
| 82 | test_review_122_store_remark_approved_application_403 | TC-REV-N122 | Remarks | 120-129 |
| 83 | test_review_123_store_remark_rejected_application_403 | TC-REV-N123 | Remarks | 120-129 |
| 84 | test_review_124_store_remark_cancelled_application_403 | TC-REV-N124 | Remarks | 120-129 |
| 85 | test_review_125_store_remark_invalid_application_id_422 | TC-REV-N125 | Remarks | 120-129 |
| 86 | test_review_126_store_remark_invalid_document_type_id_422 | TC-REV-N126 | Remarks | 120-129 |
| 87 | test_review_127_store_remark_description_exceeds_255_422 | TC-REV-N127 | Remarks | 120-129 |
| 88 | test_review_130_documents_tab_renders_with_cascading_filters | TC-REV-P130 | Docs | 130-149 |
| 89 | test_review_131_filter_cascade_works_on_documents_tab | TC-REV-P131 | Docs | 130-149 |
| 90 | test_review_132_clear_filter_on_documents_tab | TC-REV-P132 | Docs | 130-149 |
| 91 | test_review_133_document_card_icon_by_extension | TC-REV-P133 | Docs | 130-149 |
| 92 | test_review_134_document_card_meta_information | TC-REV-P134 | Docs | 130-149 |
| 93 | test_review_135_document_type_badge_and_description | TC-REV-P135 | Docs | 130-149 |
| 94 | test_review_136_response_badge_on_document_card | TC-REV-P136 | Docs | 130-149 |
| 95 | test_review_137_document_view_and_download_actions | TC-REV-P137 | Docs | 130-149 |
| 96 | test_review_138_open_related_application_link | TC-REV-P138 | Docs | 130-149 |
| 97 | test_review_139_documents_tab_empty_state | TC-REV-P139 | Docs | 130-149 |
| 98 | test_review_140_documents_display_with_results | TC-REV-P140 | Docs | 130-149 |
| 99 | test_review_90_records_are_tenant_scoped | TC-REV-T90 | Tenancy | 90-99 |
| 100 | test_review_91_stored_xss_is_escaped_on_render | TC-REV-P91 | Security | 90-99 |
| 101 | test_review_92_reviewed_by_not_spoofable_via_request | TC-REV-P92 | Security | 90-99 |
| 102 | test_review_93_remarked_by_and_uploaded_by_not_spoofable | TC-REV-P93 | Security | 90-99 |

**Total: 102 methods (85 Automated, 17 Planned).**
