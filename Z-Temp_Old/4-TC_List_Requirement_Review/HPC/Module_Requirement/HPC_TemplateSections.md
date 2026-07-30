# HPC Template Sections – Complete Guide for School Administrators

**Who can use this screen:** Only school administrators who have been given a special permission called `tenant.hpc-template-sections.*`. If you cannot see this screen, ask your school's super-admin to give you access.

**What this feature does:** A Section is the third layer of the Holistic Progress Card (HPC) system. If a Template is the whole book and a Part is one page, a Section is a block of content inside that page. Each page can have multiple sections stacked one below another. Each section has a heading that tells the teacher what that block is about. This guide explains every field and button on the Sections screen.

---

## Where Sections Fit in the Four Layers

1. **Template (The House)** – One per grade band.
2. **Parts (The Rooms)** – Pages or tabs.
3. **Sections (The Furniture inside a Room)** – Blocks of content inside a page.
4. **Rubrics & Items (The Actual Questions)** – The fields teachers fill in.

This guide covers **Layer 3 – Sections**. You must have at least one Template and one Part created before you can add Sections.

---

## The Sections Tab

On the Template Management screen, the third tab is **Sections**. Click it to see all Sections. To view Sections for a specific Part, first click the parent Template in the Templates tab, then click the parent Part in the Parts tab, and then go to the Sections tab. The list will show only the Sections that belong to that Part.

### List View

Each row in the list is one Section. Here is what you will see:

| Column | What It Means |
|---|---|
| **Template Code** | The code of the parent Template. Example: `HPC-FOUND`. |
| **Part Code** | The code of the parent Part this Section belongs to. Example: `PAGE1`. |
| **Section Code** | A short, unique identifier for this Section within its Part. Example: `STUDENT_INFO`. |
| **Display Order** | A number that decides the order of Sections within the Part. Lower numbers appear first. |
| **Has Items** | A Yes/No flag. If Yes, the items in this Section appear directly without rubric headings. If No, items are grouped into Rubrics. |
| **Is Active** | A Yes/No switch. Active Sections are visible to teachers. Inactive Sections are hidden. |

---

## Creating or Editing a Section

Click **Create** to add a new Section, or **Edit** to change an existing one. The form has the following fields:

| Field Name | Mandatory? | Maximum / Limits | What You Need to Enter |
|---|---|---|---|
| **Template** | Yes | Drop-down list | Select the parent Template. |
| **Part** | Yes | Drop-down list | Select the parent Part. The drop-down only shows Parts that belong to the selected Template. |
| **Code** | Yes | 50 characters maximum | A short, unique identifier for this Section. Must be unique within the Part. Example: `STUDENT_INFO`, `PARENT_DETAILS`. |
| **Description** | No | 512 characters maximum | The heading that teachers see above this section. Example: "Student Personal Information". |
| **Display Order** | Yes | Whole number, minimum 1, unique per Part | Determines the order of Sections within the Part. Lower numbers appear first. Example: 1, 2, 3. Must be unique within the Part. |
| **Has Items** | Yes | Checkbox (Yes/No) | Check if items in this Section appear directly without rubric grouping. Leave unchecked if you want to group items into Rubrics. |
| **Is Active** | Yes | Toggle on/off | Set to ON (Active) to make this Section visible to teachers. Set to OFF (Inactive) to hide it. |

---

## Items Sub-Form (When Has Items is Checked)

If you set **Has Items** to Yes, additional fields appear to add items directly to the Section. These items appear in a simple list without rubric headings.

| Field Name | What It Means |
|---|---|
| **html_object_name** | A unique identifier for this field across the entire template. The system uses this to store the value the teacher enters. |
| **Ordinal** | A number that determines the order of this item within the Section. Lower numbers appear first. |
| **Level Display** | The labels that the teacher sees on screen when selecting a value. Example: `["Excellent", "Good", "Developing"]`. |
| **Level Print** | The labels that appear on the printed PDF. These can be different from what the teacher sees on screen. |
| **Section Type** | Determines how this item looks on the page. Choose from: **Text** (plain text), **Image** (a picture), or **Table** (a grid like a spreadsheet). |
| **Visible** | A Yes/No switch. If Yes, this item is shown to the teacher. If No, it is hidden. |
| **Print** | A Yes/No switch. If Yes, this item appears on the printed PDF. If No, it stays in the system but does not print. |
| **Is Active** | A Yes/No switch. If Yes, the item is active. If No, it is inactive. |

---

## Table Items Sub-Form (When Section Type is "Table")

If the **Section Type** is set to "Table", additional fields appear to build a table grid. A table has rows and columns, like a spreadsheet. Here are the fields for each cell in the table:

| Field Name | What It Means |
|---|---|
| **html_object_name** | A unique identifier for this table cell across the entire template. |
| **Row ID** | Identifies which row this cell belongs to. Example: For an attendance table, rows might be "Working Days", "Present Days", "Absent Days". |
| **Column ID** | Identifies which column this cell belongs to. Example: Columns might be "June", "July", "August". |
| **Value** | The default value or label for this cell, if any. |
| **Visible** | A Yes/No switch. If Yes, this cell is shown to the teacher. If No, it is hidden. |
| **Print** | A Yes/No switch. If Yes, this cell appears on the printed PDF. If No, it does not print. |
| **Is Active** | A Yes/No switch. If Yes, the cell is active. If No, it is inactive. |

---

## Sanitising Level Display

When you enter text in the **Level Display** field, the system automatically cleans it up. It removes any dangerous or restricted HTML code. This is a safety feature. Only safe formatting like bold, italic, and basic text is allowed. If you try to enter complex computer code or scripts, the system will strip them out.

---

## Action Buttons on the Sections Tab

| Button | What Happens |
|---|---|
| **View** | Opens a read-only summary of the Section. You can see all fields but cannot change anything. |
| **Edit** | Opens the Create/Edit form with current values filled in. |
| **Soft Delete** | Moves the Section to the Trash. It is hidden but can be restored. |
| **Toggle Active/Inactive** | Switches the Section between Active and Inactive. Inactive Sections are hidden from teachers. |

---

## Trash View – Restore and Force Delete

Click the **Trash** sub-tab to see all soft-deleted Sections.

| Button | What Happens |
|---|---|
| **Restore** | Brings the Section back. All its rubrics and items come back exactly as they were. |
| **Force Delete** | Permanently destroys the Section, its rubrics, and its items. There is NO undo button. |

---

## Activity Log

Every action on a Section is recorded:

- Creating, editing, soft-deleting, restoring, force-deleting, or toggling a Section
- The log shows who made the change and when

---

## Permissions

All permissions are under the `tenant.hpc-template-sections.*` group:

| Action | Permission Required |
|---|---|
| View the Sections list | `tenant.hpc-template-sections.index` |
| View a specific Section | `tenant.hpc-template-sections.show` |
| Create a new Section | `tenant.hpc-template-sections.create` |
| Edit a Section | `tenant.hpc-template-sections.update` |
| Soft-delete a Section | `tenant.hpc-template-sections.destroy` |
| Restore a Section | `tenant.hpc-template-sections.restore` |
| Force-delete a Section | `tenant.hpc-template-sections.force-delete` |

---

## Important Rules to Remember

1. **Code must be unique within a Part.** Two Sections in the same Part cannot share the same Code.
2. **Display Order must be unique within a Part.** No two Sections in the same Part can have the same Display Order number.
3. **Has Items = Yes** means items appear directly. You will add them using the Items sub-form.
4. **Has Items = No** means you will create Rubrics inside this Section using the Rubrics tab.
5. **Section Type = Table** opens extra fields to build a grid. Use this for data like attendance records.
6. **Level Display is sanitised** to remove dangerous code. Only safe text formatting is kept.
7. **Soft delete** is reversible. **Force delete** is permanent.

---

## Real-World Example: Creating Sections for a Personal Details Page

Your Foundation template has a Part called "Personal & Academic Details" (Page 1). You want to add three sections to this page.

**Step 1 – Create Section 1: "Student Information"**
- Template: Select `HPC-FOUND`.
- Part: Select `PAGE1`.
- Code: Enter `STUDENT_INFO`.
- Description: Enter "Student Personal Information".
- Display Order: Enter `1`.
- Has Items: Leave unchecked (you will add rubrics later).
- Is Active: Set to ON.
- Click Save.

**Step 2 – Create Section 2: "Parent Details"**
- Code: Enter `PARENT_DETAILS`.
- Description: Enter "Parent/Guardian Details".
- Display Order: Enter `2`.
- Other settings same as above.
- Click Save.

**Step 3 – Create Section 3: "Attendance Record"**
- Code: Enter `ATTENDANCE`.
- Description: Enter "Monthly Attendance Record".
- Display Order: Enter `3`.
- Has Items: Check this box (items will appear directly as a table).
- Section Type for items: Select "Table".
- Click Save.

The teacher will now see Page 1 with three blocks stacked vertically: "Student Information", "Parent Details", and "Attendance Record".

---

## Frequently Asked Questions

### What is the difference between Has Items on a Part vs Has Items on a Section?

- **Part Has Items = Yes:** Items appear directly on the page without any section headings.
- **Section Has Items = Yes:** Items appear directly within this Section block without rubric headings.
- **Part Has Items = No + Section Has Items = No:** Items are grouped into Rubrics. This is the most common setup.

### When should I use Section Type = Table?

Use Table for any data that naturally fits a grid format. Common examples:
- Attendance records (rows = months, columns = days present/absent)
- Subject-wise marks (rows = subjects, columns = terms)
- Co-curricular activities (rows = activities, columns = participation level)

### Can I change a Section from Table to Text after creating it?

It is not recommended to change the Section Type after items have been added, because the data format is different. If you made a mistake, it is safer to soft-delete the Section and create a new one.

### How many Sections can I have on one page?

There is no fixed limit. However, for readability, try to keep it to 3 to 5 sections per page. Too many sections make the page hard to scroll through.
