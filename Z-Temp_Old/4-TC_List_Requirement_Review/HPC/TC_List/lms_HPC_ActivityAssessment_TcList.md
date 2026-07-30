# lms_HPC_ActivityAssessment_TcList

## Module: HPC → Activity Assessment Overview

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HPC |
| Tab Group | Activity Assessment |
| Feature | Activity Assessment Overview |
| URL(s) | `hpc/activity-assessment/{report_id}` |
| Controller | `Modules\Hpc\Http\Controllers\HpcActivityAssessmentController` |
| Model(s) | `Modules\Hpc\Models\HpcReport`, `StudentFormSubmission`, `ParentFormToken`, `PeerAssignment` |
| Validation | Route-level `report_id` existence in `hpc_reports` table |
| Permissions | `tenant.hpc.view` |
| Soft Deletes | No direct — reads from models that use SoftDeletes |
| Activity Log | None |

---

## 2. Pre-conditions

- Required permissions: `tenant.hpc.view`
- At least one `HpcReport` record with associated report_items, student, class, subject data exists for the given `report_id`
- Test user must have the above permission (default admin user or user assigned via role)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Dashboard requires at least one `HpcReport` record for the target `report_id` to render meaningful data
- Peer assignments must exist in `peer_assignments` table for peer completion tracking
- `StudentFormSubmission` records must exist with status values for student completion tracking
- `ParentFormToken` records must exist with `completed_at` for parent completion tracking
- Missing tables should gracefully render N/A without throwing errors

---

## 3. Default Data Load

When the page loads via `HpcActivityAssessmentController` (GET `hpc/activity-assessment/{report_id}`), the following data is fetched:

| Data Loaded | Source | Filters | Pagination |
|------------|--------|---------|------------|
| HpcReport with report_items | `HpcReport::with('report_items')->findOrFail($report_id)` | report_id | None (single record) |
| Teacher completion data | `HpcReport::where('id', $report_id)->withCount('report_items')->first()` | report_id | None |
| Student completion data | `StudentFormSubmission::where('hpc_report_id', $report_id)->where('status', 'completed')->count()` | hpc_report_id, status=completed | None |
| Parent completion data | `ParentFormToken::where('hpc_report_id', $report_id)->whereNotNull('completed_at')->count()` | hpc_report_id, completed_at not null | None |
| Peer completion data | `PeerAssignment::where('hpc_report_id', $report_id)->whereNotNull('completed_at')->count()` | hpc_report_id, completed_at not null | None |
| Domain progress per section | Derived from HpcReportItem grouping by domain/section with completion status | report_id | None |

---

## 4. Test Data Strategy

- **Teacher completion**: Seed an `HpcReport` with varying counts of `report_items` — some complete, some incomplete
- **Student completion**: Seed `StudentFormSubmission` records with `status=completed` and `status=pending` mix
- **Parent completion**: Seed `ParentFormToken` records with some having `completed_at` set and some null
- **Peer completion**: Seed `PeerAssignment` records with some having `completed_at` set and some null
- **Status coverage**: Ensure at least one contributor per status variant: Complete (✅), In Progress (⏳), Pending (⬜), N/A (❌)
- **Domain progress**: Seed report_items across multiple domains/sections with varying completion ratios
- **Missing tables**: Mock or simulate missing `StudentFormSubmission`, `ParentFormToken`, or `PeerAssignment` tables
- **Permissions**: Test with admin, principal, teacher, student, and guest roles
- **Pre-test cleanup**: Delete created records before/after tests to avoid collisions

---

## 5. Business Conditions

### 4.1 Database Schema — `hpc_reports` and Related Tables

| BC ID | Table | Column | Type (DDL) | Constraints |
|-------|-------|--------|------------|-------------|
| BC-DB-01 | hpc_reports | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | hpc_reports | student_id | INT UNSIGNED | NOT NULL, FK → `sch_students.id` |
| BC-DB-03 | hpc_reports | class_id | INT UNSIGNED | NOT NULL, FK → `sch_classes.id` |
| BC-DB-04 | hpc_reports | subject_id | INT UNSIGNED | NOT NULL, FK → `sch_subjects.id` |
| BC-DB-05 | hpc_reports | template_id | INT UNSIGNED | NOT NULL, FK → `hpc_templates.id` |
| BC-DB-06 | hpc_reports | status | ENUM('draft','final','published','archived') | NOT NULL DEFAULT 'draft' |
| BC-DB-07 | hpc_reports | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-08 | hpc_reports | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-09 | hpc_report_items | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-10 | hpc_report_items | hpc_report_id | INT UNSIGNED | NOT NULL, FK → `hpc_reports.id` |
| BC-DB-11 | hpc_report_items | section | VARCHAR(255) | NOT NULL |
| BC-DB-12 | hpc_report_items | domain | VARCHAR(255) | NOT NULL |
| BC-DB-13 | hpc_report_items | completion_status | ENUM('complete','in_progress','pending','not_applicable') | NOT NULL DEFAULT 'pending' |
| BC-DB-14 | hpc_report_items | score | DECIMAL(5,2) | NULLABLE |
| BC-DB-15 | student_form_submissions | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-16 | student_form_submissions | hpc_report_id | INT UNSIGNED | NOT NULL, FK → `hpc_reports.id` |
| BC-DB-17 | student_form_submissions | status | ENUM('pending','in_progress','completed') | NOT NULL DEFAULT 'pending' |
| BC-DB-18 | student_form_submissions | completed_at | TIMESTAMP | NULLABLE |
| BC-DB-19 | parent_form_tokens | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-20 | parent_form_tokens | hpc_report_id | INT UNSIGNED | NOT NULL, FK → `hpc_reports.id` |
| BC-DB-21 | parent_form_tokens | completed_at | TIMESTAMP | NULLABLE |
| BC-DB-22 | parent_form_tokens | token | VARCHAR(255) | NOT NULL UNIQUE |
| BC-DB-23 | peer_assignments | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-24 | peer_assignments | hpc_report_id | INT UNSIGNED | NOT NULL, FK → `hpc_reports.id` |
| BC-DB-25 | peer_assignments | peer_student_id | INT UNSIGNED | NOT NULL, FK → `sch_students.id` |
| BC-DB-26 | peer_assignments | completed_at | TIMESTAMP | NULLABLE |

### 4.2 Validation Rules (Create)

| BC ID | Field | Rule | Error Message / Behavior |
|-------|-------|------|--------------------------|
| BC-VAL-01 | report_id (route) | Must exist in `hpc_reports` table | 404 Not Found |
| BC-VAL-02 | report_id (route) | Must be a valid integer | 404 Not Found |
| BC-VAL-03 | hpc_report_id (submissions) | Must reference valid hpc_reports.id | FK constraint violation |

### 4.3 Validation Rules (Update)

| BC ID | Field | Rule | Error Message / Behavior |
|-------|-------|------|--------------------------|
| BC-VAL-U01 | (No update-specific validation) | N/A — feature is read-only | No update operations exist for this feature |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.hpc.view` | index() | Without → 403 Forbidden on `hpc/activity-assessment/{report_id}` |
| BC-AUTH-02 | Principal role | index() | Can view any report in the school |
| BC-AUTH-03 | Admin role | index() | Can view any report in the school |
| BC-AUTH-04 | Teacher role | index() | Can view reports for assigned students only |
| BC-AUTH-05 | Student role | index() | Can view own report only |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Dashboard loads with valid report_id | Displays Activity Assessment Overview with 4 contributor sections |
| BC-BIZ-02 | Teacher completion calculation | Based on `HpcReport` existence + count of `report_items` — if items exist with any completion_status, teacher is "In Progress"; if all items complete, teacher is "Complete"; if no items, teacher is "Pending" |
| BC-BIZ-03 | Student completion calculation | Based on `StudentFormSubmission` — if status='completed', student is "Complete"; if status='in_progress', student is "In Progress"; if status='pending' or no submission, student is "Pending"; if table missing, show N/A |
| BC-BIZ-04 | Parent completion calculation | Based on `ParentFormToken.completed_at` — if `completed_at` is not null, parent is "Complete"; if token exists but `completed_at` is null, parent is "In Progress"; if no token, parent is "Pending"; if table missing, show N/A |
| BC-BIZ-05 | Peer completion calculation | Based on `PeerAssignment.completed_at` — if all peer assignments have `completed_at` not null, peer is "Complete"; if some completed, peer is "In Progress"; if none completed, peer is "Pending"; if no assignments, peer is "N/A"; if table missing, show N/A |
| BC-BIZ-06 | Status indicators display | Complete = ✅ (green), In Progress = ⏳ (amber), Pending = ⬜ (grey), N/A = ❌ (red) |
| BC-BIZ-07 | Domain progress per section | Percentage calculated as `(completed_items_in_section / total_items_in_section) * 100` |
| BC-BIZ-08 | Missing StudentFormSubmission table | Graceful fallback — show N/A for student section, no error |
| BC-BIZ-09 | Missing ParentFormToken table | Graceful fallback — show N/A for parent section, no error |
| BC-BIZ-10 | Missing PeerAssignment table | Graceful fallback — show N/A for peer section, no error |
| BC-BIZ-11 | Contributor list displays 4 roles | Teacher, Student, Parent, Peer all shown with their respective status indicators |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | hpc_reports.student_id | sch_students (id) | CASCADE |
| BC-REF-02 | hpc_reports.class_id | sch_classes (id) | RESTRICT |
| BC-REF-03 | hpc_reports.subject_id | sch_subjects (id) | RESTRICT |
| BC-REF-04 | hpc_reports.template_id | hpc_templates (id) | RESTRICT |
| BC-REF-05 | hpc_report_items.hpc_report_id | hpc_reports (id) | CASCADE |
| BC-REF-06 | student_form_submissions.hpc_report_id | hpc_reports (id) | CASCADE |
| BC-REF-07 | parent_form_tokens.hpc_report_id | hpc_reports (id) | CASCADE |
| BC-REF-08 | peer_assignments.hpc_report_id | hpc_reports (id) | CASCADE |
| BC-REF-09 | peer_assignments.peer_student_id | sch_students (id) | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Dashboard loads for valid report_id | Page loads at `hpc/activity-assessment/{report_id}` with all 4 contributor sections visible | — | — | ⬜ |
| TC-P02 | Teacher completion shows correct percentage | Teacher section displays completion % based on report_items count matching seed data | — | — | ⬜ |
| TC-P03 | Student completion shows correct status | Student section displays correct status (Complete/In Progress/Pending) based on form submission status | — | — | ⬜ |
| TC-P04 | Parent completion shows correct status | Parent section displays correct status based on ParentFormToken.completed_at | — | — | ⬜ |
| TC-P05 | Peer completion shows correct status | Peer section displays correct status based on PeerAssignment.completed_at for all assignments | — | — | ⬜ |
| TC-P06 | Contributor list displays all 4 roles | Teacher, Student, Parent, Peer are all listed in the contributor overview | — | — | ⬜ |
| TC-P07 | Status indicators show correct colours | Each contributor shows the matching status icon (✅/⏳/⬜/❌) with correct colour | — | — | ⬜ |
| TC-P08 | Domain progress percentages display per section | Each domain/section shows a completion percentage bar or number | — | — | ⬜ |
| TC-P09 | Domain progress percentage calculation correct | Percentage = (completed items / total items) * 100 matches manual calculation | — | — | ⬜ |
| TC-P10 | Principal can view any report | Principal role user accesses any student's activity assessment successfully | — | — | ⬜ |
| TC-P11 | Admin can view any report | Admin role user accesses any student's activity assessment successfully | — | — | ⬜ |
| TC-P12 | Teacher views assigned student report | Teacher accesses report for student they are assigned to — data loads correctly | — | — | ⬜ |
| TC-P13 | Student views own report | Student accesses their own report — data loads with their specific submission status | — | — | ⬜ |
| TC-P14 | Refresh updates stale data | After updating a submission status, refreshing the dashboard shows updated data | — | — | ⬜ |
| TC-P15 | Teacher completion all items → Complete | All report_items have completion_status='complete' → Teacher shows Complete ✅ | — | — | ⬜ |
| TC-P16 | Teacher completion no items → Pending | Report has zero report_items → Teacher shows Pending ⬜ | — | — | ⬜ |
| TC-P17 | Student submission completed_at set → Complete | StudentFormSubmission status=completed → Student shows Complete ✅ | — | — | ⬜ |
| TC-P18 | Parent token completed_at set → Complete | ParentFormToken completed_at not null → Parent shows Complete ✅ | — | — | ⬜ |
| TC-P19 | All peer assignments completed → Complete | All PeerAssignment records have completed_at not null → Peer shows Complete ✅ | — | — | ⬜ |
| TC-P20 | Some peer assignments completed → In Progress | Mix of completed and pending PeerAssignment records → Peer shows In Progress ⏳ | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Invalid report_id (non-existent) | 404 Not Found — route resolves, record not found | — | — | ⬜ |
| TC-N02 | Invalid report_id (non-numeric string) | 404 Not Found — route binding fails | — | — | ⬜ |
| TC-N03 | Report without card data (no report_items) | Dashboard loads with Teacher showing Pending ⬜, no errors | — | — | ⬜ |
| TC-N04 | Student without form submission template | Student section shows Pending ⬜ or N/A ❌ gracefully | — | — | ⬜ |
| TC-N05 | Permission denied — user without tenant.hpc.view | 403 Forbidden | — | — | ⬜ |
| TC-N06 | Guest access redirect | Unauthenticated user redirected to login page | — | — | ⬜ |
| TC-N07 | Student without permissions accessing another student's report | 403 Forbidden — student cannot view other student's assessment | — | — | ⬜ |
| TC-N08 | Teacher without permissions accessing unassigned student | 403 Forbidden — teacher cannot view unassigned student's assessment | — | — | ⬜ |
| TC-N09 | Missing StudentFormSubmission table | Graceful fallback — Student section shows N/A ❌, no error thrown | — | — | ⬜ |
| TC-N10 | Missing ParentFormToken table | Graceful fallback — Parent section shows N/A ❌, no error thrown | — | — | ⬜ |
| TC-N11 | Missing PeerAssignment table | Graceful fallback — Peer section shows N/A ❌, no error thrown | — | — | ⬜ |
| TC-N12 | Empty report — no report data at all | Dashboard loads with empty/zero states, no errors | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | HpcReport FK to Student — orphaned report deleted | Deleting a student cascades to delete their HpcReport; corresponding activity assessment returns 404 | — | — | ⬜ |
| TC-D02 | B | StudentFormSubmission FK to HpcReport | Deleting an HpcReport cascades to delete related StudentFormSubmission records | — | — | ⬜ |
| TC-D03 | C | ParentFormToken FK to HpcReport | Deleting an HpcReport cascades to delete related ParentFormToken records | — | — | ⬜ |
| TC-D04 | D | PeerAssignment FK to HpcReport | Deleting an HpcReport cascades to delete related PeerAssignment records | — | — | ⬜ |
| TC-D05 | E | Missing StudentFormSubmission table → graceful N/A | Dashboard loads with Student section showing N/A ❌; no 500 error | — | — | ⬜ |
| TC-D06 | F | Missing ParentFormToken table → graceful N/A | Dashboard loads with Parent section showing N/A ❌; no 500 error | — | — | ⬜ |
| TC-D07 | G | Missing PeerAssignment table → graceful N/A | Dashboard loads with Peer section showing N/A ❌; no 500 error | — | — | ⬜ |
| TC-D08 | H | Data aggregation from 4 sources is consistent | Teacher, Student, Parent, Peer completion data all computed independently and displayed together | — | — | ⬜ |
| TC-D09 | I | Status calculation logic — Teacher Complete | All report_items completion_status='complete' → Teacher status = Complete ✅ | — | — | ⬜ |
| TC-D10 | I | Status calculation logic — Teacher In Progress | Mix of complete/incomplete report_items → Teacher status = In Progress ⏳ | — | — | ⬜ |
| TC-D11 | I | Status calculation logic — Teacher Pending | Zero report_items → Teacher status = Pending ⬜ | — | — | ⬜ |
| TC-D12 | J | Status calculation logic — Student Complete | StudentFormSubmission status='completed' → Student = Complete ✅ | — | — | ⬜ |
| TC-D13 | J | Status calculation logic — Student In Progress | StudentFormSubmission status='in_progress' → Student = In Progress ⏳ | — | — | ⬜ |
| TC-D14 | J | Status calculation logic — Student Pending | No StudentFormSubmission OR status='pending' → Student = Pending ⬜ | — | — | ⬜ |
| TC-D15 | K | Completion percentage — domain with mixed items | Domain with 7 completed out of 10 items → shows 70% completion | — | — | ⬜ |
| TC-D16 | K | Completion percentage — domain all complete | Domain with all items completed → shows 100% | — | — | ⬜ |
| TC-D17 | K | Completion percentage — domain all pending | Domain with zero completed items → shows 0% | — | — | ⬜ |
| TC-D18 | K | Completion percentage — empty domain | Domain with zero total items → shows N/A or 0%, no division error | — | — | ⬜ |
| TC-D19 | L | Large dataset — report with 500+ report_items | Dashboard loads within acceptable time; all statuses calculated correctly | — | — | ⬜ |
| TC-D20 | M | Soft-deleted student record handling | Student is soft-deleted but HpcReport exists — dashboard still loads with existing data | — | — | ⬜ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Dashboard Loads For Valid report_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Navigate to `hpc/activity-assessment/{valid_report_id}` | Page loads without errors |
| 3 | Verify page heading shows "Activity Assessment Overview" | Correct heading displayed |
| 4 | Check contributor section for Teacher | Teacher section visible with status indicator |
| 5 | Check contributor section for Student | Student section visible with status indicator |
| 6 | Check contributor section for Parent | Parent section visible with status indicator |
| 7 | Check contributor section for Peer | Peer section visible with status indicator |
| 8 | Verify domain progress sections displayed | Section-wise completion percentages visible |

---

#### TC-P02: Teacher Completion Shows Correct Percentage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HpcReport with 10 report_items: 7 complete, 3 in_progress | Fixed dataset |
| 2 | Navigate to `hpc/activity-assessment/{report_id}` | Dashboard loads |
| 3 | Locate Teacher completion section | Section visible |
| 4 | Verify Teacher status shows "In Progress" | ⏳ with correct amber colour |
| 5 | Verify completion percentage | (7/10)*100 = 70% displayed |
| 6 | Update all 10 items to 'complete' | Seed updated |
| 7 | Refresh page | Teacher status changes to Complete ✅, shows 100% |

---

#### TC-P03: Student Completion Shows Correct Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed StudentFormSubmission with status='completed' for the report | Submission exists |
| 2 | Navigate to dashboard | Page loads |
| 3 | Check Student section status | Shows Complete ✅ |
| 4 | Update submission status to 'in_progress' | Status updated |
| 5 | Refresh page | Shows In Progress ⏳ |
| 6 | Update submission status to 'pending' | Status updated |
| 7 | Refresh page | Shows Pending ⬜ |

---

#### TC-P04: Parent Completion Shows Correct Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed ParentFormToken with completed_at = now | Token with completion |
| 2 | Navigate to dashboard | Page loads |
| 3 | Check Parent section status | Shows Complete ✅ |
| 4 | Set ParentFormToken.completed_at = null | Token pending |
| 5 | Refresh page | Shows In Progress ⏳ (token exists but not completed) |
| 6 | Delete the ParentFormToken | No token exists |
| 7 | Refresh page | Shows Pending ⬜ |

---

#### TC-P05: Peer Completion Shows Correct Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 3 PeerAssignment records all with completed_at = now | All complete |
| 2 | Navigate to dashboard | Page loads |
| 3 | Check Peer section status | Shows Complete ✅ |
| 4 | Set 1 PeerAssignment.completed_at = null | Mix of complete/pending |
| 5 | Refresh page | Shows In Progress ⏳ |
| 6 | Set all 3 PeerAssignment.completed_at = null | None complete |
| 7 | Refresh page | Shows Pending ⬜ |
| 8 | Delete all PeerAssignment records | No assignments |
| 9 | Refresh page | Shows N/A ❌ |

---

#### TC-P06: Contributor List Displays All 4 Roles

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed data for all 4 contributor types | Teacher, Student, Parent, Peer have data |
| 2 | Navigate to dashboard | Page loads |
| 3 | Check that 4 contributor cards/sections are visible | Teacher, Student, Parent, Peer each have a section |
| 4 | Each section shows role name | Labels read "Teacher", "Student", "Parent", "Peer" |
| 5 | Each section shows status indicator | Icon + status text visible per contributor |

---

#### TC-P07: Status Indicators Show Correct Colours

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed Teacher: complete, Student: pending, Parent: in_progress, Peer: N/A | Mixed statuses |
| 2 | Navigate to dashboard | Page loads |
| 3 | Check Teacher indicator | ✅ green icon visible |
| 4 | Check Student indicator | ⬜ grey icon visible |
| 5 | Check Parent indicator | ⏳ amber icon visible |
| 6 | Check Peer indicator | ❌ red icon visible |

---

#### TC-P08: Domain Progress Percentages Display Per Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed report_items across 3 domains: Domain A (5 items, 4 completed), Domain B (3 items, 1 completed), Domain C (2 items, 0 completed) | Multi-domain data |
| 2 | Navigate to dashboard | Page loads |
| 3 | Verify Domain A section shows 80% | (4/5)*100 = 80% |
| 4 | Verify Domain B section shows 33% | (1/3)*100 rounded to 33% |
| 5 | Verify Domain C section shows 0% | (0/2)*100 = 0% |

---

#### TC-P09: Domain Progress Percentage Calculation Correct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Domain X has 12 total items, 9 completed | Dataset |
| 2 | Calculate expected: (9/12)*100 = 75% | — |
| 3 | Navigate to dashboard | Domain X shows 75% |
| 4 | Seed: Domain Y has 0 total items | Empty domain |
| 5 | Navigate to dashboard | Domain Y shows 0% or N/A — no division error |

---

#### TC-P10: Principal Can View Any Report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with Principal role | Dashboard loads |
| 2 | Navigate to report for Class 5A Student | Report loads successfully |
| 3 | Navigate to report for Class 10B Student | Report loads successfully |
| 4 | All 4 contributor sections visible and populated | Full data displayed |

---

#### TC-P11: Admin Can View Any Report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with Admin role | Dashboard loads |
| 2 | Navigate to any valid report_id | Report loads successfully |
| 3 | All 4 contributor sections visible and populated | Full data displayed |

---

#### TC-P12: Teacher Views Assigned Student Report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as Teacher who is assigned to Student A | Dashboard loads |
| 2 | Navigate to Student A's activity assessment | Report loads with Teacher's completion data visible |
| 3 | Verify Teacher section shows data from their own HpcReport entries | Correct data |

---

#### TC-P13: Student Views Own Report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as Student A | Dashboard loads |
| 2 | Navigate to own activity assessment | Report loads |
| 3 | Student section shows own submission status | Correct status displayed |
| 4 | Teacher section visible (read-only) | Teacher data displayed for reference |

---

#### TC-P14: Refresh Updates Stale Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to dashboard — note Student status | Status = Pending ⬜ |
| 2 | In another tab, submit student form (status=completed) | Form submitted |
| 3 | Refresh original dashboard page | Student status now = Complete ✅ |
| 4 | Verify other sections also reflect any updated data | All sections current |

---

#### TC-P15: Teacher Completion All Items → Complete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HpcReport with 5 report_items, all completion_status='complete' | All complete |
| 2 | Navigate to dashboard | Teacher shows Complete ✅ |
| 3 | Completion percentage shows 100% | All items done |

---

#### TC-P16: Teacher Completion No Items → Pending

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HpcReport with zero report_items | No items |
| 2 | Navigate to dashboard | Teacher shows Pending ⬜ |
| 3 | Completion percentage shows 0% or N/A | No items to calculate |

---

#### TC-P17: Student Submission Completed → Complete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed StudentFormSubmission with status='completed' and completed_at set | Complete submission |
| 2 | Navigate to dashboard | Student shows Complete ✅ |

---

#### TC-P18: Parent Token Completed → Complete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed ParentFormToken with completed_at = now | Completed token |
| 2 | Navigate to dashboard | Parent shows Complete ✅ |

---

#### TC-P19: All Peer Assignments Completed → Complete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 4 PeerAssignment records, all with completed_at = now | All complete |
| 2 | Navigate to dashboard | Peer shows Complete ✅ |

---

#### TC-P20: Some Peer Assignments Completed → In Progress

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 4 PeerAssignment records: 2 with completed_at, 2 with null | Mix |
| 2 | Navigate to dashboard | Peer shows In Progress ⏳ |

---

### 7.2 Negative TC Steps

#### TC-N01: Invalid report_id (Non-Existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to `hpc/activity-assessment/99999` (non-existent ID) | 404 Not Found page displayed |
| 3 | Verify no application error/stack trace shown | Clean 404 page |

---

#### TC-N02: Invalid report_id (Non-Numeric)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to `hpc/activity-assessment/abc` | 404 Not Found — route binding fails |

---

#### TC-N03: Report Without Card Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HpcReport with zero report_items | Report exists, no items |
| 2 | Navigate to dashboard | Page loads without errors |
| 3 | Teacher section shows Pending ⬜ | No items = Pending |
| 4 | Domain progress sections are empty | No domains to display |

---

#### TC-N04: Student Without Form Submission Template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HpcReport with no related StudentFormSubmission | No submission |
| 2 | Navigate to dashboard | Student section shows Pending ⬜ |
| 3 | No error thrown | Graceful handling |

---

#### TC-N05: Permission Denied

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.hpc.view` permission | Authenticated |
| 2 | Navigate to `hpc/activity-assessment/{valid_report_id}` | 403 Forbidden |
| 3 | Verify user cannot see any report data | Access denied |

---

#### TC-N06: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout completely | Not authenticated |
| 2 | Navigate to `hpc/activity-assessment/{valid_report_id}` | Redirected to login page |

---

#### TC-N07: Student Without Permissions Accessing Another Student's Report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as Student A | Authenticated |
| 2 | Navigate to Student B's activity assessment | 403 Forbidden |
| 3 | Student A cannot view other student's data | Access denied |

---

#### TC-N08: Teacher Without Permissions Accessing Unassigned Student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as Teacher who is NOT assigned to Student B | Authenticated |
| 2 | Navigate to Student B's activity assessment | 403 Forbidden |
| 3 | Verify teacher scoping enforced | Access denied |

---

#### TC-N09: Missing StudentFormSubmission Table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Drop or disable student_form_submissions table | Table unavailable |
| 2 | Navigate to dashboard | Page loads without 500 error |
| 3 | Student section shows N/A ❌ | Graceful fallback |
| 4 | Other sections (Teacher, Parent, Peer) still render normally | No cascading failure |

---

#### TC-N10: Missing ParentFormToken Table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Drop or disable parent_form_tokens table | Table unavailable |
| 2 | Navigate to dashboard | Page loads without 500 error |
| 3 | Parent section shows N/A ❌ | Graceful fallback |
| 4 | Other sections render normally | No cascading failure |

---

#### TC-N11: Missing PeerAssignment Table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Drop or disable peer_assignments table | Table unavailable |
| 2 | Navigate to dashboard | Page loads without 500 error |
| 3 | Peer section shows N/A ❌ | Graceful fallback |
| 4 | Other sections render normally | No cascading failure |

---

#### TC-N12: Empty Report — No Report Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no HpcReport, StudentFormSubmission, ParentFormToken, or PeerAssignment records exist for the test report_id | No data |
| 2 | Navigate to dashboard | Page loads without errors |
| 3 | All sections show default empty states | Appropriate empty/zero states |

---

### 7.3 Dependency TC Steps

#### TC-D01: HpcReport FK to Student — Orphaned Report Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a student with existing HpcReport records | Student exists |
| 2 | Delete the student record | Student deleted |
| 3 | Verify HpcReport records for that student are also deleted | CASCADE deleted |
| 4 | Navigate to the deleted report's activity assessment | 404 Not Found |

---

#### TC-D02: StudentFormSubmission FK to HpcReport

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create HpcReport with 3 StudentFormSubmission records | Report + submissions exist |
| 2 | Delete the HpcReport | Report deleted |
| 3 | Verify StudentFormSubmission records are also deleted | CASCADE deleted |

---

#### TC-D03: ParentFormToken FK to HpcReport

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create HpcReport with 2 ParentFormToken records | Report + tokens exist |
| 2 | Delete the HpcReport | Report deleted |
| 3 | Verify ParentFormToken records are also deleted | CASCADE deleted |

---

#### TC-D04: PeerAssignment FK to HpcReport

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create HpcReport with 4 PeerAssignment records | Report + assignments exist |
| 2 | Delete the HpcReport | Report deleted |
| 3 | Verify PeerAssignment records are also deleted | CASCADE deleted |

---

#### TC-D05: Missing StudentFormSubmission Table → Graceful N/A

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Temporarily disable student_form_submissions table | Table unavailable |
| 2 | Navigate to dashboard | Page loads |
| 3 | Student section shows N/A ❌ | Graceful fallback |
| 4 | Verify no error log entries for missing table | Handled gracefully |

---

#### TC-D06: Missing ParentFormToken Table → Graceful N/A

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Temporarily disable parent_form_tokens table | Table unavailable |
| 2 | Navigate to dashboard | Page loads |
| 3 | Parent section shows N/A ❌ | Graceful fallback |
| 4 | Verify no error log entries | Handled gracefully |

---

#### TC-D07: Missing PeerAssignment Table → Graceful N/A

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Temporarily disable peer_assignments table | Table unavailable |
| 2 | Navigate to dashboard | Page loads |
| 3 | Peer section shows N/A ❌ | Graceful fallback |
| 4 | Verify no error log entries | Handled gracefully |

---

#### TC-D08: Data Aggregation From 4 Sources Is Consistent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed data for all 4 contributors with known statuses | Fixed dataset |
| 2 | Navigate to dashboard | Page loads |
| 3 | Verify Teacher status matches report_items data | Correct Teacher status |
| 4 | Verify Student status matches form submission data | Correct Student status |
| 5 | Verify Parent status matches token data | Correct Parent status |
| 6 | Verify Peer status matches assignment data | Correct Peer status |
| 7 | Verify all 4 show correct data simultaneously | Consistent display |

---

#### TC-D09: Status Calculation — Teacher Complete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HpcReport with 8 report_items, all completion_status='complete' | All complete |
| 2 | Navigate to dashboard | Teacher shows Complete ✅ |
| 3 | Domain completion all at 100% | All domains show 100% |

---

#### TC-D10: Status Calculation — Teacher In Progress

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HpcReport with 6 report_items: 4 complete, 2 in_progress | Mix |
| 2 | Navigate to dashboard | Teacher shows In Progress ⏳ |
| 3 | Domain completion reflects partial progress | Correct per-domain % |

---

#### TC-D11: Status Calculation — Teacher Pending

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed HpcReport with zero report_items | No items |
| 2 | Navigate to dashboard | Teacher shows Pending ⬜ |

---

#### TC-D12: Status Calculation — Student Complete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed StudentFormSubmission with status='completed' | Completed submission |
| 2 | Navigate to dashboard | Student shows Complete ✅ |

---

#### TC-D13: Status Calculation — Student In Progress

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed StudentFormSubmission with status='in_progress' | In progress submission |
| 2 | Navigate to dashboard | Student shows In Progress ⏳ |

---

#### TC-D14: Status Calculation — Student Pending

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No StudentFormSubmission record for the report | No submission |
| 2 | Navigate to dashboard | Student shows Pending ⬜ |
| 3 | Create StudentFormSubmission with status='pending' | Pending submission |
| 4 | Refresh page | Still shows Pending ⬜ |

---

#### TC-D15: Completion Percentage — Domain With Mixed Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Domain "Cognitive" — 10 items, 7 complete, 3 pending | Mixed items |
| 2 | Navigate to dashboard | Cognitive domain shows 70% |

---

#### TC-D16: Completion Percentage — Domain All Complete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Domain "Motor Skills" — 5 items, all complete | All complete |
| 2 | Navigate to dashboard | Motor Skills domain shows 100% |

---

#### TC-D17: Completion Percentage — Domain All Pending

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Domain "Social" — 4 items, all pending | All pending |
| 2 | Navigate to dashboard | Social domain shows 0% |

---

#### TC-D18: Completion Percentage — Empty Domain

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Domain "Language" — 0 total items | Empty domain |
| 2 | Navigate to dashboard | Language domain shows 0% or N/A — no division error |

---

#### TC-D19: Large Dataset — Report With 500+ Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 1 HpcReport with 500 report_items across 10 domains | Large dataset |
| 2 | Also seed related StudentFormSubmission, ParentFormToken, PeerAssignment | All 4 sources populated |
| 3 | Navigate to dashboard | Page loads within acceptable time (< 5 seconds) |
| 4 | Verify all statuses calculated correctly | Teacher, Student, Parent, Peer match expected |
| 5 | Verify all domain progress percentages correct | Per-domain % matches manual calculation |

---

#### TC-D20: Soft-Deleted Student Record Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a student who has an HpcReport | Student + report exist |
| 2 | Soft-delete the student | Student.deleted_at set |
| 3 | Navigate to the student's activity assessment | Dashboard still loads (report data exists) |
| 4 | Verify student name may show as "Deleted" or empty | Graceful handling of soft-deleted relation |

## 8. CODE-TRACE: Controller Method Execution Traces

### CODE-TRACE-01: `index()` � HpcActivityAssessmentController (Line 28)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcActivityAssessmentController.php:30` | `Gate::authorize('tenant.hpc.view')` |
| 2 | `HpcActivityAssessmentController.php:32-34` | `HpcReport::with(['student','template'])->findOrFail($reportId)` |
| 3 | `HpcActivityAssessmentController.php:36` | Resolves `cycleCount`: T3=9 cycles, T4=8 cycles |
| 4 | `HpcActivityAssessmentController.php:38` | Gets `activeCycle` |
| 5 | `HpcActivityAssessmentController.php:40` | Loads saved values via `reportService->getSavedValues()` |
| 6 | `HpcActivityAssessmentController.php:43` | `$this->getCyclePages($templateId, $activeCycle, $template)` � computes 4 pages per cycle |
| 7 | `HpcActivityAssessmentController.php:46` | `$this->getPeerDataForCycle(...)` � queries PeerAssignment with responses |
| 8 | `HpcActivityAssessmentController.php:49-75` | Returns `hpc::activity-assessment.index` view |

### CODE-TRACE-02: Private `getCyclePages()` � HpcActivityAssessmentController (Line 82)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcActivityAssessmentController.php:84-90` | Computes 4 page numbers per cycle: T3 starts page 5 (5-8, 9-12...37-40), T4 starts page 10 (10-13, 14-17...38-41) |
| 2 | `HpcActivityAssessmentController.php:92-111` | Returns array per page: `page_no`, `label` (Activity Tab, Self-Reflection, Peer Feedback, Teacher Feedback), `role`, `part` |

### CODE-TRACE-03: Private `getPeerDataForCycle()` � HpcActivityAssessmentController (Line 116)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcActivityAssessmentController.php:118-136` | Queries `PeerAssignment::where('report_id',$reportId)->where('student_id',$studentId)->where('cycle_number',$cycle)->with('responses')->get()` |
| 2 | Returns `['values' => [html_object_name?value], 'assignments', 'is_complete']` |

---
