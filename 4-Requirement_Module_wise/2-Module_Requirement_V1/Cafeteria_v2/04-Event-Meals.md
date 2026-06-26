# Event Meals — Business Requirements

## What This Screen Does

The Event Meals screen handles special and festival meals that are outside the regular weekly menu. Examples include Diwali Special Lunch, Eid Feast, Christmas Party, or Republic Day Snacks. Event meals allow the school to serve a different menu to targeted groups of students on special occasions without disrupting the regular daily menu.

Unlike daily menus which apply to everyone, event meals can be targeted at specific classes or grades.

---

## When This Screen Is Used

- A festival or special occasion requires a special menu (e.g., Diwali, Eid, Christmas)
- A class party or grade-level event needs customized catering
- The school wants to serve a welcome lunch for new students or a farewell for graduating class
- Parents' association is sponsoring a special treat (e.g., ice cream day)

---

## Key Fields at a Glance

**Event Name**
A descriptive name — for example, "Diwali Special Lunch," "Annual Day Dinner."

**Event Date**
The date the special meal will be served. The same date can have both a regular daily menu and event meals.

**Meal Category**
Which meal time this event applies to (Breakfast, Lunch, Snacks, Dinner).

**Target Classes**
Which classes should see this event meal instead of the regular menu:
- NULL = all students see the event meal
- JSON array = only students in those classes see the event meal
- Empty array = no one sees it (hidden draft)

**Event Items**
Each item can be a dish from the library OR a free-text name for one-off festival dishes not worth adding to the permanent library.

**Status**
Same lifecycle as daily menus: Draft → Published → Archived.

---

## Business Rules and Conditions

**Independent of Daily Menus**
Event meals exist independently from regular daily menus. Both can exist on the same date for the same meal category.

**Portal Display Logic**
Students NOT in the event's target class set see the regular daily menu. Students IN the target class set see the event meal items.

**Multiple Events on Same Date**
Multiple event meals can exist for the same date if they target different meal categories.

**Dish Assignment**
Each event item must have either a library dish OR a free-text name, not neither.

**Publishing Requirement**
An event meal must have at least one item assigned before it can be published.

**Target Class Limits**
Maximum 100 class IDs. For all-class events, use NULL instead of listing all classes.

---

## Workflow Steps

**Creating an Event Meal**
Admin enters the event name, selects date and meal category, chooses target classes (or leaves blank for all), and submits.

**Adding Event Items**
Admin adds dishes — either by searching the dish library or typing free-text names for festival-specific items.

**Publishing**
Admin publishes the event. Targeted students see the event meal on their portal.

**Archiving**
After the event date passes, admin archives it for record-keeping.

---

## Example Scenario

The school is celebrating Diwali. Admin creates "Diwali Special Lunch":
- Date: October 31, Meal Category: Lunch
- Target Classes: All students
- Items: "Special Diwali Thali" (free-text), "Gulab Jamun" (library), "Buttermilk" (library)

All students see the Diwali Special Lunch instead of the regular lunch on October 31.

---

## Related Screens

- **Menu Categories** — Event meals are linked to a specific meal category
- **Menu Items** — Library dishes can be assigned to events
- **Weekly Menus** — Event meals override regular daily menus for targeted students
- **Orders** — Students pre-order from event meals like regular menus
