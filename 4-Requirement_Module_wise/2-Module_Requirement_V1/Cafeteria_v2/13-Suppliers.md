# Suppliers — Business Requirements

## What This Screen Does

The Suppliers screen registers every company or individual that supplies food or materials to the cafeteria — vegetable vendors, dairy suppliers, spice wholesalers, etc. Tracks FSSAI license numbers and expiry dates with automatic expiry alerts.

---

## When This Screen Is Used

- A new food supplier starts delivering and needs to be registered
- Admin needs to update a supplier's contact details or FSSAI license
- A supplier's FSSAI license is about to expire
- A supplier is no longer used and should be deactivated

---

## Key Fields at a Glance

**Supplier Name**
Company name — e.g., "Fresh Vegetables Co.," "Amul Dairy."

**Contact Information**
Contact person name, phone number, email address.

**Address**
Business address for delivery coordination.

**FSSAI License**
License number and expiry date. Two-tier expiry alerts (30-day warning, 7-day critical).

**Supply Categories**
Multi-select: Vegetables, Fruits, Grains, Pulses, Dairy, Spices, Beverages, Condiments, Cleaning, Other.

**Status**
Active or Inactive.

---

## Business Rules and Conditions

**FSSAI Expiry Alerts (BR-CAF-014)**
30-day warning: Yellow badge. 7-day critical: Red badge + notification. Nightly cron checks all suppliers.

**Soft Delete Protection**
Cannot delete supplier with existing stock items. Items must be reassigned first. ON DELETE SET NULL at DB level.

**Supply Categories**
JSON array, max 20 categories. Duplicates removed. Standard values suggested.

---

## Workflow Steps

**Adding a Supplier**
Enter company details → contact info → optional FSSAI details → select supply categories → submit.

**Viewing Suppliers**
List shows name, contact, FSSAI expiry colour badge. Green = >60 days, Yellow = 30-60, Orange = 7-30, Red = <7 days or expired.

**Editing / Deactivating**
Update any field. Toggle status to Inactive to hide from stock item dropdowns.

---

## Example Scenario

**GreenLeaf Vegetables:** FSSAI-1234567890, expires Dec 31, 2026 (yellow badge — 45 days away). Supply categories: Vegetables, Fruits.
**Amul Dairy:** Supply categories: Dairy, Beverages.
**Kumar Spices:** Supply categories: Spices, Condiments.

When any supplier's FSSAI is within 7 days of expiry, dashboard shows critical alert.

---

## Related Screens

- **Stock Items** — Each stock item can reference a preferred supplier
- **FSSAI** — School's own FSSAI license compliance records
