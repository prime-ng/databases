# Fuel Log — Business Requirements

## What This Screen Does

The Fuel Log screen records every time a school vehicle is refuelled. Each fuel entry captures which vehicle was filled, how many litres were pumped, the total cost, the fuel type (Diesel, Petrol, CNG, or Electric charging), the driver who was operating the vehicle, the odometer reading at the time of refuelling, and the date of the transaction. Every fuel entry starts with a Pending status and must be approved by a supervisor before it is considered final.

Without this screen, the school would have no central record of fuel consumption across the fleet. The Transport Manager would rely on paper receipts from drivers — receipts that get lost, faded, or forgotten. There would be no way to answer questions like "How much did we spend on diesel last month?" or "Which bus is giving the lowest mileage?" or "Is Driver A refuelling more frequently than Driver B on the same route?" The Fuel Log turns a messy pile of petrol pump receipts into a structured, auditable record of every rupee spent on keeping the fleet moving.

The screen appears in two contexts:
1. **Vehicle Management → Fuel Log tab** — A paginated list loaded by `VehicleMgmtController@fuelEntryQuery()`.
2. **Standalone CRUD** — Full resource via `TptVehicleFuelController` with create/edit/show/trash/restore/forceDelete and status approval.

---

## Default Data Load

When the Transport Manager opens Vehicle Management and clicks the Fuel Log tab, the system loads the most recent fuel entries — 10 per page — showing the vehicle registration number, driver name, date, quantity in litres, total cost, fuel type, and current approval status. A search box at the top allows searching by vehicle registration number or driver name. A status filter dropdown lets the manager view only Pending, Approved, or Rejected entries.

When the Fuel Log is accessed through the standalone menu item, the same list appears with the same search and filter options.

---

## When This Screen Is Used

- **Recording a Fuel Purchase** — A driver fills up Bus KL-05 with 50 litres of diesel at the Bharat Petroleum pump near the school and brings the receipt to the Transport Manager. The manager opens the Fuel Log, clicks Add Entry, and records the vehicle, driver, date, quantity (50 litres), cost (₹4,750), fuel type (Diesel), and the current odometer reading (1,25,340 km). The entry is saved with a "Pending" status.

- **Approving Fuel Entries at End of Week** — Every Friday, the Fleet Supervisor reviews all pending fuel entries. For each one, they check the receipt against the recorded quantity and cost. If everything matches, they click Approve and the entry turns green. If the receipt shows a different amount than what was entered, they click Reject and ask the driver to resubmit with the correct figures.

- **Monthly Fuel Cost Analysis** — The School Administrator runs a report at the end of each month to see total fuel expenditure. They filter the Fuel Log by date range (1st to 30th) and look at the Approved entries only. The system shows that the fleet of 12 buses consumed 3,200 litres of diesel this month at a cost of ₹3,04,000 — an increase of 8% over last month.

- **Investigating a Discrepancy** — The Transport Manager notices that Bus KL-07 has been refuelled 8 times this month while other buses on similar routes have only been refuelled 4-5 times. They open the Fuel Log, filter by Bus KL-07, and compare the entries — the odometer readings suggest the bus has been running more trips than usual, so the higher fuel consumption is justified. Without the odometer reading field, this investigation would be impossible.

---

## Key Fields at a Glance

**Vehicle and Driver Information**
Every fuel entry must be linked to a specific vehicle from the fleet — you cannot record fuel without saying which bus or van was filled. The driver who was operating the vehicle at the time of refuelling is also recorded, linking the fuel cost to the person responsible. If the driver field is left empty (for example, when a fleet supervisor filled the vehicle directly), the entry can still be saved.

**Transaction Details**
The date of refuelling is captured so fuel consumption can be analysed by day, week, or month. The quantity field records how many litres were pumped, accurate to three decimal places (for example, 45.750 litres). The cost field records the total amount paid in rupees, accurate to two decimal places. Together, quantity and cost allow the system to calculate the per-litre price and track fuel cost trends over time.

**Fuel Type**
The type of fuel used (Diesel, Petrol, CNG, or an Electric charging equivalent) is stored as a reference to the school's global dropdown configuration. This allows the school to add new fuel types in the future without changing the software.

**Odometer Reading**
An optional field records the vehicle's odometer reading at the time of refuelling. This is critical for calculating mileage (kilometres per litre) — without it, the system can track how much was spent but cannot answer the question "Is this vehicle's fuel efficiency acceptable?" The reading is compared against the previous entry for the same vehicle to compute distance travelled since the last fill.

**Approval Status**
Every fuel entry starts as "Pending" by default. An authorised person must review the entry and change its status to "Approved" or "Rejected". Only approved entries are counted in fuel cost reports. The status can be changed later if needed — for example, an approved entry can be moved back to "Pending" if a discrepancy is discovered later.

---

## Business Rules and Conditions

**Entries Start as Pending by Default**
Every new fuel entry is automatically assigned a "Pending" status. This is not configurable — the system always defaults to Pending. The reasoning is simple: fuel consumption is a direct cost to the school, and every expense must be verified before it becomes official. A supervisor must explicitly approve each entry.

**Approval Is Required for Reporting**
Only entries with "Approved" status are counted in fuel cost reports and dashboard calculations. Pending entries appear in the list but are excluded from totals. This prevents unverified receipts from skewing monthly fuel expenditure figures.

**No Automatic Mileage Calculation**
While the system captures odometer readings and quantity, it does not automatically compute or display kilometres-per-litre mileage for each entry. The data required for mileage calculation exists in the system, but the actual computation would need to be done manually or through a custom report.

**Search Supports Vehicle Number and Driver Name**
When searching the fuel log, the system looks for matches in the vehicle's registration number and the driver's name. It does not search by quantity, cost, date, or fuel type. If a manager wants to find all entries above ₹5,000, there is no built-in way to do so through the search box.

**Fuel Type Is a Configurable Dropdown**
The fuel type field is not a simple text box — it references the school's global dropdown configuration. This means the list of available fuel types (Diesel, Petrol, CNG, Electric) can be customised by the school. However, the values are shared across all modules that use fuel types, so changing the list here affects other parts of the system.

---

## Workflow Steps

**Recording a Fuel Purchase from a Receipt**
Driver Venkatesh has just filled Bus KL-05 with 50 litres of diesel at the Indian Oil pump near the school. He brings the receipt to Mrs. Desai, the Transport Manager. Mrs. Desai opens the Fuel Log tab and clicks Add Entry. She selects "KL-05 (KA-01-EX-1234)" from the vehicle dropdown — only active vehicles are shown. She selects "Venkatesh" from the driver dropdown. She enters today's date, 50.000 litres as the quantity, ₹4,750.00 as the total cost, "Diesel" as the fuel type, and the odometer reading of 1,25,340 kilometres. She optionally adds a remark: "Filled at Indian Oil, HAL Road." She clicks Save. The entry appears in the list with a yellow "Pending" badge. The amount is not yet counted in any fuel cost report.

**Approving a Batch of Pending Fuel Entries**
It is Friday afternoon. Mr. Sharma, the Fleet Supervisor, opens the Fuel Log and sets the status filter to "Pending." He sees 12 entries from the week. He opens the first one, checks the receipt against the recorded data, and clicks the Approve button. The system changes the status to "Approved," logs the action, and moves to the next entry. For one entry where the receipt shows ₹2,300 but the entry says ₹2,500, Mr. Sharma clicks Reject and notes in the activity log: "Receipt amount does not match — driver asked to resubmit."

**Investigating a Vehicle's High Fuel Consumption**
Mrs. Desai notices that Bus KL-07 has been refuelled 9 times this month — almost twice as often as the other buses. She opens the Fuel Log, types "KL-07" in the search box, and sees all entries for this bus. The odometer readings show that Bus KL-07 has been running 15% more kilometres than average because it was temporarily covering a second route while another bus was in the workshop. The higher consumption is justified. She makes a note in her records and moves on.

---

## Example Scenario

Green Valley School operates 12 buses and 2 vans. The fleet runs on diesel, and the monthly fuel bill averages around ₹3,00,000. The Transport Manager, Mrs. Desai, needs to track every litre consumed.

In the first week of October, Bus KL-05 (registration KA-01-EX-1234) is refuelled three times:
- Monday: 45 litres, ₹4,275, odometer 1,25,340 km
- Wednesday: 50 litres, ₹4,750, odometer 1,25,890 km
- Friday: 42 litres, ₹3,990, odometer 1,26,310 km

Mrs. Desai records all three entries. Each one shows as "Pending."

On Saturday morning, the Fleet Supervisor opens the Fuel Log, sees the three pending entries, checks the receipts against the recorded figures, and approves all three. The approved entries are now counted in the month's fuel totals.

At the end of October, Mrs. Desai opens the Fuel Log, sets the date range to October 1st to 31st, and sees that the fleet consumed 3,150 litres of diesel at a cost of ₹2,99,250. Bus KL-07 consumed the most (410 litres), while Van VN-03 consumed the least (85 litres). She exports this data for the monthly operations report.

---

## Related Screens

- **Vehicle Master** — Each fuel entry is linked to a specific vehicle registered here. The vehicle's registration number and details are displayed alongside fuel entries.
- **Vehicle Management Dashboard** — The dashboard shows total fuel consumption and cost for the current month, drawing data from approved fuel entries only.
- **Driver/Staff Records** — Each fuel entry can optionally be linked to a driver. The driver's name appears in the fuel entry list.

---

## Requirements

- Controller: `TptVehicleFuelController` with full resource methods plus `trashed`, `restore`, `forceDelete`, `updateStatus` (approval)
- Hub tab data: Loaded via `VehicleMgmtController@fuelEntryQuery()` with search and status filters
- Model: `TptVehicleFuel` (table: `tpt_vehicle_fuel`) — SoftDeletes, status defaults to Pending
- Form Request: `TptVehicleFuelRequest` — validates vehicle_id, driver_id, date, quantity, cost, fuel_type, odometer_reading, remarks, status
- Policy: `TransportVehicleFuelPolicy` (`tenant.vehicle-fuel.*`)
- Activity logging: ✅ Present on Stored, Updated (field-level changes), Trashed, Restored, Deleted, StatusUpdated
- Permissions: `tenant.vehicle-fuel.{viewAny, view, create, update, delete, restore, forceDelete, approve}`

---

## Who Can Access

- **Transport Manager** — Full control over fuel entries. They can create new entries, edit existing ones (including correcting quantity or cost), approve or reject pending entries, soft-delete incorrect records, restore accidentally deleted entries, and permanently remove test data. This is the primary user who manages fuel tracking.

- **Fleet Supervisor** — Can view all fuel entries and change the approval status from Pending to Approved or Rejected after verifying receipts. They can also edit basic fields like remarks but cannot delete entries.

- **School Administrator** — Read-only access to the fuel log. They can view entries and run reports on fuel consumption and costs, but cannot create, edit, approve, or delete any records.

- **Driver** — Does not have access to this screen. Drivers submit physical receipts to the Transport Manager, who enters the data into the system.

Behind the scenes, each action is protected by a permission check. If a user tries to perform an action they are not authorised for, the system displays an "Access Denied" message.

---

## Logic Flow

When the Transport Manager clicks the Fuel Log tab in Vehicle Management, the system loads the most recent fuel entries from the database — 10 per page — along with each entry's linked vehicle and driver information. The list shows the date, vehicle registration number, driver name, quantity in litres, total cost, fuel type, and a coloured badge showing whether the entry is Pending (yellow), Approved (green), or Rejected (red).

When the manager clicks "Add Entry," a form appears with dropdown lists for selecting the vehicle (only active vehicles that are currently in the fleet are shown) and the driver (any registered staff member can be selected, or left blank). The manager fills in the date, quantity, cost, fuel type, odometer reading (optional), and any remarks. When they click Save, the system checks that the vehicle exists, that the quantity is a positive number, that the cost is a valid amount, and that the fuel type is one of the configured options. If everything is valid, the entry is saved with a default status of "Pending," and the action is recorded in the activity log.

When the manager clicks Edit on an existing entry, the form loads with all current values pre-filled. The manager can change any field. On save, the system compares the old and new values and records exactly which fields changed in the activity log. If nothing changed, it notes "No changes were made."

When the manager clicks the Approve or Reject button next to a pending entry, the system updates the status and records the action in the activity log. An approved entry cannot be accidentally rejected later and vice versa — the manager must explicitly change it back if needed.

When the manager clicks Delete, the system does not erase the entry. It hides it from the main list and moves it to the Trash folder. From the Trash view, the manager can either Restore the entry (bringing it back to the main list with its original status) or permanently delete it.

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Vehicle | Must be selected and must exist in the fleet | "Please select a vehicle." |
| Driver | Optional — if provided, must be a valid staff member | "The selected driver is invalid." |
| Date | Must be a valid date | "Please enter a valid date." |
| Quantity (Litres) | Must be provided, must be a positive number | "Please enter the quantity in litres." |
| Cost (₹) | Must be provided, must be a valid amount | "Please enter the total cost." |
| Fuel Type | Must be selected from the configured options | "Please select a fuel type." |
| Odometer Reading | Optional — if provided, must be a whole number | "The odometer reading must be a valid number." |
| Approval Status | Must be Pending, Approved, or Rejected | "The status is invalid." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Vehicle not selected | "Please select a vehicle." — the form does not submit | Data entry error |
| Quantity is zero or negative | Validation error — the form blocks submission | Data entry error |
| Cost is negative or missing | Validation error — the form blocks submission | Data entry error |
| Invalid date format | "Please enter a valid date." — the form blocks submission | Data entry error |
| User tries to approve without permission | System shows "Access Denied" | Permission error |
| Fuel type not in dropdown list | The dropdown is empty or shows no options — form cannot be submitted until an option is selected | Configuration error — fuel types not set up |
| Odometer reading entered as text instead of number | Validation error — the form blocks submission | Data entry error |
| Driver accidentally assigned to wrong vehicle in the entry | No warning — the system saves the entry with the wrong driver-vehicle combination | Data entry gap — no cross-check |

---

## Success Scenarios — When Everything Works

**SC-001 — Recording and Approving a Week's Fuel Entries**
Mrs. Desai records 15 fuel entries over the course of a week — one for each refuelling event across the 12-bus fleet. At the end of the week, the Fleet Supervisor opens the list, reviews each entry against the paper receipts, and approves 14 of them (one is rejected because the receipt shows ₹2,300 but the entry says ₹2,500). The 14 approved entries are now included in the monthly fuel cost report. The rejected entry is sent back to the driver for correction.

**SC-002 — Analysing Monthly Fuel Costs**
At the end of the month, the School Administrator opens the Fuel Log, sets the date range to cover the full month, and sees the total cost of all approved entries: ₹3,12,450 for 3,280 litres of diesel across the fleet. This data is exported for the monthly management meeting. Bus KL-07 shows the highest consumption at 430 litres, which is flagged for investigation.

**SC-003 — Correcting a Mistaken Entry**
Mrs. Desai accidentally entered 55 litres instead of 45 litres for Bus KL-05's Tuesday refuelling. She notices the error the next day, opens the entry, corrects the quantity from 55 to 45, and adjusts the cost from ₹5,225 to ₹4,275. The system logs the changes. The corrected entry shows accurate data in the monthly report.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Fuel Entry Approved Without Receipt Verification**
The Fleet Supervisor approves a batch of fuel entries without checking the physical receipts. Driver Venkatesh has entered 60 litres for Bus KL-07, but the receipt shows only 45 litres. The inflated entry is approved and counted in the monthly fuel report, overstating the school's fuel expenditure by ₹1,425. There is no mechanism in the system to flag entries where the quantity is significantly higher than the vehicle's average or where the odometer reading does not match the expected distance travelled.

**FC-002 — No Mileage Calculation**
The system captures odometer readings and litres filled — all the data needed to calculate kilometres-per-litre mileage for each vehicle. However, this calculation is not performed automatically. If the Transport Manager wants to know whether Bus KL-05's fuel efficiency has decreased over time, they must export the data and calculate mileage in a spreadsheet. A bus with worsening mileage (indicating a developing mechanical issue) could go unnoticed until it becomes a serious problem.

**FC-003 — Rejected Entry Stays in Pending Limbo**
When the Fleet Supervisor rejects a fuel entry, the status changes to "Rejected" and the entry remains in the list. However, the system does not notify the driver or the Transport Manager that the entry was rejected. If nobody is paying attention, the rejected entry could sit in the list indefinitely, never corrected and never re-submitted — meaning the fuel cost is never recorded and the month's totals are incomplete.

**FC-004 — Search Cannot Find Entries by Cost or Quantity**
A Transport Manager wants to find all fuel entries where the cost exceeded ₹5,000 to check for unusually large purchases. The search box only searches by vehicle registration number and driver name — it does not search by cost, quantity, date, or fuel type. The manager must manually scroll through the paginated list to find high-value entries, which is impractical with hundreds of entries per month.