
# Module Requirement: stp_SchoolCalendar

## 1. Module / Feature Overview

| Field | Value |
|-------|-------|
| **Module Code** | STP |
| **Feature Name** | School Calendar |
| **FRD Reference** | REQ-STP-024 (P2) |
| **Table Prefix** | `tmt_*` (TimetableFoundation module) |
| **DB Layer** | Tenant (tenant_{uuid}) |
| **Controller** | `StudentPortalController@schoolCalendar` |
| **Route** | `GET /school-calendar` (named `school-calendar`) |
| **Associated View** | `studentportal::calendar.index` |

---

## 2. Directory Layout

### 2.1 Route Map

| Method | URI | Controller Method | Name | Purpose |
|--------|-----|-------------------|------|---------|
| GET | `/school-calendar` | `schoolCalendar` | `school-calendar` | Display interactive school calendar with working days/holidays |

---

## 3. Data / Entities

### 3.1 Primary Tables (TimetableFoundation — Consumed)

| Table | Purpose |
|-------|---------|
| `tmt_working_days` | Working day calendar — date, academic_session_id, is_school_day, day_type_id, day_type2_id, day_type3_id, day_type4_id |
| `sch_academic_sessions` (OrganizationAcademicSession) | Academic session — start_date, end_date, is_current |

### 3.2 Day Type Relationships

The working day can have up to 4 day types (dayType, dayType2, dayType3, dayType4). Each day type has:
- `is_working_day` — whether it's a working day
- `reduced_periods` — whether it has reduced periods (half-day)

### 3.3 Key Model Relationships

```
Student (std_students)
  └── currentAcademicSession
        └── academic_session_id

WorkingDay (tmt_working_days)
  ├── academic_session_id (→ matches student's session)
  ├── dayType (sys_day_types) ── is_working_day, reduced_periods
  ├── dayType2 (sys_day_types)
  ├── dayType3 (sys_day_types)
  └── dayType4 (sys_day_types)
```

---

## 4. Business Rules

### BR-STP-001 (Data Ownership)
- Calendar is scoped to the student's current active academic session.
- If no active session exists, the current year is used as a fallback (Jan-Dec of current year).

### Calendar Calculation Rules
- **School day**: `is_school_day = true` AND all day types have `is_working_day = true` (or null).
- **Holiday**: `is_school_day = false` OR any day type has `is_working_day = false`.
- **Half-day**: `is_school_day = true` AND all day types have `is_working_day = true` AND any day type has `reduced_periods = true`.
- **Stats**: Total days, school days, holidays, half-days counted.

---

## 5. Business Logic / Conditions

| Condition | Trigger | On-Violation |
|-----------|---------|-------------|
| No active academic session | Page load | Fallback: 12 months (Jan–Dec) of current year displayed with no working day data |
| No working days set for session | Page load | Empty `$dayMap`. Stats all zero. Months generated from session dates or current year |
| Session has start/end dates | Page load | Month range generated from start_of_month to end_of_month |
| Session has null start/end dates | Page load | Month range from first/last working day, or current year |

---

## 6. Access Control / Permissions

- **Authentication**: Route requires `auth` middleware.
- **Authorization Model**: No explicit `Gate::authorize()` calls.
- **Data Scoping**: Calendar scoped to student's academic session (not user-specific beyond session resolution).

---

## 7. States / Statuses

| Day Classification | Criteria |
|--------------------|----------|
| Regular School Day | `is_school_day = true`, all types `is_working_day = true`, no type has `reduced_periods = true` |
| Holiday | `is_school_day = false` OR any type has `is_working_day = false` |
| Half-Day (Reduced Periods) | `is_school_day = true`, all types `is_working_day = true`, at least one type has `reduced_periods = true` |

---

## 8. Notifications / Alerts

- No notifications sent from school calendar view.
- Activity log entry created on page view.

---

## 9. UI / UX Spec

### Calendar Page
- **Academic session info**: Start and end dates displayed.
- **Monthly grid layout**: One or more month grids rendered.
  - Color-coded cells based on day type:
    - Regular school day → default color
    - Holiday → distinct color
    - Half-day → distinct color
- **Day detail**: (Per input doc) Clicking a day should show scheduled events/activities — **not yet implemented per FRD (no data wired)**.
- **Stats summary**: Total session days, school days, holidays, half-days.

### Current Implementation Status
- Month grid is rendered from `$months` collection.
- `$dayMap` provides quick lookup of day data by `Y-m-d` key.
- Stats are computed.
- **FRD Note**: "No data wired yet" — the view exists but holiday/school event data integration from SchoolSetup is not complete (ENH-STP-007).

---

## 10. Error / Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Student has no active session | Fallback months generated (current year Jan-Dec). No working day data. Stats all zero |
| No working days exist for session | Empty dayMap. Stats all zero. Months shown but all blank |
| Working day has all day types null | `$allTypes()` returns empty → day classified based solely on `is_school_day` |
| Working day has mixed types (some working, some not) | Classification logic determines School/Holiday/Half-Day based on rules |

---

## 11. Performance / NFR

- **Single Query**: All working days for the academic session fetched in one query with eager-loaded day types.
- **In-Memory Processing**: Day classification and stats computed in PHP from fetched collection.
- **Month Generation**: Loop over months between session start and end dates — typically 10-12 iterations per session.

---

## 12. Dependencies (Cross-Module)

| Dependency | Type | Details |
|-----------|------|---------|
| `Modules\TimetableFoundation\Models\WorkingDay` | Hard | Core calendar data |
| `Modules\SchoolSetup\Models\OrganizationAcademicSession` | Hard | Session date range lookup |
| `Modules\StudentProfile\Models\Student` | Hard | Student record for session resolution |
| SchoolSetup event/holiday model | Expected | Not yet connected — ENH-STP-007 planned for S3 |

---

## 13. Test Scenarios Summary

**Positive:**
- Student views school calendar with working days data
- Calendar shows correct month range based on session dates
- Stats summary (total, school, holiday, half) correctly computed
- Color-coded day types render correctly

**Negative:**
- Student with no active session sees fallback year view with empty data
- Session with no working days configured shows empty calendar
- Student sees correct academic session info displayed

---

## 14. FRD Traceability

| FRD ID | Requirement | Status |
|--------|-------------|--------|
| REQ-STP-024 | School Calendar — interactive calendar with working days, holidays, events | 🟡 (P2, data partially wired — holidays/events stub) |

---

## 15. Known Gaps / Issues

| Gap ID | Issue | Severity |
|--------|-------|----------|
| GAP-STP-N/A | No school events/activities data wired — calendar shows working days but not scheduled events | Medium |
| ENH-STP-007 | School Calendar integration with SchoolSetup event model planned for Sprint 3 | Medium |
| FRD Note | FRD confirms "No data wired yet" — calendar is a stub with basic working day display | Low (P2) |

---

## 16. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| V1 | 2026-07-23 | OpenCode | Initial requirement document |
