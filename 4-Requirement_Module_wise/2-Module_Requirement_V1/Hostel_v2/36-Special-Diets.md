# Special Diets — Business Requirements

## What This Screen Does

The Special Diets screen tracks students with specific dietary requirements. This includes medical diets (diabetic, gluten-free, low-sodium), religious diets (Jain, Halal), vegetarian/vegan preferences, and custom dietary needs. The mess uses this information to prepare appropriate meals.

---

## When This Screen Is Used

- Student has a medical condition requiring dietary restrictions
- Student's religion requires specific food preparation
- Student/parent requests dietary accommodation
- Mess planning: knowing how many special diets to prepare
- Doctor-prescribed diet for a sick/recovering student

---

## Key Fields

- **Student** — Student with dietary requirement
- **Diet Type** — Diabetic / Jain / Gluten-Free / Nut Allergy / Lactose Intolerant / Low Sodium / Vegan / Vegetarian / Religious Fasting / Custom
- **Custom Description** — If "Custom", describe the requirement
- **Fasting Days** — If religious fasting, which days
- **Effective From** — Start date
- **Effective To** — End date (nullable for permanent)
- **Prescriber** — Doctor who prescribed (for medical diets)
- **Severity** — Medical Necessity / Preference / Religious Obligation
- **Notes** — Additional details for the mess staff
- **Status** — Active / Inactive

---

## Business Rules

- Special diet records are shared with the mess team for meal preparation
- Medical diets require doctor's verification
- The mess must have a process to accommodate listed dietary requirements
- Severe allergies (nuts, shellfish, etc.) must be prominently displayed for mess staff
- Multiple special diets per student allowed (e.g., Jain + diabetic)
- Diet changes take effect from the next meal onwards (not immediately)

---

## Related Screens

- **Mess Weekly Menus** (Tab 33) — Menus indicate special diet availability
- **Mess Opt Outs** (Tab 35) — Separate from dietary preferences
