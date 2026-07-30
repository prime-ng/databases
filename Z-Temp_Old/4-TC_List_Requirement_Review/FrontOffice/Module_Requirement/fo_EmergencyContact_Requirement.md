# Emergency Contacts — Business Requirements

## What This Screen Does

The Emergency Contacts tab manages a quick-reference directory of emergency numbers (hospitals, police, fire, ambulance, transport). Contacts are grouped by type with icons, showing name, primary phone (bold green), alternate phone, and address.

## When This Screen Is Used

- **Emergency Response**: Quick access to hospital/police/fire numbers
- **School Directory**: Important contact numbers for reference

## Key Fields

- **contact_name** (string 200) — Contact name
- **contact_type** (enum) — Hospital, Police, Fire, Transport, Ambulance, Other
- **primary_phone** (string 20) — Main phone number
- **alternate_phone** (string 20, nullable) — Backup number
- **address** (string 255, nullable) — Physical address
- **sort_order** (integer, nullable) — Display ordering

## Business Rules

**Grouped by Type:** Contacts are displayed grouped by `contact_type` in the order: Hospital, Police, Fire, Transport, Ambulance, Other. Each group has a contextual icon (hospital, shield-halved, fire, truck-medical, phone).

**Phone Display:** Primary phone shown in green bold with phone icon. Alternate phone shown smaller with phone-flip icon.

**Card Style:** Red danger left border for emergency styling.

**No Email Field:** Email field is commented out in the view (legacy).

## Requirements

- MUST display in Compliance tab group grouped by contact_type
- MUST authorize via `frontoffice.emergency-contact.*` policy gates
- MUST show type-specific icons for each group header
- MUST show primary phone in green bold with icon
- MUST show alternate phone if available
- MUST create contacts via modal with name, type, primary phone, alternate phone, address
- MUST support sort_order for display ordering
