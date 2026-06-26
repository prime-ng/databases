# Sick Bay Medications — Business Requirements

## What This Screen Does

The Sick Bay Medications screen logs every medication administered to a student during their sick bay stay. Each entry records the medication name, dosage, route, prescriber, administrator, and time. This ensures accurate medication tracking and prevents missed or double doses.

---

## When This Screen Is Used

- Administering prescribed medication to a sick bay patient
- Recording over-the-counter medication given for minor symptoms
- Handover between shifts: reviewing what medications have been given
- Medical audit: verifying medication administration records

---

## Key Fields

- **Sick Bay Admission** — Which admission this belongs to
- **Medication Name** — Name of the medication
- **Dosage** — Dosage amount (e.g., "500mg", "1 tablet", "5ml")
- **Route** — Oral / Topical / Intravenous / Intramuscular / Inhalation
- **Frequency** — Once / Twice Daily / Thrice Daily / Every N Hours / As Needed
- **Administered At** — Date & time given
- **Prescriber** — Doctor or nurse who prescribed
- **Administered By** — Staff who gave the medication
- **Is Self-Administered** — Whether student took it themselves (under supervision)
- **Notes** — Any observations after medication
- **Missed Dose Reason** — If dose was missed, why

---

## Business Rules

- Prescription information (medication, dosage, frequency) must be recorded before first administration
- Two staff members must verify scheduled medications before administration
- Missed doses must be documented with reason
- Controlled substances require additional authorization
- Medication administration times are tracked for schedule compliance
- Medication history is retained permanently

---

## Related Screens

- **Sick Bay** (Tab 30) — Parent admission record
- **Sick Bay Vitals** (Tab 31) — Vitals before/after medication
