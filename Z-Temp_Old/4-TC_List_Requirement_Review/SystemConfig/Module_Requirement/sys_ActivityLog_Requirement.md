# Activity Log Viewer — Requirement Document

## 1. Overview

The Activity Log Viewer provides a read-only, tabbed interface for platform administrators to audit all configuration changes and user actions recorded in the tenant database (`sys_activity_logs`). It supports two views: an **"All Logs"** tab showing every audit entry across all modules, and a **"Student & Parent"** tab filtered to activity originating from the StudentPortal and ParentPortal modules, grouped by student with class/section context.

| Attribute | Value |
|-----------|-------|
| **Module** | SystemConfig |
| **Controller** | `TenantActivityLogController` |
| **Prefix** | `sys_` (`sys_activity_logs`) |
| **FRD IDs** | REQ-SYS-006, BR-SYS-006, BR-SYS-012, RPT-SYS-001 |
| **Permission** | `system-config.activity-log.viewAny` |
| **Auth Pattern** | `Gate::authorize('system-config.activity-log.viewAny')` |
| **Route** | `GET /system-config/activity-log` |
| **DB Source** | Tenant database — `sys_activity_logs` |
| **Model** | `Modules\GlobalMaster\Models\ActivityLog` (table: `sys_activity_logs`, no connection override — uses tenant connection) |

---

## 2. Actor / User Role

| Role | Access |
|------|--------|
| Super Admin | Full access — view all tabs, all filters |
| Platform Manager | Inferred block (per FRD US-SYS-006: 403 expected) |
| Platform Support | Read-only access per FRD US-SYS-006 |
| School Admin | No access (routes registered under tenant middleware with `system-config.*` permissions) |

**Known Issue:** The FRD user story (US-SYS-006) states Platform Manager should receive 403, but the controller uses a single permission gate. The actual RBAC role→permission mapping for `system-config.activity-log.viewAny` is not enforced in the controller beyond `Gate::authorize()`. If the permission is granted to Platform Manager via seeder, the 403 expectation would fail.

---

## 3. Functional Requirements

| ID | Requirement | Status | Notes |
|----|-------------|--------|-------|
| FR-AL-01 | Display paginated list of all activity logs (All Logs tab) | ✅ Implemented | Paginated 25 per page, ordered `latest()` |
| FR-AL-02 | Display Student & Parent tab filtered by StudentPortal/ParentPortal modules | ✅ Implemented | JSON query filter on `properties->context->module` |
| FR-AL-03 | Global search by `subject_type`, `event`, `ip_address` | ✅ Implemented | |
| FR-AL-04 | Event type dropdown filter (All Logs tab) | ✅ Implemented | Fixed list: Stored, Updated, Trashed, Restored, Deleted, Toggled |
| FR-AL-05 | Class + Section filter (Student/Parent tab) | ✅ Implemented | Resolves `ClassSection` → `studentIds` → JSON query on `properties->context->student_id` |
| FR-AL-06 | Display student name, admission_no, class-section alongside grouped logs | ✅ Implemented | Accordion UI with student context |
| FR-AL-07 | Display parent-only logs (no student context) under "Parent Account Activity" | ✅ Implemented | Separate accordion section |
| FR-AL-08 | Show structured before/after change properties | ✅ Implemented | Inline in table; changes shown as `old → new` |
| FR-AL-09 | Sensitive values excluded from properties display | ⬜ Not implemented | BR-SYS-006 requires keys with "password", "api_key", "secret", "token" to be masked |
| FR-AL-10 | Date range filter | ⬜ Not implemented | Per FRD RPT-SYS-001; not implemented in controller or view |
| FR-AL-11 | Entity type filter | ⬜ Not implemented | Per FRD RPT-SYS-001; not implemented |
| FR-AL-12 | Platform User filter | ⬜ Not implemented | Per FRD RPT-SYS-001; not implemented |
| FR-AL-13 | Expandable detail panel | ⏳ Partial | Properties rendered inline in table row; no separate expand/collapse detail panel per FRD AC |
| FR-AL-14 | Log entries are not editable or deletable | ✅ Implemented | Read-only view; no edit/delete routes registered |
| FR-AL-15 | CSV export | — | ENH-SYS-002; not implemented |

---

## 4. Business Rules

| Rule ID | Rule | Source | Status |
|---------|------|--------|--------|
| BR-SYS-006 | Keys containing "password", "api_key", "secret", "token" → value excluded from audit log | FRD | ⬜ Not implemented in viewer (applies at write time via `activityLog()` helper) |
| BR-SYS-012 | Every mutation on settings, menus, needs, values must produce an audit log entry | FRD | ✅ Enforced at controller write endpoints |
| NFR-SYS-006 | Activity Log list (50 rows, filtered) response < 500 ms at P95 | FRD | ⬜ Not verified |
| NFR-SYS-018 | Audit log immutability — no UI or API path permits editing/deleting entries | FRD | ✅ No edit/delete routes exist |

---

## 5. Data Dictionary — `sys_activity_logs`

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | INT UNSIGNED (PK, Auto) | Yes | |
| `subject_type` | VARCHAR(255) | Yes | Polymorphic morph type (e.g. `Modules\SystemConfig\Models\Setting`) |
| `subject_id` | INT UNSIGNED | Yes | Polymorphic morph ID |
| `user_id` | INT UNSIGNED (FK → `sys_users.id`) | Yes | ON DELETE CASCADE |
| `event` | VARCHAR(255) | Yes | e.g. Created, Updated, Deleted, Stored, Trashed, Restored, Toggled |
| `properties` | JSON | No | Before/after changes, context metadata |
| `ip_address` | VARCHAR(255) | Yes | |
| `user_agent` | VARCHAR(255) | No | |
| `created_at` | TIMESTAMP | Auto | Append-only |
| `updated_at` | TIMESTAMP | Auto | |

---

## 6. Routes

| Method | URI | Name | Description |
|--------|-----|------|-------------|
| GET | `/system-config/activity-log` | `system-config.activity-log.index` | Tabbed listing with filters |

*Registered in `routes/tenant.php` under middleware `['auth', 'verified']` and prefix `system-config`.*

---

## 7. Controller Logic (TenantActivityLogController)

### `index(Request $request)`

1. **Authorization:** `Gate::authorize('system-config.activity-log.viewAny')`
2. **Tab Detection:** `$activeTab = $request->input('tab', 'all')`
3. **Base Query:** `ActivityLog::with('user')->latest()`
4. **Global Search (both tabs):** If `search` param present, filter by `subject_type`, `event`, or `ip_address` (LIKE %search%)
5. **Event Filter (both tabs):** If `event` param present, exact match on `event` column
6. **Student/Parent Tab Filtering:**
   - JSON contains check: `properties->context->module` in ['StudentPortal', 'ParentPortal']
   - If `class_id` + `section_id` provided: resolve `ClassSection` → get student IDs from `Student::whereHas('currentAcademicSession')` where `class_section_id` matches and `is_current=1`
   - Filter logs where `JSON_EXTRACT(properties, '$.context.student_id')` IN student IDs
   - Also include parent-only logs (no student_id or empty student_id) with ParentPortal module
7. **Empty Class-Section Handling:** If class-section exists but no current students, fall back to showing only parent-only logs
8. **Pagination:** 25 per page with `withQueryString()`
9. **Student Lookup:** Loads students with `currentAcademicSession.classSection.class` and `section` relationships for display
10. **Dropdown Data:** Loads active classes and sections for filter dropdowns
11. **View Data:** Returns `activityLogs`, `activeTab`, `classes`, `sections`, `selectedClassId`, `selectedSectionId`, `students`

### View Logic (activity-log/index.blade.php)

- **All Logs Tab:** Flat table with columns: Subject, Event, User, IP/Agent, Properties (changes inline), Date
- **Student/Parent Tab:** Accordion grouped by student; each accordion item shows student name, admission_no, class-section badge, activity count; inner table shows Date, Module, User, Event, Activity, IP
- **Parent Account Activity:** Separate accordion section for logs with ParentPortal module but no student context
- **Event badges:** Color-coded by event type (success/primary/warning/danger/info/secondary)

---

## 8. Known Issues & Gaps

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | No date range filter — FRD RPT-SYS-001 specifies entity type, event, user, and date range filters | Medium | ⬜ Backlog |
| 2 | No entity type filter — only search across all subject_types | Medium | ⬜ Backlog |
| 3 | No platform user filter | Medium | ⬜ Backlog |
| 4 | Sensitive value masking (BR-SYS-006) not implemented in viewer — depends on write-time masking in `activityLog()` helper | Medium | ⬜ Depends on write-side fix |
| 5 | Properties displayed inline — FRD AC mentions "expandable detail panel" which is not present | Low | ⬜ Enhancement |
| 6 | Permission granularity: FRD US-SYS-006 says Platform Manager should be blocked but Platform Support should have access — single `viewAny` gate does not differentiate | Medium | ⬜ Review |
| 7 | No feature tests exist for this controller (per FRD RISK-SYS-009) | High | ⬜ Backlog |
| 8 | View references `systemconfig::activity-log.index` — confirm view namespace is published correctly | Low | ✅ Verified present |
| 9 | The ActivityLog model is in GlobalMaster module but used from SystemConfig — cross-module dependency | Info | Noted |
| 10 | "Student & Parent" tab event filter lists 40+ event types specific to student/parent flows, while "All Logs" tab lists 6 generic events | Info | As designed |

---

## 9. Dependencies

| Dependency | Type | Module | Details |
|------------|------|--------|---------|
| `Modules\GlobalMaster\Models\ActivityLog` | Model | GlobalMaster | Reads from `sys_activity_logs` |
| `Modules\SchoolSetup\Models\ClassSection` | Model | SchoolSetup | Class-section resolution |
| `Modules\SchoolSetup\Models\SchoolClass` | Model | SchoolSetup | Class dropdown |
| `Modules\SchoolSetup\Models\Section` | Model | SchoolSetup | Section dropdown |
| `Modules\StudentProfile\Models\Student` | Model | StudentProfile | Student context lookup |
| `sys_activity_logs` table | DB | — | Tenant database |

---

## 10. Mock Data / Seed Requirements

- At least 30 `sys_activity_logs` rows across various subject_types (Setting, Menu, etc.)
- At least 10 rows with `properties->context->module` set to `StudentPortal` or `ParentPortal`
- At least 5 rows with `properties->context->student_id` matching existing student IDs
- At least 3 parent-only rows (ParentPortal module, no student_id)
- Students enrolled in at least 2 different class-sections

---

## 11. User Stories Coverage

| User Story | Status | Coverage |
|------------|--------|----------|
| US-SYS-006 (Platform Support views Activity Log) | ⏳ Partial | View + filters implemented; date/user/entity filters missing; no expandable detail panel |
| RPT-SYS-001 (Platform Activity Audit Report) | ⏳ Partial | Core data display works; report-specific filters (entity type, date range, user) not implemented |

---

## 12. Version History

| Version | Date | Author | Notes |
|---------|------|--------|-------|
| 1.0 | 2026-07-23 | OpenCode | Initial requirement document from controller analysis + FRD SYS_FRD_Complete_2026-06-30 |

---

## 13. Appendix — FRD Excerpts

**REQ-SYS-006:** Activity Log Viewer — View and filter platform-wide audit logs. Status: PARTIAL (70%). TenantActivityLogController + views exist; no date range filter; no expandable detail panel confirmed.

**RPT-SYS-001 (Activity Audit Report):** Entity type, entity identifier, acting user, event type, IP, timestamp, expandable before/after. Filters: entity type, event type, user, date range. Rules: sensitive values masked; immutable; newest-first; 50 rows per page.

*Note: Actual implementation uses 25 per page, not 50 as specified in RPT-SYS-001.*

---

## 14. Review Notes

- Controller properly reads from tenant DB via model without connection override (uses default tenant connection)
- Student/Parent tab uses JSON path queries which require MySQL 5.7+; `JSON_UNQUOTE(JSON_EXTRACT(...))` equivalent to `->>` operator
- The `properties` field stores `context` nested object; the convention `properties->context->module` and `properties->context->student_id` should be documented as standard for all activity log producers

---

## 15. Open Questions

| # | Question | Raised By | Status |
|---|----------|-----------|--------|
| 1 | Should "All Logs" tab also support class/section filter? Currently only available in Student/Parent tab | — | ⬜ Open |
| 2 | RPT-SYS-001 specifies 50 rows/page but implementation uses 25 — intentional? | — | ⬜ Open |
| 3 | Should Activity Log viewer also include central activity logs (`sys_central_activity_logs`)? | — | ⬜ Open |

---

## 16. Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Business Analyst | OpenCode AI | 2026-07-23 | — |
| Tech Lead | — | — | — |
| QA Lead | — | — | — |
