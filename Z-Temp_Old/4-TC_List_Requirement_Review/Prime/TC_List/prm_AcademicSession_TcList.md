# Academic Session Management — Test Case List

**Feature:** Academic Session Management | **REQ-ID:** REQ-PRM-009 | **Controller:** `AcademicSessionController`

---

## 1. Test Case Summary

| Total TC | Pass | Fail | Blocked | Not Run | Coverage |
|:--------:|:----:|:----:|:-------:|:-------:|:--------:|
| 32 | — | — | — | 32 | 0% |

---

## 2. Index/List — Session List (`GET /prime/academic-session`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-AS-001 | Verify session list loads with paginated results | 10+ academic sessions exist | — | Page renders 10 sessions per page | — | — | ⬜ |
| TC-PRM-AS-002 | Verify unauthenticated user redirected to login | No active session | — | Redirected to login | — | — | ⬜ |
| TC-PRM-AS-003 | Verify user without viewAny permission receives 403 | Authenticated without `prime.academic-session.viewAny` | — | 403 Forbidden | — | — | ⬜ |

---

## 3. Create/Store — Session Create (`GET /prime/academic-session/create` + `POST /prime/academic-session`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-AS-004 | Verify create form loads | Authenticated with `prime.academic-session.create` | — | Create form renders | — | — | ⬜ |
| TC-PRM-AS-005 | Verify valid session creation succeeds | — | name="2025-26", short_name="2526", start_date=2025-04-01, end_date=2026-03-31, is_current=false | Session created; activity log written; redirect | — | — | ⬜ |
| TC-PRM-AS-006 | Verify creating as current clears previous current | Existing session with is_current=true | name="2026-27", is_current=true | New session is_current=true; previous session is_current=false | — | — | ⬜ |
| TC-PRM-AS-007 | Verify end_date before start_date rejected | — | start_date=2025-04-01, end_date=2025-03-31 | Validation error: end_date must be after or equal start_date | — | — | ⬜ |
| TC-PRM-AS-008 | Verify duplicate session name rejected | Existing session "2025-26" | name="2025-26" | Validation error: name already exists | — | — | ⬜ |
| TC-PRM-AS-009 | Verify duplicate short_name rejected | Existing session short_name "2526" | short_name="2526" | Validation error: short_name already exists | — | — | ⬜ |
| TC-PRM-AS-010 | Verify user without create permission receives 403 | Authenticated without `prime.academic-session.create` | — | 403 Forbidden | — | — | ⬜ |

---

## 4. Show — Session Detail (`GET /prime/academic-session/{academic_session}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-AS-011 | Verify session detail shows all fields | Session exists | — | All session fields displayed | — | — | ⬜ |
| TC-PRM-AS-012 | Verify non-existent session returns 404 | Session ID 99999 | — | 404 Not Found | — | — | ⬜ |
| TC-PRM-AS-013 | Verify user without view permission receives 403 | Authenticated without `prime.academic-session.view` | — | 403 Forbidden | — | — | ⬜ |

---

## 5. Edit/Update — Session Edit (`GET /prime/academic-session/{academic_session}/edit` + `PUT /prime/academic-session/{academic_session}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-AS-014 | Verify edit form loads with pre-filled data | Session exists | — | Edit form with current values | — | — | ⬜ |
| TC-PRM-AS-015 | Verify valid update saves changes | Existing session | name="Updated 2025-26" | Session updated; activity log shows changed fields; redirect | — | — | ⬜ |
| TC-PRM-AS-016 | Verify setting is_current=true on update clears other sessions | Another session is currently current | is_current=true | Other session's is_current is cleared; target session becomes current | — | — | ⬜ |
| TC-PRM-AS-017 | Verify update with no changes creates audit log | Existing session; submit unchanged data | — | Redirect; activity log: "No attributes changed." | — | — | ⬜ |
| TC-PRM-AS-018 | Verify user without update permission receives 403 | Authenticated without `prime.academic-session.update` | — | 403 Forbidden | — | — | ⬜ |

---

## 6. Delete — Session Destroy (`DELETE /prime/academic-session/{academic_session}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-AS-019 | Verify soft-delete of non-current session | Session exists with is_current=false | — | Session soft-deleted; activity log written; redirect | — | — | ⬜ |
| TC-PRM-AS-020 | Verify deleting current session is blocked | Session with is_current=true | — | Error: "Cannot move active session to Trash"; no delete performed | — | — | ⬜ |
| TC-PRM-AS-021 | Verify user without delete permission receives 403 | Authenticated without `prime.academic-session.delete` | — | 403 Forbidden | — | — | ⬜ |

---

## 7. Trash/Restore/Force-Delete

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-AS-022 | Verify trashed list shows only soft-deleted sessions | Soft-deleted sessions exist | — | Only soft-deleted sessions displayed (paginated) | — | — | ⬜ |
| TC-PRM-AS-023 | Verify restore works correctly | Soft-deleted session | — | Session restored; activity log written; redirect | — | — | ⬜ |
| TC-PRM-AS-024 | Verify force-delete permanently removes session | Soft-deleted session | — | Session permanently deleted; activity log written | — | — | ⬜ |
| TC-PRM-AS-025 | Verify non-existent restore target returns 404 | Session ID 99999 not in trash | — | 404 Not Found | — | — | ⬜ |
| TC-PRM-AS-026 | Verify non-existent force-delete target returns 404 | Session ID 99999 | — | 404 Not Found | — | — | ⬜ |
| TC-PRM-AS-027 | Verify user without restore permission receives 403 | Authenticated without `prime.academic-session.restore` | — | 403 Forbidden | — | — | ⬜ |
| TC-PRM-AS-028 | Verify user without forceDelete permission receives 403 | Authenticated without `prime.academic-session.forceDelete` | — | 403 Forbidden | — | — | ⬜ |

---

## 8. Toggle Status (is_current)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-AS-029 | Verify toggle is_current=true clears other sessions | Another session is currently current | is_current=true | All other sessions set to is_current=false; target becomes current; JSON success | — | — | ⬜ |
| TC-PRM-AS-030 | Verify toggle is_current=false deactivates session | Session is currently current | is_current=false | Session is_current set to false; JSON success | — | — | ⬜ |
| TC-PRM-AS-031 | Verify toggle with non-boolean value rejected | — | is_current=invalid | Validation error | — | — | ⬜ |
| TC-PRM-AS-032 | Verify toggle without update permission receives 403 | Authenticated without `prime.academic-session.update` | — | 403 Forbidden | — | — | ⬜ |

---

## 9. Permissions Matrix

| Role | viewAny | create | view | update | delete | restore | forceDelete |
|------|:-------:|:------:|:----:|:------:|:------:|:-------:|:-----------:|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Platform Manager | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Platform IT/Ops | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Platform Finance | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## 10. Data Table

| TC-ID | REQ-ID | BR-ID | Type | Priority | Test Level | Automated |
|-------|:------:|:-----:|:----:|:--------:|:----------:|:---------:|
| TC-PRM-AS-001 | REQ-PRM-009 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-AS-002 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-AS-003 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-AS-004 | REQ-PRM-009 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-AS-005 | REQ-PRM-009 | BR-PRM-023 | Positive | P0 | Functional | ⬜ |
| TC-PRM-AS-006 | REQ-PRM-009 | BR-PRM-021 | Positive/Atomic | P0 | Functional | ⬜ |
| TC-PRM-AS-007 | REQ-PRM-009 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-AS-008 | REQ-PRM-009 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-AS-009 | REQ-PRM-009 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-AS-010 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-AS-011 | REQ-PRM-009 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-AS-012 | REQ-PRM-009 | — | Negative/404 | P2 | Functional | ⬜ |
| TC-PRM-AS-013 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-AS-014 | REQ-PRM-009 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-AS-015 | REQ-PRM-009 | BR-PRM-023 | Positive | P0 | Functional | ⬜ |
| TC-PRM-AS-016 | REQ-PRM-009 | BR-PRM-021 | Positive/Atomic | P0 | Functional | ⬜ |
| TC-PRM-AS-017 | REQ-PRM-009 | BR-PRM-023 | Positive/Edge | P1 | Functional | ⬜ |
| TC-PRM-AS-018 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-AS-019 | REQ-PRM-009 | BR-PRM-023 | Positive/Soft-Delete | P0 | Functional | ⬜ |
| TC-PRM-AS-020 | REQ-PRM-009 | BR-PRM-021 | Negative/Business | P0 | Functional | ⬜ |
| TC-PRM-AS-021 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-AS-022 | REQ-PRM-009 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-AS-023 | REQ-PRM-009 | BR-PRM-023 | Positive/Restore | P0 | Functional | ⬜ |
| TC-PRM-AS-024 | REQ-PRM-009 | BR-PRM-023 | Positive/Force-Delete | P0 | Functional | ⬜ |
| TC-PRM-AS-025 | REQ-PRM-009 | — | Negative/404 | P2 | Functional | ⬜ |
| TC-PRM-AS-026 | REQ-PRM-009 | — | Negative/404 | P2 | Functional | ⬜ |
| TC-PRM-AS-027 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-AS-028 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-AS-029 | REQ-PRM-009 | BR-PRM-021 | Positive/Toggle | P0 | Functional | ⬜ |
| TC-PRM-AS-030 | REQ-PRM-009 | BR-PRM-021 | Positive/Toggle | P0 | Functional | ⬜ |
| TC-PRM-AS-031 | REQ-PRM-009 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-AS-032 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |

---

## 11. Known Issues

| # | Issue | Linked TC | Severity | Status |
|---|-------|:---------:|:--------:|:------:|
| 1 | `toggleStatus()` is_current logic not wrapped in DB transaction — partial failure may cause data inconsistency | TC-PRM-AS-029 | Medium | ⬜ |
| 2 | `store()` and `update()` do not wrap is_current clear logic in DB transaction | TC-PRM-AS-006, TC-PRM-AS-016 | Medium | ⬜ |
| 3 | No feature tests exist | All TCs | High | ⬜ |

---

## 12. Route Reference

| Method | URI | Name |
|--------|-----|------|
| GET | `/prime/academic-session` | `central.prime.academic-session.index` |
| GET | `/prime/academic-session/create` | `central.prime.academic-session.create` |
| POST | `/prime/academic-session` | `central.prime.academic-session.store` |
| GET | `/prime/academic-session/{academic_session}` | `central.prime.academic-session.show` |
| GET | `/prime/academic-session/{academic_session}/edit` | `central.prime.academic-session.edit` |
| PUT | `/prime/academic-session/{academic_session}` | `central.prime.academic-session.update` |
| DELETE | `/prime/academic-session/{academic_session}` | `central.prime.academic-session.destroy` |
| GET | `/prime/academic-session/trash/view` | `central.prime.academic-session.trashed` |
| GET | `/prime/academic-session/{id}/restore` | `central.prime.academic-session.restore` |
| DELETE | `/prime/academic-session/{id}/force-delete` | `central.prime.academic-session.forceDelete` |
| POST | `/prime/academic-session/{session}/toggle-status` | `central.prime.academic-session.toggleStatus` |

---

## 13. Execution Status

| TC-ID | Status | Executed By | Execution Date | Build | Comments |
|-------|:-----:|:-----------:|:--------------:|:-----:|----------|
| TC-PRM-AS-001 | ⬜ | — | — | — | — |
| ... (all 32 TCs) | ⬜ | — | — | — | — |
