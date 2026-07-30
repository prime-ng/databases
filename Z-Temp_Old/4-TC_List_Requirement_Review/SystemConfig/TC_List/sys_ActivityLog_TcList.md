# Activity Log Viewer — Test Case List

## 1. Module Overview

| Attribute | Value |
|-----------|-------|
| **Module** | SystemConfig |
| **Feature** | Activity Log Viewer (REQ-SYS-006) |
| **Controller** | `TenantActivityLogController` |
| **Route** | `GET /system-config/activity-log` (name: `system-config.activity-log.index`) |
| **Permission** | `system-config.activity-log.viewAny` |
| **Auth Pattern** | `Gate::authorize('system-config.activity-log.viewAny')` |
| **DB Table** | `sys_activity_logs` |
| **Pagination** | 25 per page |
| **Tabs** | All Logs (default), Student & Parent |

---

## 2. Test Environment

- PHP 8.2+, Laravel 12
- MySQL 8.0+ (JSON path queries require MySQL 5.7+)
- Tenant database must have `sys_activity_logs` table
- Seed data: minimum 30 activity logs across various subject_types
- Seed data: minimum 10 logs with `properties->context->module` set to 'StudentPortal' or 'ParentPortal'
- Active SchoolClass and Section records for class/section filter tests
- Student records with current academic sessions for student context tests

---

## 3. Test Case Matrix

### 3.1 Authentication & Authorization

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-AL-01 | Unauthenticated user redirected to login | User not logged in | 1. Access `GET /system-config/activity-log` | Redirected to login page | — | — | ⬜ | ◌ |
| TC-AL-02 | Authenticated user without permission receives 403 | User lacks `system-config.activity-log.viewAny` | 1. Log in as user without permission<br>2. Access the route | 403 Forbidden | — | — | ⬜ | ◌ |
| TC-AL-03 | Authenticated user with permission can view page | User has `system-config.activity-log.viewAny` | 1. Log in as Super Admin / Platform Support<br>2. Access the route | 200 OK, view rendered | — | — | ⬜ | ◌ |
| TC-AL-04 | Permission check uses correct gate | N/A | 1. Inspect controller code | `Gate::authorize('system-config.activity-log.viewAny')` present on line 25 | — | — | ✅ | ◌ |

### 3.2 Tab Navigation

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-AL-05 | Default tab is "All Logs" | No `tab` param in request | 1. Access route without tab param | Active tab is "All Logs" (`$activeTab = 'all'`) | — | — | ⬜ | ◌ |
| TC-AL-06 | "All Logs" tab loads successfully | User has permission | 1. Access route with `?tab=all` | Tab content rendered, logs displayed | — | — | ⬜ | ◌ |
| TC-AL-07 | "Student & Parent" tab loads successfully | User has permission | 1. Access route with `?tab=student-parent` | Tab content rendered, filtered logs displayed | — | — | ⬜ | ◌ |
| TC-AL-08 | Invalid tab parameter defaults to "All Logs" | User has permission | 1. Access route with `?tab=invalid` | Defaults to 'all' (no explicit validation — request input default) | — | — | ⬜ | ◌ |

### 3.3 All Logs Tab — Search & Filter

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-AL-09 | Search by subject_type | Activity logs exist with known subject_types | 1. Enter subject_type partial text in search<br>2. Submit | Results filtered by matching subject_type | — | — | ⬜ | ◌ |
| TC-AL-10 | Search by event name | Activity logs exist with known events | 1. Enter event text in search<br>2. Submit | Results filtered by matching event | — | — | ⬜ | ◌ |
| TC-AL-11 | Search by IP address | Activity logs exist with known IPs | 1. Enter IP address in search<br>2. Submit | Results filtered by matching IP address | — | — | ⬜ | ◌ |
| TC-AL-12 | Search with no results returns empty state | Search term matches no records | 1. Enter unique search term<br>2. Submit | "No activity logs found." empty state displayed | — | — | ⬜ | ◌ |
| TC-AL-13 | Empty search returns all records | All logs loaded | 1. Submit empty search | All paginated logs displayed | — | — | ⬜ | ◌ |
| TC-AL-14 | Search uses LIKE %term% — partial match | Log with `subject_type = 'Setting'` exists | 1. Search for "ett" | "Setting" matched and shown | — | — | ⬜ | ◌ |
| TC-AL-15 | Event dropdown filter — exact match | Logs with various events (Stored, Updated, etc.) | 1. Select "Stored" from event dropdown<br>2. Submit | Only "Stored" event logs shown | — | — | ⬜ | ◌ |
| TC-AL-16 | Event dropdown "All Events" option | Any logs present | 1. Select "All Events"<br>2. Submit | No event filter applied, all logs shown | — | — | ⬜ | ◌ |
| TC-AL-17 | Search + Event combined filter | Logs matching criteria | 1. Enter search + select event<br>2. Submit | Both filters applied (AND condition) | — | — | ⬜ | ◌ |

### 3.4 Student & Parent Tab

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-AL-18 | Student/Parent tab shows only StudentPortal + ParentPortal logs | Mixed logs in DB | 1. Switch to Student/Parent tab | Only logs with `properties->context->module` = StudentPortal or ParentPortal shown | — | — | ⬜ | ◌ |
| TC-AL-19 | Class filter on Student/Parent tab | Multiple classes with students exist | 1. Select a class from dropdown | Logs filtered to students in that class | — | — | ⬜ | ◌ |
| TC-AL-20 | Section filter on Student/Parent tab | Multiple sections within a class | 1. Select a section from dropdown | Logs filtered to students in that section | — | — | ⬜ | ◌ |
| TC-AL-21 | Class + Section combined filter | ClassSection exists with active students | 1. Select both class and section | Logs filtered to students in that specific class-section | — | — | ⬜ | ◌ |
| TC-AL-22 | Class filter auto-submits on change | User has permission | 1. Change class dropdown | Form auto-submits via `onchange="this.form.submit()"` | — | — | ⬜ | ◌ |
| TC-AL-23 | Section filter auto-submits on change | User has permission | 1. Change section dropdown | Form auto-submits | — | — | ⬜ | ◌ |
| TC-AL-24 | Class/Section filter with no students in that section | ClassSection exists but no current students | 1. Select class-section with no enrolled students | Only parent-only logs shown (ParentPortal, no student_id) | — | — | ⬜ | ◌ |
| TC-AL-25 | Parent-only logs appear in separate accordion | ParentPortal logs without student context exist | 1. View Student/Parent tab | "Parent Account Activity" accordion section visible with parent-only logs | — | — | ⬜ | ◌ |
| TC-AL-26 | Student context shows correct name, admission_no, class-section | Student records linked via `properties->context->student_id` | 1. Click accordion header for a student | Student name, admission_no, class-section displayed | — | — | ⬜ | ◌ |
| TC-AL-27 | Student with missing record still displays | Student ID in log but student deleted | 1. View accordion for missing student | Shows "Student #N" fallback instead of name | — | — | ⬜ | ◌ |
| TC-AL-28 | Reset button clears filters | Filters active | 1. Apply class/section/search filters<br>2. Click reset button | Filters cleared, tab reloaded with defaults | — | — | ⬜ | ◌ |

### 3.5 Pagination

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-AL-29 | All Logs tab paginates at 25 per page | 30+ logs in DB | 1. View All Logs tab | 25 records shown; pagination links visible | — | — | ⬜ | ◌ |
| TC-AL-30 | Page 2 loads next batch | 30+ logs in DB | 1. Click page 2 | Remaining 5+ records shown | — | — | ⬜ | ◌ |
| TC-AL-31 | Pagination preserves query string (search, event, tab) | Search/event active | 1. Apply filter<br>2. Navigate to page 2 | URL includes `?search=...&event=...&tab=...&page=2` | — | — | ⬜ | ◌ |
| TC-AL-32 | Total records badge updates | n/a | 1. View tab header | Badge shows correct total count from `$activityLogs->total()` | — | — | ⬜ | ◌ |

### 3.6 Display & Data Integrity

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-AL-33 | Subject column shows class_basename + ID | Log with subject_type and subject_id | 1. View any log row | Shows short class name (e.g. "Setting") + badge "#123" | — | — | ⬜ | ◌ |
| TC-AL-34 | Event column color-coded by type | Various events present | 1. View log rows | Stored=green, Updated=blue, Trashed=warning, Deleted=danger, Restored=info, Toggled=secondary | — | — | ⬜ | ◌ |
| TC-AL-35 | User column shows username | Log has user relationship | 1. View log row | User name displayed (or "—" if null) | — | — | ⬜ | ◌ |
| TC-AL-36 | IP + User Agent displayed | Log has ip_address and user_agent | 1. View log row | IP address shown; user_agent truncated with tooltip | — | — | ⬜ | ◌ |
| TC-AL-37 | Properties changes shown as old → new | Log with properties.changes | 1. View log row | Changes rendered as list: "Field: old → new" | — | — | ⬜ | ◌ |
| TC-AL-38 | Properties message displayed | Log with properties.message | 1. View log row | Message shown in bold above changes | — | — | ⬜ | ◌ |
| TC-AL-39 | Properties empty = "[no details]" shown | Log with null or empty properties | 1. View log row | "[no details]" placeholder shown | — | — | ⬜ | ◌ |
| TC-AL-40 | Date column formatted correctly | Any log | 1. View log row | Date in "d M Y H:i" format (e.g. "23 Jul 2026 14:30") | — | — | ⬜ | ◌ |
| TC-AL-41 | Student/Parent tab module badge color-coded | StudentPortal + ParentPortal logs | 1. View inner table | StudentPortal=green badge, ParentPortal=blue badge | — | — | ⬜ | ◌ |
| TC-AL-42 | Accordion expand/collapse works | Student logs exist | 1. Click accordion header | Inner table expands/collapses | — | — | ⬜ | ◌ |

### 3.7 No Edit/Delete (Immutability)

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-AL-43 | No edit button on any log entry | Any log | 1. Inspect page for edit controls | No edit button, link, or form present | — | — | ✅ | ◌ |
| TC-AL-44 | No delete button on any log entry | Any log | 1. Inspect page for delete controls | No delete button or form present | — | — | ✅ | ◌ |
| TC-AL-45 | No create/new button on page | Any state | 1. Inspect page for create controls | No create button present | — | — | ✅ | ◌ |
| TC-AL-46 | No edit/delete routes registered | N/A | 1. Check route list | No PUT/DELETE routes for activity-log | — | — | ✅ | ◌ |

---

## 4. Boundary & Edge Cases

| TC# | Test Case | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------|-----------------|----|----|--------|----|
| TC-AL-47 | Empty activity log table (no records) | 1. Access activity log with empty table | "No activity logs found." empty state on both tabs | — | — | ⬜ | ◌ |
| TC-AL-48 | User with 100+ characters search term | 1. Enter very long search string | Search executes (LIKE may be slow but should not error) | — | — | ⬜ | ◌ |
| TC-AL-49 | SQL injection attempt in search | 1. Enter `'; DROP TABLE sys_activity_logs;--` | Search treated as plain text; no injection | — | — | ⬜ | ◌ |
| TC-AL-50 | XSS in log properties (malicious message) | 1. Create log with `<script>alert('xss')</script>` in properties.message | HTML escaped in output | — | — | ⬜ | ◌ |
| TC-AL-51 | Student/Parent tab with class_id but no section_id | 1. Select class only, submit | Class filter applied; no section filter | — | — | ⬜ | ◌ |
| TC-AL-52 | Student/Parent tab with invalid class_id | 1. Pass non-existent class_id | No filter applied (ClassSection not found) | — | — | ⬜ | ◌ |
| TC-AL-53 | Activity logs with null user_id | Orphaned log | 1. View log row | User column shows "—" | — | — | ⬜ | ◌ |
| TC-AL-54 | Properties with deeply nested context | Complex JSON | 1. View log row | Properties rendered correctly, no JSON parsing error | — | — | ⬜ | ◌ |

---

## 5. Test Data Requirements

| Data Type | Quantity | Details |
|-----------|----------|---------|
| sys_activity_logs rows | ≥ 30 | Mix of subject_types: Setting, Menu, DropdownNeed, DropdownValue |
| StudentPortal logs | ≥ 6 | With `properties->context->module = 'StudentPortal'` |
| ParentPortal logs | ≥ 6 | With `properties->context->module = 'ParentPortal'` (3 with student_id, 3 without) |
| Class records | ≥ 3 | Active classes with ordinal ordering |
| Section records | ≥ 3 | Active sections with ordinal ordering |
| ClassSection records | ≥ 3 | Linking classes to sections, is_active = true |
| Student records | ≥ 5 | With currentAcademicSession linked to ClassSections |
| Event types represented | ≥ 4 | Stored, Updated, Trashed, Deleted, Restored, Toggled |

---

## 6. Test Execution Checklist

| Check | Description | Done? |
|-------|-------------|-------|
| Authentication tests pass (TC-AL-01 to TC-AL-04) | | ⬜ |
| Tab navigation works correctly (TC-AL-05 to TC-AL-08) | | ⬜ |
| Search and filter functional (TC-AL-09 to TC-AL-17) | | ⬜ |
| Student/Parent tab filtering works (TC-AL-18 to TC-AL-28) | | ⬜ |
| Pagination works across tabs (TC-AL-29 to TC-AL-32) | | ⬜ |
| Display renders correctly (TC-AL-33 to TC-AL-42) | | ⬜ |
| Immutability verified (TC-AL-43 to TC-AL-46) | | ⬜ |
| Boundary/edge cases covered (TC-AL-47 to TC-AL-54) | | ⬜ |
| No regression on existing features | | ⬜ |

---

## 7. Automation Notes

- Consider using `Pest` with `get()` helper for HTTP tests
- Use `DatabaseTransactions` trait for test isolation
- Seed activity logs via factory or `ActivityLog::create()` inline
- Student context tests require: `Student`, `ClassSection`, `SchoolClass`, `Section`, `ActivityLog` factories
- JSON path queries (`JSON_UNQUOTE(JSON_EXTRACT(...))`) need raw MySQL — use `DB::raw()` in tests if filtering
- Test for both successful auth (200) and forbidden (403) scenarios

---

## 8. Known Issues

| # | Issue | Impact | Status |
|---|-------|--------|--------|
| 1 | No date range filter (per RPT-SYS-001) | Cannot verify date filtering in testing | ⬜ Backlog |
| 2 | No entity type filter | Cannot test entity-specific filtering | ⬜ Backlog |
| 3 | No user filter | Cannot test user-specific filtering | ⬜ Backlog |
| 4 | Sensitive value masking not implemented in viewer | Cannot test masking in log detail | ⬜ Backlog |
| 5 | No feature tests exist — test list is forward-looking | All TCs unexecuted | ⬜ Backlog |

---

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/system-config/activity-log` | `system-config.activity-log.index` | `TenantActivityLogController@index` |

---

## 10. Execution Status

| Total TCs | Pass | Fail | Blocked | Not Run | Coverage |
|-----------|------|------|---------|---------|----------|
| 54 | 0 | 0 | 0 | 54 | 0% |

**Last Executed:** —
**Executed By:** —
**Environment:** —
**Remarks:** Initial test case list created from code analysis. No automated tests exist yet.

---

## Document History

| Version | Date | Author | Notes |
|---------|------|--------|-------|
| 1.0 | 2026-07-23 | OpenCode AI | Initial TC list from controller + FRD analysis |
