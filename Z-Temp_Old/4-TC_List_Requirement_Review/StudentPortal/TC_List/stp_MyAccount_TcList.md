# My Account — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | StudentPortal (STP) |
| **Tab Group** | Account |
| **Feature** | My Account / Account Settings — read-only student profile, guardians, addresses, siblings |
| **URL(s)** | `GET /account` |
| **Controller** | `StudentPortalController.account()` |
| **View** | `studentportal::account.index` |
| **FRD Refs** | REQ-STP-029, BR-STP-035, BR-STP-036 |
| **Priority** | P2 (Could) |
| **Code Status** | 🟡 Implemented (backend complete; security/notification tabs stubs) |
| **DB Tables** | `sys_users`, `std_students`, `std_student_details`, `std_student_addresses`, `std_student_guardian_jnt`, `std_guardians`, `std_student_academic_sessions` |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | Student must be authenticated via the standard `auth` guard |
| PC-02 | Student must have a linked `std_students` record via `auth()->user()->student` |
| PC-03 | Student must have a `std_student_details` record for personal details display (optional) |
| PC-04 | At least one `std_student_addresses` record must exist for address display (optional) |
| PC-05 | At least one `std_student_guardian_jnt` record must exist for guardian display (optional) |
| PC-06 | At least one `std_guardians` record linked via junction must exist (optional) |
| PC-07 | Other students must share the same guardian IDs for sibling detection (optional) |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | User loaded with `student`, `student.profile`, `student.addresses`, `student.studentGuardianJnts`, `student.sessions`, `student.guardians.user` eager-loads | `account():289-297` |
| DL-02 | Siblings queried via raw DB on `std_student_guardian_jnt`: find other students with same guardian IDs, excluding self | `account():303-318` |
| DL-03 | Activity log entry created on account view | `account():321-329` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Student with complete profile** | Has user, student, profile, addresses, multiple guardians, and siblings |
| TD-02 | **Student with no profile details** | `profile` relationship returns null |
| TD-03 | **Student with no addresses** | `addresses` relationship returns empty collection |
| TD-04 | **Student with no guardians** | `guardians` relationship returns empty collection |
| TD-05 | **Student with no siblings** | No other students share the same guardian IDs |
| TD-06 | **Student with single guardian** | Only one guardian linked |
| TD-07 | **Student with multiple guardians** | e.g., Father + Mother + Grandparent |
| TD-08 | **Student with one sibling** | One other student shares a guardian |
| TD-09 | **Student with multiple siblings** | Multiple other students share guardians |
| TD-10 | **Student with inactive sibling** | Sibling has `is_active = false` — should not appear |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| BC ID | Column/Field | Type | Constraints |
|-------|-------------|------|-------------|
| BC-DB-01 | `std_students.is_active` | BOOLEAN | 0 or 1 |
| BC-DB-02 | `std_student_guardian_jnt.relation` | VARCHAR | Father, Mother, Guardian, etc. |
| BC-DB-03 | `std_student_details.blood_group` | VARCHAR | A+, A-, B+, B-, AB+, AB-, O+, O- |
| BC-DB-04 | `std_student_details.gender` | ENUM/VARCHAR | Male, Female, Other |
| BC-DB-05 | `std_student_addresses.address_type` | VARCHAR | Current, Permanent |
| BC-DB-06 | `std_guardians.mobile` | VARCHAR | Contact number |

### BC-UI: UI Display Conditions

| BC ID | Condition | UI Behaviour |
|-------|-----------|-------------|
| BC-UI-01 | No profile record | Personal details table shows empty/dash fields |
| BC-UI-02 | No addresses | Address section shows "No address on record" |
| BC-UI-03 | No guardians | Guardian section shows "No guardians on record" |
| BC-UI-04 | No siblings | Sibling block shows "No siblings found" |
| BC-UI-05 | Sibling is_active = false | Sibling excluded from sibling list |

---

## 6. Test Cases

| TC ID | Test Case | Pre-condition | Test Data | Test Steps | Expected Result | Status |
|-------|-----------|---------------|-----------|------------|----------------|--------|
| TC-ACC-001 | Account page loads with complete profile data | PC-01 to PC-06 satisfied | TD-01 | 1. Login as student with complete profile<br>2. Navigate to `/account` | All tabs render with full data: academic details, personal details, guardians, addresses, siblings | ⬜ |
| TC-ACC-002 | Academic details card displays correctly | PC-01, PC-02 satisfied | TD-01 | 1. Navigate to `/account`<br>2. Check Profile tab | Shows full name (first + middle + last), "Student" badge, admission number, admission date, email, mobile | ⬜ |
| TC-ACC-003 | Personal details table displays all fields | PC-01, PC-02, PC-03 satisfied | TD-01 | 1. Navigate to `/account`<br>2. Check Student Details tab | Shows DOB, gender, blood group, religion, caste, category, mother tongue | ⬜ |
| TC-ACC-004 | Guardian directory shows all linked guardians | PC-05, PC-06 satisfied | TD-01 (2 guardians) | 1. Navigate to `/account`<br>2. Check Guardian/Parent Details tab | Shows both guardians with name, relation (Father/Mother), contact, email, occupation, photo | ⬜ |
| TC-ACC-005 | Single guardian displayed correctly | PC-05, PC-06 satisfied | TD-06 | 1. Navigate to `/account`<br>2. Check Guardian tab | Shows single guardian entry with all fields | ⬜ |
| TC-ACC-006 | Address details show current and permanent addresses | PC-04 satisfied | TD-01 (2 addresses) | 1. Navigate to `/account`<br>2. Check address section | Shows both current and permanent addresses with street, city, state, country, ZIP | ⬜ |
| TC-ACC-007 | Sibling block shows linked siblings | PC-07 satisfied | TD-08 (1 sibling) | 1. Navigate to `/account`<br>2. Check sibling block | Shows sibling name (hyperlink), class-section, roll number, status (Active) | ⬜ |
| TC-ACC-008 | Multiple siblings displayed in sibling block | PC-07 satisfied | TD-09 (3 siblings) | 1. Navigate to `/account`<br>2. Check sibling block | Shows all 3 siblings in table rows | ⬜ |
| TC-ACC-009 | Inactive sibling excluded from sibling block | PC-07 satisfied | TD-10 | 1. Navigate to `/account`<br>2. Check sibling block | Inactive sibling not displayed | ⬜ |
| TC-ACC-010 | No guardian data shows empty state | PC-05 fails | TD-04 | 1. Navigate to `/account`<br>2. Check Guardian tab | Shows "No guardians on record" | ⬜ |
| TC-ACC-011 | No address data shows empty state | PC-04 fails | TD-03 | 1. Navigate to `/account`<br>2. Check address section | Shows "No address on record" | ⬜ |
| TC-ACC-012 | No sibling data shows empty state | PC-07 fails | TD-05 | 1. Navigate to `/account`<br>2. Check sibling block | Shows "No siblings found" | ⬜ |
| TC-ACC-013 | Student not linked to user record | PC-02 fails | TD-02 | 1. Login as user without student record<br>2. Navigate to `/account` | Page may error gracefully or show empty student fields; `$student` is null | ⬜ |
| TC-ACC-014 | Activity log entry created on account view | PC-01, PC-02 satisfied | Any | 1. Navigate to `/account`<br>2. Check activity_logs table | Entry exists with `message = 'Student viewed account details.'` and correct context | ⬜ |
| TC-ACC-015 | Account page accessible only to authenticated users | Varies | — | 1. Logout<br>2. Attempt to access `/account` | Redirected to login page | ⬜ |

---

## 7. Edge Cases

| # | Edge Case | Expected Behaviour |
|---|-----------|-------------------|
| EC-01 | Student has guardian but guardian has no linked user account | Guardian details shown from guardian record directly (name, mobile, email from guardian table) |
| EC-02 | Student has 5+ guardians | All guardians listed in guardian directory |
| EC-03 | Student has multiple addresses of same type (e.g., 2 "Current") | All addresses shown (ordered by type) |
| EC-04 | Student has sibling who is also a guardian's linked student but inactive | Inactive sibling excluded from sibling list |
| EC-05 | Guardian junction has null `relation` field | Relation shown as "—" |
| EC-06 | Personal details field (e.g., mother_tongue) is NULL | Field shown as "—" or empty |
| EC-07 | Address fields partially filled | Each populated field shown; empty fields display "—" |

---

## 8. Test Execution Notes

| # | Note |
|---|------|
| TN-01 | The account page is entirely read-only — no forms, no data mutation |
| TN-02 | Sibling detection involves a separate raw DB query (not an Eloquent relationship) — verify siblings are detected correctly across different guardian combinations |
| TN-03 | Guardian data can come from two sources: the `std_guardians` table directly or the linked `sys_users` record — verify display for both cases |
| TN-04 | The `account()` method does not throw exceptions for missing relationships — verify graceful fallback for each missing relationship |
| TN-05 | Security Settings, Notification Preferences, and Privacy Settings tabs are UI stubs (not functional) — testing these is out of scope |

---

## 9. Test Data Setup Requirements

| # | Setup Requirement |
|---|-------------------|
| TDS-01 | Create a `sys_users` record linked to a `std_students` record |
| TDS-02 | Create a `std_student_details` record for the student |
| TDS-03 | Create `std_student_addresses` records (current + permanent) |
| TDS-04 | Create `std_guardians` records and link via `std_student_guardian_jnt` with different relation types |
| TDS-05 | Create additional students sharing the same guardian IDs for sibling detection |
| TDS-06 | Create a student with `is_active = false` sharing a guardian (for exclusion test) |

---

## 10. Traceability Matrix

| TC ID | Maps To (FRD/BR) | Requirement |
|-------|-----------------|-------------|
| TC-ACC-001 | REQ-STP-029 | Account loads with complete profile |
| TC-ACC-002 | REQ-STP-029 | Academic details card |
| TC-ACC-003 | REQ-STP-029 | Personal details display |
| TC-ACC-004 to 005 | REQ-STP-029 | Guardian directory display |
| TC-ACC-006 | REQ-STP-029 | Address details display |
| TC-ACC-007 to 009 | REQ-STP-029 | Sibling detection and display |
| TC-ACC-010 to 012 | REQ-STP-029 | Empty state handling |
| TC-ACC-013 | BR-STP-001 | Student-less user handling |
| TC-ACC-014 | REQ-STP-029 | Activity logging |
| TC-ACC-015 | REQ-STP-001 | Authentication guard |
