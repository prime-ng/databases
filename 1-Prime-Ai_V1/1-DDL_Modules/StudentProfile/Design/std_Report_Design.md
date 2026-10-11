# Student Profile Report Designs (Deliverable E)

## 1. CLASS-WISE STUDENT STRENGTH REPORT

**What this Report Covers**
- Breakdown of student count per Class and Section.
- Gender-wise distribution (Boys/Girls).
- Category-wise distribution (General/OBC/SC/ST).

**Useful For**
- Principal
- Academic Coordinator
- Transport Manager (for capacity planning)

**Fields Shown**
- Class Name
- Section
- Total Students
- Boys Count
- Girls Count
- General
- OBC/SC/ST
- RTE/EWS
- Class Teacher

**Tables Used**
- `std_student_academic_sessions` (for current class allocation)
- `sch_class_section_jnt`
- `std_students` (Gender)
- `std_student_profiles` (Category/Caste)

**Filters**
- Academic Session
- Class (Range)

**MySQL Query (Reference)**
```sql
SELECT 
    cls.name AS class_name,
    sec.name AS section_name,
    COUNT(s.id) AS total_students,
    SUM(CASE WHEN s.gender = 'Male' THEN 1 ELSE 0 END) AS boys,
    SUM(CASE WHEN s.gender = 'Female' THEN 1 ELSE 0 END) AS girls,
    SUM(CASE WHEN p.caste_category IN (SELECT id FROM sys_dropdown_table WHERE value='General') THEN 1 ELSE 0 END) AS general_cat
FROM std_student_academic_sessions sas
JOIN std_students s ON s.id = sas.student_id
JOIN sch_class_section_jnt csj ON csj.id = sas.class_section_id
JOIN sch_classes cls ON cls.id = csj.class_id
JOIN sch_sections sec ON sec.id = csj.section_id
LEFT JOIN std_student_profiles p ON p.student_id = s.id
WHERE sas.is_current = 1 AND s.is_active = 1
GROUP BY cls.ordinal, sec.ordinal, cls.name, sec.name
ORDER BY cls.ordinal, sec.ordinal;
```

**Charts (📊)**
- Stacked Bar Chart: Strength by Class (Gender Split)

---

## 2. ADMISSION REGISTER REPORT

**What this Report Covers**
- List of new admissions in a given date range.
- Details required for government submission/audit.
- Previous school details.

**Useful For**
- Administrative Office
- Audit Team

**Fields Shown**
- Admission No
- Admission Date
- Student Name
- DOB
- Gender
- Father Name
- Mother Name
- Address
- Previous School Name
- TC Number (if submitted)

**Tables Used**
- `std_students`
- `std_guardians`
- `std_previous_education`

**Filters**
- Admission Date Range
- Class

---

## 3. STUDENT MEDICAL PROFILE & EXCEPTIONS

**What this Report Covers**
- List of students with specific medical conditions or allergies.
- Students without updated vaccination records.
- Recent medical incidents at school.

**Useful For**
- School Nurse
- Physical Education Teachers

**Fields Shown**
- Student Name
- Class-Section
- Blood Group
- Allergies
- Chronic Conditions
- Emergency Contact Name
- Emergency Contact Mobile

**Filters**
- Health Condition (Has Allergy / Has Condition)
- Blood Group

**MySQL Query (Reference)**
```sql
SELECT 
    s.first_name, s.last_name,
    CONCAT(cls.name, '-', sec.name) AS class_sec,
    h.blood_group,
    h.allergies,
    h.chronic_conditions,
    g.first_name AS emergency_contact,
    g.mobile_no
FROM std_health_profiles h
JOIN std_students s ON s.id = h.student_id
JOIN std_student_academic_sessions sas ON sas.student_id = s.id AND sas.is_current=1
JOIN sch_class_section_jnt csj ON csj.id = sas.class_section_id
JOIN sch_classes cls ON cls.id = csj.class_id
JOIN sch_sections sec ON sec.id = csj.section_id
JOIN std_student_guardian_jnt sgj ON sgj.student_id = s.id AND sgj.is_emergency_contact=1
JOIN std_guardians g ON g.id = sgj.guardian_id
WHERE h.allergies IS NOT NULL OR h.chronic_conditions IS NOT NULL;
```
