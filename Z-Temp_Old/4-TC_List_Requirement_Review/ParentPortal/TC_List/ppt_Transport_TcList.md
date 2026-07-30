# ParentPortal — Transport (TC List)

## 1. Feature Overview

| Attribute | Details |
|-----------|---------|
| Feature | Transport Information |
| Module | ParentPortal (PPT) + Transport Module |
| Priority | P1 |
| Type | Read-only |
| Test Strategy | Functional + Display + Edge Cases (shortened per rules for read-only) |

## 2. Test Environment

| Parameter | Value |
|-----------|-------|
| Base URL | `{tenant_url}/parent-portal/transport` |
| Auth Required | Yes (Parent role) |
| Child Context | Active child must be selected |
| Database | Tenant database with tpt_student_route_jnt + related tables |
| Precondition | Transport module must be active for the tenant |

## 3. Test Case Matrix

### 3.1 UI / Screen Navigation

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-TRN-001 | Verify transport page loads with allocation details | 1. Login as Parent<br>2. Active child with transport allocation<br>3. Navigate to Transport | Route, vehicle, driver, pickup/drop stop details displayed | ⬜ | ◌ |
| TC-PPT-TRN-002 | Verify no allocation shows graceful message | 1. Select child without transport allocation<br>2. Navigate to Transport | "Not assigned" or "No transport allocation" message | ⬜ | ◌ |
| TC-PPT-TRN-003 | Verify vehicle details shown | 1. View transport with allocation | Vehicle number, type visible | ⬜ | ◌ |
| TC-PPT-TRN-004 | Verify driver details shown | 1. View transport with allocation | Driver name and contact visible | ⬜ | ◌ |
| TC-PPT-TRN-005 | Verify helper details shown (if assigned) | 1. View transport with helper assigned | Helper name visible | ⬜ | ◌ |
| TC-PPT-TRN-006 | Verify pickup stop details shown | 1. View transport with allocation | Pickup stop name, time, location visible | ⬜ | ◌ |
| TC-PPT-TRN-007 | Verify drop stop details shown | 1. View transport with allocation | Drop stop name, time, location visible | ⬜ | ◌ |
| TC-PPT-TRN-008 | Verify route details shown | 1. View transport with allocation | Route name/number visible | ⬜ | ◌ |
| TC-PPT-TRN-009 | Verify boarding log shown (if data exists) | 1. Have boarding log records<br>2. View Transport | Last 5 boarding events displayed | ⬜ | ◌ |

### 3.2 Graceful Degradation

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-TRN-010 | Verify Transport module disabled shows message | 1. Disable Transport module for tenant<br>2. Navigate to Transport | "Transport module not activated" | ⬜ | ◌ |
| TC-PPT-TRN-011 | Verify no GPS shown as unavailable | 1. View transport page | GPS/Live tracking section shows "not available" | ⬜ | ◌ |

### 3.3 Security Tests

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-TRN-012 | Access transport page without auth | 1. Logout<br>2. Navigate to Transport | Redirected to login | ⬜ | ◌ |
| TC-PPT-TRN-013 | Verify data changes when switching active child | 1. Switch active child<br>2. View Transport | Shows different child's transport data (or no allocation) | ⬜ | ◌ |

### 3.4 Audit Logging

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-TRN-014 | Verify audit log on transport view | 1. Access transport page<br>2. Check sys_activity_logs | "Viewed" event logged with student context | ⬜ | ◌ |

## 4. Test Data Setup

| Entity | Required Records |
|--------|-----------------|
| TptStudentAllocationJnt | Active allocation for at least one child |
| TptRoute | Route record linked to allocation |
| TptVehicle | Vehicle linked via driverRouteVehicles |
| TptDriver | Driver linked via driverRouteVehicles |
| TptStop | Pickup/drop stops |
| tpt_student_boarding_log | Optional — last 5 RFID events |

## 5. Database Assertions

| Assertion | Query / Check |
|-----------|--------------|
| Allocation exists | `SELECT * FROM tpt_student_route_jnt WHERE student_id = ? AND active_status = 1` |
| Allocation active | `active_status = 1` |

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
| 1 | GPS tracking not implemented | Low | ⬜ |
| 2 | Boarding log uses Schema::hasTable() check — fragile | Low | ⬜ |

## 8. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/parent-portal/transport` | `transport.index` | `index` |

## 9. Execution Status

| TC Count | Automated | Manual | Pass | Fail | Blocked | Not Run |
|----------|-----------|--------|------|------|---------|---------|
| 14 | 0 | 0 | 0 | 0 | 0 | 14 |
