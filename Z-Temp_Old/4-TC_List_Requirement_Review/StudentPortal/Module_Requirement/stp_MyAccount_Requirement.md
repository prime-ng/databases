# StudentPortal My Account — Business Requirements

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | StudentPortal (STP) |
| **Tab Group** | Account |
| **Feature** | My Account / Account Settings — student profile, guardians, siblings, security |
| **URL(s)** | `GET /account` |
| **Controller** | `StudentPortalController.account()` — single method |
| **View** | `studentportal::account.index` |
| **FRD Refs** | REQ-STP-029, BR-STP-035, BR-STP-036 |
| **Priority** | P2 (Could) |
| **Code Status** | 🟡 Implemented (backend complete; security/notification preference tabs are stubs) |

---

## 2. What This Screen Does

The Account Settings screen displays the student's complete profile information in a read-only multi-tab layout. It shows academic details (name, admission number, email, mobile), personal demographics (DOB, gender, blood group, religion, caste, category, mother tongue), a guardian directory with contact information, residential addresses (current and permanent), and a sibling verification block showing other students linked to the same guardians. Security Settings, Notification Preferences, and Privacy Settings tabs are planned but not yet implemented.

---

## 3. When This Screen Is Used

- When a student wants to verify or view their personal and academic details
- To check linked guardian information and contact details
- To view siblings enrolled in the same school
- To access address details (current and permanent)
- (Planned) To change password, update notification preferences, or manage privacy settings

---

## 4. Default Data Load

When the user navigates to the Account page, `StudentPortalController@account()` executes the following eager-loads:

| Data | Source | Relationships Loaded |
|------|--------|---------------------|
| User | `auth()->user()` | `student`, `student.profile`, `student.addresses`, `student.studentGuardianJnts`, `student.sessions`, `student.guardians.user` |
| Student | `user.student` | Core student record (first_name, middle_name, last_name, admission_no, admission_date, email, mobile) |
| Profile (Personal Details) | `student.profile` | DOB, gender, blood_group, religion, caste, category, mother_tongue |
| Addresses | `student.addresses` | Current and permanent address (city, state, country, zip, street) |
| Guardians | `student.guardians` via `studentGuardianJnts` | guardian name, relation, contact, email, occupation, photo |
| Siblings | DB query on `std_student_guardian_jnt` | Other students sharing same guardian IDs (name, class-section, roll number, status) |

---

## 5. UI Components / Screen Structure

| Component | Description |
|-----------|-------------|
| **Profile Information Tab** | Student avatar, full name, role/type badge, admission number, admission date, email, mobile number |
| **Student Details Tab** | Academic details card + personal details table (DOB, gender, blood group, religion, caste, category, mother tongue) |
| **Guardian Information Tab** | Guardian directory card showing all linked guardians with name, relation, contact, email, occupation, photo |
| **Parent Details Tab** | Same guardian data presented in parent-focused layout |
| **Address Details Card** | Current address and permanent address sections with city, state, country, ZIP, street |
| **Sibling Verification Block** | Table of siblings: name (hyperlink), class & section, roll number, current status (Active/Inactive) |

---

## 6. Data Tables / Fields Displayed

### Academic Details Card

| Field | Source |
|-------|--------|
| Full Name | `first_name` + `middle_name` + `last_name` |
| Role/Type | "Student" (hardcoded) |
| Admission Number | `admission_no` |
| Admission Date | `admission_date` |
| Email | `user.email` |
| Mobile Number | `student.mobile` or `user.mobile` |

### Personal Details Table

| Field | Source |
|-------|--------|
| Date of Birth | `profile.date_of_birth` |
| Gender | `profile.gender` (Male/Female/Other) |
| Blood Group | `profile.blood_group` |
| Religion | `profile.religion` |
| Caste | `profile.caste` |
| Category | `profile.category` |
| Mother Tongue | `profile.mother_tongue` |

### Guardian Directory Fields

| Field | Source |
|-------|--------|
| Full Name | `guardian.name` |
| Relation | `studentGuardianJnt.relation` (Father, Mother, Guardian, etc.) |
| Contact | `guardian.mobile` |
| Email | `guardian.email` |
| Occupation | `guardian.occupation` |
| Photo | `guardian.avatar` |

### Address Fields

| Field | Source |
|-------|--------|
| Street Address | `address.street_address` |
| City | `address.city` |
| State | `address.state` |
| Country | `address.country` |
| ZIP/Pincode | `address.pincode` |

### Sibling Table Columns

| Column | Detail |
|--------|--------|
| Sibling Name | Hyperlink to sibling mini profile (or student view) |
| Class & Section | `sibling.sessions.classSection.class.name` + `section.name` |
| Roll Number | `sibling.roll_number` |
| Current Status | Active/Inactive badge |

---

## 7. Business Rules and Conditions

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-STP-001 | All data must belong to the authenticated student | Data isolation through `auth()->user()->student` chain |
| BR-STP-035 | Password change must verify current password | (Planned — not implemented) |
| BR-STP-036 | Notification preferences must be persistable per user | (Planned — not implemented) |
| — | Sibling detection via shared guardian IDs | Queries `std_student_guardian_jnt` for students sharing guardians |
| — | Only active siblings shown | `where('is_active', true)` filter on sibling query |
| — | All fields read-only — no edit/save operations | No form submission on this page |

---

## 8. Workflow Steps

**Typical Account Viewing Session:**
1. Student clicks "Account Settings" from dashboard profile card or navigation
2. System loads user with all related student data, guardians, addresses, and siblings
3. Student views their academic and personal details on the Profile tab
4. Student switches to Guardian tab to verify parent contact information
5. Student switches to Address tab to confirm current and permanent addresses
6. Student views sibling block to see brothers/sisters enrolled at the same school

---

## 9. Example Scenario

Priya, a Class 8-A student, navigates to her Account Settings page. She sees:
- **Profile Tab:** "Priya S. Sharma", Student, Admission No. 2024-087, Email: priya.sharma@email.com, Mobile: 9876543210
- **Personal Details:** DOB: 15-06-2012, Gender: Female, Blood Group: B+, Religion: Hindu, Caste: General, Mother Tongue: Hindi
- **Guardians:** Mr. Rajesh Sharma (Father), 9876543211; Mrs. Anjali Sharma (Mother), 9876543212
- **Address:** 42, Sunshine Apartments, MG Road, Bangalore, Karnataka — 560001
- **Siblings:** Arjun Sharma (Class 5-C, Roll No. 12, Active)

---

## 10. Related Screens

- **Dashboard** (`/dashboard`) — Profile card linking to Account Settings
- **Student ID Card** (`/student-id-card`) — Digital ID card with photo and identifiers
- **Health Records** (`/health-records`) — Medical and health profile
- **Academic Information** (`/academic-information`) — Academic history and marksheets

---

## 11. Requirements (MUST)

- The system MUST display the student's full name (first + middle + last) with role type
- The system MUST display admission number, admission date, email, and mobile number
- The system MUST display personal details: DOB, gender, blood group, religion, caste, category, mother tongue
- The system MUST display all linked guardians with name, relation, contact, email, occupation, and photo
- The system MUST display current and permanent addresses with city, state, country, ZIP, and street
- The system MUST display siblings sharing the same guardians with name, class-section, roll number, and status
- The system MUST scope all data to the authenticated student (BR-STP-001)

---

## 12. Who Can Access This Screen

| Role | Access | Notes |
|------|--------|-------|
| Student | ✅ Full | Authenticated via standard auth guard |
| Parent | 🟡 Planned | Parent portal mode in development |
| Teacher/Admin | ❌ No | Separate user management interfaces |

---

## 13. How This Screen Works — Logic Flow (Non-Technical)

When a student opens Account Settings, the system loads the logged-in user's record along with their linked student profile, personal details table, all residential addresses, guardian relationships (and the guardian's own user accounts), and all academic sessions the student has been part of.

The system then performs an additional query: it looks up all guardian IDs linked to this student, then finds all other students who share any of those same guardian IDs. These are the student's siblings. Only siblings with active enrollment status are shown.

All this information is passed to a read-only view with multiple tabs. No forms can be submitted from this page — it is purely for viewing.

---

## 14. Validate Before Save

No data entry occurs on this screen as of current implementation. Security Settings (password change) and Notification Preferences tabs are planned but not yet functional.

---

## 15. Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Student record not linked to user | Profile fields show "—" or empty | Informational |
| No personal details record | Personal details table shows empty fields | Informational |
| No addresses configured | Address sections show "No address on record" | Informational |
| No guardians linked | Guardian directory shows "No guardians on record" | Informational |
| No siblings found | Sibling block shows "No siblings found" | Informational |
| Guardian has no linked user account | Guardian contact shown from guardian record (not user) | Informational |

---

## 16. Dependencies

### Source Tables Read

| Table | Module | Data Used |
|-------|--------|-----------|
| `sys_users` | SystemConfig | User identity |
| `std_students` | StudentProfile | Core student record |
| `std_student_details` | StudentProfile | Personal details (DOB, gender, blood group, etc.) |
| `std_student_addresses` | StudentProfile | Current and permanent addresses |
| `std_student_guardian_jnt` | StudentProfile | Guardian relationship junction |
| `std_guardians` | StudentProfile | Guardian identity and contact |
| `std_student_academic_sessions` | StudentProfile | Academic session history |

### Models/Relationships Used

- `auth()->user()` — Authenticated user
- `user.student` — Student record
- `student.profile` — `StudentDetail` model
- `student.addresses` — `StudentAddress` collection
- `student.studentGuardianJnts` — Guardian junction records
- `student.guardians.user` — Guardian user accounts
- `student.sessions` — Academic session history
- Raw DB query on `std_student_guardian_jnt` — Sibling detection
