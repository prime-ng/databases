# Lesson Date Planning — Business Requirements

## What This Screen Does

The Lesson Date Planning screen transforms the sequenced and scheduled syllabus into a dynamic, time-bound academic calendar displayed in a visual card-based grid. It provides an intuitive overview of all planned topics with their assigned date ranges, allowing academic coordinators to quickly scan, verify, and adjust the teaching timeline at a glance.

This screen offers two viewing modes: a Grid View with animated cards showing progress indicators for each topic's date completion status, and a List View displaying the same data in a traditional tabular format with full record details. Each card allows inline date editing and individual save actions, making micro-adjustments fast without reloading the entire page.

---

## When This Screen Is Used

- Daily Schedule Review used by HODs to quickly scan the upcoming week's planned topics and verify dates are correctly set
- Micro-Adjustments when a teacher needs to shift a topic by a day or two due to an unexpected assembly or school event
- Progress Monitoring to visually track how many topics have both start and end dates filled versus those still pending date assignment
- Term Planning Review at the beginning of a term to ensure every topic in the syllabus has been assigned a calendar window before teaching begins

## Default Data Load

This screen displays within the Syllabus Planning tab group. When the user navigates to Syllabus → Planning, SyllabusController@planning() applies default filters (class_section_id=1, subject_id=5, academic_session_id=7) and loads tab-specific data. Shared dropdowns include Class, Section, Class-Section, Subject, and Academic Session.

---

---

## Key Fields at a Glance

**Identity and Classification**
Each card displays the Lesson code and Topic Level Type badge for quick identification. The Class and Subject are shown as a combined badge at the top of the card. The topic or lesson name is displayed prominently as the card title with a two-line truncation for long names.

**Date Range Inputs**
A Start Date and End Date picker are embedded directly in each card. The date inputs are styled with distinct icons—a blue calendar-plus for start dates and a red calendar-check for end dates. Both fields accept date input through the browser's native date picker interface.

**Completion Progress**
A visual progress bar at the bottom of each card indicates the date completion status. If both dates are set, the bar shows 100% in green and a "Filled" badge appears. If only one date is set, the bar shows 50% in blue with a "Partial" badge. If no dates are set, the bar shows 0% with an "Empty" badge in yellow.

**Visual Design**
Each card has a colored accent bar at the top drawn from a rotating palette of six colors. Cards animate in with a fade-up effect and staggered delays for a polished presentation. Hovering lifts the card with an enhanced shadow effect for interactive feedback.

**List View Columns**
The alternate List View displays the academic session, class with section, subject, lesson with level type, topic name, assigned teacher with employee code, start date, end date, and priority badge. Action buttons for view, edit, and delete are available per row based on user permissions.

---

## How This Screen Works — Logic Flow (Non-Technical)

This screen has two distinct views and an inline save mechanism. Each one follows its own decision logic. Below is exactly how each part works.

### Feature 1: Dual-View Toggle (Grid vs. List)

When the Lesson Date Planning tab opens, the system checks:

**"Which view did the user last use?"**

```
Condition                             → What happens
──────────────────────────────────────────────────────────
No view parameter in the URL          → Show Grid View (default)
view=grid in the URL                  → Show Grid View with animated cards
view=list in the URL                  → Show List View with data table
```

The view mode is stored as a query parameter `?view=grid` or `?view=list`. This means users can bookmark their preferred view. When someone clicks the toggle button, the page reloads with the new view parameter—it does not switch views silently via JavaScript. Each view loads its own dataset and pagination from the server.

---

### Feature 2: Loading Data — Each View Gets Its Own Query

The system loads data differently depending on which view is active:

**Grid View Data (cards):**
The system queries the Syllabus Schedule table for the selected class, section, and subject. It fetches the lesson name, topic name, topic level type, scheduled start date, and scheduled end date for each record. The results are sorted with the most recent start dates first (`latest('scheduled_start_date')`) and paginated at **12 cards per page**.

```
For Grid View:
    Query: SELECT from slb_syllabus_schedule
    WHERE class_id = selected_class
      AND section_id = selected_section
      AND subject_id = selected_subject
      AND academic_session_id = selected_session
    ORDER BY scheduled_start_date DESC
    PAGINATE: 12 records per page (page name: "planning_lessons_page")
```

**List View Data (table):**
The system runs a similar query but includes additional relationships: academic session, assigned teacher with employee code, and all date fields. This view is paginated at **10 rows per page** with a different page name (`schedules_page`) to avoid pagination conflicts when switching views.

```
For List View:
    Query: SELECT from slb_syllabus_schedule (with teacher, session joins)
    WHERE (same filters as Grid View)
    ORDER BY scheduled_start_date DESC
    PAGINATE: 10 records per page (page name: "schedules_page")
```

**Why separate queries?** The Grid View needs fewer columns (only card display data) while the List View loads full teacher and session details. Keeping them separate means each view loads exactly what it needs, reducing unnecessary data transfer.

---

### Feature 3: Inline Card Save (Date Validation Chain)

When a user changes a date on a card and clicks **Save Planning**, the system runs through this checklist:

```
STEP 1: User clicks Save on a single card

STEP 2: Client-side validation (in the browser)
    Check: Is the start date empty AND the end date empty?
        → If BOTH empty → Send both as null to the server (clearing dates is allowed)
    Check: Is only one date filled?
        → Allow it (partial dates are acceptable)
    Check: Are both dates filled?
        → Is end_date >= start_date?
            → If YES → Proceed
            → If NO → Show error toast "End date cannot be before start date"
                       Stop here, do not send request

STEP 3: Send AJAX request
    URL: POST /syllabus/planning/{schedule_id}/update-dates
    Body: { planned_start_date: "2026-07-15", planned_end_date: "2026-07-18" }
    The request goes out for THIS CARD ONLY. Other cards are not affected.

STEP 4: Server-side validation (at the backend)
    Gate check: Does user have "tenant.lesson.update" permission?
        → If NO → Return 403 Forbidden
        → If YES → Continue
    
    Rule check: If both dates are filled:
        → Is end_date >= start_date? (uses Laravel's after_or_equal rule)
            → If NO → Return validation error with message
            → If YES → Continue
    
    Record check: Does this schedule_id exist in the database?
        → Find the record by ID
        → If NOT FOUND → Return 404 error
        → If FOUND → Continue

STEP 5: Update the database
    SQL: UPDATE slb_syllabus_schedule
         SET scheduled_start_date = "2026-07-15",
             scheduled_end_date = "2026-07-18"
         WHERE id = {schedule_id}

STEP 6: Return response
    → If SUCCESS → Return JSON: { success: true, message: "Date Planning Updated successfully!" }
    → The card shows the new dates and the progress bar recalculates
    → If FAILURE → Return JSON: { success: false, message: "error description" }
```

**Why this matters:** The inline save means editing one card does not require saving the entire page. Validation happens twice—once in the browser for instant feedback, and once on the server as a safety net. If the network fails, only that one card's change is lost, not all changes.

---

### Feature 4: Progress Bar Calculation (Client-Side Only)

When the page loads or a card is saved, each card's progress bar recalculates:

```
Condition                                      → Progress Bar Display
───────────────────────────────────────────────────────────────────────────
scheduled_start_date IS NOT NULL AND           → 100% | Green bar | "Filled" badge
scheduled_end_date IS NOT NULL                  

scheduled_start_date IS NOT NULL XOR           → 50%  | Blue bar  | "Partial" badge
scheduled_end_date IS NOT NULL                  

scheduled_start_date IS NULL AND              → 0%   | Yellow bar | "Empty" badge
scheduled_end_date IS NULL                      
```

This calculation happens entirely in the browser using JavaScript. No server request is needed to update the progress bar after a save—the save response confirms success and the client immediately updates the card's visual state.

---

### Feature 5: Pagination — Two Independent Paginators

Because Grid View and List View load different datasets, they have separate pagination counters:

```
Grid View:
    - 12 cards per page
    - Pagination parameter: ?planning_lessons_page=2
    - URL preserves: view=grid&tab=lesson_date_planning&class_section_id=...&subject_id=...

List View:
    - 10 rows per page
    - Pagination parameter: ?schedules_page=3
    - URL preserves: view=list&tab=lesson_date_planning&class_section_id=...&subject_id=...
```

**Why two different page sizes?** Cards are larger and need more visual space. 12 cards fit well on a single screen. List rows are compact, so 10 rows per page is the standard table density.

**Why separate page names?** If both views used the same `page` parameter, switching from Grid page 3 to List view would incorrectly show List page 3 instead of List page 1. The different parameter names (`planning_lessons_page` vs `schedules_page`) keep the pagination state independent.

---

## Business Rules and Conditions

**Dual-View Architecture**
The screen supports Grid View and List View toggled by a button group. The selected view is persisted as a query parameter so that users can bookmark or share their preferred view. Grid View is the default and renders animated cards with inline editing. List View renders a standard data table with full CRUD actions.

**Date Validation Before Save**
The system validates that the end date is not earlier than the start date before sending the save request. If the validation fails, a toast error is displayed and the save is aborted. This check runs both on the client side before the AJAX call and on the server side during update.

**Section-Level Date Boundaries**
All scheduled dates must fall within the boundaries of the selected Academic Session. The system enforces that the end date cannot be earlier than the start date. Validation occurs both client-side before submission and server-side during save.

**Individual Card Save**
Each card saves independently via an AJAX call to a dedicated endpoint. This means the user can edit one topic's dates and save without affecting any other rows. The save button shows a loading spinner during the request and reverts to the default state on completion.

**Pagination Awareness**
Both views are independently paginated. Grid View paginates at 12 cards per page. List View paginates at 10 rows per page. Pagination links preserve the current view mode and tab selection in their query strings to maintain context during navigation.

**Cascading Filter Requirement**
Filters must be applied in a specific order. The user must select a Class and Section first, then a Subject. The Subject dropdown dynamically filters based on the selected Class using an AJAX-dependent relationship. No data is loaded until all required filters are applied.

---

## Conditions at a Glance — Decision Table

| Feature | Condition | If True | If False |
|---------|-----------|---------|----------|
| View mode | view query param in URL? | Show that view | Show Grid (default) |
| Card save: both dates filled? | start_date AND end_date present | Validate end >= start | Allow partial/null dates |
| Card save: dates valid? | end_date >= start_date | Send AJAX request | Show error toast |
| Server: permission check? | User has lesson.update? | Continue save | Return 403 Forbidden |
| Server: end >= start? | after_or_equal validation | Continue save | Return validation error |
| Server: record exists? | schedule_id in DB? | Update record | Return 404 |
| Progress bar | Both dates filled? | 100% Green "Filled" | Check partial/empty |
| Progress bar | One date filled? | 50% Blue "Partial" | 0% Yellow "Empty" |
| Pagination | View = grid? | 12 per page | 10 per page (list) |

---

## Workflow Steps

**Adjusting Dates for a Single Topic**
The Science HOD opens the Lesson Date Planning tab to review the upcoming schedule. The grid view loads 12 cards showing topics for Class 9 Physics. The HOD notices that "Refraction of Light" has only a start date but no end date, showing a "Partial" badge at 50%. They click the end date picker on that card and select October 15th. The progress bar instantly updates to 100% with a green "Filled" badge. They click Save Planning. The system validates the dates and saves. A success toast appears, and the card remains in its filled state.

---

## Example Scenario

It is the week before the Mid-Term Examinations. The Exam Coordinator needs to verify that all topics are properly scheduled before creating the exam blueprint. They open the Lesson Date Planning screen, switch to List View, and filter by Class 10 for all subjects. The table loads showing every scheduled topic across Science, Math, and English. The Coordinator notices that three topics in English have no end dates, showing blanks in the End Date column. They export the list and email it to the English HOD with a request to fill in the missing dates within 24 hours, ensuring the exam blueprint can be finalized on time.

---

## Related Screens

- **Lesson Scheduling** — The primary source for batch date and teacher assignment; this screen provides a visual card-based alternative for individual date adjustments
- **Lesson Sequencing** — Provides the ordered list of topics that appear in the planning grid
- **Topic Release Control** — Directly relies on the scheduled start dates set here to determine when to automatically unlock content for students
- **Planning Accuracy Report** — Compares the scheduled end dates against actual completion dates to calculate pacing efficiency

---

## Requirements

- The system MUST display scheduled topics in a card-based Grid View and a tabular List View, toggled via `?view=grid|list` query parameter under the `lesson_date_planning` tab of `planning.index`
- The system MUST fetch Grid View data from `SyllabusSchedule` with `lesson`, `topic`, `topicLevelType` relations, filtered by `academic_session_id`, `class_id`, `section_id`, `subject_id`, paginated at 12 per page using `planning_lessons_page` parameter
- The List View MUST load `SyllabusSchedule` with `academicSession`, `class`, `section`, `subject`, `lesson`, `topic`, `topicLevelType`, `assignedTeacher`, paginated at 10 per page using `schedules_page` parameter
- Inline save MUST send `POST /planning/update-dates/{id}` with `planned_start_date` and `planned_end_date` fields (snake_case, not `scheduled_*`)
- The server MUST enforce `Gate::authorize('tenant.lesson.update')` before saving any date change
- Server validation: if both dates are filled, `after_or_equal:planned_start_date` rule MUST apply; partial/null dates MUST be allowed
- The system MUST use `SyllabusSchedule::findOrFail($id)` to locate the record; returns 404 if not found
- Grid View progress bar (client-side only): both dates set → 100% green "Filled", one date set → 50% blue "Partial", no dates → 0% yellow "Empty"

---

## Who Can Access This Screen

| Role | Access Level | Permission | Notes |
|------|-------------|------------|-------|
| HOD / Academic Coordinator | Full Access | `tenant.lesson.update` | Can view both views, edit and save dates for any topic |
| Teacher | Read-Only | `tenant.lesson.viewAny` | Can view all topics; cannot edit dates via this screen |
| Administrator | Full Access | `tenant.lesson.update` | Can view, edit, and save all date changes |
| Principal / Director | Read-Only | `tenant.lesson.viewAny` | Can browse Grid or List view but cannot edit or save |
| System Admin | Full Access | `tenant.lesson.update` | Can access all functionality including date overrides |

---

## Validate Before Save (Multiple Conditions)

The `SyllabusController@updatePlanningDates()` method performs this chain:

```
CHECK 1: Gate Authorization
    Gate::authorize('tenant.lesson.update')
    → If NO → 403 Forbidden response
    → If YES → Continue

CHECK 2: Server-Side Date Validation
    If both planned_start_date AND planned_end_date are submitted:
        Rule: planned_end_date >= planned_start_date (after_or_equal)
        → If NO → 500 validation error: "The planned end date must be a date after or equal to planned start date."
        → If YES → Continue
    If one or both are empty → Allow (null values accepted)

CHECK 3: Record Existence
    SyllabusSchedule::findOrFail($id)
    → If NOT FOUND → 404 error
    → If FOUND → Proceed to update
```

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status | Trigger |
|----------|--------------|-------------|---------|
| End date before start date | Client-side toast (browser validation) | Client-side | User clicks Save with invalid date range |
| Missing permission | 403 Forbidden (Laravel exception) | 403 | User without `tenant.lesson.update` tries to save |
| Record not found | ModelNotFoundException → 404 | 404 | `schedule_id` does not exist in `slb_syllabus_schedule` |
| Server validation failure | "The planned end date must be a date after or equal to planned start date." | 500 | Server-side `after_or_equal` rule fails |
| Database error | Exception caught → JSON error response | 500 | Database write failure in `update()` call |
| Invalid date format | "The planned start date is not a valid date." | 500 | Malformed date string submitted |

---

## Success Scenarios

**Scenario 1: Successful Single-Card Date Save**
The HOD sets `planned_start_date=2026-07-15` and `planned_end_date=2026-07-18` on a topic card. The AJAX `POST /planning/update-dates/{id}` request passes `tenant.lesson.update` gate and `after_or_equal` validation. `SyllabusSchedule::findOrFail($id)` updates the record. Response: `{ success: true, message: "Date Planning Updated successfully!" }`. The card's progress bar recalculates to 100% green "Filled".

**Scenario 2: Clearing Both Dates**
The HOD clears both date inputs on a card and clicks Save. The client sends both fields as null. Server validation passes (nulls allowed). The record's `scheduled_start_date` and `scheduled_end_date` are set to NULL. The card shows 0% yellow "Empty".

**Scenario 3: Grid-to-List View Toggle**
The user bookmarks `?tab=lesson_date_planning&view=list&class_section_id=5&subject_id=12`. Opening the link loads the List View directly with pre-selected filters and `schedules_page` pagination state intact.

---

## Failure Scenarios

**Scenario 1: End Date Before Start Date (Client-Side Catch)**
The user sets `planned_start_date=2026-07-20` and `planned_end_date=2026-07-15`. Client-side JS validation catches `end < start` before the AJAX call. A toast error appears. No request is sent to the server.

**Scenario 2: Missing Permission**
A teacher without `tenant.lesson.update` clicks Save. `Gate::authorize()` throws `AuthorizationException`. Laravel converts to 403 response. The card does not update. The user sees a 403 error page or AJAX error handler.

**Scenario 3: Record Deleted Mid-Session**
Between page load and save, another admin deletes the schedule record. `SyllabusSchedule::findOrFail($id)` throws `ModelNotFoundException`. The server returns 404. The card shows an error and the user must refresh.

---

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `slb_syllabus_schedule` | Database Table | Primary data source; stores `id`, `lesson_id`, `topic_id`, `topic_level_type_id`, `scheduled_start_date`, `scheduled_end_date`, `assigned_teacher_id`, `academic_session_id`, `class_id`, `section_id`, `subject_id`, `ordinal`, `planned_periods`, `priority`, `is_active`, `is_locked`, `is_completed`, `completed_at`, `completed_by`, `created_by` |
| `SyllabusSchedule` Model | Eloquent Model | `Modules\Syllabus\Models\SyllabusSchedule` with `SoftDeletes`, table `slb_syllabus_schedule` |
| `SyllabusController@planning()` | Controller | Renders the `lesson_date_planning` tab via `GET /planning` (route: `planning.index`) |
| `SyllabusController@updatePlanningDates()` | Controller | Handles inline date save at `POST /planning/update-dates/{id}` (route: `lesson.updatePlanningDates`) |
| `tenant.lesson.update` | Permission | Gate policy checked before any save operation |
| `Module: SchoolSetup` | Module | Provides `Employee`, `ClassSection`, `SchoolClass`, `Subject`, `OrganizationAcademicSession` models |
| `slb_topic_level_types` | Database Table | Provides topic level type names for badge display |
