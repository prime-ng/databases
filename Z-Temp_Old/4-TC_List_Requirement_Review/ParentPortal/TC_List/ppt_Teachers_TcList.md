# ParentPortal — Teachers (TC List)

## 1. Feature Overview

| Attribute | Details |
|-----------|---------|
| Feature | Teacher Contact List |
| Module | ParentPortal (PPT) + TimetableFoundation |
| Priority | P1 |
| Type | Read-only |
| Test Strategy | Functional + Display (shortened per rules for read-only) |

## 2. Test Environment

| Parameter | Value |
|-----------|-------|
| Base URL | `{tenant_url}/parent-portal/teachers` |
| Auth Required | Yes (Parent role) |
| Child Context | Active child must be selected |
| Database | Tenant database with tt_activities and tt_activity_teachers |

## 3. Test Case Matrix

### 3.1 UI / Screen Navigation

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-TCH-001 | Verify teacher list page loads | 1. Login as Parent<br>2. Active child with class-section<br>3. Navigate to Teachers | List of teachers displayed | ⬜ | ◌ |
| TC-PPT-TCH-002 | Verify empty state when no teachers | 1. Select child without class-section<br>2. Navigate to Teachers | Empty state or "No teachers assigned" message | ⬜ | ◌ |
| TC-PPT-TCH-003 | Verify teacher name displayed | 1. View teacher list | Each teacher's name shown | ⬜ | ◌ |
| TC-PPT-TCH-004 | Verify subjects displayed per teacher | 1. View teacher list | Each teacher's subjects shown | ⬜ | ◌ |
| TC-PPT-TCH-005 | Verify teachers sorted alphabetically | 1. Check teacher order | Teachers in alphabetical order by name | ⬜ | ◌ |
| TC-PPT-TCH-006 | Verify teacher with multiple subjects shows all subjects | 1. Assign teacher to 2+ subjects<br>2. View list | All subjects listed under that teacher | ⬜ | ◌ |
| TC-PPT-TCH-007 | Verify only teachers for active child's class-section shown | 1. Switch active child<br>2. View Teachers | Different teacher list for different child | ⬜ | ◌ |

### 3.2 Security Tests

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-TCH-008 | Access teachers page without auth | 1. Logout<br>2. Navigate to Teachers | Redirected to login | ⬜ | ◌ |

### 3.3 Audit Logging

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-TCH-009 | Verify audit log on teacher list view | 1. Access teachers page<br>2. Check sys_activity_logs | "Viewed" event logged with student context | ⬜ | ◌ |

## 4. Test Data Setup

| Entity | Required Records |
|--------|-----------------|
| StudentAcademicSession | Active session for child with class-section |
| Activity | At least 3 activities for the class-section |
| ActivityTeacher | Assign teachers to activities (some with multiple subjects) |
| AcademicTerm | Current term marked with is_current = true |

## 5. Database Assertions

| Assertion | Query / Check |
|-----------|--------------|
| Teachers loaded | `SELECT COUNT(*) FROM tt_activity_teachers WHERE ...` |
| Only active | `is_active = 1` on activities and activity teachers |

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
| 1 | No contact info (phone/email) loaded for teachers | Low | ⬜ |
| 2 | FRD does not document this feature | Low | ⬜ |

## 8. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/parent-portal/teachers` | `teachers.index` | `index` |

## 9. Execution Status

| TC Count | Automated | Manual | Pass | Fail | Blocked | Not Run |
|----------|-----------|--------|------|------|---------|---------|
| 9 | 0 | 0 | 0 | 0 | 0 | 9 |
