# Periods Allocation — Business Requirements

## What This Screen Does

This is a **read-only display** screen. It shows period allocation data that is created and managed entirely in the **Timetable module**. No data is created, edited, or deleted from this screen.

It displays how many teaching periods are allocated per day and per week for each subject across classes, sections, and dates. This data is used by Lesson Sequencing and Lesson Scheduling as reference limits.

---

## When This Screen Is Used

- Capacity Verification — check available periods before finalizing syllabus plan
- Limit Checking — verify period allocation limits before saving sequencing
- Holiday/Closure Review — check which dates are marked as non-teaching days

---

## Default Data Load

Loaded via `SyllabusController@planning()` with `tab=periods_allocation`. Default filters: `class_section_id=1`, `subject_id=5`, `academic_session_id=7`.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared dropdowns | planning() | Classes, Sections, ClassSections, Subjects, AcademicSessions | is_active | None |
| Periods Allocation Grid | planning() | `PeriodsAllocation::with(academicSession,class,section,subject,subjectStudyFormat)` | class_id, section_id, subject_id, academic_session_id, date_from, date_to | 25/page (pa_page) |

> **Data comes from the Timetable module.** The `subjectStudyFormat` is a reference column to Timetable's study format config, not the data source.

---

## Key Fields at a Glance

| Column | Description |
|--------|-------------|
| Date | Calendar date for the allocation |
| Class / Section | Classroom cohort |
| Subject | Subject name |
| Study Format | Delivery format (Theory/Practical/Tutorial) — from Timetable module |
| Periods Per Day | Teaching periods allocated for this subject on this date |
| Periods Per Week | Total weekly period count for this subject |
| School Open | Whether school is open (Yes/No) |
| Source | `MANUAL` (entered in Timetable) or `AUTO` (generated from Scheduling) |
| Notes | Additional context |

---

## How This Screen Works

### Only Feature: Display with Filters

The user selects filters (academic session, class-section, subject, date range) and the system queries `slb_syllabus_periods_allocation` with those filters, returning 25 records per page.

```
Query filters: academic_session_id, class_id, section_id, subject_id, date >= date_from, date <= date_to
Order: latest('date')
Pagination: 25 records/page (pa_page)
```

**No write operations.** No create, update, or delete buttons exist.

> **Data insertion detail:** Records are added only through the **Timetable module** (manual entry, `data_created_by='MANUAL'`) or auto-generated from **Lesson Scheduling saves** (`data_created_by='AUTO'` via `syncPeriodsAllocation()`). For sync logic details, refer to the Scheduling TC list and code.

---

## Business Rules

- **Read-only display** — no CRUD on this screen
- **Data source is Timetable module** — all manual entries happen there
- **Filters** — academic_session, class_section, subject, date range
- **Pagination** — 25 per page

---

## Requirements

- MUST display `PeriodsAllocation` records in a read-only paginated table under `periods_allocation` tab of `planning.index`
- MUST show: date, class, section, subject, study format, periods_per_day, periods_per_week, school_open, source
- MUST filter by: academic_session_id, class_section_id, subject_id, date_from, date_to
- MUST paginate at 25/page using `pa_page` parameter
- No dedicated controller, FormRequest, or Policy — loaded in `SyllabusController@planning()` lines 352-374
- No permission check specific to this tab — inherits planning page gate (`tenant.lesson.viewAny`)
- **No create/update/delete UI elements**

---

## Dependencies

| Dependency | Type | Details |
|-----------|------|---------|
| `slb_syllabus_periods_allocation` | DB Table | Stores id, date, is_school_open_for_study, class_id, section_id, subject_id, subject_study_format_id, academic_session_id, tot_periods_in_day, tot_periods_in_week, data_created_by ENUM('MANUAL','AUTO'), notes |
| `PeriodsAllocation` Model | Model | `Modules\Syllabus\Models\PeriodsAllocation` |
| `SyllabusController@planning()` | Controller | Renders tab (lines 352-374) |
| Timetable Module | External | Source of manual period allocation data |
