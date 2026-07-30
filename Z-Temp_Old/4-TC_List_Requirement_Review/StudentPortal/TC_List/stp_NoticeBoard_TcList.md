
# Test Case List: stp_NoticeBoard

## 1. Module / Feature Overview

| Field | Value |
|-------|-------|
| **Module Code** | STP |
| **Feature Name** | Notice Board |
| **FRD Reference** | REQ-STP-023, BR-STP-031, BR-STP-034 |
| **Controller** | `StudentPortalController@noticeBoard` |
| **Total Test Cases** | 6 |

---

## 2. Test Case Summary

### 2.1 Notice Board Display

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-NTB-001 | Verify notice board loads with list of notifications | User has personal notifications | 1. Login as student with notifications<br>2. Navigate to `/notice-board` | Page loads. List of notifications shown sorted by `created_at` DESC. Paginated at 20 per page | ✅ | — | ⬜ | ◌ |
| TC-NTB-002 | Verify notice board shows empty state for user with no notifications | User has zero notifications | 1. Login as student with no notifications<br>2. Navigate to `/notice-board` | Empty list rendered. No errors. Paginator shows "0 results" | ✅ | — | ⬜ | ◌ |
| TC-NTB-003 | Verify notice board pagination when >20 notifications exist | User has 25+ notifications | 1. Login as user with 25+ notifications<br>2. Navigate to `/notice-board` | First page shows 20 items. Page 2 shows remaining 5. Pagination controls visible | ✅ | — | ⬜ | ◌ |
| TC-NTB-004 | Verify notice board uses personal notifications (current impl) | User has notifications from various modules | 1. Login and inspect notice board data source | Data returned from `auth()->user()->notifications()`. This is the known gap (GAP-STP-07) — should be school announcements | ✅ | — | ⬜ | ◌ |
| TC-NTB-005 | Verify activity is logged when viewing notice board | User is authenticated | 1. Login as student<br>2. Navigate to `/notice-board` | Activity log entry created: "Student viewed the notice board" with student context | ✅ | — | ⬜ | ◌ |
| TC-NTB-006 | Verify notice board does not depend on academic session | User has no active academic session | 1. Login as student without current session<br>2. Navigate to `/notice-board` | Notice board loads normally (no session dependency in controller) | ✅ | — | ⬜ | ◌ |

### 2.2 Gap Verification

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-NTB-GAP-001 | Verify notice board shows personal notifications instead of school announcements (GAP-STP-07) | User has both personal notifications and expected announcements | 1. Navigate to `/notice-board`<br>2. Compare displayed items with expected school announcements | **GAP CONFIRMED**: Board shows personal notifications (exam start, homework due, etc.) rather than official school circulars | — | ✅ | ⬜ | ◌ |
