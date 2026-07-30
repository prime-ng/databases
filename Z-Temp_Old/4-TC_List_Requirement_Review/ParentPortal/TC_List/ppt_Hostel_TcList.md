# ParentPortal — Hostel (TC List)

## 1. Feature Overview

| Attribute | Details |
|-----------|---------|
| Feature | Hostel Information |
| Module | ParentPortal (PPT) + Hostel Module |
| Priority | P2 |
| Type | Read-only |
| Test Strategy | Functional + Display + Edge Cases (shortened per rules for read-only) |

## 2. Test Environment

| Parameter | Value |
|-----------|-------|
| Base URL | `{tenant_url}/parent-portal/hostel` |
| Auth Required | Yes (Parent role) |
| Child Context | Active child must be selected |
| Database | Tenant database with hst_* tables |
| Precondition | Hostel module must be active for the tenant |

## 3. Test Case Matrix

### 3.1 UI / Screen Navigation

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-HST-001 | Verify hostel page loads | 1. Login as Parent with hostel allocation<br>2. Navigate to Hostel | Hostel page renders with all sections | ⬜ | ◌ |
| TC-PPT-HST-002 | Verify accommodation section shows building/room/bed | 1. View hostel page | Building name, floor, room number, bed number, bed type displayed | ⬜ | ◌ |
| TC-PPT-HST-003 | Verify hostel attendance section loads | 1. View hostel page with attendance records | Attendance entries visible with session and status | ⬜ | ◌ |
| TC-PPT-HST-004 | Verify leave passes section loads | 1. View hostel page with leave passes | Leave pass records visible with status | ⬜ | ◌ |
| TC-PPT-HST-005 | Verify mess menu section loads | 1. View hostel page with published menus | Weekly menu displayed for child's hostel | ⬜ | ◌ |
| TC-PPT-HST-006 | Verify mess bills section loads | 1. View hostel page with mess bills | Mess bill records visible with status | ⬜ | ◌ |
| TC-PPT-HST-007 | Verify fee demands section loads | 1. View hostel page with fee demands | Fee demand records visible with status | ⬜ | ◌ |
| TC-PPT-HST-008 | Verify laundry tickets section loads | 1. View hostel page with laundry tickets | Laundry ticket records visible with status | ⬜ | ◌ |
| TC-PPT-HST-009 | Verify room change requests section loads | 1. View hostel page with room changes | Room change records visible with status | ⬜ | ◌ |
| TC-PPT-HST-010 | Verify empty state when no hostel allocation | 1. Select child without hostel allocation<br>2. View Hostel | "Not allotted" or "No hostel accommodation" message | ⬜ | ◌ |

### 3.2 Graceful Degradation

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-HST-011 | Verify Hostel module disabled shows message | 1. Disable Hostel module<br>2. Navigate to Hostel | "Hostel module not activated" | ⬜ | ◌ |
| TC-PPT-HST-012 | Verify empty section renders without errors | 1. Choose child without some hostel data<br>2. View each section | Empty sections show "No records" without errors | ⬜ | ◌ |

### 3.3 Security Tests

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-HST-013 | Access hostel page without auth | 1. Logout<br>2. Navigate to Hostel | Redirected to login | ⬜ | ◌ |
| TC-PPT-HST-014 | Verify data changes with active child switch | 1. Switch active child<br>2. View Hostel | Different child's hostel data shown | ⬜ | ◌ |

### 3.4 Audit Logging

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-HST-015 | Verify audit log on hostel view | 1. Access hostel page<br>2. Check sys_activity_logs | "Viewed" event logged with student context | ⬜ | ◌ |

## 4. Test Data Setup

| Entity | Required Records |
|--------|-----------------|
| Allotment | Active allotment for at least one child with full relationship chain |
| HstAttendanceEntry | At least 2-3 attendance records |
| LeavePass | At least 1 leave pass record |
| MessWeeklyMenu | Published menu for the child's hostel |
| MessBill | At least 1 mess bill |
| FeeDemand | At least 1 fee demand |
| LaundryTicket | At least 1 laundry ticket |
| RoomChangeRequest | At least 1 room change request |

## 5. Database Assertions

| Assertion | Query / Check |
|-----------|--------------|
| Allocation exists | `SELECT * FROM hst_allotments WHERE student_id = ? AND is_active = 1 AND is_alloted = 1` |

## 6. Browser / Device Compatibility

| Platform | Support |
|----------|---------|
| Chrome (Desktop) | ✅ |
| Firefox (Desktop) | ✅ |
| Chrome (Android) | ✅ |
| Safari (iOS) | ✅ |

## 7. Known Issues

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | 8 separate queries — potential performance concern | Medium | ⬜ |
| 2 | Room mate count (per FRD) not explicitly in data | Low | ⬜ |
| 3 | FRD classifies as P2 but controller fully built | Low | ⬜ |

## 8. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/parent-portal/hostel` | `hostel.index` | `index` |

## 9. Execution Status

| TC Count | Automated | Manual | Pass | Fail | Blocked | Not Run |
|----------|-----------|--------|------|------|---------|---------|
| 15 | 0 | 0 | 0 | 0 | 0 | 15 |
