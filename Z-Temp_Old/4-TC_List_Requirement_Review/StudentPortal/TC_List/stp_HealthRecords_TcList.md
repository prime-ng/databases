# Health Records — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | StudentPortal (STP) |
| **Tab Group** | Reports / Academic |
| **Feature** | Health Records — centralized medical and health profile |
| **URL(s)** | `GET /health-records` |
| **Controller** | `StudentPortalController.healthRecords()` |
| **View** | `studentportal::health.index` |
| **FRD Refs** | REQ-STP-020, BR-STP-001 |
| **Priority** | P1 (Should) |
| **Code Status** | ✅ Implemented |
| **DB Tables** | `std_student_health_profiles` |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | Student must be authenticated via the standard `auth` guard |
| PC-02 | Student must have a linked `std_students` record |
| PC-03 | Student must have a `std_student_health_profiles` record linked to their student ID (optional — empty state) |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | User loaded with `student`, `student.healthProfile` | `healthRecords():525-528` |
| DL-02 | Activity log entry created on health records view | `healthRecords():530-539` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Student with complete health profile** | All fields populated: height, weight, BMI, blood group, vision, conditions, allergies, medications, immunization log, medical history, emergency contacts |
| TD-02 | **Student with no health profile** | `healthProfile` relationship returns null |
| TD-03 | **Student with partial health profile** | Some fields populated, others null |
| TD-04 | **Student with medical conditions and allergies** | chronic_conditions and allergies populated |
| TD-05 | **Student with immunization records** | immunization_log populated with multiple entries |
| TD-06 | **Student with medical history** | medical_history populated with past events |
| TD-07 | **Student with emergency contacts only** | Only emergency action fields populated |
| TD-08 | **Student with no medical history or immunizations** | Only vital statistics and emergency contact present |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| BC ID | Column/Field | Type | Constraints |
|-------|-------------|------|-------------|
| BC-DB-01 | `std_student_health_profiles.student_id` | INT UNSIGNED | FK to `std_students.id`, UNIQUE |
| BC-DB-02 | `std_student_health_profiles.blood_group` | VARCHAR | A+, A-, B+, B-, AB+, AB-, O+, O-, null |
| BC-DB-03 | `std_student_health_profiles.height` | DECIMAL(5,2) | Nullable |
| BC-DB-04 | `std_student_health_profiles.weight` | DECIMAL(5,2) | Nullable |
| BC-DB-05 | `std_student_health_profiles.bmi` | DECIMAL(4,1) | Nullable |
| BC-DB-06 | `std_student_health_profiles.vision_left` | VARCHAR | Nullable |
| BC-DB-07 | `std_student_health_profiles.vision_right` | VARCHAR | Nullable |
| BC-DB-08 | `std_student_health_profiles.chronic_conditions` | TEXT/JSON | Nullable |
| BC-DB-09 | `std_student_health_profiles.allergies` | TEXT/JSON | Nullable |
| BC-DB-10 | `std_student_health_profiles.medications` | TEXT/JSON | Nullable |
| BC-DB-11 | `std_student_health_profiles.immunization_log` | JSON/TEXT | Nullable |
| BC-DB-12 | `std_student_health_profiles.medical_history` | JSON/TEXT | Nullable |
| BC-DB-13 | `std_student_health_profiles.emergency_contact_phone` | VARCHAR | Nullable |

### BC-UI: UI Display Conditions

| BC ID | Condition | UI Behaviour |
|-------|-----------|-------------|
| BC-UI-01 | No health profile exists | Page shows "No health records found" |
| BC-UI-02 | Individual field is null | Field shows "—" or "Not recorded" |
| BC-UI-03 | Immunization log empty | Section shows "No immunization records available" |
| BC-UI-04 | Medical history empty | Section shows "No medical history recorded" |
| BC-UI-05 | No emergency contact | Emergency section shows "Not available" |

---

## 6. Test Cases

| TC ID | Test Case | Pre-condition | Test Data | Test Steps | Expected Result | Status |
|-------|-----------|---------------|-----------|------------|----------------|--------|
| TC-HLT-001 | Health records page loads with complete profile | PC-01 to PC-03 satisfied | TD-01 | 1. Login as student with complete health profile<br>2. Navigate to `/health-records` | All sections displayed: vital statistics, medical conditions, allergies, medications, immunization log, medical history, emergency actions | ⬜ |
| TC-HLT-002 | Vital statistics display correctly | PC-03 satisfied | TD-01 | 1. Navigate to `/health-records`<br>2. Check vital statistics section | Shows height (cm), weight (kg), BMI, blood group, vision left/right | ⬜ |
| TC-HLT-003 | Blood group displays correctly | PC-03 satisfied | TD-01 (blood_group = "B+") | 1. Navigate to `/health-records`<br>2. Check vital statistics | Blood group shown as "B+" | ⬜ |
| TC-HLT-004 | Medical conditions section displays chronic conditions | PC-03 satisfied | TD-04 | 1. Navigate to `/health-records`<br>2. Check medical conditions | Chronic conditions listed (e.g., "Mild asthma") | ⬜ |
| TC-HLT-005 | Allergies section displays food and drug allergies | PC-03 satisfied | TD-04 | 1. Navigate to `/health-records`<br>2. Check allergies | Food allergies and drug allergies listed separately | ⬜ |
| TC-HLT-006 | Medications section displays current medications | PC-03 satisfied | TD-04 | 1. Navigate to `/health-records`<br>2. Check medications | Current medications listed with name, dosage, timing | ⬜ |
| TC-HLT-007 | Immunization log table displays all vaccine records | PC-03 satisfied | TD-05 (3 records) | 1. Navigate to `/health-records`<br>2. Check immunization log | Table shows all records with Vaccine Name, Dose, Date, Doctor, Remarks columns | ⬜ |
| TC-HLT-008 | Medical history timeline displays past events | PC-03 satisfied | TD-06 (2 events) | 1. Navigate to `/health-records`<br>2. Check medical history | Timeline shows events with Date, Diagnosis, Doctor, Description | ⬜ |
| TC-HLT-009 | Emergency action details display correctly | PC-03 satisfied | TD-07 | 1. Navigate to `/health-records`<br>2. Check emergency section | Shows contact name, phone, preferred hospital, special instructions | ⬜ |
| TC-HLT-010 | No health profile shows empty state | PC-03 fails | TD-02 | 1. Login as student with no health profile<br>2. Navigate to `/health-records` | Shows "No health records found" or empty state | ⬜ |
| TC-HLT-011 | Partial profile — null fields show "—" | PC-03 satisfied | TD-03 | 1. Navigate to `/health-records`<br>2. Check null fields | Null fields display "—" or "Not recorded" | ⬜ |
| TC-HLT-012 | No immunization records shows empty state | PC-03 satisfied | TD-08 (no immunizations) | 1. Navigate to `/health-records`<br>2. Check immunization section | Shows "No immunization records available" | ⬜ |
| TC-HLT-013 | No medical history shows empty state | PC-03 satisfied | TD-08 (no medical history) | 1. Navigate to `/health-records`<br>2. Check medical history section | Shows "No medical history recorded" | ⬜ |
| TC-HLT-014 | Activity log entry created on health records view | PC-01, PC-02 satisfied | Any | 1. Navigate to `/health-records`<br>2. Check activity_logs table | Entry exists with `message = 'Student viewed health records.'` and correct context | ⬜ |
| TC-HLT-015 | Health records page accessible only to authenticated users | Varies | — | 1. Logout<br>2. Attempt to access `/health-records` | Redirected to login page | ⬜ |

---

## 7. Edge Cases

| # | Edge Case | Expected Behaviour |
|---|-----------|-------------------|
| EC-01 | Height stored in cm but display expected in feet-inches | Displayed in cm as stored (no automatic conversion) |
| EC-02 | BMI calculation stored as 0.0 or NULL | Displayed as "—" if null; as "0.0" if stored |
| EC-03 | Vision field contains free-text notes | Displayed as-is |
| EC-04 | Immunization log stored as JSON with unexpected structure | Display logic handles gracefully; shows raw or parsed data |
| EC-05 | Medical history has events without a doctor name | Doctor field shows "Not specified" |
| EC-06 | Emergency contact name stored but phone is null | Phone shows "—" while name is displayed |
| EC-07 | Health profile record exists but all fields are null | All sections show "Not recorded" fallbacks |

---

## 8. Test Execution Notes

| # | Note |
|---|------|
| TN-01 | Health records page is read-only — no forms to submit |
| TN-02 | The `healthProfile` relationship is a one-to-one on `std_students` — only one record per student |
| TN-03 | Immunization log and medical history may be stored as JSON or serialized data — verify front-end parsing is correct |
| TN-04 | The controller loads `student.healthProfile` only — no additional queries beyond this relationship |
| TN-05 | No data mutation occurs on this page; testing focuses on display accuracy and empty states |

---

## 9. Test Data Setup Requirements

| # | Setup Requirement |
|---|-------------------|
| TDS-01 | Create a `std_student_health_profiles` record with all health fields populated (height, weight, BMI, blood group, vision left/right, chronic conditions, allergies, medications, immunization log with multiple entries, medical history, emergency contact name/phone/hospital/instructions) |
| TDS-02 | Create a student with NO health profile record |
| TDS-03 | Create a health profile with only some fields populated (partial data) |
| TDS-04 | Create a health profile with no immunization log |
| TDS-05 | Create a health profile with no medical history |

---

## 10. Traceability Matrix

| TC ID | Maps To (FRD/BR) | Requirement |
|-------|-----------------|-------------|
| TC-HLT-001 | REQ-STP-020 | Health records loads with complete data |
| TC-HLT-002 to 003 | REQ-STP-020 | Vital statistics display |
| TC-HLT-004 to 006 | REQ-STP-020 | Medical conditions and allergies |
| TC-HLT-007 | REQ-STP-020 | Immunization log display |
| TC-HLT-008 | REQ-STP-020 | Medical history display |
| TC-HLT-009 | REQ-STP-020 | Emergency action details |
| TC-HLT-010 | REQ-STP-020 | No profile empty state |
| TC-HLT-011 | REQ-STP-020 | Partial profile handling |
| TC-HLT-012 to 013 | REQ-STP-020 | Empty sub-section states |
| TC-HLT-014 | REQ-STP-020 | Activity logging |
| TC-HLT-015 | REQ-STP-001 | Authentication guard |
