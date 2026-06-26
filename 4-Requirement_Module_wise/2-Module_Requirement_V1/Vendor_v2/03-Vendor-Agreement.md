# Vendor Agreement — Business Requirements

## What This Screen Does

The Vendor Agreement screen is where the school records the formal contract between itself and a vendor. Once a vendor is registered in the system, the school must create an agreement that defines what the vendor will supply, for how long, under what billing terms, and what the pricing structure looks like.

Think of the Vendor Agreement as the digital version of the signed contract. It captures all the critical terms — start date, end date, billing cycle, payment deadline, and the specific items (services or products) being contracted — and links everything to one agreement reference number.

Every invoice and payment in the system traces back to a specific agreement. Without an agreement, billing cannot begin.

---

## When This Screen Is Used

- School signs a new contract with a vendor (e.g., a new transport company or canteen supplier) and needs to record the terms
- An existing agreement is expiring and needs to be renewed with updated pricing or new items
- Admin wants to view all active agreements to track which contracts are currently operational
- Finance team needs to check the billing cycle or payment terms of a specific vendor agreement before raising an invoice
- An agreement is terminated early and needs to be marked as Terminated in the system

---

## Key Fields at a Glance

**Agreement Reference Number**
A unique identifier for this agreement — for example, AGR-2025-BUS-001. This number is printed on all invoices generated under this agreement and helps trace any billing query back to its source contract.

**Linked Vendor**
The vendor this agreement belongs to. Only active vendors from the Vendor Master can be selected.

**Agreement Period — Start Date and End Date**
The duration of the contract. The start date is when the vendor begins providing services, and the end date is when the contract expires. For example, 1 April 2025 to 31 March 2026 for an annual transport contract.

**Agreement Status**
Each agreement moves through a lifecycle:
- **Draft** — The agreement has been entered in the system but is not yet operational
- **Active** — The agreement is currently running and billing can proceed
- **Expired** — The end date has passed and no further invoices should be raised
- **Terminated** — The agreement was cancelled before its natural end date

**Billing Cycle**
How frequently the vendor expects to be billed:
- **Monthly** — Invoice raised every month (e.g., security guards, bus routes)
- **One-Time** — A single payment for the entire contract (e.g., a one-time setup fee)
- **On-Demand** — Invoice raised only when a service is consumed or triggered (e.g., repair calls)

**Payment Terms (Days)**
The number of days within which the school must pay an invoice after it is raised. For example, 30 days means if an invoice is raised on 1 May, the school must pay by 31 May.

**Agreement Document Upload**
A scanned copy of the signed physical agreement (PDF or image) can be uploaded. This serves as the digital archive of the original contract.

**Remarks**
Any additional notes about the agreement — special conditions, verbal commitments, or internal notes.

---

## Agreement Items — The Core of an Agreement

Each agreement contains one or more **Agreement Items**. These define exactly what is being billed under this agreement and at what rate.

**Item Selection**
The specific product or service from the Vendor Item master. For example, "Monthly Bus Route Service" or "Security Guard Deployment."

**Billing Model**
How the billing amount is calculated for this item:
- **Fixed** — A flat amount regardless of usage. Example: ₹25,000 per month for one bus route, no matter how many trips are made.
- **Per Unit** — Billed based on actual usage multiplied by a unit rate. Example: ₹35 per 20L water jar, with 200 jars consumed = ₹7,000.
- **Hybrid** — A fixed base amount plus a per-unit charge on usage above a guaranteed minimum. Example: ₹10,000 fixed + ₹50 per trip above 100 guaranteed trips.

**Fixed Charge**
The flat monthly or one-time amount applicable when billing model is Fixed or Hybrid.

**Unit Rate**
The price per unit used when billing model is Per Unit or Hybrid.

**Minimum Guarantee Quantity**
In Hybrid billing, this is the minimum usage quantity that the fixed charge covers. Usage above this is billed additionally. Example: The school guarantees a minimum of 100 bus trips per month. Anything above 100 is billed at ₹50 per trip.

**Tax Percentages (Tax1, Tax2, Tax3, Tax4)**
Multiple tax rates (e.g., CGST, SGST, IGST, TDS) can be applied to each item. The system calculates the total tax and adds it to the sub-total to arrive at the net payable amount.

**Related Entity**
For transport-related items, the agreement item can be linked to a specific vehicle or driver/helper. For example, the "Monthly Bus Route Service" item can be linked to Vehicle KA-01-AB-1234, making it clear which vehicle this billing line corresponds to.

---

## Business Rules and Conditions

**Unique Agreement Reference Number**
No two agreements within the same school can have the same reference number. The system rejects duplicates.

**End Date After Start Date**
The agreement end date must always be after the start date. An agreement that runs from March 2026 to January 2025 is invalid and should be rejected.

**At Least One Item Required**
An agreement must have at least one agreement item before it can be moved from Draft to Active. An agreement with no items cannot be invoiced.

**Status Transitions**
- Draft → Active: Only when the agreement has at least one active item
- Active → Expired: Happens automatically when today's date crosses the end date
- Active → Terminated: Admin can manually terminate a running agreement with a reason
- Expired / Terminated → Active: Should not be allowed unless dates are revised

**Billing Cycle Drives Invoice Generation**
The billing cycle (Monthly, One-Time, On-Demand) determines how and when invoices are generated under this agreement:
- Monthly agreements generate one invoice per billing period
- One-Time agreements generate a single invoice and then no further billing
- On-Demand agreements generate invoices only when admin triggers generation (based on usage log data)

**Duplicate Invoice Prevention**
For the same agreement item, the system must not allow two invoices for the same billing period. If an invoice already exists for a given start-date to end-date range, a duplicate cannot be generated.

**Agreement Document Upload**
Once an agreement is moved to Active, uploading the signed document (PDF) should be strongly recommended. The uploaded flag is tracked and visible in the agreement list.

---

## Workflow Steps

**Creating an Agreement**
Admin selects the vendor, fills in the agreement reference number, sets start and end dates, selects billing cycle, enters payment terms (e.g., 30 days), adds remarks, and saves. The agreement is created in Draft status.

**Adding Items to the Agreement**
After saving the agreement, admin adds one or more agreement items — selecting the item from the master, choosing the billing model, filling in the fixed charge or unit rate, setting tax percentages, and optionally linking a vehicle or driver.

**Activating the Agreement**
Once all items are added and the physical agreement is signed, admin changes the status from Draft to Active. From this point, billing can begin.

**Uploading the Agreement Document**
Admin uploads the scanned agreement PDF. The system marks the document as uploaded.

**Viewing Agreements**
The agreement list shows all agreements with filters for vendor, status, and date range. Each row shows reference number, vendor name, period, billing cycle, status, and whether the document is uploaded.

**Editing an Agreement**
Admin can edit dates, billing cycle, payment terms, or items. If the agreement is Active and invoices have already been generated, editing rates or items should be done with caution as it does not retroactively change past invoices.

**Terminating an Agreement**
Admin changes the status to Terminated. The agreement is closed and no further invoices can be generated under it.

---

## Example Scenario

The school signs a 1-year contract with "Sharma Transport Services" for running three bus routes. Admin creates an agreement:
- Reference: AGR-2025-BUS-001
- Vendor: Sharma Transport Services
- Period: 1 April 2025 to 31 March 2026
- Billing Cycle: Monthly
- Payment Terms: 30 days

Three agreement items are added — one for each bus route:
1. Route A — "Monthly Bus Route Service," Billing Model: Fixed, Fixed Charge: ₹18,000, GST: 18%
2. Route B — "Monthly Bus Route Service," Billing Model: Fixed, Fixed Charge: ₹20,000, GST: 18%
3. Route C — "Monthly Bus Route Service," Billing Model: Hybrid, Fixed: ₹15,000, Unit Rate: ₹50/trip, Min Guarantee: 100 trips, GST: 18%

The agreement is activated. Each month, finance generates an invoice per route item and records payments as they are received.

---

## Related Screens

- **Vendor Master** — A vendor must be registered before an agreement can be created
- **Vendor Item** — Items must be defined before they can be added to an agreement
- **Vendor Invoice** — Invoices are generated from agreement items under this agreement
- **Usage Log** — For Per Unit or Hybrid billing, usage is tracked and referenced during invoice generation
