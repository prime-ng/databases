# Weekly Menus — Business Requirements

## What This Screen Does

The Weekly Menus screen is where the cafeteria admin plans what food will be served each day. Each calendar date gets its own menu with specific dishes assigned to each meal category (Breakfast, Lunch, Snacks, Dinner). A menu goes through a lifecycle — it starts as a Draft, gets Published when finalized, and becomes Archived after the date has passed.

Think of this as the school's meal calendar. Just like a teacher plans lessons in advance, the cafeteria admin plans what dishes will be cooked and served on which day.

---

## When This Screen Is Used

- The weekly menu needs to be planned for the upcoming week
- A menu has been finalized and needs to be published so students can start pre-ordering
- The kitchen needs to see what dishes are scheduled for today or tomorrow
- A published menu needs to be modified (e.g., a supplier couldn't deliver an ingredient)
- Today's menu has passed and needs to be archived for record-keeping

---

## Key Fields at a Glance

**Menu Date**
The calendar date this menu is for. Each date can have exactly one menu. This is a unique constraint.

**Week Start Date**
The ISO Monday of the week this menu belongs to. Auto-computed from the menu date.

**Academic Term**
The academic term this menu belongs to (optional). Links to the school's academic term master.

**Status**
Draft → Published → Archived lifecycle. Draft is being planned. Published is visible to students for pre-ordering. Archived is read-only historical record.

**Dish Assignments**
Each meal category on that date gets dishes assigned from the dish library via a junction table.

**Kitchen Notes**
Optional notes for the kitchen staff.

---

## Business Rules and Conditions

**One Menu Per Date**
A menu can only be created for a date that does not already have a menu. Soft-deleted menus occupy their date — must be restored or force-deleted first.

**Publishing Requires Items**
A menu cannot be published if it has no dish assignments.

**Archiving Restriction**
Only menus with dates in the past can be archived. Future menus cannot be archived.

**Unpublish Protection**
Only future or today's menus can be reverted from Published to Draft.

**Dish Assignment Uniqueness**
Within a single menu, the same dish cannot appear twice in the same meal category. It can appear in different meal categories.

**Soft Delete Restriction**
Only Draft menus can be soft-deleted. Published or Archived menus must be unpublished or archived first.

**Restore Date Check**
Restoring checks that the menu date is not already taken by another active menu.

---

## Workflow Steps

**Creating a Weekly Menu**
Admin selects a date range (e.g., Monday to Friday). System creates daily menus as Draft. Admin opens each day to assign dishes.

**Assigning Dishes**
Admin opens a specific date, sees meal categories listed, and assigns dishes from the library to each category.

**Publishing**
Admin clicks Publish. Menu becomes visible on the student portal. Students can see what is being served and place pre-orders.

**Modifying a Published Menu**
Admin can unpublish a future menu, make changes, and republish. Past menus cannot be unpublished.

**Archiving Past Menus**
After the menu date has passed, admin archives it. Archived menus are read-only.

---

## Example Scenario

**Monday:** Breakfast — Idli + Sambhar, Lunch — Veg Thali, Snacks — Banana + Milk
**Tuesday:** Breakfast — Poha, Lunch — Chole Bhature, Snacks — Fruit Salad
**Wednesday:** Breakfast — Dosa + Chutney, Lunch — Biryani + Raita, Snacks — Tea + Biscuits

Admin creates each day's menu, assigns dishes, and publishes all five days by Friday afternoon.

---

## Related Screens

- **Menu Categories** — Define the serving slots
- **Menu Items** — Dish library items are assigned to menu days
- **Event Meals** — Can override regular menus for specific student groups
- **Orders** — Students place pre-orders based on published menus
