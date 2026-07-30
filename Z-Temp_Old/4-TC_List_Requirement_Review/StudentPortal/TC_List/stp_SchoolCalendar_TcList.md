
# Test Case List: stp_SchoolCalendar

## 1. Module / Feature Overview

| Field | Value |
|-------|-------|
| **Module Code** | STP |
| **Feature Name** | School Calendar |
| **FRD Reference** | REQ-STP-024 (P2) |
| **Controller** | `StudentPortalController@schoolCalendar` |
| **Total Test Cases** | 10 |

---

## 2. Test Case Summary

### 2.1 School Calendar Display

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-SC-001 | Verify school calendar loads with active session info | Student has active academic session with working days | 1. Login as student with active session<br>2. Navigate to `/school-calendar` | Page loads. Academic session start/end dates displayed. Month grids rendered. Stats summary visible (total, school, holiday, half) | ✅ | — | ⬜ | ◌ |
| TC-SC-002 | Verify month range is calculated from session start/end dates | Session has start_date and end_date | 1. View calendar | Month grids from `start_date` start_of_month to `end_date` end_of_month. Each month has a grid | ✅ | — | ⬜ | ◌ |
| TC-SC-003 | Verify working days are keyed by date and color-coded | Working days exist with day type classifications | 1. View calendar<br>2. Inspect day cells | Days colored/labeled: Regular school day, Holiday (is_school_day=false), Half-day (reduced_periods). Day types shown | ✅ | — | ⬜ | ◌ |
| TC-SC-004 | Verify stats are correctly calculated | Session has mix of school days, holidays, half-days | 1. View calendar<br>2. Review stats counter | `stats.total` = all working days. `stats.school` = days matching school criteria. `stats.holiday` = days matching holiday criteria. `stats.half` = days matching half-day criteria | ✅ | — | ⬜ | ◌ |
| TC-SC-005 | Verify holiday classification when `is_school_day = false` | Working day has is_school_day = false | 1. View calendar for day with is_school_day=false | Day classified as Holiday. Counted in holiday stat | ✅ | — | ⬜ | ◌ |
| TC-SC-006 | Verify half-day classification when day_type has `reduced_periods = true` | Working day has is_school_day=true, all day_types working, one has reduced_periods | 1. View calendar for half-day | Day classified as Half-Day. Counted in half stat | ✅ | — | ⬜ | ◌ |
| TC-SC-007 | Verify student without active session sees fallback year view | Student has no currentAcademicSession | 1. Login as student without active session<br>2. Navigate to `/school-calendar` | Academic session is null. Months shown for current year (Jan–Dec). No working day data (all empty). Stats all zero | ✅ | — | ⬜ | ◌ |
| TC-SC-008 | Verify session with no working days shows empty calendar | Session exists but no WorkingDay records | 1. View calendar for session without working days | Month grids shown (from session dates). All cells blank/empty. Stats all zero | ✅ | — | ⬜ | ◌ |
| TC-SC-009 | Verify session with null start/end dates generates months from working day boundaries | Session has null dates but working days exist | 1. View calendar | Month range generated from first working day's date → last working day's date | ✅ | — | ⬜ | ◌ |
| TC-SC-010 | Verify activity log on page view | User is authenticated | 1. Navigate to `/school-calendar` | Activity log entry: "Student viewed the school calendar." with student context | ✅ | — | ⬜ | ◌ |
