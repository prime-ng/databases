# Session & Board Setup (Combined Tab) — Test Case List

**Feature:** Session & Board Setup | **REQ-ID:** REQ-PRM-009 | **Controller:** `SessionBoardSetupController`

---

## 1. Test Case Summary

| Total TC | Pass | Fail | Blocked | Not Run | Coverage |
|:--------:|:----:|:----:|:-------:|:-------:|:--------:|
| 18 | — | — | — | 18 | 0% |

---

## 2. Index — Combined Tab View (`GET /prime/session-board-setup`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-SBS-001 | Verify combined view loads with two tabs | Authenticated with `prime.session-board-setup.viewAny`; sessions and boards exist | — | Tabbed view renders with Academic Session and Board tabs | — | — | ⬜ |
| TC-PRM-SBS-002 | Verify unauthenticated user redirected to login | No active session | — | Redirected to login | — | — | ⬜ |
| TC-PRM-SBS-003 | Verify user without viewAny permission receives 403 | Authenticated without `prime.session-board-setup.viewAny` | — | 403 Forbidden | — | — | ⬜ |

---

## 3. Academic Sessions Tab

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-SBS-004 | Verify sessions tab shows paginated sessions ordered by start_date desc | 10+ academic sessions exist | fragment=#academicsession | Sessions list (10/page) ordered by start_date descending | — | — | ⬜ |
| TC-PRM-SBS-005 | Verify search by session name filters results | Session "2025-26" exists | search=2025-26 | Matching sessions displayed | — | — | ⬜ |
| TC-PRM-SBS-006 | Verify search by session short_name filters results | Session short_name "2526" exists | search=2526 | Matching sessions displayed | — | — | ⬜ |
| TC-PRM-SBS-007 | Verify status filter shows only active sessions | Mix of active/inactive sessions | status=1 | Only active sessions displayed | — | — | ⬜ |
| TC-PRM-SBS-008 | Verify status filter shows only inactive sessions | Mix of active/inactive sessions | status=0 | Only inactive sessions displayed | — | — | ⬜ |

---

## 4. Boards Tab

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-SBS-009 | Verify boards tab shows paginated boards ordered by name | 4+ boards exist | fragment=#academicboard | Boards list (4/page) ordered by name ascending | — | — | ⬜ |
| TC-PRM-SBS-010 | Verify search by board name filters results | Board "CBSE" exists | search=CBSE | Matching boards displayed | — | — | ⬜ |
| TC-PRM-SBS-011 | Verify search by board short_name filters results | Board short_name "ICSE" exists | search=ICSE | Matching boards displayed | — | — | ⬜ |
| TC-PRM-SBS-012 | Verify status filter shows only active boards | Mix of active/inactive boards | status=1 | Only active boards displayed | — | — | ⬜ |
| TC-PRM-SBS-013 | Verify status filter shows only inactive boards | Mix of active/inactive boards | status=0 | Only inactive boards displayed | — | — | ⬜ |

---

## 5. Pagination & URL Fragments

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-SBS-014 | Verify session page parameter preserved | 10+ sessions | academicsession_page=2&fragment=#academicsession | Page 2 of sessions with fragment | — | — | ⬜ |
| TC-PRM-SBS-015 | Verify board page parameter preserved | 4+ boards | academicboard_page=2&fragment=#academicboard | Page 2 of boards with fragment | — | — | ⬜ |
| TC-PRM-SBS-016 | Verify search + pagination combined | — | search=CBSE&academicboard_page=1&fragment=#academicboard | Search applied and page loads | — | — | ⬜ |

---

## 6. Stub CRUD Methods

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-SBS-017 | Verify create stub returns view with gate check | Authenticated with `prime.session-board-setup.create` | — | View returned (stub) | — | — | ⬜ |
| TC-PRM-SBS-018 | Verify user without create permission receives 403 | Authenticated without create permission | — | 403 Forbidden | — | — | ⬜ |

---

## 7. Permissions Matrix

| Role | viewAny | create | view | update | delete |
|------|:-------:|:------:|:----:|:------:|:------:|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| Platform Manager | ✅ | ✅ | ✅ | ✅ | ✅ |
| Platform IT/Ops | ✅ | ✅ | ✅ | ✅ | ✅ |
| Platform Finance | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## 8. Data Table

| TC-ID | REQ-ID | BR-ID | Type | Priority | Test Level | Automated |
|-------|:------:|:-----:|:----:|:--------:|:----------:|:---------:|
| TC-PRM-SBS-001 | REQ-PRM-009 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-SBS-002 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-SBS-003 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-SBS-004 | REQ-PRM-009 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-SBS-005 | REQ-PRM-009 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-SBS-006 | REQ-PRM-009 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-SBS-007 | REQ-PRM-009 | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-SBS-008 | REQ-PRM-009 | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-SBS-009 | REQ-PRM-009 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-SBS-010 | REQ-PRM-009 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-SBS-011 | REQ-PRM-009 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-SBS-012 | REQ-PRM-009 | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-SBS-013 | REQ-PRM-009 | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-SBS-014 | REQ-PRM-009 | — | Pagination | P2 | Functional | ⬜ |
| TC-PRM-SBS-015 | REQ-PRM-009 | — | Pagination | P2 | Functional | ⬜ |
| TC-PRM-SBS-016 | REQ-PRM-009 | — | Pagination/Search | P2 | Functional | ⬜ |
| TC-PRM-SBS-017 | REQ-PRM-009 | — | Positive/Stub | P2 | Functional | ⬜ |
| TC-PRM-SBS-018 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |

---

## 9. Known Issues

| # | Issue | Linked TC | Severity | Status |
|---|-------|:---------:|:--------:|:------:|
| 1 | All CRUD resource methods except `index()` are stubs | TC-PRM-SBS-017, TC-PRM-SBS-018 | — (by design) | ⬜ |
| 2 | Board pagination set to only 4 per page — may be too few | — | Low | ⬜ |
| 3 | No feature tests exist | All TCs | High | ⬜ |

---

## 10. Route Reference

| Method | URI | Name |
|--------|-----|------|
| GET | `/prime/session-board-setup` | `central.prime.session-board-setup.index` |
| GET | `/prime/session-board-setup/create` | `central.prime.session-board-setup.create` |
| POST | `/prime/session-board-setup` | `central.prime.session-board-setup.store` |
| GET | `/prime/session-board-setup/{session_board_setup}` | `central.prime.session-board-setup.show` |
| GET | `/prime/session-board-setup/{session_board_setup}/edit` | `central.prime.session-board-setup.edit` |
| PUT | `/prime/session-board-setup/{session_board_setup}` | `central.prime.session-board-setup.update` |
| DELETE | `/prime/session-board-setup/{session_board_setup}` | `central.prime.session-board-setup.destroy` |

---

## 11. Execution Status

| TC-ID | Status | Executed By | Execution Date | Build | Comments |
|-------|:-----:|:-----------:|:--------------:|:-----:|----------|
| TC-PRM-SBS-001 | ⬜ | — | — | — | — |
| ... (all 18 TCs) | ⬜ | — | — | — | — |
