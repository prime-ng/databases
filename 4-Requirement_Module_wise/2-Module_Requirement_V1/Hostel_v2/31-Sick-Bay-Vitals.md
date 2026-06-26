# Sick Bay Vitals — Business Requirements

## What This Screen Does

The Sick Bay Vitals screen records periodic vital sign readings for students admitted to the sick bay. Temperature, pulse, respiratory rate, blood pressure, SpO2, and other parameters are tracked at regular intervals. Abnormal readings trigger alerts for immediate attention.

---

## When This Screen Is Used

- Regular monitoring of a sick bay patient (every 4-6 hours for routine, more frequent for serious)
- Recording initial vitals at admission
- Alerting warden/nurse of abnormal readings
- Providing vitals history to doctor during consultation

---

## Key Fields

- **Sick Bay Admission** — Which admission this belongs to
- **Recorded At** — Date & time of reading
- **Temperature** — Body temperature (℃)
- **Pulse Rate** — Heart rate (bpm)
- **Respiratory Rate** — Breaths per minute
- **Blood Pressure** — Systolic/Diastolic (mmHg)
- **SpO2** — Oxygen saturation (%)
- **Weight** — Weight (kg)
- **Height** — Height (cm)
- **Pain Score** — 1-10 scale
- **Notes** — Any observations
- **Recorded By** — Staff who took the reading
- **Alarm Flag** — Whether any reading was abnormal

---

## Business Rules

- At minimum, vitals are recorded at admission and discharge
- Frequency of readings depends on severity: every 2/4/6/8 hours
- Abnormal ranges are configurable per parameter
- Any abnormal reading triggers an alert to the attending warden/nurse
- Multiple readings are charted to show recovery trend
- Vitals are retained permanently for medical history

---

## Related Screens

- **Sick Bay** (Tab 30) — Parent admission record
