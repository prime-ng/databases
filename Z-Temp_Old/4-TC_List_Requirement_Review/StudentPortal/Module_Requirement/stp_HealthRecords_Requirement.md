# StudentPortal Health Records — Business Requirements

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | StudentPortal (STP) |
| **Tab Group** | Reports / Academic (health-records route under //begin::Academics) |
| **Feature** | Health Records — centralized medical and health profile |
| **URL(s)** | `GET /health-records` |
| **Controller** | `StudentPortalController.healthRecords()` — single method |
| **View** | `studentportal::health.index` |
| **FRD Refs** | REQ-STP-020, BR-STP-001 |
| **Priority** | P1 (Should) |
| **Code Status** | ✅ Implemented |

---

## 2. What This Screen Does

The Health Records screen provides a centralized repository of the student's medical information. It displays core vital statistics (height, weight, BMI, blood group, vision details), medical conditions and allergies (chronic conditions, food/drug allergies, medications), an immunization log table (vaccine name, dose number, administration date, doctor, remarks), a medical history timeline (past procedures, hospitalizations, injuries), and emergency action details (primary responder contact, preferred hospital, special medical instructions). All data is sourced from the student's health profile (`std_student_health_profiles`).

---

## 3. When This Screen Is Used

- During school medical check-ups and health camps
- When a student has a medical emergency and staff need quick access to critical information
- At the start of the school year to verify immunization records are up-to-date
- Before field trips or sports events to review medical conditions and allergies
- When parents/students need to access vaccination records for external requirements

---

## 4. Default Data Load

When the user navigates to the Health Records page, `StudentPortalController@healthRecords()` executes the following eager-loads:

| Data | Source | Relationships Loaded |
|------|--------|---------------------|
| User + Student | `auth()->user()` | `student`, `student.healthProfile` |

The `healthProfile` relationship points to `Modules\StudentProfile\Models\StudentHealthProfile` which stores all health-related data in the `std_student_health_profiles` table. The health profile is a single record per student.

### Data Fields Available

| Category | Fields | Source |
|----------|--------|--------|
| Core Vital Statistics | Height (cm/ft), Weight (kg), BMI, Blood Group, Vision (Left/Right) | `healthProfile` |
| Medical Conditions | Chronic conditions, Food/Drug Allergies, Medications | `healthProfile` |
| Immunization Log | Vaccine Name, Dose Number, Administration Date, Doctor, Remarks | `healthProfile` (JSON or related table) |
| Medical History | Date, Diagnosis, Doctor, Description | `healthProfile` (JSON or related table) |
| Emergency Action | Emergency contact, Preferred Hospital, Special Instructions | `healthProfile` |

---

## 5. UI Components / Screen Structure

| Component | Description |
|-----------|-------------|
| **Core Vital Statistics Card** | Height, weight, BMI, blood group, vision details — displayed as a summary grid |
| **Medical Conditions & Allergies Section** | Chronic conditions list, food/drug allergies, current medications |
| **Immunization Log Table** | Tabular list of vaccines with dose numbers, dates, doctor, remarks |
| **Medical History Timeline** | Chronological list of past procedures, hospitalizations, injuries |
| **Emergency Action Details Card** | Primary emergency responder contact, preferred hospital, special instructions |

---

## 6. Data Tables / Fields Displayed

### Core Vital Statistics

| Field | Detail |
|-------|--------|
| Height | In cm / feet-inches |
| Weight | In kg |
| BMI | Calculated body mass index |
| Blood Group | A+, A-, B+, B-, AB+, AB-, O+, O- |
| Vision (Left Eye) | Vision diagnostic notes |
| Vision (Right Eye) | Vision diagnostic notes |

### Medical Conditions & Allergies

| Field | Detail |
|-------|--------|
| Chronic Conditions | Diagnosed terms (asthma, diabetes, epilepsy, etc.) |
| Food Allergies | Allergen list (peanuts, dairy, gluten, etc.) |
| Drug Allergies | Medication allergens (penicillin, sulfa, etc.) |
| Medications | Mandatory drugs administered during school hours (name, dosage, timing) |

### Immunization Log Columns

| Column | Detail |
|--------|--------|
| Vaccine Name | e.g., DPT, Polio, Measles, Hepatitis B |
| Dose Number | 1st, 2nd, Booster |
| Administration Date | Date vaccine was given |
| Doctor Name | Administering physician |
| Remarks | Any notes or reactions |

### Medical History Timeline Fields

| Field | Detail |
|-------|--------|
| Date | Date of event (procedure, hospitalization, injury) |
| Diagnosis | Medical diagnosis |
| Doctor | Attending physician |
| Description | Detailed description of the event |

### Emergency Action Details

| Field | Detail |
|-------|--------|
| Emergency Contact Name | Primary responder name |
| Emergency Contact Phone | Contact number |
| Preferred Hospital | Hospital name and location |
| Special Instructions | Medical alerts, precautions, care instructions |

---

## 7. Business Rules and Conditions

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-STP-001 | All data must belong to the authenticated student | Data isolation through `auth()->user()->student` chain |
| — | Health profile is a single record per student | One-to-one relationship between `std_students` and `std_student_health_profiles` |
| — | All fields are read-only — no edit/save operations | No form submission on this page |
| — | Immunization log may be stored as JSON in health profile | Display depends on data structure |

---

## 8. Workflow Steps

**Typical Health Records Session:**
1. Student navigates to Health Records from Reports or quick navigation
2. System loads the student's health profile
3. Student can view vital statistics (height, weight, BMI, blood group)
4. Student reviews medical conditions and allergies to confirm accuracy
5. Student checks immunization log for completeness before an external requirement
6. Student reviews emergency action details for school records

---

## 9. Example Scenario

Meera, a Class 7 student, opens her Health Records page. She sees:

- **Vital Statistics:** Height 152 cm, Weight 42 kg, BMI 18.2, Blood Group B+, Vision L: 6/6, R: 6/6
- **Medical Conditions:** Mild asthma (controlled with inhaler), No known allergies
- **Medications:** Inhaler (Salbutamol) — 2 puffs before PE class
- **Immunization Log:**
  | Vaccine | Dose | Date | Doctor | Remarks |
  |---------|------|------|--------|---------|
  | DPT | 1st | 02-06-2015 | Dr. Sharma | No reaction |
  | DPT | 2nd | 10-08-2015 | Dr. Sharma | No reaction |
  | MMR | 1st | 15-01-2016 | Dr. Gupta | — |
- **Medical History:** None significant
- **Emergency Action:** Contact: Mrs. Ananya Rao (Mother) — 9876543210; Preferred Hospital: City Children's Hospital; Instructions: Keep inhaler accessible at all times

---

## 10. Related Screens

- **Student ID Card** (`/student-id-card`) — Shows blood group and emergency contact
- **Account Settings** (`/account`) — Profile information
- **Academic Information** (`/academic-information`) — Academic records (health profile loaded but not displayed)

---

## 11. Requirements (MUST)

- The system MUST display core vital statistics: height, weight, BMI, and blood group
- The system MUST display vision details for both eyes
- The system MUST display medical conditions including chronic conditions, food/drug allergies, and current medications
- The system MUST display an immunization log with vaccine name, dose number, administration date, doctor, and remarks
- The system MUST display a medical history timeline with date, diagnosis, doctor, and description
- The system MUST display emergency action details: contact name, phone, preferred hospital, special instructions
- The system MUST scope all data to the authenticated student (BR-STP-001)

---

## 12. Who Can Access This Screen

| Role | Access | Notes |
|------|--------|-------|
| Student | ✅ Full | Authenticated via standard auth guard |
| Parent | 🟡 Planned | Parent portal mode in development |
| Teacher/Admin | ❌ No | Health records managed through StudentProfile admin module |

---

## 13. How This Screen Works — Logic Flow (Non-Technical)

When a student opens the Health Records page, the system loads the student's user record along with their linked `StudentHealthProfile`. This profile is a single record in the `std_student_health_profiles` table, linked one-to-one with the student. The profile contains all medical fields stored as individual columns or structured data (JSON) for immunization history and medical timeline.

The system passes the health profile data to the view, which renders it in structured sections: vital statistics at the top, followed by medical conditions and allergies, immunization log, medical history, and emergency action details at the bottom.

---

## 14. Validate Before Save

No data entry occurs on this screen. It is a read-only display screen with no forms to validate.

---

## 15. Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| No health profile exists for student | "No health records found" or similar empty state | Informational |
| Individual field is null/empty within existing profile | Field shows "—" or "Not recorded" | Informational |
| Immunization log is empty | "No immunization records available" | Informational |
| Medical history is empty | "No medical history recorded" | Informational |

---

## 16. Dependencies

### Source Tables Read

| Table | Module | Data Used |
|-------|--------|-----------|
| `std_student_health_profiles` | StudentProfile | All health fields: height, weight, BMI, blood group, vision, conditions, allergies, medications, immunization log, medical history, emergency contacts |

### Model Used

- `Modules\StudentProfile\Models\StudentHealthProfile` — One-to-one relationship with `std_students`

### Fields (std_student_health_profiles)

| Column | Type | Description |
|--------|------|-------------|
| `id` | INT UNSIGNED | PK |
| `student_id` | INT UNSIGNED | FK to `std_students.id` |
| `height` | DECIMAL | Height in cm |
| `weight` | DECIMAL | Weight in kg |
| `bmi` | DECIMAL | Calculated BMI |
| `blood_group` | VARCHAR | A+, A-, B+, B-, AB+, AB-, O+, O- |
| `vision_left` | VARCHAR | Left eye vision |
| `vision_right` | VARCHAR | Right eye vision |
| `chronic_conditions` | TEXT/JSON | Diagnosed medical conditions |
| `allergies` | TEXT/JSON | Food and drug allergies |
| `medications` | TEXT/JSON | Current medications |
| `immunization_log` | JSON/TEXT | Vaccination history records |
| `medical_history` | JSON/TEXT | Past procedures and hospitalizations |
| `emergency_contact_name` | VARCHAR | Primary responder name |
| `emergency_contact_phone` | VARCHAR | Emergency phone number |
| `preferred_hospital` | VARCHAR | Hospital name |
| `special_instructions` | TEXT | Medical alerts and precautions |
