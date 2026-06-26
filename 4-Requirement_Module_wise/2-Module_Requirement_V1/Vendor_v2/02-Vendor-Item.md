# Vendor Item — Business Requirements

## What This Screen Does

The Vendor Item screen is where the school defines all the goods and services that vendors supply. Before any agreement is created between the school and a vendor, the specific items being purchased or contracted must exist in this master list.

Think of Vendor Items as a catalogue of everything the school can ever procure — for example, "Bus Route Service," "Security Guard Service," "Drinking Water Supply," "Canteen Tray Supply," or "Annual Maintenance Contract." Each item is defined once here and then reused across multiple vendor agreements.

---

## When This Screen Is Used

- School needs to register a new type of service or product that a vendor will supply (e.g., "CCTV Maintenance Service")
- Admin wants to update an item's description, category, unit of measurement, or default price
- An item is no longer being procured and should be deactivated
- Finance team needs to search or filter items by category or type before creating a new agreement

---

## Key Fields at a Glance

**Item Code**
A short unique identifier for the item, like BUS-001, SEC-GUARD, or CANTEEN-TRAY. This helps quickly identify items in dropdowns and reports.

**Item Name**
A clear, human-readable name for the item — for example, "Bus Route Monthly Service," "Security Guard Deployment," or "RO Water Supply."

**Item Type**
Whether the item is a **Service** (something done, like maintenance or transport) or a **Product** (something physically supplied, like stationery or water bottles). This classification helps with GST calculations and reporting.

**Item Nature**
Defines how the item is tracked — whether it is a regular recurring item or a one-time procurement.

**Category**
A broader classification such as Transport, Canteen, Security, IT, Maintenance, etc. This is picked from a master dropdown list. Categories help group and filter items in reports.

**Unit of Measurement**
How the item is measured — Per Month, Per Trip, Per Unit, Per Hour, Per Day, etc. This unit appears on invoices and helps calculate the total billable amount.

**HSN / SAC Code**
The government-assigned tax classification code for the item. HSN codes are for products; SAC codes are for services. These are required for GST-compliant invoicing.

**Default Price**
A suggested rate per unit for this item. This acts as a starting reference when setting up an agreement but can be overridden in the agreement itself.

**Reorder Level**
For consumable products, the minimum stock quantity at which a reorder should be triggered. Not applicable for service-type items.

**Photo Upload**
A photo of the physical item can be attached. Mostly relevant for product-type items (e.g., uniforms, stationery boxes).

---

## Business Rules and Conditions

**Unique Item Code**
No two items in the same school can share the same item code. The system must reject duplicate codes.

**Item Type Determines Fields**
If the item type is Service, the reorder level and photo fields are typically not applicable. If it is a Product, all fields including reorder level are relevant.

**HSN/SAC Code Requirement**
For GST-compliant invoicing, the HSN or SAC code must be filled. The system should warn if this is missing when the item is linked to an agreement.

**Deactivation Safety Check**
If an item is currently linked to an active agreement, it cannot be deactivated without a warning. Admin should resolve active agreements first.

**Reorder Level is Optional**
For service items, the reorder level field can be left empty. For product items, setting this value allows the system (or admin) to be alerted when procurement is needed.

---

## Workflow Steps

**Adding a New Item**
Admin opens the Add Vendor Item form, enters an item code and name, selects the item type (Service/Product), picks a category from the dropdown, selects the unit of measurement, enters the HSN/SAC code, optionally fills the default price and reorder level, writes a description, and submits.

**Viewing Items**
The item list page shows all items with filters — filter by category, type, or status. Each row shows item code, name, category, unit, and active status.

**Editing an Item**
Admin can change any field. If the item is already in use in an agreement, changing the name or unit of measurement should be done carefully as it may affect invoice presentation.

**Deactivating an Item**
Admin uses the status toggle on the list screen. An inactive item no longer appears in agreement setup dropdowns but remains visible in historical invoices.

---

## Example Scenarios

**Service Item**
Item Code: BUS-ROUTE-01, Item Name: "Monthly Bus Route Service," Type: Service, Category: Transport, Unit: Per Month, SAC Code: 996511, Default Price: ₹25,000. This item is used when creating a transport agreement with a bus vendor.

**Product Item**
Item Code: WATER-JAR, Item Name: "20L RO Water Jar," Type: Product, Category: Canteen, Unit: Per Jar, HSN Code: 2201, Default Price: ₹35, Reorder Level: 20. When stock goes below 20 jars, admin is alerted.

**Service Item (Security)**
Item Code: SEC-GUARD, Item Name: "Security Guard Deployment," Type: Service, Category: Security, Unit: Per Month Per Guard, SAC Code: 998524, Default Price: ₹18,000. Multiple guards can be contracted using this same item.

---

## Related Screens

- **Vendor Agreement** — Items are selected when defining what a vendor will supply under an agreement
- **Vendor Invoice** — Invoice line items reference these master items for proper billing
