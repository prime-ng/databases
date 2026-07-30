# STP — Transport Information TC List

---

## 1. Module / Sub-Module
- **Module:** StudentPortal (STP)
- **Sub-Module:** Services — Transport Information

---

## 2. FRD / BR Reference
- **REQ-STP-019** — Transport Information (P1)
- **BR-STP-001** — Data must belong to authenticated student

---

## 3. Test Scenarios

| TC ID | Test Case | Preconditions | Test Steps | Expected Result | Status |
|-------|-----------|--------------|------------|----------------|--------|
| TC-STP-TRN-001 | Verify page loads with active transport allocation | Student has active allocation with pickup/drop routes, vehicle assigned | 1) Login as student 2) Navigate to /transport 3) Observe page | Page renders: route details, shift, pickup stop, drop stop, vehicle reg no, driver name/contact, helper name | ⬜ |
| TC-STP-TRN-002 | Verify page loads with no allocation (empty state) | Student has NO transport allocation | 1) Login as student 2) Navigate to /transport | Page shows empty state message — no route/vehicle data displayed | ⬜ |
| TC-STP-TRN-003 | Verify vehicle & crew details display correctly | Allocation exists with vehicle + driver + helper assigned | 1) Login as student 2) Navigate to /transport | Vehicle registration number, driver name, driver contact, helper name displayed correctly | ⬜ |
| TC-STP-TRN-004 | Verify vehicle section hidden when no vehicle assigned | Allocation exists but no DriverRouteVehicleJnt record | 1) Login as student 2) Navigate to /transport | Vehicle/crew section not rendered or shows "No vehicle assigned" | ⬜ |
| TC-STP-TRN-005 | Verify boarding logs table displays last 30 days | Student has boarding log entries | 1) Login as student 2) Navigate to /transport 3) Check boarding logs section | Table shows trip date, boarding stop/time, unboarding stop/time, status; limited to 20 entries, last 30 days | ⬜ |
| TC-STP-TRN-006 | Verify boarding logs empty state | Student has no boarding logs in last 30 days | 1) Login as student 2) Navigate to /transport | Boarding logs section shows "No boarding records" or empty table | ⬜ |
| TC-STP-TRN-007 | Verify data ownership — another student's data not visible | Student A and Student B both have allocations | 1) Login as Student A 2) Navigate to /transport 3) Inspect network/DB queries | Only Student A's allocation, vehicle, and logs are loaded | ⬜ |
| TC-STP-TRN-008 | Verify boarding log status values display correctly | Boarding log entries with various statuses (Boarded, Unboarded, etc.) | 1) Login as student 2) Navigate to /transport 3) Observe status column | Status values rendered as per DB, no exception for unknown statuses | ⬜ |
| TC-STP-TRN-009 | Verify pickup stop and drop stop names display correctly | Allocation has pickupStop and dropStop with names | 1) Login as student 2) Navigate to /transport 3) Observe route details | Pickup stop name and drop stop name shown in their respective sections | ⬜ |
| TC-STP-TRN-010 | Verify shift name displayed | Allocation has pickupRoute with shift relation | 1) Login as student 2) Navigate to /transport 3) Observe route details | Shift name/timing displayed correctly | ⬜ |

---

## 4. Test Data Requirements
- Student with active transport allocation (all tpt_* tables seeded)
- Student with no transport allocation
- Student with boarding logs across various statuses
- At least two students with different allocations for ownership test

---

## 5. Test Environment
- **Browser:** Chrome / Firefox / Edge (latest)
- **Auth:** Authenticated student user with `auth` + `verified` middleware
- **DB:** Tenant database seeded with Transport module data

---

## 6. Automation Scope
| TC ID | Automatable? | Notes |
|-------|-------------|-------|
| TC-STP-TRN-001 | Yes | Use Laravel Dusk or Pest — assert view has route details |
| TC-STP-TRN-002 | Yes | Assert empty state message present |
| TC-STP-TRN-003–010 | Yes | All are assertion-based on view content |

---

## 7. Pass / Fail Criteria
- **Pass:** All TC IDs pass without errors; data rendered matches DB values
- **Fail:** Any TC fails due to incorrect data display, ownership leak, or exception

---

## 8. Known Issues
| Issue | Description | Severity |
|-------|-------------|----------|
| — | Boarding status values from DB may contain inconsistent casing | Low |
| — | Pickup route driver shown but not drop route driver | Low |

---

## 9. Route Reference
| Method | URI | Name |
|--------|-----|------|
| GET | /transport | student-portal.transport |

---

## 10. Execution Status
| Total TCs | Passed | Failed | Blocked | Not Run |
|-----------|--------|--------|---------|---------|
| 10 | — | — | — | 10 |
