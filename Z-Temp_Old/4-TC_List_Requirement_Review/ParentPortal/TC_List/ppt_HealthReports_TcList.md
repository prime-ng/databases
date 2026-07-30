# ParentPortal — Health Reports (TC List)

## 1. Feature Overview

| Attribute | Details |
|-----------|---------|
| Feature | Health Reports |
| Module | ParentPortal (PPT) + StudentProfile |
| Priority | P1 |
| Type | Read-only |
| Test Strategy | Functional + Visibility Gating + Edge Cases (shortened per rules for read-only) |

## 2. Test Environment

| Parameter | Value |
|-----------|-------|
| Base URL | `{tenant_url}/parent-portal/health` |
| Auth Required | Yes (Parent role) |
| Child Context | Active child must be selected |
| Database | Tenant database with std_health_profiles |

## 3. Test Case Matrix

### 3.1 UI / Screen Navigation

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-HLT-001 | Verify health page loads with profile data | 1. Login as Parent<br>2. Set child with health profile<br>3. Navigate to Health | Health profile displayed with blood group, height, weight, BMI | ⬜ | ◌ |
| TC-PPT-HLT-002 | Verify empty state when no health profile exists | 1. Select child without health profile<br>2. Navigate to Health | Graceful empty state; no error | ⬜ | ◌ |
| TC-PPT-HLT-003 | Verify BMI calculated correctly | 1. Set height=150cm, weight=50kg<br>2. View Health | BMI = 22.2 (rounded to 1 decimal) | ⬜ | ◌ |
| TC-PPT-HLT-004 | Verify BMI not shown when height or weight is 0 | 1. Set height=0 or weight=0<br>2. View Health | BMI not displayed (null) | ⬜ | ◌ |
| TC-PPT-HLT-005 | Verify health detail route redirects to index | 1. Navigate to /health/{any_id}<br>2. Check redirect | Redirected to health.index | ⬜ | ◌ |

### 3.2 Visibility Gating

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-HLT-006 | Verify parent_visible=1 records shown | 1. Set parent_visible=1 on health profile<br>2. View Health | Health data visible | ⬜ | ◌ |
| TC-PPT-HLT-007 | Verify parent_visible=0 records hidden | 1. Set parent_visible=0<br>2. View Health | Health data excluded or not visible | ⬜ | ◌ |
| TC-PPT-HLT-008 | Verify counsellor report hidden when setting OFF (default) | 1. Ensure counsellor report visibility OFF<br>2. View Health | Counsellor section hidden | ⬜ | ◌ |
| TC-PPT-HLT-009 | Verify counsellor report shown when setting ON | 1. Enable counsellor report visibility<br>2. View Health | Counsellor section visible (if HPC data exists) | ⬜ | ◌ |

### 3.3 Security Tests

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-HLT-010 | Access health page without auth | 1. Logout<br>2. Navigate to Health | Redirected to login | ⬜ | ◌ |
| TC-PPT-HLT-011 | Verify data for active child only | 1. Switch active child<br>2. View Health | Shows health data for the new active child | ⬜ | ◌ |

### 3.4 Audit Logging

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-HLT-012 | Verify audit log on health view | 1. Access health index<br>2. Check sys_activity_logs | "Viewed" event logged with student context | ⬜ | ◌ |

## 4. Test Data Setup

| Entity | Required Records |
|--------|-----------------|
| StudentHealthProfile | Health profile for at least one child (varying parent_visible values) |
| HPC counsellor reports | Data in hpc_counsellor_reports (if testing counsellor visibility) |
| sys_school_settings | parent_counsellor_report_visibility toggle |

## 5. Database Assertions

| Assertion | Query / Check |
|-----------|--------------|
| Health profile exists | `SELECT * FROM std_health_profiles WHERE student_id = ?` |
| parent_visible flag | `parent_visible` value determines visibility |

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
| 1 | HPC counsellor report gate not enforced in controller — view-level only | Medium | ⬜ |
| 2 | parent_visible check not explicitly in controller — relies on model scoping | Medium | ⬜ |
| 3 | HPC module integration incomplete (physical assessments missing) | Medium | ⬜ |

## 8. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/parent-portal/health` | `health.index` | `index` |
| GET | `/parent-portal/health/{record}` | `health.show` | `show` (redirect) |

## 9. Execution Status

| TC Count | Automated | Manual | Pass | Fail | Blocked | Not Run |
|----------|-----------|--------|------|------|---------|---------|
| 12 | 0 | 0 | 0 | 0 | 0 | 12 |
