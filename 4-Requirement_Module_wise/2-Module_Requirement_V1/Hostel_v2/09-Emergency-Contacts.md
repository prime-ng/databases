# Emergency Contacts — Business Requirements

## What This Screen Does

The Emergency Contacts screen stores hostel-level emergency phone numbers and contact information. This includes doctors, ambulances, hospitals, fire services, police, plumbers, electricians, and other essential services. These contacts are distinct from student-level emergency contacts stored in the Student Profile module.

---

## When This Screen Is Used

- During hostel setup to register all emergency numbers
- When a service provider's contact changes
- When a new service is added (e.g., a new hospital tie-up)
- During an actual emergency to quickly find the right number

---

## Key Fields

- **Service Type** — Category (Doctor, Ambulance, Hospital, Fire, Police, Plumber, Electrician, Warden Emergency, Vendor, Other)
- **Service Name** — Name of the service provider or person
- **Contact Person** — Name of the contact person
- **Phone Number** — Primary contact number (required)
- **Alternate Phone** — Secondary number (optional)
- **Address** — Location address (for hospitals, police station, etc.)
- **Available 24x7** — Yes / No flag
- **Notes** — Additional instructions or details
- **Status** — Active / Inactive

---

## Business Rules

- At least one emergency contact per service type is recommended
- Emergency contacts are hostel-specific (not shared across hostels)
- Deactivated contacts remain in the list but are visually marked
- Displayed prominently on the hostel dashboard for quick access

---

## Related Screens

- **Hostels** (Tab 05) — Emergency contacts are per hostel
- **Hostel Dashboard** (Tab 01) — Quick-access display
