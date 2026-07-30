# hmw_SummaryReport_TcList

## Module: LmsHomework → Homework Master → Summary Report

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsHomework |
| Tab Group | Homework Master |
| Feature | Summary Report |
| URL(s) | `/lms-home-work` (index via tab `home_work_summary`), `/lms-home-work/summary` (standalone) |
| Controller | `Modules\LmsHomework\Http\Controllers\LmsHomeworkController` |
| Method(s) | `index()` (tab=home_work_summary), `summary()` (standalone) |
| Model(s) | `Homework`, `HomeworkAssignment`, `HomeworkSubmission` |
| Permissions | `tenant.home-work-summary.viewAny` |
| Soft Deletes | N/A (read-only summary; inactive homework excluded) |
| Activity Log | N/A |

---

## 2. Pre-conditions

- Required permissions: `tenant.home-work-summary.viewAny`
- Required seed data: At least one published `Homework` with assignments created via publish
- Required seed data: At least one `HomeworkSubmission` linked to an assignment (for submitted/checked/reassigned counts)
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For filter tests: Homework assigned to multiple classes, sections, and subjects

---

## 3. Default Data Load

When the page loads via Summary tab, the following data is computed:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Homework List with Counts | HomeworkAssignment → Homework IDs → Homework with withCount | `assignments_count`, `submitted_count`, `checked_count`, `reassigned_count` via sub-queries | class_id, section_id, subject_id, date_from, date_to, search(title/topic) | 20/page |
| Shared: Classes | index() | `SchoolClass::where('is_active',1)->get()` | is_active=1 | None |
| Shared: Sections | index() | `Section::where('is_active',1)->get()` | is_active=1 | None |
| Shared: Subjects | index() | `Subject::where('is_active',1)->get()` | is_active=1 | None |

---

## 4. Test Data Strategy

- **Homework**: Create with varied class/section/subject, then publish to create assignments
- **Assignments**: Create via publish or direct insert; ensure some with submissions, some graded, some resubmission-requested
- **Filters**: Create homework across 2+ classes, 2+ subjects, 2+ sections
- **Pre-test cleanup**: Delete created homework by ID after tests

---

## 5. Business Conditions

### 5.1 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Assigned Count | Count of `HomeworkAssignment` records for this homework |
| BC-BIZ-02 | Submitted Count | Count of assignments whose submission has non-null `submitted_at` |
| BC-BIZ-03 | Checked Count | Count of assignments whose submission has non-null `graded_at` |
| BC-BIZ-04 | Reassigned Count | Count of assignments whose submission has `is_resubmission_requested=true` |
| BC-BIZ-05 | Consistency: submitted <= assigned | Submitted count can never exceed assigned count |
| BC-BIZ-06 | Consistency: checked <= submitted | Checked count can never exceed submitted count |
| BC-BIZ-07 | Only active homework shown | `is_active=1` filter applied; inactive/soft-deleted excluded |
| BC-BIZ-08 | Filters apply to all counts consistently | Same class/subject/section filter applied to all sub-queries |
| BC-BIZ-09 | Search by homework title | `title LIKE %search%` filter |
| BC-BIZ-10 | Search by topic name | `topic.name LIKE %search%` filter |
| BC-BIZ-11 | Zero assignments for unpublished homework | Draft homework has 0 for all four counts |

### 5.2 Authorization (Permission Gates)

| BC ID | Permission | Method | Behavior |
|-------|-----------|--------|----------|
| BC-AUTH-01 | tenant.home-work-summary.viewAny | index() (tab=home_work_summary), summary() | Without → 403 or tab hidden |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Summary Report Loads With All Columns | Table shows homework title, topic, subject, class/section, assigned/submitted/checked/reassigned counts | — | — | ⬜ |
| TC-P02 | Assigned Count Is Accurate | Count matches `lms_homework_assignment` records for that homework | — | — | ⬜ |
| TC-P03 | Submitted Count Is Accurate | Count matches assignments with non-null `submitted_at` | — | — | ⬜ |
| TC-P04 | Checked Count Is Accurate | Count matches assignments with non-null `graded_at` | — | — | ⬜ |
| TC-P05 | Reassigned Count Is Accurate | Count matches assignments with `is_resubmission_requested=true` | — | — | ⬜ |
| TC-P06 | All Four Counts Are Consistent | submitted <= assigned, checked <= submitted | — | — | ⬜ |
| TC-P07 | Filter By Class | Selecting class shows only that class's homework with correct counts | — | — | ⬜ |
| TC-P08 | Filter By Subject | Selecting subject shows only that subject's homework | — | — | ⬜ |
| TC-P09 | Filter By Section | Selecting section narrows results | — | — | ⬜ |
| TC-P10 | Filter By Date Range | Selecting from/to dates filters homework created in that range | — | — | ⬜ |
| TC-P11 | Search By Homework Title | Typing title finds matching homework | — | — | ⬜ |
| TC-P12 | Search By Topic Name | Typing topic name finds matching homework | — | — | ⬜ |
| TC-P13 | Multiple Filters Combine | Class + Subject + Date Range applied together; all counts consistent | — | — | ⬜ |
| TC-P14 | Clear Filters Resets To All Data | Clearing all filters shows unfiltered summary | — | — | ⬜ |
| TC-P15 | Draft Homework Shows Zero Counts | Unpublished homework displays 0 for all four columns | — | — | ⬜ |
| TC-P16 | Empty State — No Homework For Filter | "No records found" message | — | — | ⬜ |
| TC-P17 | Homework Ordered By Latest First | Most recently created homework at top | — | — | ⬜ |
| TC-P18 | Pagination Works (20 per page) | 21st homework appears on page 2 | — | — | ⬜ |
| TC-P19 | Summary Page Loads Via Standalone /summary Route | Accessing `/lms-home-work/summary` loads the same summary report as the tabbed view | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Permission 403 — No Summary Permission | User without `tenant.home-work-summary.viewAny` sees 403 or tab hidden | — | — | ⬜ |
| TC-N02 | Guest Access Redirect | Logged-out user redirected to /login | — | — | ⬜ |
| TC-N03 | Invalid Date Range | "Please select a valid date range." | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Submitted <= Assigned for every homework | Each row: submitted_count <= assignments_count | — | — | ⬜ |
| TC-D02 | A | Checked <= Submitted for every homework | Each row: checked_count <= submitted_count | — | — | ⬜ |
| TC-D03 | B | Draft homework excluded from counts (but shown with 0) | Draft homework shown in list with all counts = 0 | — | — | ⬜ |
| TC-D04 | C | Soft-deleted homework excluded | Not visible in summary list | — | — | ⬜ |
| TC-D05 | D | Inactive homework (is_active=0) excluded | Not shown in summary | — | — | ⬜ |
| TC-D06 | E | New submission updates submitted count instantly | After student submits, refresh summary → submitted_count incremented | — | — | ⬜ |
| TC-D07 | F | New grade updates checked count instantly | After teacher grades, refresh summary → checked_count incremented | — | — | ⬜ |
| TC-D08 | G | Resubmission request updates reassigned count | After teacher requests resubmission, reassigned_count incremented | — | — | ⬜ |
| TC-D09 | H | Re-publishing Homework Increments Assignment Count | Calling `publish()` creates new `HomeworkAssignment` rows, increasing the count for that homework | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Blade @can — Tab permission check | Tab hidden if user lacks `tenant.home-work-summary.viewAny` | — | — | ◌ |
| TC-CR02 | CR | P1 | withCount sub-queries use efficient SQL | Four withCount queries run as sub-queries, not separate queries per row | — | — | ◌ |
| TC-CR03 | CR | P1 | isset()/null-safe checks for topic/subject relationships | `$homework?->topic?->name` used; no undefined errors | — | — | ◌ |
| TC-CR04 | CR | P1 | Hub page tab integration — permission-filtered tab | Tab only visible with `tenant.home-work-summary.viewAny`; direct URL returns 403 without permission | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-P02: Assigned Count Is Accurate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework for Class 8-A (35 students) | Homework published; 35 assignments |
| 2 | Create homework for Class 8-B (30 students) | Homework published; 30 assignments |
| 3 | Navigate to Summary tab | Both homework visible |
| 4 | Verify assigned count for Class 8-A homework = 35 | Matches |
| 5 | Verify assigned count for Class 8-B homework = 30 | Matches |

#### TC-D01: Submitted <= Assigned For Every Homework

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework, publish to 35 students | 35 assignments |
| 2 | Create submissions for 20 students | 20 submissions |
| 3 | Navigate to Summary tab | assigned=35, submitted=20 |
| 4 | Verify: 20 <= 35 | True |
| 5 | Create submissions for 5 more students | 25 total submissions |
| 6 | Refresh Summary | assigned=35, submitted=25 |
| 7 | Verify: 25 <= 35 | True |

#### TC-P01: Summary Report Loads With All Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Homework → Summary tab | Summary Report page loads |
| 3 | Verify table columns: Homework Title, Topic, Subject, Class/Section, Assigned, Submitted, Checked, Reassigned | All columns present |
| 4 | Verify each row has data in all columns | Data displayed correctly |

#### TC-P03: Submitted Count Is Accurate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework, publish to 30 students | 30 assignments created |
| 2 | Have 12 students submit homework | 12 submissions recorded |
| 3 | Navigate to Summary tab | Homework visible |
| 4 | Verify submitted count = 12 | Matches |
| 5 | Have 8 more students submit | 20 total submissions |
| 6 | Refresh Summary | Submitted count updates to 20 |

#### TC-P04: Checked Count Is Accurate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework, publish to 30 students | 30 assignments created |
| 2 | Have 20 students submit | 20 submissions |
| 3 | Grade 15 submissions | 15 graded |
| 4 | Navigate to Summary tab | Homework visible |
| 5 | Verify checked count = 15 | Matches |

#### TC-P05: Reassigned Count Is Accurate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework, publish to 30 students | 30 assignments created |
| 2 | Have 20 students submit | 20 submissions |
| 3 | Request resubmission from 5 students | 5 resubmission requests |
| 4 | Navigate to Summary tab | Homework visible |
| 5 | Verify reassigned count = 5 | Matches |

#### TC-P06: All Four Counts Are Consistent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework, publish to 30 students | 30 assignments |
| 2 | 20 students submit, 15 graded, 5 resubmission requested | Diverse data setup |
| 3 | Navigate to Summary tab | Homework visible |
| 4 | Verify submitted (20) <= assigned (30) | Consistent |
| 5 | Verify checked (15) <= submitted (20) | Consistent |
| 6 | Verify reassigned (5) <= checked (15) | Consistent |

#### TC-P07: Filter By Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Create homework for Class 8 and Class 9 | Both homework published |
| 3 | Navigate to Summary tab | Both homework visible |
| 4 | Select "Class 8" in class filter | Only Class 8 homework shown |
| 5 | Select "Class 9" in class filter | Only Class 9 homework shown |

#### TC-P08: Filter By Subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Create homework for Math and Science | Both homework published |
| 3 | Navigate to Summary tab | Both homework visible |
| 4 | Select "Math" in subject filter | Only Math homework shown |
| 5 | Select "Science" in subject filter | Only Science homework shown |

#### TC-P09: Filter By Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Create homework for Section A and Section B | Both homework published |
| 3 | Navigate to Summary tab | Both homework visible |
| 4 | Select "Section A" in section filter | Only Section A homework shown |
| 5 | Select "Section B" in section filter | Only Section B homework shown |

#### TC-P10: Filter By Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Create homework on 2024-01-01 and 2024-06-15 | Two homework with different dates |
| 3 | Navigate to Summary tab | Both homework visible |
| 4 | Set date from 2024-01-01 to 2024-03-31 | Only Jan homework shown |
| 5 | Set date from 2024-04-01 to 2024-12-31 | Only June homework shown |

#### TC-P11: Search By Homework Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Create homework titled "Algebra Quiz" and "Geometry Quiz" | Both homework created |
| 3 | Navigate to Summary tab | Both homework visible |
| 4 | Type "Algebra" in search box | Only "Algebra Quiz" shown |
| 5 | Type "Geometry" in search box | Only "Geometry Quiz" shown |

#### TC-P12: Search By Topic Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Create homework with topic "Linear Equations" and "Triangles" | Both homework created |
| 3 | Navigate to Summary tab | Both homework visible |
| 4 | Type "Linear" in search box | Homework with "Linear Equations" topic shown |
| 5 | Type "Triangles" in search box | Homework with "Triangles" topic shown |

#### TC-P13: Multiple Filters Combine

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Create homework across 2 classes, 2 subjects, 2 date ranges | Diverse dataset created |
| 3 | Navigate to Summary tab | All homework visible |
| 4 | Select Class 8 + Math + specific date range | Only matching homework shown; counts consistent |
| 5 | Verify submitted <= assigned and checked <= submitted for each filtered row | All consistency checks pass |

#### TC-P14: Clear Filters Resets To All Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Summary tab with multiple homework across classes | All homework visible |
| 3 | Select "Class 8" class filter | Only Class 8 homework shown |
| 4 | Click "Clear" or reset filters button | All homework visible again; filter inputs reset |

#### TC-P15: Draft Homework Shows Zero Counts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Create a draft homework (do not publish) | Draft saved |
| 3 | Create another homework and publish it | Published with assignments |
| 4 | Navigate to Summary tab | Both homework visible |
| 5 | Verify draft homework shows assigned=0, submitted=0, checked=0, reassigned=0 | All four counts are zero |
| 6 | Verify published homework shows correct non-zero counts | Counts accurate |

#### TC-P16: Empty State — No Homework For Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Summary tab | Homework list visible |
| 3 | Select a class or filter with no homework assigned | "No records found" message displayed |

#### TC-P17: Homework Ordered By Latest First

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Create homework H1 (older date), then H2 (newer date) | Both published |
| 3 | Navigate to Summary tab | H2 appears above H1 |
| 4 | Verify descending order by created_at | Latest homework is first |

#### TC-P18: Pagination Works (20 per page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Create 21 published homework | 21 homework created |
| 3 | Navigate to Summary tab | First 20 homework shown on page 1 |
| 4 | Verify pagination controls visible | Page 1 of 2 shown |
| 5 | Click page 2 | Remaining 1 homework displayed |

#### TC-N01: Permission 403 — No Summary Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without tenant.home-work-summary.viewAny | Dashboard loads |
| 2 | Navigate to Homework tab | Summary tab not visible |
| 3 | Directly navigate to /lms-home-work/summary | 403 Forbidden page shown |

#### TC-N02: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout from the application | Redirected to login page |
| 2 | Navigate to /lms-home-work/summary | Redirected to /login |
| 3 | Verify login form is displayed | Login page loads |

#### TC-N03: Invalid Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Summary tab | Summary page loads |
| 3 | Set date_from later than date_to | Invalid date range entered |
| 4 | Click filter or apply button | Validation error displayed: "Please select a valid date range." |

#### TC-D02: Checked <= Submitted For Every Homework

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework, publish to 30 students | 30 assignments |
| 2 | 20 students submit homework | 20 submissions |
| 3 | Grade 15 submissions | 15 checked |
| 4 | Navigate to Summary tab | assigned=30, submitted=20, checked=15 |
| 5 | Verify: 15 <= 20 | True |

#### TC-D03: Draft Homework Excluded From Counts (But Shown With 0)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create draft homework (do not publish) | Draft saved |
| 2 | Navigate to Summary tab | Draft homework visible in list |
| 3 | Verify assigned = 0 | 0 |
| 4 | Verify submitted = 0 | 0 |
| 5 | Verify checked = 0 | 0 |
| 6 | Verify reassigned = 0 | 0 |

#### TC-D04: Soft-deleted Homework Excluded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Note existing homework count on Summary tab | Baseline count |
| 3 | Soft-delete a homework from database (set deleted_at) | Homework soft-deleted |
| 4 | Refresh Summary tab | That homework no longer shown; total count decreased by 1 |

#### TC-D05: Inactive Homework (is_active=0) Excluded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Note existing homework count on Summary tab | Baseline count |
| 3 | Set is_active=0 for a homework directly in DB | Homework deactivated |
| 4 | Refresh Summary tab | That homework no longer shown; total count decreased by 1 |

#### TC-D06: New Submission Updates Submitted Count Instantly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework, publish to 30 students | 30 assignments |
| 2 | Navigate to Summary tab | submitted=0 |
| 3 | Create submissions for 10 students | 10 submissions created |
| 4 | Refresh Summary tab | submitted=10 |

#### TC-D07: New Grade Updates Checked Count Instantly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework, publish to 30 students | 30 assignments |
| 2 | Create submissions for 20 students | 20 submissions |
| 3 | Navigate to Summary tab | checked=0 |
| 4 | Grade 10 submissions | 10 graded |
| 5 | Refresh Summary tab | checked=10 |

#### TC-D08: Resubmission Request Updates Reassigned Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework, publish to 30 students | 30 assignments |
| 2 | Create submissions for 20 students | 20 submissions |
| 3 | Navigate to Summary tab | reassigned=0 |
| 4 | Request resubmission from 8 students | 8 resubmission requests |
| 5 | Refresh Summary tab | reassigned=8 |

#### TC-CR01: Blade @can — Tab Permission Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Hub blade file containing homework tab group | Locate @can('tenant.home-work-summary.viewAny') directive |
| 2 | Verify @can wraps the Summary tab link | Tab rendered only when permission is granted |
| 3 | Verify @else or @cannot behavior for users without permission | Tab hidden for unauthorized users |

#### TC-CR02: withCount Sub-queries Use Efficient SQL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open LmsHomeworkController source file | Locate index() and summary() methods |
| 2 | Inspect withCount queries for assigned, submitted, checked, reassigned | Four sub-queries inside single withCount array |
| 3 | Verify no N+1 queries (no foreach count() calls) | All counts computed in SQL, not PHP loops |

#### TC-CR03: isset()/null-safe Checks For Topic/Subject Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open blade file listing summary rows | Locate topic and subject display code |
| 2 | Verify null-safe operator `?->` or isset() used before accessing topic->name, subject->name | No direct property access on potentially null relationship |
| 3 | Verify a homework without topic/subject does not throw error | Null displayed gracefully (empty or dash) |

#### TC-CR04: Hub Page Tab Integration — Permission-filtered Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Hub page layout file | Locate homework tab group definition |
| 2 | Verify @can guard on summary tab link | Tab only visible with tenant.home-work-summary.viewAny |
| 3 | Open LmsHomeworkController summary() method | Verify permission check via middleware or Gate |
| 4 | Direct URL /lms-home-work/summary without permission | Returns 403 |

#### TC-P19: Summary Page Loads Via Standalone /summary Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate directly to `/lms-home-work/summary` | Summary Report page loads successfully (HTTP 200) |
| 3 | Verify the table shows the same columns as the tabbed view: Homework Title, Topic, Subject, Class/Section, Assigned, Submitted, Checked, Reassigned | All expected columns present |
| 4 | Verify homework rows display correct counts | assigned, submitted, checked, reassigned values populated |
| 5 | Verify filters (class, subject, section, date range) are available above the table | Filter controls visible and functional |
| 6 | Verify pagination is functional | Pagination controls displayed at bottom |

#### TC-D09: Re-publishing Homework Increments Assignment Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with initial publish to 30 students | 30 assignment records exist |
| 2 | Enroll 5 new students in the class | 35 total enrolled students |
| 3 | Call `publish()` on the homework via the UI (re-publish) | Success message |
| 4 | DB check: `SELECT COUNT(*) FROM lms_homework_assignment WHERE homework_id={id}` | Count = 35 (5 new assignments created for new students) |
| 5 | Navigate to Summary Report | Assigned count for this homework shows 35 |
| 6 | Verify existing 30 assignments still have their original `created_at` timestamps | Existing records updated but not recreated |
