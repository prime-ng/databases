# Usage Log — Business Requirements

## What This Screen Does

The Usage Log screen is where the school records the actual consumption of a vendor's services or products. This data directly feeds into the invoice generation process for vendors who are billed on a Per Unit or Hybrid basis.

Think of the Usage Log as the school's service consumption diary. For example, if the school has a contract with a water jar supplier where billing is per jar consumed, every time 20L water jars are received, the count is logged here. At month-end, the system reads these logs and uses the total quantity to calculate the invoice amount automatically.

Without usage logs, the system cannot accurately bill for per-unit or hybrid agreements. For fixed billing agreements, usage logs are optional (the amount is fixed regardless of usage) but may still be maintained for internal tracking purposes.

---

## When This Screen Is Used

- A vendor delivers a batch of goods (e.g., 50 water jars) and the delivery is being recorded in the system
- A service has been consumed (e.g., a bus made 15 trips this week) and the count needs to be updated
- Admin wants to review total usage for a vendor for a given period before approving invoice generation
- Finance wants to cross-check usage data against the vendor's own invoice/delivery challan
- A usage log entry was entered incorrectly and needs to be edited or deleted

---

## Key Fields at a Glance

**Vendor**
The vendor whose service or product was consumed. Selecting the vendor filters the relevant agreement items to show in the next field.

**Agreement Item**
The specific item from the vendor's agreement for which usage is being logged. For example, if Sharma Transport Services has three route items, you select the specific route for which the trip count is being logged.

**Usage Date**
The date on which the service was consumed or the product was received. This is important for linking usage to the correct billing period.

**Quantity Used**
The actual quantity consumed on this entry. For example:
- 50 jars received on 5 May → Qty = 50
- 15 bus trips made on 10 May → Qty = 15
- 1 maintenance call completed on 15 May → Qty = 1

**Remarks**
Any additional notes about this specific usage entry — for example, "Emergency water delivery for Annual Day" or "Extra trips due to exam schedule."

**Logged By**
The system automatically records which logged-in user made this log entry. This creates a clear audit trail.

---

## Business Rules and Conditions

**Agreement Item Must Be Active**
Usage can only be logged for an agreement item that is currently active. Logging usage against an inactive or expired agreement item is not permitted.

**Usage Date Must Be Reasonable**
Usage date should typically fall within the agreement period (between the agreement's start and end dates). Logging usage for a period outside the agreement's duration should be flagged or prevented.

**Quantity Must Be Positive**
The quantity used must be a positive number greater than zero. Negative or zero quantities are not valid log entries.

**Cumulative Usage for Invoice Calculation**
When an invoice is generated for a Per Unit or Hybrid agreement item, the system sums all usage log entries for that vendor and that agreement item to arrive at the total quantity. For example:
- 5 May: 50 jars
- 12 May: 80 jars
- 20 May: 60 jars
- Total for invoice = 190 jars

**Minimum Usage of 1**
If no usage has been logged for an agreement item and an invoice is generated anyway, the system defaults to a minimum quantity of 1. This prevents zero-value invoices and ensures at least a base charge is applied.

**Usage Log Does Not Auto-Reset After Invoice**
Usage logs remain in the system after an invoice is generated. The logs are not deleted or reset. The finance team must be aware that for subsequent billing cycles, previous usage logs continue to accumulate unless the billing period is carefully tracked.

**Edit and Delete**
Usage log entries can be edited or deleted by authorised admin users. Deleting a log entry will reduce the cumulative usage count and may affect future invoice calculations if not yet invoiced.

---

## Workflow Steps

**Logging New Usage**
Admin opens the Add Usage Log form (accessible from the Usage Log tab), selects the vendor, selects the specific agreement item, enters the usage date, enters the quantity consumed, adds optional remarks, and submits. The log is saved and immediately counted in the total for the next invoice generation.

**Viewing Usage Logs**
The usage log list can be filtered by vendor and by date. Each row shows the vendor name, agreement item, usage date, quantity used, remarks, and the user who logged the entry.

**Editing a Usage Log**
If a quantity was entered incorrectly (e.g., 50 jars logged instead of 5), admin can click Edit, correct the value, and save. The change affects the cumulative total immediately.

**Deleting a Usage Log**
Admin can delete an incorrect log entry. A confirmation prompt appears. On deletion, the entry is soft-deleted and no longer counted in future invoice calculations.

---

## Example Scenarios

**Scenario 1 — Water Jar Supplier (Per Unit Billing)**
The school has a contract with "AquaPure Water Supply" for 20L water jars at ₹35 per jar. Billing is Per Unit.

Usage logs for May 2025:
- 1 May: 20 jars (summer season starts, refill stock)
- 8 May: 30 jars (mid-week delivery)
- 15 May: 25 jars (regular delivery)
- 22 May: 40 jars (pre-exam extra stock)
- 29 May: 20 jars (end of month)

Total jars = 135

When finance generates the May invoice, the system reads usage total = 135 jars.
Invoice amount = 135 × ₹35 = ₹4,725 + GST 12% = ₹5,292

**Scenario 2 — Transport (Hybrid Billing)**
Contract with "Sharma Transport Services" for Route C:
- Fixed charge: ₹15,000/month
- Unit rate: ₹50/trip above 100 trips (minimum guarantee)

Usage logs for April 2025:
- Week 1: 28 trips
- Week 2: 31 trips
- Week 3: 35 trips
- Week 4: 30 trips

Total trips = 124

Billable qty above minimum = 124 - 100 = 24 trips
Variable charge = 24 × ₹50 = ₹1,200
Sub-total = ₹15,000 + ₹1,200 = ₹16,200
GST 18% = ₹2,916
Net Payable = ₹19,116

**Scenario 3 — Maintenance (On-Demand)**
The school has a contract with "TechFix Solutions" for CCTV maintenance at ₹2,500 per service call.

Usage logs:
- 10 April: 1 call (camera replacement at Gate 1)
- 25 April: 1 call (DVR servicing)

Total calls = 2
Invoice = 2 × ₹2,500 = ₹5,000 + GST 18% = ₹5,900

---

## Related Screens

- **Vendor Agreement** — Usage is always logged against a specific agreement item
- **Vendor Invoice** — The usage log data is consumed during invoice generation for Per Unit and Hybrid billing
