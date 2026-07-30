# Student ID Card — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | StudentPortal (STP) |
| **Tab Group** | Reports |
| **Feature** | Student ID Card — secure digital identity card |
| **URL(s)** | `GET /student-id-card` |
| **Controller** | `StudentPortalController.idCard()` |
| **View** | `studentportal::id-card.index` |
| **FRD Refs** | REQ-STP-021, RPT-STP-004 |
| **Priority** | P1 (Should) |
| **Code Status** | 🟡 Implemented (PDF download route not defined) |
| **DB Tables** | `std_students`, `std_student_details`, `std_student_addresses`, `std_student_guardian_jnt`, `std_guardians`, `std_student_academic_sessions`, `sch_classes`, `sch_sections`, `std_student_health_profiles` |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | Student must be authenticated via the standard `auth` guard |
| PC-02 | Student must have a linked `std_students` record |
| PC-03 | Student must have a current academic session (`std_student_academic_sessions` with `is_current = 1`) |
| PC-04 | Student must have a `std_student_health_profiles` record for blood group (optional — empty) |
| PC-05 | Student must have at least one guardian linked for emergency contact (optional — fallback) |
| PC-06 | School logo and principal signature must be configured in system settings (optional — placeholder) |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | User loaded with `student`, `student.healthProfile`, `student.addresses`, `student.studentGuardianJnts.guardian`, `student.currentSession.classSection.class`, `student.currentSession.classSection.section`, `student.currentSession.academicSession` | `idCard():612-620` |
| DL-02 | Activity log entry created on ID card view | `idCard():622-631` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Student with complete ID card data** | Has photo, all name parts, active session, class-section, health profile, guardian, school config |
| TD-02 | **Student with no photo** | Avatar returns null/placeholder |
| TD-03 | **Student with no health profile** | Blood group field shows "Not recorded" |
| TD-04 | **Student with no guardians** | Emergency contact shows "Not available" |
| TD-05 | **Student with no current session** | Class/section/session fields show "—" |
| TD-06 | **Student with multiple guardians** | Emergency contact uses first guardian's phone |
| TD-07 | **Student with no middle name** | Full name = first + last name only |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| BC ID | Column/Field | Type | Constraints |
|-------|-------------|------|-------------|
| BC-DB-01 | `std_students.first_name` | VARCHAR | NOT NULL |
| BC-DB-02 | `std_students.middle_name` | VARCHAR | Nullable |
| BC-DB-03 | `std_students.last_name` | VARCHAR | NOT NULL |
| BC-DB-04 | `std_students.admission_no` | VARCHAR | NOT NULL, unique |
| BC-DB-05 | `std_student_health_profiles.blood_group` | VARCHAR | A+, A-, B+, B-, AB+, AB-, O+, O- |
| BC-DB-06 | `std_guardians.mobile` | VARCHAR | Contact number |

### BC-UI: UI Display Conditions

| BC ID | Condition | UI Behaviour |
|-------|-----------|-------------|
| BC-UI-01 | No student photo | Default avatar placeholder |
| BC-UI-02 | No blood group | Shows "—" or "Not recorded" |
| BC-UI-03 | No emergency contact | Shows "Not available" |
| BC-UI-04 | No current session | Class/section/session display as "—" |
| BC-UI-05 | Missing middle name | Full name = "First Last" (no extra spaces) |

---

## 6. Test Cases

| TC ID | Test Case | Pre-condition | Test Data | Test Steps | Expected Result | Status |
|-------|-----------|---------------|-----------|------------|----------------|--------|
| TC-IDC-001 | ID card renders with complete student data | PC-01 to PC-06 satisfied | TD-01 | 1. Login as student with complete data<br>2. Navigate to `/student-id-card` | ID card displayed with all fields: school logo/name, STUDENT badge, photo, full name, class-section, roll number, admission number, blood group, emergency contact, session | ⬜ |
| TC-IDC-002 | School logo and name displayed in header | PC-06 satisfied | TD-01 | 1. Navigate to `/student-id-card`<br>2. Check card header | School logo and organization name visible at top | ⬜ |
| TC-IDC-003 | "STUDENT" verification tag displayed | PC-01, PC-02 satisfied | TD-01 | 1. Navigate to `/student-id-card`<br>2. Check header | "STUDENT" badge/tag visible | ⬜ |
| TC-IDC-004 | Student photo displayed in circular format | PC-01, PC-02 satisfied | TD-01 | 1. Navigate to `/student-id-card`<br>2. Check photo | Photo displayed with circular/cropped styling, centred | ⬜ |
| TC-IDC-005 | Full name displayed correctly (first + middle + last) | PC-02 satisfied | TD-01 (has middle name) | 1. Navigate to `/student-id-card`<br>2. Check name field | Shows "First Middle Last" | ⬜ |
| TC-IDC-006 | Full name without middle name | PC-02 satisfied | TD-07 (no middle name) | 1. Navigate to `/student-id-card`<br>2. Check name field | Shows "First Last" without extra spaces | ⬜ |
| TC-IDC-007 | Class and section displayed correctly | PC-03 satisfied | TD-01 | 1. Navigate to `/student-id-card`<br>2. Check class-section field | Shows "Class X - Section B" (or similar format) | ⬜ |
| TC-IDC-008 | Roll number displayed | PC-02 satisfied | TD-01 | 1. Navigate to `/student-id-card`<br>2. Check roll number | Correct roll number shown | ⬜ |
| TC-IDC-009 | Admission number displayed | PC-02 satisfied | TD-01 | 1. Navigate to `/student-id-card`<br>2. Check admission number | Correct admission_no shown | ⬜ |
| TC-IDC-010 | Blood group displayed prominently | PC-04 satisfied | TD-01 | 1. Navigate to `/student-id-card`<br>2. Check blood group | Blood group shown clearly (e.g., "O+") with visual emphasis | ⬜ |
| TC-IDC-011 | Emergency contact from first guardian | PC-05 satisfied | TD-01 | 1. Navigate to `/student-id-card`<br>2. Check emergency contact | First guardian's phone number shown as emergency contact | ⬜ |
| TC-IDC-012 | Academic session displayed | PC-03 satisfied | TD-01 | 1. Navigate to `/student-id-card`<br>2. Check session field | Current academic session label shown (e.g., "2025-2026") | ⬜ |
| TC-IDC-013 | Principal signature image displayed | PC-06 satisfied | TD-01 | 1. Navigate to `/student-id-card`<br>2. Check signature box | Principal signature image visible | ⬜ |
| TC-IDC-014 | "Download PDF" / "Print" button visible | Any | Any | 1. Navigate to `/student-id-card` | Download PDF and/or Print button visible | ⬜ |
| TC-IDC-015 | No photo shows default placeholder | PC-02 satisfied | TD-02 | 1. Navigate to `/student-id-card`<br>2. Check photo | Default avatar placeholder shown instead of photo | ⬜ |
| TC-IDC-016 | No health profile shows blood group as "Not recorded" | PC-04 fails | TD-03 | 1. Navigate to `/student-id-card`<br>2. Check blood group | Shows "—" or "Not recorded" | ⬜ |
| TC-IDC-017 | No guardians shows emergency contact as "Not available" | PC-05 fails | TD-04 | 1. Navigate to `/student-id-card`<br>2. Check emergency contact | Shows "Not available" | ⬜ |
| TC-IDC-018 | No current session shows class/section/session as "—" | PC-03 fails | TD-05 | 1. Navigate to `/student-id-card`<br>2. Check academic fields | Class, section, and session fields show "—" | ⬜ |
| TC-IDC-019 | Multiple guardians — emergency contact uses first guardian | PC-05 satisfied | TD-06 (2 guardians) | 1. Navigate to `/student-id-card`<br>2. Check emergency contact | First guardian's phone number shown | ⬜ |
| TC-IDC-020 | Activity log entry created on ID card view | PC-01, PC-02 satisfied | Any | 1. Navigate to `/student-id-card`<br>2. Check activity_logs table | Entry exists with `message = 'Student viewed ID card.'` and correct context | ⬜ |
| TC-IDC-021 | ID card page accessible only to authenticated users | Varies | — | 1. Logout<br>2. Attempt to access `/student-id-card` | Redirected to login page | ⬜ |

---

## 7. Edge Cases

| # | Edge Case | Expected Behaviour |
|---|-----------|-------------------|
| EC-01 | Student has no linked health profile model | `healthProfile` returns null; blood group field shows "Not recorded" |
| EC-02 | Guardian has no phone number | Emergency contact shows "—" or "No contact" |
| EC-03 | Student avatar field is null | Default user avatar or placeholder image shown |
| EC-04 | School logo not configured | Logo area shows school name text instead |
| EC-05 | Principal signature not configured | Signature box shows empty placeholder |
| EC-06 | Student name has special characters | Displayed as-is with proper encoding |
| EC-07 | Academic session name is null | Session field shows "—" |

---

## 8. Test Execution Notes

| # | Note |
|---|------|
| TN-01 | The ID card is a read-only display — no forms to submit or data to mutate |
| TN-02 | PDF download route is NOT defined as of current implementation — testing the PDF functionality is out of scope |
| TN-03 | Emergency contact is determined by the first guardian in the `studentGuardianJnts` collection — order depends on DB query; may not be deterministic without explicit ordering |
| TN-04 | School logo and principal signature are managed through system configuration / media library — verify these are available in the test environment |

---

## 9. Test Data Setup Requirements

| # | Setup Requirement |
|---|-------------------|
| TDS-01 | Create a `std_students` record with first_name, middle_name, last_name, admission_no, roll_number, and avatar media |
| TDS-02 | Create a `std_student_health_profiles` record with a blood_group value |
| TDS-03 | Create `std_guardians` record(s) and link via `std_student_guardian_jnt` |
| TDS-04 | Create a `std_student_academic_sessions` record with `is_current = 1` linked to class and section |
| TDS-05 | Configure school name, logo, and principal signature in system settings |
| TDS-06 | Create a student record with null avatar and no health profile for empty state testing |

---

## 10. Traceability Matrix

| TC ID | Maps To (FRD/BR) | Requirement |
|-------|-----------------|-------------|
| TC-IDC-001 | REQ-STP-021 | ID card renders with all data |
| TC-IDC-002 | REQ-STP-021 | School logo and name |
| TC-IDC-003 | REQ-STP-021 | Verification tag |
| TC-IDC-004 | REQ-STP-021 | Student photo display |
| TC-IDC-005 to 006 | REQ-STP-021 | Full name display |
| TC-IDC-007 to 009 | REQ-STP-021 | Academic identifiers |
| TC-IDC-010 | REQ-STP-021 | Blood group display |
| TC-IDC-011 | REQ-STP-021 | Emergency contact |
| TC-IDC-012 | REQ-STP-021 | Academic session |
| TC-IDC-013 | REQ-STP-021 | Principal signature |
| TC-IDC-014 | REQ-STP-021, RPT-STP-004 | Download/Print button |
| TC-IDC-015 to 018 | REQ-STP-021 | Empty state handling |
| TC-IDC-019 | REQ-STP-021 | Multiple guardians |
| TC-IDC-020 | REQ-STP-021 | Activity logging |
| TC-IDC-021 | REQ-STP-001 | Authentication guard |
