# Dietary Profiles — Business Requirements

## What This Screen Does

The Dietary Profiles screen manages each student's personal food preferences, allergies, and dietary restrictions. Every student can have exactly one dietary profile that records their food preference (Veg/Non-Veg/Egg/Jain), allergy flags, and medical dietary notes.

When a student scans their QR code at the POS counter, the system reads their dietary profile and displays relevant warnings — RED alert for nut allergy, yellow warning for food preference conflicts.

---

## When This Screen Is Used

- A new student joins and their dietary profile needs to be set up
- A student has a medical dietary requirement (e.g., gluten-free) that needs recording
- A student's food preferences change
- Parents want to update their child's dietary restrictions via the student portal
- Admin needs to check how many students have specific dietary flags

---

## Key Fields at a Glance

**Student**
The student this profile belongs to. One profile per student — unique constraint.

**Food Preference**
Veg, Non_Veg, Egg, or Jain. Cross-checked against menu item food types at order/POS time.

**Dietary Restriction Flags**
- No Onion No Garlic (Satvik)
- Gluten Free
- Nut Allergy — triggers RED alert at POS
- Dairy Free

**Custom Restrictions**
Free-form text for unlisted restrictions.

**Medical Dietary Note**
Doctor-recommended dietary guidance visible to cafeteria staff.

**Status**
Active or Inactive. Inactive profiles are not checked at POS.

---

## Business Rules and Conditions

**One Profile Per Student**
Unique on student_id. If profile exists, admin must edit it. Prevents conflicting data.

**Auto-Creation**
When the Cafeteria module is activated, default profiles (Veg, all flags OFF) can be bulk-created.

**POS Scan Dietary Check**
- Nut Allergy = RED banner "NUT ALLERGY — Verify meal items."
- Veg student ordering Non-Veg = "This item contains non-vegetarian ingredients."
- Jain student ordering Egg/Non-Veg = "This item conflicts with your dietary preference."
- All warnings are display-only — transactions are NOT blocked.

**Student Portal Access**
Students and parents can update their profile from the portal. Admin can also manage profiles.

---

## Workflow Steps

**Creating a Profile**
Admin searches for a student → selects food preference → sets restriction flags → adds custom notes → submits.

**Viewing Profiles**
List shows student name, food preference badge, allergy icons, and status. Filter by preference.

**Editing a Profile**
Update any field. Changes take effect immediately for POS checks.

---

## Example Scenario

- Student A: Veg, no allergies. Standard profile.
- Student B: Veg, nut allergy = YES. At POS, ordering Peanut Chikki shows RED alert.
- Student C: Jain, no onion/garlic = YES. Items with onion/garlic show warning.

---

## Related Screens

- **Orders** — Food preference checked against ordered items' food type
- **POS Sessions** — Dietary flags displayed as warnings during POS transactions
- **Students** — Profiles linked to student records from StudentProfile module
