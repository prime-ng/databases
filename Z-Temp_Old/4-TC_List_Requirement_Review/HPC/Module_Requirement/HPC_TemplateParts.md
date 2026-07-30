# HPC Template Parts – Complete Guide for School Administrators

**Who can use this screen:** Only school administrators who have been given a special permission called `tenant.hpc-template-parts.*`. If you cannot see this screen, ask your school's super-admin to give you access.

**What this feature does:** A Part is the second layer of the Holistic Progress Card (HPC) system. If a Template is the whole book, each Part is one page or one tab inside that book. When a teacher opens a student's card, they see tabs at the top of the screen. Each tab is one Part. This guide explains every field and button on the Parts screen so you can build and manage the pages of your HPC card.

---

## Where Parts Fit in the Four Layers

Think of building a house:

1. **Template (The House)** – One template per grade band.
2. **Parts (The Rooms)** – Each room is a page or a tab in the card.
3. **Sections (The Furniture inside a Room)** – Blocks of content inside a page.
4. **Rubrics & Items (The Actual Questions)** – The fields teachers fill in.

This guide covers **Layer 2 – Parts**. You should already have at least one Template created before you start creating Parts.

---

## The Parts Tab

On the Template Management screen, you will see four tabs across the top. The second tab is **Parts**. Click it to see all Parts in your school.

### How to Access Parts for a Specific Template

In the Templates tab, each template row has a small clickable area or link. When you click a template row, the Parts tab opens and shows only the Parts that belong to that template. If you have multiple templates, you must first click the template you want to work with, then go to the Parts tab.

### List View

The list shows each Part as a row. Here is what you will see:

| Column | What It Means |
|---|---|
| **Template Code** | The code of the parent template this Part belongs to. Example: `HPC-FOUND`. |
| **Part Code** | A short, unique identifier for this Part within its template. Example: `PAGE1`, `ACADEMICS`, `ATTENDANCE`. |
| **Page No** | The physical page number for printing. When the card is printed as a PDF, this number decides which page the content goes on. |
| **Display Page Number** | A Yes/No flag. If Yes, the page number is shown on the printed card. If No, the page number is hidden. |
| **Has Items** | A Yes/No flag. If Yes (1), this Part has its own items (questions) directly on the page. If No (0), the Part just holds Sections which you create in the Sections tab. |
| **Is Active** | A Yes/No switch. Active Parts are visible to teachers. Inactive Parts are hidden. |

---

## Creating or Editing a Part

Click **Create** to add a new Part, or click **Edit** on an existing Part to change it. The form has the following fields:

| Field Name | Mandatory? | Maximum / Limits | What You Need to Enter |
|---|---|---|---|
| **Template** | Yes | Drop-down list | Select the parent Template from the drop-down. This tells the system which template this Part belongs to. |
| **Code** | Yes | 50 characters maximum | A short, unique identifier for this Part. Must be unique within the selected template. Example: `PAGE1`, `COCURRICULAR`. |
| **Description** | No | 512 characters maximum | A label that teachers see on the tab. This should be plain English so teachers know what is on the page. Example: "Personal & Academic Details". |
| **Help File** | No | 255 characters maximum (typically a URL) | An optional web link that points to instructions for teachers. If you provide a link, teachers will see a "Help" button on that tab. Example: `https://yourschool.edu/hpc/help/personal-details`. Leave blank if you do not need it. |
| **Display Order** | Yes | Whole number, minimum 1 | Determines the order of tabs. Part with Display Order 1 appears as the first tab. Part with Display Order 2 appears as the second tab, and so on. |
| **Page No** | Yes | Whole number, minimum 1, unique per template | The physical page number for the printed PDF. Each page number must be used only once per template. Example: 1, 2, 3, 4. |
| **Display Page Number** | Yes | Checkbox (Yes/No) | Check the box if you want the page number to appear on the printed card. Uncheck if you do not want it shown. |
| **Has Items** | Yes | Checkbox (Yes/No) | Check this box (Yes) if this Part has its own questions directly on the page, without using Sections. Leave unchecked (No) if this Part is just a container for Sections. |
| **Is Active** | Yes | Toggle on/off | Set to ON (Active) to make this Part visible to teachers. Set to OFF (Inactive) to hide it. |

---

## Items Sub-Form (When Has Items is Checked)

If you set **Has Items** to Yes (checked), additional fields appear to add items (questions) directly to the Part. These items are like simple fields that appear on the page without any Section headings. Here are the fields for each item:

| Field Name | What It Means |
|---|---|
| **Ordinal** | A number that determines the order of this item on the page. Lower numbers appear first. |
| **html_object_name** | A unique identifier for this field. The system uses this to store the value the teacher enters. This must be unique across the entire template. |
| **Level Display** | The labels that the teacher sees on screen when selecting a value. Example: `["Excellent", "Good", "Developing"]`. |
| **Level Print** | The labels that appear on the printed PDF. These can be different from what the teacher sees on screen. |
| **Visible** | A Yes/No switch. If Yes, this item is shown to the teacher. If No, it is hidden. |
| **Print** | A Yes/No switch. If Yes, this item appears on the printed PDF. If No, it stays in the system but does not print. |
| **Is Active** | A Yes/No switch. If Yes, the item is active. If No, it is inactive. |

---

## Action Buttons on the Parts Tab

Each Part row has action buttons on the right side:

| Button | What Happens |
|---|---|
| **View** | Opens a read-only summary of the Part. You can see all fields but cannot change anything. |
| **Edit** | Opens the Create/Edit form with current values filled in. |
| **Soft Delete** | Moves the Part to the Trash. It is hidden from teachers and the main list but can be restored. |
| **Toggle Active/Inactive** | Switches the Part between Active and Inactive. Inactive Parts are hidden from teachers. |

---

## Trash View – Restore and Force Delete

Click the **Trash** sub-tab to see all soft-deleted Parts. From here:

| Button | What Happens |
|---|---|
| **Restore** | Brings the Part back to the main list. All its data (sections, rubrics, items) is restored exactly as it was. |
| **Force Delete** | Permanently destroys the Part and everything inside it. There is NO undo button. |

---

## Activity Log

Every action on a Part is recorded in the Activity Log:

- Creating a Part
- Editing any field
- Soft-deleting a Part
- Restoring a Part from trash
- Force-deleting a Part
- Toggling Active/Inactive

The log shows who made the change and when.

---

## Permissions

Different actions require different permissions, all under the `tenant.hpc-template-parts.*` group:

| Action | Permission Required |
|---|---|
| View the Parts list | `tenant.hpc-template-parts.index` |
| View a specific Part | `tenant.hpc-template-parts.show` |
| Create a new Part | `tenant.hpc-template-parts.create` |
| Edit a Part | `tenant.hpc-template-parts.update` |
| Soft-delete a Part | `tenant.hpc-template-parts.destroy` |
| Restore a Part | `tenant.hpc-template-parts.restore` |
| Force-delete a Part | `tenant.hpc-template-parts.force-delete` |

---

## Important Rules to Remember

1. **Code must be unique within a template.** Two Parts in the same Template cannot share the same Code. But two Parts in different Templates CAN share the same Code.
2. **Page No must be unique within a template.** No two Parts in the same Template can have the same Page No.
3. **Has Items = Yes** means items appear directly on the page. You do NOT create Sections for this Part.
4. **Has Items = No** means you will create Sections inside this Part using the Sections tab.
5. **Only Parts with section_id=NULL rubrics are shown.** The system only displays Parts that have rubrics not linked to any specific Section. This is an internal rule that the system handles automatically.
6. **Soft delete** is safe and reversible. **Force delete** is permanent.

---

## Real-World Example: Creating 18 Pages for a Template

Suppose you are building a Foundation Stage template with 18 pages.

1. Go to the Templates tab and click your Foundation template.
2. Click the Parts tab.
3. Click Create.
4. Template: Select `HPC-FOUND` from the drop-down.
5. Code: Enter `PAGE1`.
6. Description: Enter "Personal & Academic Details".
7. Help File: Leave blank.
8. Display Order: Enter `1` (this is the first tab).
9. Page No: Enter `1`.
10. Display Page Number: Check the box.
11. Has Items: Leave unchecked (you will add Sections in the Sections tab).
12. Is Active: Set to ON.
13. Click Save.

Repeat for pages 2 through 18, changing the Code, Description, Display Order, and Page No each time.

---

## Frequently Asked Questions

### Should I set Has Items to Yes or No?

Set **Has Items to No** (unchecked) for almost all cases. This gives you the most flexibility. You can always add Sections later. Only set Has Items to Yes if the page is extremely simple (like a single text box for "Teacher's Comments").

### Can I reorder tabs after creating them?

Yes. Change the Display Order numbers. For example, if you want Page 4 to become Page 2, change its Display Order from 4 to 2. You may need to adjust other pages' Display Orders to avoid duplicate numbers.

### What happens if I delete a Part that has Sections?

Soft-deleting a Part also soft-deletes all its Sections, Rubrics, and Items. If you later restore the Part, everything comes back. Force-deleting a Part destroys everything permanently.

### Can two templates share the same Part?

No. Each Part belongs to exactly one Template. If you want the same page in two templates, you must create it separately in each template.
