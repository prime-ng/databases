# Sick Bay — Business Requirements

## What This Screen Does

The Sick Bay screen manages the complete lifecycle of student admissions to the hostel's sick bay / infirmary. When a student falls ill, they are admitted to the sick bay, their symptoms and diagnosis are recorded, treatment is administered, and they are discharged when recovered. Vitals and medications are tracked throughout the stay.

---

## When This Screen Is Used

- Student falls ill during the night / early morning
- Student needs rest and monitoring for minor illness
- Student returns from hospital and needs recovery monitoring
- Parent notification about student's health status
- Hospital referral for serious cases

---

## Key Fields

- **Student** — Admitted student
- **Admission Date & Time** — When admitted to sick bay
- **Symptoms** — Presenting symptoms
- **Diagnosis** — Diagnosis by attending staff/doctor
- **Treatment Notes** — Treatment administered
- **Attending Staff** — Nurse/warden who attended
- **Hospital Referral** — Whether referred to hospital
- **Parent Notified** — Whether parent was informed
- **Discharge Date & Time** — When discharged
- **Discharge Summary** — Summary at discharge
- **Status** — Admitted / Under Observation / Discharged / Referred

---

## Business Rules

- Parent must be notified within 30 minutes of admission
- Hospital referral is auto-triggered for critical symptoms
- Vital signs are recorded periodically during stay (linked to Tab 31)
- Medications administered are logged (linked to Tab 32)
- Sick bay admissions are confidential — only relevant staff can view
- Recurring illness patterns for a student can be flagged

---

## Workflow Steps

**Admission**
Warden/nurse admits student, records symptoms, diagnoses, notifies parent.

**Monitoring**
During stay, vitals are checked periodically, medications administered.

**Discharge**
Doctor/warden clears student for discharge, records discharge summary.

**Referral**
If condition is serious, student is referred to hospital, referral details documented.

---

## Related Screens

- **Sick Bay Vitals** (Tab 31) — Vital sign readings during admission
- **Sick Bay Medications** (Tab 32) — Medication logs
- **Incidents** (Tab 27) — Incidents involving injury may lead to sick bay
