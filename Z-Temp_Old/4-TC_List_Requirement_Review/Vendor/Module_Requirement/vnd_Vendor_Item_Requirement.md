# Vendor Item / Service Catalogue — Business Requirements

## What This Screen Does

This screen lets the school manage a catalogue of all items and services that can be bought from vendors. Each item (for example, stationery, furniture, or a maintenance service) is recorded with its name, code, type (Product or Service), nature (Consumable, Asset, Service, or Not Applicable), price, reorder alert level, tax code, and an optional photo.

---

## When This Screen Is Used

- **Setting up procurement** — when creating items that will later be linked to vendor agreements
- **Creating a vendor agreement** — when picking items for rate contracts or purchase orders
- **Managing inventory** — when defining the minimum stock level for consumable or asset items
- **Tax compliance** — when entering tax codes for GST and other tax reporting

---

## Key Details at a Glance

**Identity and Coding**
Each item can have an optional code and a required name that appears throughout the procurement screens. The type tells you whether it is a Service or a Product. The nature further classifies it as Consumable, Asset, Service, or Not Applicable (the default).

**Pricing and Inventory**
- **Default Price** — the standard unit price, shown with up to two decimal places
- **Reorder Level** — the minimum stock quantity that triggers a replenishment alert
- **Tax Code** — the code used on tax invoices for GST compliance

**Photo and Status**
An optional photo can be attached to the item. The system notes whether a photo has been uploaded. An Active/Inactive setting controls whether the item appears in selection lists.

---

## Business Rules

**Rule 1 — Warning When Deactivating an Item Linked to Active Agreements**
If someone tries to turn off an item that is currently linked to one or more active vendor agreements, the system must show a warning listing those agreement references. The deactivation happens only after the user confirms.

**Rule 2 — Only Active Items Appear in Dropdowns**
Selection lists on vendor agreement screens must show only active items. Inactive or removed items are hidden from these lists.

---

## How It Works

**Creating a Catalogue Item**
The user goes to the Item Catalogue screen and clicks Add Item. They enter the item name (required), optionally assign a unique code, select the type (Service/Product) and nature (Consumable/Asset/Service/Not Applicable). They pick a category and unit from the system-maintained lists, and optionally enter a tax code, default price, reorder level, and description. They may upload a photo. When they save, the system checks all the information and stores it.

**Editing an Existing Item**
The user opens the item record, makes changes, and saves. If a new photo is uploaded, the system replaces the old one.

**Viewing Item Details**
The user can open any item to see its full details, including the photo and all linked information.

**Deactivating an Item**
The user toggles the item from Active to Inactive. If the item is linked to active agreements, the system first shows a warning. After confirmation, the item is made inactive and no longer appears in selection lists.

**Removing an Item (Soft Removal)**
The user can remove an item from the active list. The item is hidden from view but can be restored later if needed.

**Restoring a Removed Item**
The user can view the list of removed items and restore any item back to active status.

**Permanently Deleting an Item**
The user can permanently delete an item. This action cannot be undone and also removes any associated photo.

---

## What the System Checks Before Saving

| Field | What Is Required | If Something Is Wrong |
|-------|-----------------|-----------------------|
| Item Code | Optional, up to 50 characters, must be unique | "This item code is already in use." |
| Item Name | Required, up to 100 characters | "Item name is required." |
| Item Type | Required — must be SERVICE or PRODUCT | "Item type must be SERVICE or PRODUCT." |
| Item Nature | Required — must be CONSUMABLE, ASSET, SERVICE, or NA | "Item nature must be CONSUMABLE, ASSET, SERVICE, or NA." |
| Category | Required — must pick from the available list | "Category is required and must be valid." |
| Unit | Required — must pick from the available list | "Unit is required and must be valid." |
| Tax Code | Optional, up to 20 characters | — |
| Default Price | Optional, must be a positive number | "Default price must be a positive number." |
| Reorder Level | Optional, must be a positive number | "Reorder level must be a positive number." |
| Description | Optional, any text | — |
| Active Status | Optional — Yes or No | — |

---

## Error Messages at a Glance

| Situation | Message Shown to User |
|-----------|----------------------|
| Item code already used by another item | "This item code is already in use." |
| Item name not entered | "Item name is required." |
| Wrong item type chosen | "Item type must be SERVICE or PRODUCT." |
| Invalid category chosen | "Category is required and must be valid." |
| Trying to deactivate an item linked to active agreements | "This item is linked to [number] active agreement(s): [reference numbers]. Are you sure you want to deactivate it?" |
| Trying to delete a category that is still used by existing items | "Cannot delete because this record is linked to existing items." |

---

## Example Scenario

A school procurement officer wants to catalogue "Whiteboard Markers (Box of 10)" as a Product of nature Consumable. They assign the code "ITM-001", set the default price to ₹250, set the reorder level to 20 units, and pick "Stationery" as the category. They enter the tax code "9608" and upload a photo of the markers. Later, this item is selected when creating a vendor agreement with a stationery supplier.

---

## Success Scenarios

**SC-001 — Creating a Product Item**
A user creates item "A4 Paper Ream" with code "ITM-010", type Product, nature Consumable, category "Stationery", unit "Box", default price ₹500, reorder level 50, tax code "4802". The system saves it successfully. The item is Active and visible.

**SC-002 — Uploading an Item Photo**
A user edits an item and uploads a photo. The system stores the photo and notes that one has been uploaded.

**SC-003 — Removing and Restoring an Item**
A user removes an item. It disappears from the active list. The user goes to the removed-items list and restores it. The item reappears in the active list.

**SC-004 — Turning Off an Item**
A user switches an item from Active to Inactive. The system confirms the change. The item no longer appears in agreement dropdowns.

---

## Failure Scenarios

**FC-001 — Duplicate Item Code**
A user tries to create an item with code "ITM-001", but that code is already used. The system shows: "This item code is already in use."

**FC-002 — Missing Required Fields**
A user submits the form without entering the item name, type, nature, category, and unit. The system returns all the relevant error messages at once.

**FC-004 — Deleting a Category That Is Still in Use**
A user tries to delete a category that is still linked to existing items. The system prevents the deletion and shows: "Cannot delete because this record is linked to existing items."

---

## Who Can Do What

| Role / Permission | What They Can Do |
|------------------|------------------|
| View Items | View the item list and open item details |
| Create Items | Add new items to the catalogue |
| Edit Items | Modify existing items and turn them on/off |
| Remove Items | Remove items from the active list (can be restored) |
| Restore Items | Bring back removed items |
| Permanently Delete Items | Permanently erase items (cannot be undone) |
| View Removed Items | See the list of items that have been removed |

---

## Dependencies

| What It Depends On | How It Is Used |
|-------------------|----------------|
| **Category and Unit Lists** | The system-maintained lists from which the user picks a category and unit for each item |
| **Vendor Agreement Items** | The link between items and vendor agreements — used to check if an item has active agreements before deactivation |
| **Vendor Agreements** | Used to check active agreement references when warning about deactivation |
| **File Storage** | Stores the item photo when one is uploaded |
| **Activity Log** | Records all create, edit, remove, restore, and delete actions for audit trail |
