# HPC Templates – Complete Guide for School Administrators

**Who can use this screen:** Only school administrators who have been given a special permission called `tenant.hpc-templates.*`. If you cannot see this screen, ask your school's super-admin to give you access.

**What this feature does:** A Template is the top-most layer of the Holistic Progress Card (HPC) system. Think of it as the cover and spine of a book. One template serves one grade band (for example, Foundation stage or Secondary stage). You will create one template for each group of classes in your school. This guide explains every part of the Templates screen so you can create, edit, and manage templates with confidence.

---

## The Big Picture – Where Templates Fit

The HPC system has four layers, like a house:

1. **Templates (The House)** – One per grade band. This is the top layer.
2. **Parts (The Rooms)** – Pages or tabs inside the template.
3. **Sections (The Furniture)** – Blocks of content inside a page.
4. **Rubrics & Items (The Questions)** – The actual fields that teachers fill in.

This guide covers **Layer 1 – Templates**. The other layers have their own guides.

---

## The Templates Tab

When you open the Template Management screen by going to `/hpc/templates` in your browser, you will see four tabs across the top. The first tab is **Templates**. This tab shows a list of all the templates in your school.

Each row in the list represents one template. Here is what you will see in the list view:

| Column | What It Means |
|---|---|
| **Code** | A short, unique name that the system uses to identify this template. You make this up when you create the template. It is like a licence plate for a car. |
| **Version** | A number that starts at 1. Each time you update the template and save it as a new version, this number goes up. Teachers already using an older version keep working on that version. |
| **Title** | The human-readable name of the template. Teachers see this name when the system assigns a card to their students. |
| **Applicable Grades** | Which class levels (grades) this template is meant for. A Nursery student only sees Foundation templates. A Class 11 student only sees Secondary templates. |
| **Is Active** | A Yes/No switch. Active templates can be used by teachers to create new cards. Inactive templates are hidden from teachers. |

---

## Creating or Editing a Template

To create a new template, click the **Create** button above the list. To edit an existing template, click the **Edit** button on the row of the template you want to change. Both buttons open a form with the following fields:

| Field Name | Mandatory? | Maximum Length / Limits | What You Need to Enter |
|---|---|---|---|
| **Code** | Yes | 50 characters maximum | A short, unique identifier. Example: `HPC-FOUND` for Foundation stage. No two templates can have the same code. |
| **Version** | Yes | Must be a whole number, minimum 1 | Start with 1. If you later create a new version, set it to 2, then 3, and so on. |
| **Title** | Yes | 255 characters maximum | The name teachers will see. Example: "Foundation Stage Progress Card". |
| **Description** | No | 512 characters maximum | An optional note about this template. Only admins see this. Example: "Created for the 2025-26 academic year for Nursery to Class 3." |
| **Applicable Grades** | Yes | Select from your school's class list | Choose one or more grades. Hold the Ctrl key (or Command key on Mac) to select multiple grades. Example: For Foundation, select Nursery, LKG, UKG, Class 1, Class 2, Class 3. |
| **Is Active** | Yes | Toggle on/off | Set to ON (Active) if teachers should be able to use this template. Set to OFF (Inactive) to hide it from teachers. |

### Important Uniqueness Rule

The combination of **Code + Version** must be unique. This means:

- You CAN have `HPC-FOUND` with Version 1 and `HPC-FOUND` with Version 2. These are two different templates.
- You CANNOT have two templates both called `HPC-FOUND` with Version 1. The system will not allow it.

If you try to save a template with a Code + Version combination that already exists, the system will show an error message. Simply change the Version number or use a different Code.

---

## Action Buttons – What Each One Does

Every row in the Templates list has a set of buttons on the right side. Here is what each button does:

| Button | What Happens When You Click It |
|---|---|
| **View** | Opens a read-only summary of the template. You can see all the fields and settings, but you cannot change anything. Use this to inspect a template before editing it. |
| **Edit** | Opens the same Create form but with the current values already filled in. You can change any field and save. This changes the current template; it does NOT create a new version. |
| **Soft Delete** | Moves the template to the Trash (recycle bin). The template still exists in the system. It is hidden from teachers and from the main list, but an administrator can restore it. Think of it like putting a document in a drawer instead of throwing it away. |
| **Toggle Active/Inactive** | A simple on/off switch. If the template is Active, clicking this makes it Inactive. If it is Inactive, clicking this makes it Active. This does NOT delete anything. It only controls whether teachers can see and use this template for new cards. |

---

## The Trash View – Restore or Permanently Delete

When you click the **Trash** tab (the fourth sub-tab at the top of the screen), you see all templates that have been soft-deleted. From here you have two actions:

| Button | What Happens |
|---|---|
| **Restore** | Brings the template back to the main list. Everything inside it (parts, sections, rubrics, items) comes back exactly as they were. Nothing is lost. |
| **Force Delete** | Permanently destroys the template AND everything inside it forever. There is NO undo button. Once you do this, the data is gone. Only use this when you are 100% certain the template will never be needed again. |

### Real-World Example: Soft Delete vs Force Delete

Suppose you created a test template called "HPC-TEST" to practise the system. You filled it with sample data. Now you are cleaning up.

- **If you are not sure:** Use Soft Delete. The template goes to the Trash. If a teacher later says "I need that template!", you can restore it in one click.
- **If you are absolutely sure:** Use Force Delete. The template is gone permanently. Most admins soft-delete first, wait a month or two, and only force-delete if nobody has complained.

---

## Activity Log – Tracking All Changes

Every action you take on a template is recorded in an Activity Log. This includes:

- Creating a new template
- Editing any field (the log records what changed)
- Soft-deleting a template
- Restoring a template from trash
- Force-deleting a template
- Toggling Active/Inactive status

The Activity Log shows who made the change, what they changed, and when. This is useful for audits and for troubleshooting if something unexpected happens.

---

## Permissions – Who Can Do What

Different actions require different permissions. Here is a simple table:

| Action | Permission Required |
|---|---|
| View the Templates list | `tenant.hpc-templates.index` |
| View a specific template details | `tenant.hpc-templates.show` |
| Create a new template | `tenant.hpc-templates.create` |
| Edit an existing template | `tenant.hpc-templates.update` |
| Soft-delete a template | `tenant.hpc-templates.destroy` |
| Restore a soft-deleted template | `tenant.hpc-templates.restore` |
| Force-delete a template | `tenant.hpc-templates.force-delete` |

If you try to perform an action without the correct permission, the system will show an error. Ask your super-admin to grant you any permissions you are missing.

---

## URLs (Screen Addresses)

Here are the web addresses for each screen related to Templates:

| Screen | URL |
|---|---|
| Template Management (main screen with 4 tabs) | `/hpc/templates` |
| Templates list (first tab) | `/hpc/hpc-templates` |
| Create a new template | `/hpc/hpc-templates/create` |
| View a specific template | `/hpc/hpc-templates/{id}` |
| Edit a specific template | `/hpc/hpc-templates/{id}/edit` |
| View the Trash (soft-deleted templates) | `/hpc/hpc-templates/trash/view` |

The `{id}` in the URL is a number that the system assigns to each template automatically. You do not need to memorise it. Just click the buttons on the screen, and the system takes you to the right address.

---

## Summary of Key Rules

1. **Code is unique.** No two templates can have the same Code.
2. **Code + Version must be unique together.** You can have two versions of the same Code (e.g., `HPC-FOUND` Version 1 and Version 2), but you cannot have two records with the same Code AND same Version.
3. **Active templates** are visible to teachers. **Inactive templates** are hidden from teachers but existing cards continue to work.
4. **Soft delete** moves to trash (recoverable). **Force delete** is permanent (not recoverable).
5. **Activity Log** records every action for audit purposes.
6. **Permissions** control who can view, create, edit, delete, restore, and force-delete templates.
7. **No programming required.** Every change you make is immediate.

---

## Frequently Asked Questions

### How many templates should my school have?

Most schools create one template per grade band. For example:
- **Foundation (Nursery to Class 3):** One template
- **Preparatory (Class 4 to Class 5):** One template
- **Middle (Class 6 to Class 8):** One template
- **Secondary (Class 9 to Class 12):** One template

If you have different curricula (e.g., CBSE and state board), you may create separate templates for each.

### Can I have two active templates for the same grade?

Technically yes, but it is not recommended. Teachers would see two templates and might pick the wrong one. It is better to have one active template per grade band.

### What happens if I make a template Inactive while teachers are using it?

Existing cards continue to work. Teachers can still open and edit cards they already started. They just cannot start new cards with that template. This is safe to do at any time.

### How do I create a new version of a template?

Open the template in Edit mode. Change the Version number to the next number (e.g., from 1 to 2). Change the Code if needed (usually you keep the same Code). Then save. The system treats this as a new template. Set the new version to Active and the old version to Inactive.

### Can a teacher see multiple versions of the same template?

No. Each teacher only sees the active template for their grade. Old versions are hidden from teachers but still exist in the database for existing cards.

---

## Need Help?

If you are unsure about any step, start by creating a test template with a Code like `HPC-TEST`. Practise creating, editing, soft-deleting, restoring, and toggling the status. Once you are comfortable, create your real templates. Remember that anything soft-deleted can be restored, so do not be afraid to experiment.
