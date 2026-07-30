# STP — Hostel Information TC List

---

## 1. Module / Sub-Module
- **Module:** StudentPortal (STP)
- **Sub-Module:** Services — Hostel Information

---

## 2. FRD / BR Reference
- **REQ-STP-026** — Hostel Information (P2 — Blocked)
- **BR-STP-001** — Data must belong to authenticated student

---

## 3. Test Scenarios

| TC ID | Test Case | Preconditions | Test Steps | Expected Result | Status |
|-------|-----------|--------------|------------|----------------|--------|
| TC-STP-HST-001 | Verify page loads with active hostel allotment | Student has active allotment with bed/room/hostel, mess menus published | 1) Login as student 2) Navigate to /hostel 3) Observe page | Page renders: building name, room number, room type, bed number, floor | ⬜ |
| TC-STP-HST-002 | Verify page loads without allotment (non-boarder) | Student has NO hostel allotment | 1) Login as student 2) Navigate to /hostel | Page shows empty state for allotment section; remaining sections are empty | ⬜ |
| TC-STP-HST-003 | Verify mess weekly menu displays for allotted hostel | MessWeeklyMenu records exist for hostel, published | 1) Login as student 2) Navigate to /hostel 3) Observe mess menu | Mess menu table shows week start date, day of week, menu items | ⬜ |
| TC-STP-HST-004 | Verify mess menu hidden when none published | No published mess menus for hostel | 1) Login as student 2) Navigate to /hostel | Mess menu section is empty or shows "No menus published" | ⬜ |
| TC-STP-HST-005 | Verify attendance entries display | HstAttendanceEntry records exist for student | 1) Login as student 2) Navigate to /hostel 3) Observe attendance | Table shows session, status, date sorted by latest | ⬜ |
| TC-STP-HST-006 | Verify leave passes display | LeavePass records exist for student | 1) Login as student 2) Navigate to /hostel 3) Observe leave passes | Table shows leave details with status | ⬜ |
| TC-STP-HST-007 | Verify mess bills display | MessBill records exist for student | 1) Login as student 2) Navigate to /hostel 3) Observe mess bills | Table shows bill month, amount, status | ⬜ |
| TC-STP-HST-008 | Verify fee demands display | FeeDemand records exist for student | 1) Login as student 2) Navigate to /hostel 3) Observe fee demands | Table shows period, amount, status | ⬜ |
| TC-STP-HST-009 | Verify laundry tickets display | LaundryTicket records exist for student | 1) Login as student 2) Navigate to /hostel 3) Observe laundry | Table shows ticket details with status | ⬜ |
| TC-STP-HST-010 | Verify room change requests display | RoomChangeRequest records exist for student | 1) Login as student 2) Navigate to /hostel 3) Observe room change | Table shows requested room, status, date | ⬜ |
| TC-STP-HST-011 | Verify data ownership — another student's data not visible | Student A and Student B both have allotments | 1) Login as Student A 2) Navigate to /hostel | Only Student A's allotment and related records are loaded | ⬜ |
| TC-STP-HST-012 | Verify allotment shows hostel building name | Allotment has bed->room->hostel chain | 1) Login as student 2) Navigate to /hostel | Hostel building name displayed correctly | ⬜ |
| TC-STP-HST-013 | Verify all empty states handled gracefully | Student has allotment but no mess/attendance/etc. records | 1) Login as student 2) Navigate to /hostel | Each empty section shows appropriate "no data" message, no exceptions | ⬜ |

---

## 4. Test Data Requirements
- Student with active hostel allotment + all related records seeded
- Student with allotment only (no mess/attendance/leave/bill/ticket data)
- Student without any allotment
- At least two hostel-resident students for ownership test
- Hostel (HST) module installed and seeded

---

## 5. Test Environment
- **Browser:** Chrome / Firefox / Edge (latest)
- **Auth:** Authenticated student user
- **DB:** Tenant database seeded with Hostel module data

---

## 6. Automation Scope
| TC ID | Automatable? | Notes |
|-------|-------------|-------|
| TC-STP-HST-001–013 | Yes (conditional) | Requires HST module installed; otherwise blocked |

---

## 7. Pass / Fail Criteria
- **Pass:** All TC IDs pass; data matches DB values; empty states handled
- **Fail:** SQL exception if HST module missing; data ownership leak; incorrect values

---

## 8. Known Issues
| Issue | Description | Severity |
|-------|-------------|----------|
| GAP-STP-26-02 | Blocked on Hostel module readiness | Medium |
| GAP-STP-26-03 | No graceful degradation if HST module is absent | Medium |
| — | STP controller directly references Hostel model classes — module coupling | Medium |

---

## 9. Route Reference
| Method | URI | Name |
|--------|-----|------|
| GET | /hostel | student-portal.hostel |

---

## 10. Execution Status
| Total TCs | Passed | Failed | Blocked | Not Run |
|-----------|--------|--------|---------|---------|
| 13 | — | — | — | 13 |
