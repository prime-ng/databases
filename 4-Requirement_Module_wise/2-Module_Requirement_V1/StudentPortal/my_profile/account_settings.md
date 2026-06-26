# My Profile — Account Settings Tab Requirements

## 1. Functional Overview
The **Account Settings** tab displays read-only details of the student's academic profile, personal parameters, linked guardians, residential address data, and sibling links.

---

## 2. Page Structure & Form Parameters

### A. Academic Details Card
- **Full Name**: Combines first name, middle name, and last name.
- **Role/Type**: Student.
- **Admission Number**: System-generated identifier (`admission_no`).
- **Admission Date**: Date when enrolled.
- **Email**: Active login email.
- **Mobile Number**: Contact number.

### B. Personal Details Table
- **Date of Birth**: Student DOB.
- **Gender**: Male / Female / Other.
- **Blood Group**: Selected blood group.
- **Religion, Caste, Category**: Core demographic classifications.
- **Mother Tongue**: Native language of the student.

### C. Guardian Directory Card
- Displays all linked guardians:
  - **Full Name**: Guardian name.
  - **Relation**: Father, Mother, Guardian, etc.
  - **Contact & Email**: Contact phone and email addresses.
  - **Occupation**: Occupation details.
  - **Photo**: Guardian avatar image.

### D. Address Details
- **Current Address**: City, State, Country, ZIP, and Street Address.
- **Permanent Address**: Address details matching official documents.

### E. Sibling Verification Block
- Queries other students that share the same guardian IDs.
- **Table Columns**:
  - Sibling Name (hyperlink to sibling mini profile)
  - Class & Section
  - Roll Number
  - Current Status (Active/Inactive)

---

## 3. Database & Model Reference
- **Model**: [Student](file:///c:/laragon/www/prime_ai/Modules/StudentProfile/app/Models/Student.php) (Namespace `Modules\StudentProfile\Models\Student`)
- **Relationships**:
  - `profile`
  - `addresses`
  - `studentGuardianJnts.guardian`
  - `sessions`
  - `studentDetail`
- **Tables**:
  - `std_students`
  - `std_student_details`
  - `std_student_addresses`
  - `std_student_guardian_jnt`
  - `std_guardians`
