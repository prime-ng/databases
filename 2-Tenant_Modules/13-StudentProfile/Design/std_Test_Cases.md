# Student Profile Module - Testing & QA Strategy (Deliverable D)

**Document Version:** 1.0
**Context:** Verification protocols for Student Management: Admission, Profile Update, Promotion, and Guardian Linking.

---

## 1. Developer Test-Run Checklist (Per Screen)

### 1.1 Student Admission Screen
- [ ] **Validation (Client)**: admission_no is mandatory, mobile is 10 digits/valid format.
- [ ] **Validation (Server)**: Check uniqueness of `admission_no` and `aadhar_id`.
- [ ] **Guardian Linking**:
    - [ ] Searching by mobile should fetch existing guardian details.
    - [ ] Linking an existing guardian should NOT duplicate the guardian record.
    - [ ] Creating new guardian should insert into `std_guardians`.
- [ ] **Academic Session**: Ensure `std_student_academic_sessions` entry is created with `is_current=1`.
- [ ] **Data Integrity**: verify `role_id` is assigned to `sys_users` when student login is created.

### 1.2 Student List & Search
- [ ] **Performance**: Search should return results in < 500ms for database > 10,000 records.
- [ ] **Filters**: Filtering by Class/Section updates the list correctly.
- [ ] **Sort**: Clicking 'Admission No' or 'Name' sorts the grid.

### 1.3 Previous Education & Docs
- [ ] **File Upload**: Verify files are saved to correct path/S3 and linked via `sys_media` or path.
- [ ] **Grid**: Adding a previous school row updates the local state/grid immediately.

---

## 2. QA Test-Run Checklist

### 2.1 Functional Flows
- [ ] **End-to-End Admission**: Create Student -> Assign Class -> Link Parent -> Verify Data in DB.
- [ ] **Promotion**: Promote Student from Class 9 to 10 -> Verify `is_current` flags update correctly in `std_student_academic_sessions`.
- [ ] **Parent Portal**: Verify linked guardian can see the student in their portal (based on `std_student_guardian_jnt`).
- [ ] **Profile Picture**: Upload photo -> Verify it appears on ID Card preview.

### 2.2 Role Based Access
- [ ] **Teacher**: Should only be able to Edit 'Attendance' or 'Remarks', not 'Admission No'.
- [ ] **Clerk**: Can Add/Edit but not Delete students.

---

## 3. Representative Test Cases

### 3.1 Scenario: New Student Admission
| ID | Test Scenario | Pre-Condition | Action / Input Steps | Expected Result | Severity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-01** | Admission with New Guardian | Admin Logged In | 1. Enter Basic Info (Adm No: A-101).<br>2. Enter New Guardian Info.<br>3. Save. | Student Created. Guardian Created. Linked in `std_student_guardian_jnt`. | High |
| **TC-02** | Admission with Existing Guardian | Guardian exists (Mob: 9999999999) | 1. Enter Basic Info.<br>2. Search Guardian by 9999999999.<br>3. Select Guardian.<br>4. Save. | Student Created. No new Guardian created. `std_student_guardian_jnt` links new student to existing ID. | High |
| **TC-03** | Duplicate Admission No | Student exists with Adm No: A-101 | 1. Try creating new student with Adm No: A-101.<br>2. Save. | Validation Error: "Admission Number already exists". | Medium |

### 3.2 Scenario: Academic History & Promotion
| ID | Test Scenario | Pre-Condition | Action / Input Steps | Expected Result | Severity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-04** | Promote Student | Student in Class 5 (Session 2024) | 1. Go to Academic Tab.<br>2. Click Promote.<br>3. Select Class 6 (Session 2025).<br>4. Save. | Old session `is_current=0`. New session `is_current=1`. History preserved. | Critical |
| **TC-05** | Section Allocation | Capacity 40, Enrolled 40 | 1. Try assigning 41st student to Class 10-A. | Warning: "Section Capacity Exceeded" (Soft check). | Low |

### 3.3 Scenario: Health & Documents
| ID | Test Scenario | Pre-Condition | Action / Input Steps | Expected Result | Severity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-06** | Upload Large Document | Max size 5MB | 1. Upload 10MB PDF for TC. | Error: "File size exceeds limit". | Low |
| **TC-07** | Medical Incident Log | Student Exists | 1. Log Incident (Fever).<br>2. Check Health Profile. | Incident appears in history. | Medium |

---
**End of Testing Strategy**
