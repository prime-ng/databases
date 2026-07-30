# Trip Approve — Business Requirements

## What This Screen Does

The Trip Approve tab (within the Trip Management hub page) is where authorised personnel review trips and toggle their approval status. A trip is not considered fully confirmed until someone with the right authority opens this tab and flips the toggle switch. The moment a trip is approved, the system calculates the distance the vendor's vehicle travelled and creates a billing record so the vendor can be paid correctly.

Without this screen, trips would run without formal approval. Drivers would take buses out, complete routes, and at the end of the month there would be no central record of which trips were authorised and which were not. Vendors would submit bills based on their own logs, and the school would have no way to verify the distance claimed against the approved data. The Trip Approve tab brings order to the approval process — a single place where every trip must pass through before it becomes official and before any vendor billing can happen.

The screen works for individual trips and for multiple trips at once. Mrs. Desai can toggle a single trip's approval with one click of a switch, or she can select ten trips and approve them all together. If some of those ten trips are already approved, the system skips them during bulk approve — no errors, no double approval. Bulk unapprove processes all selected trips regardless of their current state.

---

## Default Data Load

When the Transport Manager opens the Trip Approve tab, the system loads all trips — 10 per page — showing trip date, route, vehicle, driver, trip status, start/end times, start/end odometer readings, start/end fuel readings, and a toggle switch for approval status (checked = approved, unchecked = unapproved). An "Approval Status" filter at the top lets the manager view only approved trips, only unapproved trips, or all trips together. A search box allows searching by route name/code, vehicle registration number, or driver name.

Each trip in the list shows its current status clearly. An approved trip shows the toggle switch checked. An unapproved trip shows the toggle unchecked. The table does not display the approver's name or approval timestamp in the list view — only the toggle state indicates approval.

---

## When This Screen Is Used

- **Approving a Trip Before It Runs** — Mrs. Desai reviews tomorrow's trip schedule. Bus KL-05 is assigned to the "Jayanagar — North Route" with Driver Venkatesh. She finds the trip in the Trip Approve tab, confirms the odometer readings look correct, and flips the toggle switch to approve. The system sets the trip as approved, records her user ID and the current timestamp, and creates a billing record for the vendor based on the calculated distance.

- **Bulk Approving at the Start of the Week** — Every Monday morning, Mrs. Desai opens the Trip Approve tab and selects all trips for the week that have been scheduled and reviewed. She clicks Approve Selected. The system processes each trip one by one — approving those that are not yet approved and automatically skipping any that were already approved earlier. By the time she finishes her tea, all approved trips have vendor billing records created.

- **Unapproving a Trip That Was Cancelled** — A trip scheduled for Wednesday is cancelled because the school is closed for a holiday. Mrs. Desai finds the trip in the Trip Approve tab, selects it, and clicks Unapprove Selected (or toggles the switch off for a single trip). The system clears the approval fields and deletes the vendor billing record that was created when the trip was approved. The trip returns to an unapproved state.

- **Investigating a Vendor Billing Discrepancy** — A vendor claims that Bus KL-07 travelled 85 kilometres on a particular route, but the approved trip record shows only 65 kilometres. Mrs. Desai opens the Trip Approve tab, finds the approved trip, and checks the calculated distance. She sees that the system calculated 65 kilometres based on the odometer readings (end_odometer 1,25,400 minus start_odometer 1,25,335). The vendor's claim does not match. She flags the discrepancy with the accounts department.

---

## Key Fields at a Glance

**Trip Information**
Each approval is linked to a specific trip. The trip's route number, vehicle, driver, and scheduled timing are displayed so the approver knows exactly what they are approving. There is no way to approve a trip without seeing these details first.

**Approval Status**
A trip is either approved or not approved. There is no in-between state — either someone authorised has given the go-ahead, or they have not. Approval data (`approved`, `approved_by`, `approved_at`) is stored in the `tpt_trip` table.

**Vendor Distance Calculation**
The moment a trip is approved, the system calculates the distance the vendor's vehicle travelled. It takes the end odometer reading from the trip and subtracts the start odometer reading. If the result is negative, the distance is set to zero. The calculated distance is stored in a VndUsageLog record that the billing system uses to pay the vendor. If the trip is later unapproved, this record is deleted.

---

## Business Rules and Conditions

**Approval Creates Vendor Billing Record Automatically**
When a trip is approved, the system does two things at once: it marks the trip as approved, and it creates a VndUsageLog record. The distance in this record is calculated as end_odometer minus start_odometer, with a floor of zero. This means a trip with no odometer readings (both are zero or null) results in a billing record with zero distance — the vendor is not paid for that trip. If the odometer readings were not entered before approval, the billing record shows zero distance. The trip can be edited and re-approved, but the billing record is not automatically updated — the manager would need to unapprove and re-approve to get a corrected calculation.

**Bulk Approval Skips Already-Approved Trips**
When using the bulk approve feature, the system processes each selected trip individually. If a trip is already approved, it is silently skipped — no error, no warning message. The system does not re-approve or modify the existing approval. This lets Mrs. Desai select a large batch of trips without having to check which ones are already approved.

**Bulk Unapprove Processes All Selected Trips**
When using the bulk unapprove feature, the system processes every selected trip — it does not check whether a trip is currently approved before clearing its approval fields and deleting its VndUsageLog record. Trips that are already unapproved are still processed (their approval fields are cleared again and the VndUsageLog lookup finds nothing to delete).

**Unapproval Deletes the Vendor Billing Record**
When a trip is unapproved, the system deletes the corresponding VndUsageLog record (matched by remarks containing the trip ID). If the trip is approved again later, a new billing record is created with the current calculated distance. This means a vendor whose trip was approved, then unapproved, then re-approved will not see duplicate billing records.

**Search is Limited to Route, Vehicle, and Driver**
The search box looks for matches in the route name/code, vehicle registration number, and driver name. It does not search by approval status — that is handled by the separate filter dropdown. It also does not search by approval date, approver name, or vendor distance. If Mrs. Desai wants to find all trips approved by a specific person, there is no built-in way to do so through the search box.

---

## Workflow Steps

**Approving a Single Trip via Toggle Switch**
Mrs. Desai opens the Trip Approve tab and sees a list of upcoming trips. She finds the "Jayanagar — North Route" trip scheduled for tomorrow morning. She checks the odometer readings (start: 1,25,335, end: 1,25,400) displayed in the table, confirms the distance is roughly correct, and flips the toggle switch on for that trip. The system marks the trip as approved with her user ID and timestamp, and creates a VndUsageLog record with 65 kilometres.

**Bulk Approving a Week's Trips**
On Monday morning, Mrs. Desai opens the Trip Approve tab and selects the checkbox next to all 15 trips scheduled for the week. She clicks Approve Selected. The system processes each trip: 12 are approved successfully, 3 are skipped because they were already approved by the Fleet Supervisor on Friday. The page reloads with a generic success message.

**Unapproving a Single Trip via Toggle Switch**
A trip that was approved for Wednesday is now cancelled because the school declared a holiday. Mrs. Desai finds the trip and flips the toggle switch off. The system clears the approved fields (approved=0, approved_by=null, approved_at=null) and deletes the corresponding VndUsageLog record. The trip returns to an unapproved state.

**Unapproving a Batch of Trips**
A vendor has notified the school that one of their buses will be unavailable for the entire next week. Mrs. Desai selects all trips assigned to that vendor for the coming week and clicks Unapprove Selected. The system processes each selected trip — clearing approval fields and deleting VndUsageLog records regardless of each trip's current approval state. The page reloads with a generic success message.

---

## Example Scenario

Green Valley School contracts with three transport vendors to supplement the school-owned fleet of 12 buses. Each vendor trip must be approved before it runs, because the school pays the vendor based on the distance travelled.

It is Sunday evening. Mrs. Desai opens the Trip Approve tab to review next week's vendor trips. There are 45 vendor trips scheduled — some are morning pickup routes, some are afternoon drop-off routes, and a few are field trip routes for the week.

She starts with Monday's trips. She selects all 15 Monday trips and clicks Approve Selected. The system approves 13 of them (2 were already approved by the Fleet Supervisor on Friday). A billing record is created for each approved trip with the calculated distance from the trip's odometer readings. The page reloads with a generic success message.

Then she notices that one of the approved trips has a distance of zero — the odometer readings were not entered for that trip. She toggles the approval switch off for that single trip, contacts the driver to get the readings, updates the trip with the correct odometer values, and toggles it back on. The new billing record now shows the correct distance.

By the end of the week, all 45 vendor trips are approved. The accounts department has 45 VndUsageLog records to process for vendor payments. When one vendor disputes a payment, Mrs. Desai opens the Trip Approve tab, finds the trip in question, and confirms that the approved distance of 72 kilometres matches the odometer readings on file. The dispute is resolved.

---

## Related Screens

- **Trip Management** — Trips are created and scheduled here. The Trip Approve tab is the next step — a trip must be created before it can be approved.
- **Trip Dashboard** — The dashboard may show the number of approved versus unapproved trips for today or this week.
- **Vendor Billing** — Approved trips generate VndUsageLog records that feed into the vendor billing module. The accounts department uses these records to calculate payments.
- **Vehicle Management** — Odometer readings recorded in trip data come from the vehicle's fuel and maintenance logs.

---

## Requirements

- Tab within Trip Management hub page (TripMgmtController::index)
- Approval logic is in TripController (toggleApproval, bulkApprove methods)
- Table: `tpt_trip` — uses columns `approved`, `approved_by`, `approved_at`
- Single trip approve/unapprove via AJAX toggle switch (POST to `toggle-approve`)
- Bulk approve/unapprove via AJAX on selected trips (POST to `bulk-approve`)
  - Bulk approve skips already-approved trips silently
  - Bulk unapprove processes all selected trips (no skip check)
- On approve: sets `approved=1`, `approved_by=current_user`, `approved_at=now()`, creates `VndUsageLog` record with distance = max(end_odometer - start_odometer, 0)
- On unapprove: clears `approved`, `approved_by`, `approved_at`, deletes corresponding `VndUsageLog` record (matched by remarks containing "Trip Approved (Trip ID: {id})")
- Filter by approval status (All / Approved / Unapproved)
- Search by route name/code, vehicle registration number, driver name
- Table displays: trip date, route, vehicle, driver, trip status, start/end time, start/end odometer, start/end fuel, approval toggle, action (view, edit remark)
- Remark editing via modal (AJAX update-remark endpoint)
- Permissions: `tenant.trip-approve.*` (config/permissionslist.php defines it as CRUD group)

---

## Who Can Access

Access is controlled entirely by the `tenant.trip-approve.*` permission group (defined in `config/permissionslist.php`). The following permission keys are used in controllers and views:

- `tenant.trip-approve.viewAny` — Access the Trip Approve tab
- `tenant.trip-approve.view` — View trip details (eye icon link)
- `tenant.trip-approve.approve` — Toggle a single trip's approval (toggleApproval controller)
- `tenant.trip-approve.bulkApprove` — Bulk approve/unapprove selected trips (bulkApprove controller)
- `tenant.trip-approve.edit` — Edit trip remark via modal
- `tenant.trip-approve.status` — View the approval toggle column
- `tenant.trip-approve.delete` — View the action column (shared with edit)

Additional permission keys exist in the policy (`TransportTripApprovePolicy`) but are not currently used in code: `reject`, `viewHistory`, `export`, `print`, `viewPending`, `override`.

If a user tries to approve or unapprove a trip without the required permission, Gate throws an access denied error.

---

## Logic Flow

When an authorised person opens the Trip Approve tab, the system loads all trips from the database (via TripMgmtController::TripQuery with tab='trip_approve') — 10 per page — showing trip date, route, vehicle registration number, driver name, trip status, start/end times, odometer readings, fuel readings, and a toggle checkbox for approval status (checked = approved, unchecked = unapproved). The approver's name and timestamp are stored in the database but are not displayed in the table.

When the user flips the toggle switch on a single trip, an AJAX POST request is sent to `TripController::toggleApproval`. The system checks that the trip exists and that the user has the `tenant.trip-approve.approve` permission. If toggling to approved (status=1), it sets approved=1, records the current user's ID in approved_by, and records the current timestamp in approved_at. It then calculates the distance by subtracting the start odometer reading from the end odometer reading (defaulting to zero if negative). It creates a VndUsageLog record with this distance using `firstOrCreate` matched on a remarks string. If the vendor does not exist on the trip's vehicle, the VndUsageLog record is not created.

When the user flips the toggle switch off (status=0), the system clears the approval fields (approved=0, approved_by=null, approved_at=null) and deletes the VndUsageLog record matched by remarks containing "Trip Approved (Trip ID: {id})".

When the user selects multiple trips and clicks Approve Selected, the system loops through each trip. For each trip, it checks whether it is already approved. If it is, the trip is skipped. If it is not, the system applies the same approval logic as for a single trip. A generic success message ("X trip(s) updated successfully") is returned — there is no breakdown of approved vs skipped counts.

When the user selects multiple trips and clicks Unapprove Selected, the system loops through each selected trip and applies unapproval logic unconditionally — it does not skip trips that are already unapproved. The approval fields are cleared and the VndUsageLog record is deleted for every selected trip.

There is no activity logging on approve or unapprove actions. There is no transaction wrapping around approve/unapprove operations — partial failure may leave inconsistencies.

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Trip existence (toggleApproval) | Trip must exist in the database | AJAX returns 404: "Trip not found." |
| User permission (toggleApproval) | User must have `tenant.trip-approve.approve` | Gate throws 403 (Access Denied) |
| User permission (bulkApprove) | User must have `tenant.trip-approve.bulkApprove` | Gate throws 403 (Access Denied) |
| Bulk action value (bulkApprove) | Action must be 'approve' or 'unapprove' | Validation error (422) |
| Bulk trip_ids (bulkApprove) | Must be an array | Validation error (422) |
| Trip status | No validation — any trip can be approved regardless of its status | (No check performed) |
| Odometer readings | No validation — zero distance billing record is created if readings are missing | (No error — trip is still approved) |
| Already approved (bulk approve) | System skips already-approved trips silently | (No error — trip is skipped) |
| Already unapproved (bulk unapprove) | No skip check — all selected trips are processed | (All trips processed regardless of current state) |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| User tries to approve without permission | Gate throws 403 — "Access Denied" | Permission error |
| Network fails during bulk approval | The system may approve some trips before the failure. The AJAX callback shows: "Bulk action failed" | Network error — partial completion |
| Odometer readings are missing | The trip is approved, but the VndUsageLog shows zero distance. No warning is shown to the user. | Data quality gap — vendor may not be paid correctly |
| User toggles already-approved trip (single) | Toggle switch changes to the unchecked state and the AJAX response reverts the switch. No specific error for "already approved." | Toggle switch behavior |
| User toggles already-unapproved trip off (single) | The system still clears the approval fields and deletes (or attempts to delete) the VndUsageLog. No error shown. | Toggle switch behavior — no skip check |
| VndUsageLog creation fails while approval succeeds | No transaction wrapping — the trip is approved but no billing record exists. Data inconsistency. | System error — data inconsistency |
| VndUsageLog deletion fails while unapproval succeeds | No transaction wrapping — the trip is unapproved but the billing record still exists. Data inconsistency. | System error — data inconsistency |
| Trip not found (toggleApproval) | AJAX returns 404: "Trip not found." | Data integrity |
| Vendor missing from vehicle | VndUsageLog record is NOT created (silently skipped) | Data quality gap — vendor not paid |

---

## Success Scenarios — When Everything Works

**SC-001 — Weekly Bulk Approval of Vendor Trips**
Mrs. Desai opens the Trip Approve tab on Sunday evening and selects all 45 vendor trips scheduled for the coming week. She clicks Approve Selected. The system processes 43 trips (2 were already approved) and creates VndUsageLog records with calculated distances for all 43. A generic success message is shown.

**SC-002 — Correcting a Trip's Odometer Readings After Approval**
Mrs. Desai toggles a trip on, then realises the odometer readings were entered incorrectly. The calculated distance is 25 kilometres instead of the actual 55 kilometres. She toggles the trip off, corrects the odometer readings in the trip data, and toggles it on again. The system deletes the old VndUsageLog and creates a new one with the correct 55-kilometre distance. The vendor will be paid the correct amount.

**SC-003 — Unapproving a Cancelled Trip**
A field trip scheduled for Friday is cancelled because of bad weather. Mrs. Desai finds the approved trip and toggles it off. The vendor billing record is deleted. The vendor will not bill the school for a trip that never happened.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Trip Approved Without Odometer Readings**
Mrs. Desai toggles a vendor trip on without checking whether the odometer readings were entered. The trip is approved successfully, and a VndUsageLog record is created with a distance of zero. The vendor completes the trip but receives no payment because the billing record shows zero distance. The vendor calls the accounts department to complain. The only fix is to toggle off, update the odometer readings, and toggle back on — but by the time someone notices, the billing cycle may have already closed.

**FC-002 — Bulk Approval Skips Important Details**
Mrs. Desai bulk-approves 15 trips without opening each one individually. One of those trips has incorrect route details — the vehicle assigned is out of service and a replacement was supposed to be scheduled. The trip is approved with the wrong vehicle. The system does not cross-check vehicle availability against maintenance schedules or other trips. The wrong vehicle shows up for the trip, causing confusion at the pickup point.

**FC-003 — No Notification When Trip Is Approved**
Mrs. Desai approves a trip, but the driver does not know it has been approved. The driver assumes the trip is not running and does not report for duty. The students are waiting at the pickup points, but no bus arrives. The approval action does not trigger any automatic notification — the Transport Manager must inform the driver separately. If she forgets, the trip may not run even though it was officially approved.

**FC-004 — Unapproved Trip Still Runs**
A driver runs a trip that was never approved. The system does not prevent a trip from running just because it is unapproved — the Trip Approve tab is a billing and authorisation tool, not a gate that physically prevents the bus from leaving. A driver could take the bus out, complete the route, and submit odometer readings, but because the trip was never approved, no vendor billing record is created. The school has no record of the trip in the billing system, and the vendor is not paid for work that was actually done.
