# lms_Activity-Log_TcList

## Module: LmsQuests → Quest Management → Activity Log

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuests |
| Tab Group | Quest Management (Tabbed Interface) |
| Features | Activity Log (REQ-QST-017, RPT-QST-005) |
| URL | `/lms-quests/quest` (index — activity_log tab) |
| Controller | `Modules\LmsQuests\Http\Controllers\LmsQuestController` |
| Model(s) | `AttemptActivityLog`, `AttemptActivityEventType` |
| Validation | N/A (read-only) |
| Permission Gates | `tenant.quest.viewAny` (activity log view) |
| Soft Deletes | N/A (permanent records) |

---

## 2. Pre-conditions

- Required permissions: `tenant.quest.viewAny`
- At least one `AttemptActivityLog` record must exist with `attempt_type='QUEST'`
- `AttemptActivityEventType` records must exist for event type filter dropdown

---

## 3. Default Data Load

When page loads (GET `/lms-quests/quest`) with `active_tab=activity_log`:

| Data | Source | Notes |
|------|--------|-------|
| Activity Logs | `AttemptActivityLog::with(['eventType'])` | Hard-filtered: attempt_type='QUEST' |
| Event Types | `AttemptActivityEventType::active()` | For filter dropdown |
| Pagination | 15 per page, `log_page` parameter | Independent pagination |

---

## 4. Database Schema (BC-DB)

### `sp_attempt_activity_logs`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT(20) UNSIGNED | PK, auto-increment |
| BC-DB-02 | attempt_id | BIGINT(20) UNSIGNED | NOT NULL, FK |
| BC-DB-03 | attempt_type | VARCHAR(20) | NOT NULL, filtered to 'QUEST' |
| BC-DB-04 | event_type_id | BIGINT(20) UNSIGNED | NOT NULL, FK |
| BC-DB-05 | student_id | BIGINT(20) UNSIGNED | NOT NULL |
| BC-DB-06 | quest_id | BIGINT(20) UNSIGNED | NOT NULL |
| BC-DB-07 | occurred_at | TIMESTAMP | NOT NULL |
| BC-DB-08 | extra_data | JSON | DEFAULT NULL |
| BC-DB-09 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

### `sp_attempt_activity_event_types`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-10 | id | BIGINT(20) UNSIGNED | PK, auto-increment |
| BC-DB-11 | name | VARCHAR(100) | NOT NULL |
| BC-DB-12 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-13 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

---

## 5. Validation Rules (BC-VAL)

No validation rules — view-only interface.

---

## 6. Authorization (BC-AUTH)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.quest.viewAny | index() (activity_log tab) | Without → 403 |

---

## 7. Business Logic (BC-BIZ)

| BC ID | Rule | Description |
|-------|------|-------------|
| BC-BIZ-01 | Hard-Filtered to QUEST | `AttemptActivityLog::where('attempt_type', 'QUEST')` — only Quest logs shown |
| BC-BIZ-02 | View-Only Interface | No create/update/delete operations — read-only |
| BC-BIZ-03 | Event Type Filter | Filters by `event_type_id` via `log_event_type` request parameter |
| BC-BIZ-04 | Date Range Filter | Filters by `occurred_at` between date_from and date_to |
| BC-BIZ-05 | Combined Filters | Event type + date range can be applied together |
| BC-BIZ-06 | Pagination = 15 | Uses `log_page` query parameter, ordered by `occurred_at DESC` |
| BC-BIZ-07 | Event Type Dropdown | `AttemptActivityEventType::active()` — only active types shown |
| BC-BIZ-08 | Activity Tab Must Be Active | Filters only apply when `active_tab === 'activity_log'` |

---

## 8. Referential Integrity (BC-REF)

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | event_type_id | sp_attempt_activity_event_types (id) | RESTRICT |

---

## 9. Test Case Summary

### Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-ACT-P01 | Activity log loads with QUEST-type events | Only QUEST logs shown; QUIZ logs excluded | — | — | ⬜ |
| TC-ACT-P02 | Filter by event type | Only matching event type logs shown | — | — | ⬜ |
| TC-ACT-P03 | Filter by date range | Only logs within date range shown | — | — | ⬜ |
| TC-ACT-P04 | Combined event type + date range filter | Both filters applied together | — | — | ⬜ |
| TC-ACT-P05 | Pagination (15 per page) | 15 on page 1, remaining on page 2 | — | — | ⬜ |
| TC-ACT-P06 | Event type dropdown populated | Only active event types shown | — | — | ⬜ |

### Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-ACT-N01 | No logs exist | Empty table, 0 results, no error | — | — | ⬜ |
| TC-ACT-N02 | Read-only (no CUD operations) | No POST/PUT/DELETE routes exist | — | — | ⬜ |

### Code Review Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-CR15 | index() — Activity log query | Hard-filter to QUEST, filters, ordering, pagination correct | — | — | ⬜ |
| TC-CR21 | Blade @can Directives | Permission-based visibility for activity log tab | — | — | ⬜ |
| TC-CR22 | Breadcrumb Config | Route registered in config/breadcrumb.php | — | — | ⬜ |

### Dependency Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-D04 | Activity log linked to Paper Check investigation flow | Cross-referencing student_id/attempt_id across screens | — | — | ⬜ |

---

## 10. Detailed Test Steps

### 10.1 Positive TC Steps

#### TC-ACT-P01: Activity log loads with QUEST-type events

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 5 AttemptActivityLog records with attempt_type='QUEST', varied event_type_ids | Logs exist |
| 2 | Create 1 AttemptActivityLog record with attempt_type='QUIZ' (should be excluded) | Quiz log |
| 3 | Load Activity Log tab (`active_tab=activity_log`) | Log tab loads |
| 4 | Verify 5 QUEST-type logs shown | Only QUEST logs |
| 5 | Verify QUIZ-type log NOT shown | Other types excluded |
| 6 | Verify logs ordered by occurred_at DESC | Recent first |

---

#### TC-ACT-P02: Activity log — Filter by event type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Event types: ET1="Tab Switched", ET2="Connection Lost" | Types exist |
| 2 | 3 logs with ET1, 2 logs with ET2 | Logs exist |
| 3 | Load Activity Log with `log_event_type=ET1` | Filter applied |
| 4 | Verify only ET1 (Tab Switched) logs shown | Event type filter works |

---

#### TC-ACT-P03: Activity log — Filter by date range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logs: L1(occurred_at=2026-07-10), L2(2026-07-15), L3(2026-07-20) | 3 logs on different dates |
| 2 | Load Activity Log with `date_from=2026-07-12&date_to=2026-07-18` | Filter applied |
| 3 | Verify only L2 shown (July 15) | Date range filter works |

---

#### TC-ACT-P04: Activity log — Combined event type + date range filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | ET1 logs: 2026-07-10, 2026-07-15; ET2 logs: 2026-07-15 | Logs exist |
| 2 | Load Activity Log with `log_event_type=ET1&date_from=2026-07-14&date_to=2026-07-16` | Combined filters |
| 3 | Verify only ET1 log from 2026-07-15 shown | Both filters applied |

---

#### TC-ACT-P05: Activity log — Pagination (15 per page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 20 AttemptActivityLog records (attempt_type='QUEST') | 20 logs |
| 2 | Load Activity Log tab | Page 1 with 15 logs |
| 3 | Navigate to page 2 (`&log_page=2`) | Remaining 5 logs |

---

#### TC-ACT-P06: Activity log — Event type dropdown populated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have 3 active AttemptActivityEventType records | Types exist |
| 2 | Load Activity Log tab | Page loads |
| 3 | Verify eventTypes collection has 3 entries | Dropdown populated |
| 4 | Verify inactive event types excluded (is_active=0) | Only active types |

---

### 10.2 Negative TC Steps

#### TC-ACT-N01: Activity log — No logs exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No AttemptActivityLog records | Empty |
| 2 | Load Activity Log tab | Empty table, 0 results, no error |

---

#### TC-ACT-N02: Activity log — Read-only (no create/update/delete operations)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify no POST/PUT/DELETE routes exist for activity logs | Read-only confirmed |
| 2 | Attempt direct POST to activity log endpoint (if any) | 404 Method Not Allowed or no route |

---

### 10.3 Code Review TC Steps

#### TC-CR15: index() — Activity log query

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review hard-filter: `AttemptActivityLog::where('attempt_type', 'QUEST')` | Only QUEST logs |
| 2 | Review event type filter: `where('event_type_id', $request->log_event_type)` | Applied only when active_tab='activity_log' |
| 3 | Review date range filter: `whereBetween('occurred_at', [startOfDay, endOfDay])` | Applied only when active_tab='activity_log' |
| 4 | Review ordering: `latest('occurred_at')` | Most recent first |
| 5 | Review pagination: `paginate(15, ['*'], 'log_page')` | 15 per page |

---

#### TC-CR21: Blade @can Directives — Permission-based visibility for activity log tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `resources/views/tab_module/tab.blade.php` tab configuration | Activity Log tab defined with `permission => 'tenant.quest.viewAny'` |
| 2 | Review `@can('tenant.quest-activity-log.viewAny')` directive wrapping the activity log include | Tab content only rendered when user has `tenant.quest-activity-log.viewAny` |
| 3 | Verify consistency between tab `permission` attribute and `@can` directive | Tab header shown via `tenant.quest.viewAny`; tab body gated by `tenant.quest-activity-log.viewAny` |

---

#### TC-CR22: Breadcrumb Config — Route registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `config/breadcrumb.php` for Quest module entries | `lms-quests`, `quest`, `quest-scope`, `quest-question`, `quest-allocation` registered |
| 2 | Check activity-log breadcrumb mapping | `'activity-log' => 'activity_log'` exists in breadcrumb config |

---

### 10.4 Dependency TC Steps

#### TC-D04: Activity log linked to Paper Check investigation flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Activity log shows "Tab Switched" for student S1 on Quest Q1 | Log visible |
| 2 | Open Paper Check for Q1 | Same student shown |
| 3 | Open Attempt Detail for S1's attempt | Full answer review available |
| 4 | Verify cross-referencing possible (student_id/attempt_id links all screens) | Integrated flow |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/lms-quests/quest` | lms-quests.quest.index | index() (activity_log tab) | tenant.quest.viewAny |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | Activity log filter only applies when `active_tab === 'activity_log'` | **Low** | Event type and date range filters for activity logs are only applied conditionally on the active tab |
| KI-02 | No soft-delete handling for deleted quests referenced in activity logs | **Low** | If a quest is soft-deleted, the quest name may not be resolvable in the log view |

---

## 13. Feature Summary Matrix

| Feature | REQ ID | RPT ID | Controller Method(s) | Key Models | Pagination |
|---------|--------|--------|---------------------|------------|------------|
| Activity Log | REQ-QST-017 | RPT-QST-005 | index() (activityLog section) | AttemptActivityLog, AttemptActivityEventType | 15 per page |
