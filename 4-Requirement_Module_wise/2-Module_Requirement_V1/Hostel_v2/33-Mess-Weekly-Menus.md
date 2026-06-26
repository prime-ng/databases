# Mess Weekly Menus — Business Requirements

## What This Screen Does

The Mess Weekly Menus screen plans the hostel's weekly meal schedule. Each day of the week (Monday to Sunday) has menu entries for each meal type (Breakfast, Lunch, Snacks, Dinner). Menus can be published for students to view, and special dietary options are indicated.

---

## When This Screen Is Used

- Weekly menu planning by mess in-charge
- Publishing menu for student viewing
- Making adjustments based on ingredient availability
- Setting up recurring menu patterns
- Special holiday or festival menus

---

## Key Fields

- **Week Start Date** — Monday of the menu week
- **Day** — Monday / Tuesday / ... / Sunday
- **Meal Type** — Breakfast / Lunch / Snacks / Dinner
- **Menu Items** — List of dishes being served
- **Special Diet Options** — Whether Jain/diabetic/gluten-free options are available
- **Is Published** — Whether visible to students
- **Notes** — Any meal-specific notes or announcements
- **Created By** — Mess in-charge who created

---

## Business Rules

- Menus are planned weekly (Monday to Sunday)
- A menu can be copied from a previous week for easy setup
- Published menus are visible to students on their portal
- Unpublished menus are draft/internal only
- Each day must have at least breakfast, lunch, and dinner defined
- Multiple menu items per meal allowed (e.g., 2 sabzis, 3 rotis, rice, salad)
- Menu history is retained for nutritional tracking

---

## Workflow Steps

**Creating Weekly Menu**
Mess in-charge selects week start date, fills menu items for each day/meal, optionally publishes.

**Publishing**
Once finalized, menu is published and students can view it on their portal.

**Copying Week**
Existing week's menu can be copied to a new week to save time.

---

## Related Screens

- **Special Diets** (Tab 36) — Dietary requirements linked to menu planning
- **Mess Attendance** (Tab 34) — Menu influences meal attendance
