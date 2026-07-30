# HPC Template Rubrics – Complete Guide for School Administrators

**Who can use this screen:** Only school administrators who have been given a special permission called `tenant.hpc-template-rubrics.*`. If you cannot see this screen, ask your school's super-admin to give you access.

**What this feature does:** A Rubric is the fourth and final layer of the Holistic Progress Card (HPC) system. If a Template is the whole book, a Part is one page, and a Section is a block on that page, then a Rubric is a group of related questions or fields inside that block. Each question inside a Rubric is called an Item. This is where you define the actual fields that teachers will fill in — text boxes, drop-down menus, grade selectors, checkboxes, and more.

---

## Where Rubrics Fit in the Four Layers

1. **Template (The House)** – One per grade band.
2. **Parts (The Rooms)** – Pages or tabs.
3. **Sections (The Furniture inside a Room)** – Blocks of content inside a page.
4. **Rubrics & Items (The Actual Questions)** – The fields teachers fill in.

This guide covers **Layer 4 – Rubrics & Items**. You must have at least one Template, one Part, and one Section created before you can add Rubrics. However, if a Part or Section has **Has Items = Yes**, Rubrics are skipped and items are added directly.

---

## The Rubrics Tab

On the Template Management screen, the fourth tab is **Rubrics**. Click it to see all Rubrics. To view Rubrics for a specific Section, first click the parent Template, then the parent Part, then the parent Section, and then go to the Rubrics tab.

### List View

The list shows each Rubric as a row. Here is what you will see:

| Column | What It Means |
|---|---|
| **Template Code** | The code of the parent Template. |
| **Part Code** | The code of the parent Part. |
| **Section Code** | The code of the parent Section (may be blank if the rubric is not linked to any section). |
| **Rubric Code** | A short, unique identifier for this Rubric. |
| **Description** | The heading that teachers see above this group of items. |
| **Mandatory** | A Yes/No flag. If Yes, the teacher MUST fill at least one item in this rubric. |
| **Display Order** | A number that determines the order of this rubric within its Section. |
| **Visible** | A Yes/No flag. If Yes, the rubric is shown to teachers. If No, it is hidden. |
| **Print** | A Yes/No flag. If Yes, this rubric appears on the printed PDF. If No, it does not print. |
| **Is Active** | A Yes/No switch. Active Rubrics are visible. Inactive Rubrics are hidden. |

---

## Creating or Editing a Rubric

Click **Create** to add a new Rubric, or **Edit** to change an existing one. The form has the following fields:

| Field Name | Mandatory? | Maximum / Limits | What You Need to Enter |
|---|---|---|---|
| **Template** | Yes | Drop-down list | Select the parent Template. |
| **Part** | Yes | Drop-down list | Select the parent Part. Only Parts belonging to the selected Template are shown. |
| **Section** | No | Drop-down list (optional) | Optionally link this Rubric to a specific Section. Leave blank if the Rubric is not inside any Section. |
| **Code** | Yes | 50 characters maximum | A short, unique identifier for this Rubric. Example: `COMM_SKILLS`, `MATH_ASSESSMENT`. |
| **Description** | Yes | 512 characters maximum | The heading that teachers see above this group of items. Example: "Communication Skills". |
| **Mandatory** | Yes | Checkbox | Check if the teacher MUST fill at least one item in this rubric before saving the card. |
| **Display Order** | Yes | Whole number, minimum 0, unique per Section | Determines the order of this Rubric within its Section. Lower numbers appear first. Must be unique when grouped by Section ID. |
| **Visible** | Yes | Checkbox | Check to show this Rubric to teachers. Uncheck to hide it temporarily. |
| **Print** | Yes | Checkbox | Check to include this Rubric in the printed PDF. Uncheck to exclude it from printing. |
| **Is Active** | Yes | Toggle on/off | Set to ON (Active) to make this Rubric usable. Set to OFF (Inactive) to disable it. |

---

## Items – The Individual Fields Inside a Rubric

Every Rubric must have at least one Item. Items are the actual fields that teachers fill in. Click **Add Item** inside the Rubric to create one. Here are all the fields for an Item:

| Field Name | Mandatory? | What It Means |
|---|---|---|
| **html_object_name** | Yes | A unique identifier for this field across the entire template. The system uses this to store and retrieve the value the teacher enters. Example: `english_reading`, `math_marks`. |
| **Ordinal** | Yes | A number that determines the order of this item within the Rubric. Lower numbers appear first. |
| **Input Type** | Yes | What kind of field this is. Choose from: **Descriptor**, **Numeric**, **Grade**, **Text**, **Boolean**, **Image**, or **Json**. See the table below for explanations. |
| **Output Type** | Yes | The type used for printing. Same choices as Input Type. Can be the same or different from Input Type. |
| **Input Dropdown** | No | If Input Type is a dropdown-based type, enter the list of choices here. See the section on dropdown values below. |
| **Output Dropdown** | No | The list of choices for printing. Can be different from Input Dropdown. |
| **Input Level** | No | The labels the teacher sees on screen when selecting a value. Example: `["Excellent", "Good", "Developing"]`. Enter them separated by commas or new lines. |
| **Output Level** | No | The labels that appear on the printed PDF. Can be different from Input Level. |
| **Input Level Numeric** | No | The numeric values tied to each Input Level. Example: If levels are "Excellent", "Good", "Developing", the numeric values might be 3, 2, 1. |
| **Output Level Numeric** | No | The numeric values tied to each Output Level. |
| **Display Input Label** | Yes | Checkbox. Check to show the field label on the screen. Uncheck to hide it. |
| **Print Output Label** | Yes | Checkbox. Check to show the label on the printed PDF. Uncheck to hide it. |
| **Weight** | Yes | A decimal number (e.g., 1.0, 1.5, 2.0) that controls how much this item counts towards a total. Higher weight = more important. |
| **Description** | No | An optional note about this item. Only admins see this. |
| **Input Required** | Yes | Checkbox. If checked, the teacher MUST fill this item before saving. |
| **Is Active** | Yes | Toggle on/off. Set to ON to make this item active. Set to OFF to disable it. |

---

## Input Types Explained

| Input Type | What It Does | Real Example |
|---|---|---|
| **Descriptor** | A selection from pre-defined descriptive levels. You define the level labels. | "Behaviour Rating" with levels: "Always Respectful", "Usually Respectful", "Needs Improvement". |
| **Numeric** | A field that only accepts numbers. | "Marks Obtained" – teacher enters: 85. |
| **Grade** | A drop-down menu with grade options like A, B, C, D. | "English Grade" – teacher selects "A". |
| **Text** | A plain text box for typing comments. | "Teacher's Comments" – teacher types a paragraph. |
| **Boolean** | A Yes/No toggle or checkbox. | "Participates in Sports" – teacher clicks Yes or No. |
| **Image** | A button to upload a picture file. | "Student Photo" – teacher uploads a photo. |
| **Json** | A field for storing complex structured data. For advanced use only. | "Sports Scores" storing sport name, score, and date together. |

---

## Dropdown Values – How to Enter Them

For the **Input Dropdown** and **Output Dropdown** fields, you need to provide the list of choices. You can enter them in two ways:

1. **Comma-separated:** Type each choice separated by a comma. Example: `Excellent, Good, Satisfactory, Needs Improvement`.
2. **Newline-separated:** Type each choice on a new line. Example:
   ```
   Excellent
   Good
   Satisfactory
   Needs Improvement
   ```

The system stores these as a JSON array internally. You do not need to worry about the technical details. Just type the options in a way that makes sense to you.

---

## Auto-Copy Logic

There is a smart feature called **Auto-Copy**. It works like this:

- If you set **Input Required** to Yes (checked), the system automatically copies the **Output Level** and **Output Level Numeric** values from the **Input Level** and **Input Level Numeric** fields.
- This saves you time because in most cases the screen values and the print values are the same.
- If you want the output to be different from the input, you can manually change the Output fields after the auto-copy happens. The system will not overwrite your manual changes.

---

## Action Buttons on the Rubrics Tab

| Button | What Happens |
|---|---|
| **View** | Opens a read-only summary of the Rubric and its Items. |
| **Edit** | Opens the form with current values filled in. |
| **Soft Delete** | Moves the Rubric and all its Items to the Trash. Can be restored. |
| **Toggle Active/Inactive** | Switches the Rubric between Active and Inactive. |

---

## Trash View – Restore and Force Delete

Click the **Trash** sub-tab to see all soft-deleted Rubrics.

| Button | What Happens |
|---|---|
| **Restore** | Brings the Rubric and all its Items back exactly as they were. |
| **Force Delete** | Permanently destroys the Rubric and all its Items. There is NO undo button. |

---

## Activity Log

Every action on a Rubric or Item is recorded:

- Creating, editing, soft-deleting, restoring, force-deleting, or toggling a Rubric
- Adding, editing, or deleting Items inside a Rubric
- The log shows who made the change and when

---

## Permissions

All permissions are under the `tenant.hpc-template-rubrics.*` group:

| Action | Permission Required |
|---|---|
| View the Rubrics list | `tenant.hpc-template-rubrics.index` |
| View a specific Rubric | `tenant.hpc-template-rubrics.show` |
| Create a new Rubric | `tenant.hpc-template-rubrics.create` |
| Edit a Rubric | `tenant.hpc-template-rubrics.update` |
| Soft-delete a Rubric | `tenant.hpc-template-rubrics.destroy` |
| Restore a Rubric | `tenant.hpc-template-rubrics.restore` |
| Force-delete a Rubric | `tenant.hpc-template-rubrics.force-delete` |

---

## Important Rules to Remember

1. **Every Rubric must have at least one Item.** You cannot save a Rubric without adding at least one Item to it.
2. **html_object_name must be unique across the entire template.** No two Items anywhere in the template can share the same html_object_name.
3. **Display Order (min 0) must be unique per Section ID.** This means Rubrics linked to the same Section must have different Display Order numbers.
4. **Section is optional.** A Rubric can exist without being linked to any Section.
5. **Auto-Copy is automatic.** When Input Required is checked, Output Level and Output Level Numeric are copied from Input automatically. Change them manually if needed.
6. **Dropdown values** can be entered as comma-separated or newline-separated text. The system converts them to JSON arrays.
7. **Soft delete** is reversible. **Force delete** is permanent.

---

## Real-World Example: Creating a Communication Skills Rubric

Your Foundation template has a Section called "Language Skills". Inside it, you want a Rubric for "Communication Skills" with three Items.

**Step 1 – Create the Rubric**
- Template: Select `HPC-FOUND`.
- Part: Select `PAGE1`.
- Section: Select `LANGUAGE_SKILLS`.
- Code: Enter `COMM_SKILLS`.
- Description: Enter "Communication Skills".
- Mandatory: Check the box.
- Display Order: Enter `1`.
- Visible: Checked.
- Print: Checked.
- Is Active: Set to ON.
- Click Save.

**Step 2 – Add Item 1: "Speaking"**
- html_object_name: `comm_speaking`.
- Input Type: Grade.
- Output Type: Grade.
- Input Level: `Excellent, Good, Developing, Needs Improvement`.
- Input Level Numeric: `4, 3, 2, 1`.
- Weight: `1.0`.
- Input Required: Checked.
- Click Save.

**Step 3 – Add Item 2: "Listening"**
- html_object_name: `comm_listening`.
- Same settings as above.
- Click Save.

**Step 4 – Add Item 3: "Writing"**
- html_object_name: `comm_writing`.
- Same settings as above.
- Click Save.

The teacher will now see a box on the card labelled "Communication Skills" with three drop-down menus for Speaking, Listening, and Writing.

---

## Frequently Asked Questions

### What is the difference between Input Level and Output Level?

- **Input Level** is what the teacher sees on their computer screen when filling the card.
- **Output Level** is what appears on the printed PDF.
- They can be the same or different. For example, the teacher might see "Excellent" on screen but the printed card shows "A+".

### What is the difference between Input Dropdown and Output Dropdown?

Same concept as levels. Input Dropdown controls the options the teacher sees on screen. Output Dropdown controls the options on the printed PDF.

### How does Weight work?

Weight determines how much an item counts towards a total score. An item with Weight 2.0 counts twice as much as an item with Weight 1.0. An item with Weight 0.5 counts half as much.

### Can I change the Input Type after creating an Item?

It is not recommended, because changing the type may break existing data. If you made a mistake, soft-delete the Item and create a new one with the correct type.

### What happens if I make a Rubric Inactive?

The Rubric and all its Items are hidden from teachers. Existing data in those Items is NOT lost. When you make the Rubric Active again, everything comes back.

### Can an Item have different Input Type and Output Type?

Yes. For example, you might have Input Type as "Grade" (teacher selects A, B, C, D) and Output Type as "Descriptor" (printed as "Excellent", "Good", "Satisfactory"). This gives you flexibility.
