# My Profile — Health Records Tab Requirements

## 1. Functional Overview
Provides a centralized repository of the student's medical statistics, emergency action plans, vaccination records, and historical health diagnoses.

---

## 2. Records Sections & Parameters

### A. Core Vital Statistics
- **Height**: In cm / feet.
- **Weight**: In kg.
- **BMI Status**: Calculated body mass index.
- **Blood Group**: Confirmed group.
- **Vision Details**: Left Eye / Right Eye vision diagnostics notes.

### B. Medical Conditions & Allergies
- **Chronic Conditions**: Diagnosed terms (asthma, diabetes, etc.).
- **Food/Drug Allergies**: Detailed list of allergens.
- **Medications**: Mandatory drugs administered during school hours.

### C. Immunization Log Table
- **Columns**:
  - Vaccine Name
  - Dose Number
  - Administration Date
  - Doctor Name/Signature
  - Remarks

### D. Medical History Timeline
- Displays past procedures, hospitalizations, or injuries.
- **Fields**: Date, Diagnosis, Doctor, Description.

### E. Emergency Action Details
- Name and contact details of the primary emergency responder.
- Preferred hospital name.
- Special medical instructions or notices.

---

## 3. Database References
- **Model**: `Modules\StudentProfile\Models\StudentHealthProfile`
- **Table**: `std_student_health_profiles`
- **Relationships**: Linked to `std_students.id`.
