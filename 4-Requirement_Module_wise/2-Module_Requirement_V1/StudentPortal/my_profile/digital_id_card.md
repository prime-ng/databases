# My Profile — Digital ID Card Tab Requirements

## 1. Functional Overview
Renders a secure virtual student identity card containing the student's photo, academic identifiers, health indicators, emergency contacts, and a unique QR barcode.

---

## 2. Card Components & Layout Rules
- **Header Section**:
  - School Logo & Organization Name.
  - Verification Tag (e.g. "STUDENT").
- **Body Section**:
  - Student Photo (circular border, centered).
  - Student Full Name.
  - Class & Section (e.g., "Class X - Section B").
  - Roll Number.
  - Admission Number / Student ID.
- **Footer Section**:
  - Emergency Contact Phone Number.
  - Student's Blood Group (marked clearly).
  - Academic Session (e.g. "2025-2026").
- **Signature Box**: Head of School/Principal signature image.
- **Print Option**: "Download PDF" / "Print ID Card" button.

---

## 3. Database References
- **Models**:
  - `Modules\StudentProfile\Models\Student`
  - `Modules\StudentProfile\Models\StudentDetail`
- **Fields**:
  - `std_students.first_name`
  - `std_students.last_name`
  - `std_students.admission_no`
  - `std_student_details.blood_group`
  - `std_student_details.avatar`
