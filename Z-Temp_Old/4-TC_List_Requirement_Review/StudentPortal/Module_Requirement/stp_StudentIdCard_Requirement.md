# StudentPortal Student ID Card — Business Requirements

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | StudentPortal (STP) |
| **Tab Group** | Reports |
| **Feature** | Student ID Card — secure digital identity card |
| **URL(s)** | `GET /student-id-card` |
| **Controller** | `StudentPortalController.idCard()` — single method |
| **View** | `studentportal::id-card.index` |
| **FRD Refs** | REQ-STP-021, RPT-STP-004 |
| **Priority** | P1 (Should) |
| **Code Status** | 🟡 Implemented (PDF download route not defined) |

---

## 2. What This Screen Does

The Student ID Card screen renders a secure virtual identity card containing the student's photograph, full name, academic identifiers (class, section, roll number, admission number), health information (blood group), emergency contact, academic session, and a QR barcode. The ID card is designed to be printed or downloaded as a PDF for physical use (PDF route planned but not yet implemented). All data is scoped to the authenticated student.

---

## 3. When This Screen Is Used

- At the start of a new academic year when students need updated ID cards
- When a student loses their physical ID card and needs a replacement
- For verification purposes during school events, exams, or transportation
- To share emergency contact information with school staff
- As a quick reference for blood group and medical information

---

## 4. Default Data Load

When the user navigates to the ID Card page, `StudentPortalController@idCard()` executes the following eager-loads:

| Data | Source | Relationships Loaded |
|------|--------|---------------------|
| User + Student | `auth()->user()` | `student`, `student.healthProfile`, `student.addresses`, `student.studentGuardianJnts.guardian`, `student.currentSession.classSection.class`, `student.currentSession.classSection.section`, `student.currentSession.academicSession` |

### Data Fields Used

| Field | Source | Display Location |
|-------|--------|-----------------|
| School Logo & Name | System config / SchoolSetup | Header section |
| Verification Tag | "STUDENT" (hardcoded) | Header section |
| Student Photo | `student.avatar` or user avatar | Body — circular, centred |
| Full Name | `student.first_name` + `middle_name` + `last_name` | Body |
| Class & Section | `currentSession.classSection.class.name` + `section.name` | Body — e.g., "Class X - Section B" |
| Roll Number | `student.roll_number` | Body |
| Admission Number | `student.admission_no` | Body |
| Academic Session | `currentSession.academicSession.name` | Footer |
| Blood Group | `student.healthProfile.blood_group` | Footer — marked clearly |
| Emergency Contact | First guardian's phone number | Footer |
| Principal Signature | School config / media | Signature box |

---

## 5. UI Components / Screen Structure

| Component | Description |
|-----------|-------------|
| **Header Section** | School logo + organization name; "STUDENT" verification tag |
| **Body Section** | Student photo (circular, centred); full name; class & section; roll number; admission number |
| **Footer Section** | Emergency contact phone; blood group (prominent); academic session |
| **Signature Box** | Head of School / Principal signature image |
| **Action Buttons** | "Download PDF" / "Print ID Card" button |
| **QR Barcode** | Unique code/barcode for digital verification |

---

## 6. Data Tables / Fields Displayed

### ID Card Fields

| Field | Detail | Source |
|-------|--------|--------|
| School Name | Organization name | System config |
| Card Type | "STUDENT" | Hardcoded |
| Photo | Student image | `student.avatar` or `user.profile_photo_url` |
| Student Name | Full name (First Middle Last) | `student.first_name`, `middle_name`, `last_name` |
| Class | Class name | `currentSession.classSection.class.name` |
| Section | Section name | `currentSession.classSection.section.name` |
| Roll Number | Unique roll number | `student.roll_number` |
| Admission No | System-generated ID | `student.admission_no` |
| Blood Group | Blood group label | `student.healthProfile.blood_group` |
| Emergency Contact | Guardian phone | First guardian's `mobile` from `studentGuardianJnts` |
| Academic Session | Session label | `currentSession.academicSession.name` |
| Principal Signature | Signature image | School/media config |

---

## 7. Business Rules and Conditions

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-STP-001 | All data must belong to the authenticated student | Data isolation through `auth()->user()->student` chain |
| — | Photo displayed with circular border, centred | CSS styling on avatar/image element |
| — | Blood group marked prominently (e.g., coloured badge) | Distinct visual treatment for medical information |
| — | Emergency contact sourced from first linked guardian | First guardian in `studentGuardianJnts` order |
| — | QR barcode encodes a unique student identifier | (Planned — implementation dependent on system config) |

---

## 8. Workflow Steps

**Typical ID Card Viewing/Download Session:**
1. Student navigates to ID Card from Reports section or quick navigation
2. System loads student data with health profile, addresses, guardians, and current session
3. Digital ID card renders with all fields populated
4. Student can view the card on screen
5. Student clicks "Download PDF" or "Print ID Card" (planned — currently no PDF endpoint)
6. PDF is generated and downloaded (or print dialog opens)

---

## 9. Example Scenario

Arjun, a Class 9-A student, opens his digital ID card. He sees:

```
┌─────────────────────────────────────┐
│  🌟 Sunshine International School   │
│         ★ STUDENT ★                 │
│                                     │
│          [Photo]                     │
│        Arjun K. Sharma              │
│     Class IX - Section A            │
│     Roll No: 15  |  Adm: 2023-089  │
│                                     │
│  🩸 Blood Group: O+                 │
│  📞 Emergency: 9876543210           │
│  📅 Session: 2025-2026              │
│                                     │
│  ┌─────────┐                        │
│  │ [QR]    │   [Principal's Sig]    │
│  └─────────┘                        │
│                                     │
│  [Download PDF]  [Print]            │
└─────────────────────────────────────┘
```

---

## 10. Related Screens

- **Account Settings** (`/account`) — Profile information used in ID card
- **Health Records** (`/health-records`) — Detailed health and medical information
- **Progress Card** (`/progress-card`) — Academic progress report for the session

---

## 11. Requirements (MUST)

- The system MUST display the school logo and organization name on the ID card header
- The system MUST display "STUDENT" as the verification tag
- The system MUST display the student's photo in a circular, centred format
- The system MUST display the student's full name (first + middle + last)
- The system MUST display class and section (e.g., "Class X - Section B")
- The system MUST display the student's roll number and admission number
- The system MUST display the blood group prominently on the card
- The system MUST display the emergency contact phone number from the first linked guardian
- The system MUST display the current academic session label
- The system MUST display the Principal/Head of School signature image
- The system MUST provide a "Download PDF" or "Print ID Card" action button
- The system MUST scope all data to the authenticated student (BR-STP-001)

---

## 12. Who Can Access This Screen

| Role | Access | Notes |
|------|--------|-------|
| Student | ✅ Full | Authenticated via standard auth guard |
| Parent | 🟡 Planned | Parent portal mode in development |
| Teacher/Admin | ❌ No | Separate ID card generation interfaces in admin |

---

## 13. How This Screen Works — Logic Flow (Non-Technical)

When a student opens the ID Card page, the system loads the student's complete profile including their photograph, health records (for blood group), addresses, guardian information (for emergency contact), and current academic session with class and section details.

The system passes all this data to a dedicated ID card view template. The template renders a styled card layout with a header (school identity), body (student photo and identifiers), and footer (medical info, emergency contact, session). The student can view this card on screen.

For PDF generation (planned), the system would convert the card layout into a downloadable PDF document using a library like DomPDF, preserving the card's visual design and all embedded data.

---

## 14. Validate Before Save

No data entry occurs on this screen. It is a read-only display screen with no forms to validate.

---

## 15. Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Student has no photo/avatar | Default avatar placeholder shown | Informational |
| No health profile (blood group missing) | Blood group field shows "—" or "Not recorded" | Informational |
| No guardians linked for emergency contact | Emergency contact shows "Not available" | Informational |
| No current academic session | Class/section/session fields show "—" | Informational |
| No principal signature configured | Signature box shown as empty placeholder | Informational |

---

## 16. Dependencies

### Source Tables Read

| Table | Module | Data Used |
|-------|--------|-----------|
| `std_students` | StudentProfile | Student name, admission_no, roll_number, avatar |
| `std_student_details` | StudentProfile | Blood group |
| `std_student_addresses` | StudentProfile | Address (loaded but may not be displayed) |
| `std_student_guardian_jnt` | StudentProfile | Guardian junction for emergency contact |
| `std_guardians` | StudentProfile | Guardian phone number |
| `std_student_academic_sessions` | StudentProfile | Current session reference |
| `sch_classes` | SchoolSetup | Class name |
| `sch_sections` | SchoolSetup | Section name |
| `std_student_health_profiles` | StudentProfile | Blood group, medical info |
| System config | SystemConfig | School name, logo, principal signature |

### Models/Relationships Used

- `auth()->user()->student` — Core student identity
- `student.healthProfile` — Blood group
- `student.addresses` — Address data
- `student.studentGuardianJnts.guardian` — Guardian contact for emergency number
- `student.currentSession.classSection.class` — Class name
- `student.currentSession.classSection.section` — Section name
- `student.currentSession.academicSession` — Session label
