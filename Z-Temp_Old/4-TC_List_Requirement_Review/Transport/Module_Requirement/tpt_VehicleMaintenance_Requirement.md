# Vehicle Maintenance — Business Requirements

## What This Screen Does

The Vehicle Maintenance screen records every instance where a school vehicle enters the workshop for service or repair. Each maintenance record is linked to a previously approved service request and captures when the vehicle went in, when it came out, what type of maintenance was performed, how much it cost, which workshop handled the work, and when the next service is due. Every record begins with a Pending status, moves through approval, and eventually closes as Completed.

Without this screen, the school would have no structured way to track whether approved service requests actually resulted in a vehicle being taken to the workshop. The Transport Manager would rely on word of mouth or scattered email chains to know if Bus KL-05 ever made it to the mechanic after the service request was approved. There would be no record of how many days a vehicle sat in the workshop, what the actual repair cost was versus what was estimated, or when the next service is due. The Vehicle Maintenance screen closes the loop between "we approved a repair" and "the repair actually happened."

The screen is accessed through the Vehicle Management module under the **Veh. Maintenance** tab. It is a read-heavy tab by design — new entries are never created manually from this screen. They are born automatically when a service request is approved elsewhere in the system.

---

## Default Data Load

When the Transport Manager opens Vehicle Management and clicks the Veh. Maintenance tab, the system loads the most recent maintenance records — 10 per page — showing the vehicle registration number, service request reference, maintenance type, in-service date (when the vehicle entered the garage), out-service date (when it left), total cost, workshop name, next due date, and the current status badge. A search box at the top allows searching across multiple fields. Dropdown filters let the manager narrow by status, request status, vehicle type, or approved by.

---

## When This Screen Is Used

- **Tracking a Vehicle After Service Request Approval** — The Transport Manager has just approved a service request for Bus KL-05's brake replacement. The moment they click Approve, the system automatically creates a maintenance record with a Pending status. The manager does not fill out any forms — the record is there, waiting for the vehicle to actually go into the workshop.

- **Recording Workshop Entry and Exit Dates** — Once the bus is physically sent to the workshop, the manager opens the automatically created maintenance record and fills in the in-service date (when the bus entered the garage) and later, the out-service date (when it was driven out). The workshop details are added — the name of the garage, the mechanic's notes, and the final cost of the repair.

- **Setting the Next Service Due Date** — After the repair is complete, the mechanic may recommend the next service in 3 months or 5,000 kilometres. The manager enters this next due date into the maintenance record. The system can later be used to flag vehicles whose next service date is approaching.

- **Reviewing Workshop Performance** — The Fleet Supervisor opens the Veh. Maintenance tab at the end of the quarter, filters by a specific workshop, and looks at how long vehicles stayed in that garage on average. One workshop keeps buses for 3 days on average; another keeps them for 7 days. This data helps in making future workshop selection decisions.

- **Auditing Approved Service Requests That Never Materialised** — The manager filters maintenance records by Pending status and sees a list of service requests that were approved weeks ago but have no workshop activity. Bus KL-07's brake replacement was approved 15 days ago, but the maintenance record still shows Pending with no in-service date. The manager follows up with the driver.

---

## Key Fields at a Glance

**Service Request Link**
Every maintenance record is tied to exactly one service request — the approved request that triggered the maintenance. This link is established automatically when the service request is approved. You cannot create a maintenance record without a linked service request, and you cannot link a maintenance record to a service request that is not yet approved. The relationship is one-to-one: one approved service request produces one maintenance record.

**Maintenance Initiation Date**
The date on which the maintenance was initiated — typically the date the service request was approved and the maintenance record was created. This is set automatically by the system and is not changed by the user.

**Maintenance Type**
Describes the category of work performed — for example, Brake Replacement, Engine Service, Tyre Change, General Inspection, or Body Repair. This is inherited from the linked service request and is visible here for reference.

**Cost**
The actual amount charged by the workshop, entered in rupees with two decimal places. This may differ from the estimated cost in the original service request. The actual cost is the final figure that will be used for expense tracking.

**In-Service Date and Out-Service Date**
Two critical dates that track how long the vehicle was in the workshop. The in-service date is when the vehicle was handed over to the garage. The out-service date is when the vehicle was returned to service. The difference between these dates tells the school how many days the vehicle was off the road. Both fields are optional — the manager may not know the exact dates at the time of creating the record.

**Workshop Details**
A free-text field where the manager can enter the name of the workshop, the mechanic's name, the garage address, or any other notes about where the work was performed. This is unstructured data meant for internal reference.

**Next Due Date**
An optional field capturing when the next maintenance or service is due for this vehicle. This is typically set by the workshop or the Transport Manager based on the type of repair performed. A vehicle that had its engine serviced might be due again in 6 months; a vehicle that had a minor brake adjustment might be due in 3 months.

**Status**
Every maintenance record has one of three statuses: Pending (yellow), Approved (green), or Rejected (red). Pending means the record exists but the vehicle has not yet completed the workshop cycle. Approved means the maintenance has been verified and the record is final. Rejected means the maintenance record was invalidated for some reason.

---

## Business Rules and Conditions

**Records Are Never Created Manually**
This is the most important rule: the Veh. Maintenance tab does not have a create button. Maintenance records cannot be added by clicking "Add New" — they are created automatically by the system when a service request is approved. This happens through a `firstOrCreate` call triggered by either the `TptVehicleServiceRequestController@updateStatus` or `VehicleMgmtController@updateStatus` method. The system checks if a maintenance record already exists for this service request; if not, it creates one. This prevents duplicate records and ensures every approved service request has exactly one corresponding maintenance entry.

**Once Completed or Approved, Edits Are Blocked**
If a maintenance record reaches "Completed" or "Approved" status, the edit screen cannot be accessed. The `edit()` method explicitly blocks this. If the manager needs to change something in a completed record, there is no way to do it from this screen — the field remains frozen. This ensures that once maintenance is finalised, the record is locked and cannot be tampered with.

**Approval Triggers a Cascade Update**
When a maintenance record's status is changed to "Approved" through the `updateStatus` method, the system does not just update the maintenance table. It also reaches back to the linked service request and updates four fields: `approved_by` is set to the current user, `service_completion_date` is set to the current date and time, `request_approval_status` is changed to "Approved", and `vehicle_status` is set to "Service Done". This cascade ensures that approving the maintenance record also officially closes the service request loop.

**Filtering Is Extensive**
The system supports filtering by search keyword, status, request status, date range, approved by, vehicle type, and cost range. A manager looking for all maintenance records approved by a specific person for buses only, with costs between ₹5,000 and ₹20,000, in the last quarter, can set all these filters at once.

**Activity Is Logged for Destruction Events**
When a maintenance record is soft-deleted, restored, or force-deleted, the system records the action in the activity log. Each log entry includes the action performed and the identifier of the maintenance record that was affected.

---

## Workflow Steps

**Automatic Creation After Service Request Approval**
Mr. Sharma, the Transport Manager, opens the service request for Bus KL-05 — a brake replacement estimated at ₹8,500. He has verified the mechanic's quote and is satisfied. He changes the service request status to "Approved." The moment he clicks save, the system looks at the approved service request and calls `firstOrCreate` on the maintenance table. If no maintenance record already exists for this service request, the system creates one. The new record shows a Pending status, with the vehicle's details, the maintenance type (Brake Replacement), and the service request reference pre-populated. Mr. Sharma does not fill out a form — the record appears automatically in the Veh. Maintenance tab.

**Filling in Workshop Details After the Vehicle Goes to the Garage**
Two days later, Bus KL-05 is driven to the workshop. Mrs. Desai, who handles the day-to-day tracking, opens the maintenance record. She enters the in-service date as today's date. She adds the workshop name: "Kiran Auto Works, Industrial Layout." She leaves the out-service date blank for now. She saves the record. The status remains Pending.

**Completing the Record After the Vehicle Returns**
Three days later, Bus KL-05 returns from the workshop. Mrs. Desai opens the same maintenance record. She enters the out-service date, the actual cost of ₹9,200 (₹700 more than estimated because additional parts were needed), the next due date as 3 months from now, and adds a remark: "Brake pads replaced. Additional work on hydraulic line." She saves again. The record still shows Pending because the approval step has not happened yet.

**Final Approval of the Maintenance Record**
At the end of the week, Mr. Sharma reviews completed maintenance records. He opens Bus KL-05's record, verifies the workshop details and cost against the invoice, and changes the status to "Approved." The system immediately updates the linked service request: sets the service completion date to now, the approval status to "Approved", the vehicle status to "Service Done", and records who approved it. The maintenance record is now locked — no further edits are allowed.

---

## Example Scenario

Green Valley School operates a fleet of 12 buses and 2 vans. Over the course of October, the Transport Manager approves 8 service requests for various vehicles — brake replacements, engine tune-ups, tyre changes, and AC repairs. Each time a service request is approved, the system automatically creates a corresponding maintenance record.

Bus KL-07's engine service request is approved on October 5th. The maintenance record appears automatically. The vehicle goes to the workshop on October 7th (in-service date entered), stays for 4 days, and returns on October 11th (out-service date entered). The actual cost is ₹18,500 versus the estimated ₹15,000. The workshop, "Precision Motors," recommends the next service in 6 months, which Mrs. Desai enters as April 11th. Mr. Sharma reviews and approves the record on October 15th. The service request is automatically closed with vehicle status "Service Done."

Bus KL-05's brake replacement is also approved in October, but the vehicle never goes to the workshop. The maintenance record sits in Pending status with no in-service date. At the end of October, Mrs. Desai filters the Veh. Maintenance tab by Pending status and sees Bus KL-05's record. She investigates and finds that the driver was not aware the approval had been granted. She follows up, and the bus goes to the workshop the next day.

By the end of the month, 7 out of 8 maintenance records are completed and approved. The 8th is still pending because the vehicle has not yet been sent to the workshop. The completed records provide a full audit trail of every vehicle that went through the workshop, how long it stayed, what it cost, and when the next service is due.

---

## Related Screens

- **Vehicle Service Request (Service Request tab)** — Maintenance records are created automatically when a service request is approved. The service request provides the maintenance type, estimated cost, and initial details. The maintenance record references the service request through a foreign key relationship.
- **Vehicle Master** — The vehicle itself is accessed through the maintenance record's relationship chain: maintenance → service request → inspection → vehicle. Each maintenance record ultimately belongs to a vehicle registered in the Vehicle Master.
- **Vehicle Management Dashboard** — The dashboard may display counts of vehicles currently in the workshop (maintenance records with in-service date set but no out-service date) or vehicles due for service (next due date approaching).
- **Inspection Records** — The vehicle's latest inspection details are accessible through the chain from maintenance record, enabling the manager to see both the inspection history and the maintenance history in context.

---

## Requirements

- **Controller**: `TptVehicleMaintenanceController` with full resource methods (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`) plus `trashed`, `restore`, `forceDelete`, `updateStatus` (approval flow)
- **Automatic creation**: Maintenance records are never created manually — they are created via `firstOrCreate` from `TptVehicleServiceRequestController@updateStatus` or `VehicleMgmtController@updateStatus`
- **Model**: `TptVehicleMaintenance` (table: `tpt_vehicle_maintenance`) — SoftDeletes, `belongsTo` serviceRequest, `belongsTo` approvedBy
- **Dynamic Attribute**: `getVehicleAttribute()` traverses `serviceRequest → inspection → vehicle` to provide vehicle details without joining multiple tables
- **Form Request**: `TptVehicleMaintenanceRequest` — validates `vehicle_service_request_id` must be unique (no two maintenance records for the same service request)
- **Model Scopes**: `scopePending`, `scopeApproved`, `scopeDateRange`, `scopeVehicleFilter` for clean query building
- **Policy**: `TransportVehicleMaintenancePolicy` (`tenant.vehicle-maintenance.*`)
- **Activity logging**: ✅ Present on Deleted, Restored, Force Delete actions
- **Permissions**: `tenant.vehicle-maintenance.{viewAny, view, create, update, delete, restore, forceDelete}`

---

## Who Can Access

- **Transport Manager** — Full control over maintenance records. They can view all records, edit pending records to add workshop details and dates, approve completed records, soft-delete incorrect records, restore accidentally deleted records, and permanently remove test data. This is the primary user who manages the end-to-end maintenance tracking workflow.

- **Fleet Supervisor** — Can view all maintenance records and change the approval status from Pending to Approved or Rejected after verifying workshop invoices. They can edit basic fields like workshop details and dates on pending records. They cannot delete records.

- **School Administrator** — Read-only access to the Veh. Maintenance tab. They can view records, apply filters, and run reports on workshop costs and vehicle downtime, but cannot create, edit, approve, or delete any records.

Behind the scenes, each action is protected by a permission check. If a user tries to perform an action they are not authorised for, the system displays an "Access Denied" message. Additionally, even authorised users cannot edit a record once it reaches Completed or Approved status — the `edit()` method explicitly blocks access regardless of permissions.

---

## Logic Flow

When the Transport Manager clicks the Veh. Maintenance tab in Vehicle Management, the system loads the most recent maintenance records from the database — 10 per page — along with each record's linked service request and vehicle details. The list shows the vehicle registration number, service request reference, maintenance type, in-service and out-service dates, total cost, workshop name, next due date, and a coloured badge showing whether the record is Pending (yellow), Approved (green), or Rejected (red). A search box at the top allows searching by vehicle registration number, service request identifier, workshop name, or remarks. Dropdown filters let the manager narrow down by status, request status, date range, approved by, vehicle type (Bus, Van, Car), and minimum or maximum cost.

There is no "Add Entry" button. The only way a maintenance record appears in this list is through the automatic creation trigger — when a service request is approved, the system calls `firstOrCreate` to ensure exactly one maintenance record exists for that service request.

When the manager clicks on a record that is in Pending status, the edit form opens with the current values pre-filled. The manager can update the in-service date, out-service date, workshop details, cost, next due date, and remarks. They cannot change the linked service request or the maintenance type — those are inherited from the approval event. On save, the system validates the form data and updates the record.

When the manager changes the status of a record to "Approved," the system does more than just update the maintenance record. It also updates the linked service request: it sets `approved_by` to the current user's ID, `service_completion_date` to the current timestamp, `request_approval_status` to "Approved", and `vehicle_status` to "Service Done". This ensures that approving the maintenance record has the side effect of officially closing the service request.

When the manager clicks Delete, the system soft-deletes the record — it hides it from the main list and moves it to the Trash view. From the Trash view, the manager can either Restore the record (bringing it back with its original status) or permanently delete it (force delete). Both actions are logged in the activity log.

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Vehicle Service Request | Must exist and must be approved | "The selected service request is invalid or not yet approved." |
| Vehicle Service Request (duplicate) | Must be unique — no two maintenance records for the same service request | "A maintenance record already exists for this service request." |
| In-Service Date | Must be a valid date if provided | "Please enter a valid in-service date." |
| Out-Service Date | Must be a valid date if provided; must be on or after in-service date if both are entered | "The out-service date cannot be before the in-service date." |
| Cost | Must be a valid decimal amount if provided | "Please enter a valid cost amount." |
| Next Due Date | Must be a valid date if provided | "Please enter a valid next due date." |
| Status | Must be Pending, Approved, or Rejected | "The selected status is invalid." |
| Workshop Details | Free text — no specific validation | N/A |
| Remarks | Free text — no specific validation | N/A |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| User tries to create a maintenance record manually | There is no create button or direct creation endpoint — the form does not exist in the UI | Design limitation — intentional |
| User tries to edit a Completed or Approved record | The edit page shows an error or redirects away — the `edit()` method blocks access | Access restriction |
| Vehicle service request ID is duplicated (two maintenance records for same request) | Validation error — "A maintenance record already exists for this service request." | Data integrity check |
| Out-service date is before in-service date | Validation error — "The out-service date cannot be before the in-service date." | Data entry error |
| User tries to approve without permission | System shows "Access Denied" | Permission error |
| Service request referenced in the maintenance record is deleted or invalid | The record may load without service request details, or the relationship returns null | Data integrity issue |
| Cost entered as text instead of a number | Validation error — form blocks submission | Data entry error |

---

## Success Scenarios — When Everything Works

**SC-001 — Full Maintenance Lifecycle for Bus KL-05**
A service request for Bus KL-05's brake replacement is approved by the Transport Manager. The system automatically creates a maintenance record with Pending status. The vehicle goes to the workshop on October 7th, and the manager enters the in-service date. The vehicle returns on October 10th, and the manager enters the out-service date, the actual cost of ₹8,200, workshop details ("Kiran Auto Works"), and a next due date of January 10th. The Fleet Supervisor reviews the record, verifies the details, and changes the status to Approved. The system automatically updates the linked service request: sets service completion date, approval status to "Approved", and vehicle status to "Service Done." The record is now locked and serves as an auditable record of the entire maintenance event.

**SC-002 — Bulk Review of Monthly Workshop Activity**
At the end of the month, the Transport Manager opens the Veh. Maintenance tab, sets the date range to the full month, and sees all 12 maintenance records created from approved service requests. Of these, 10 have workshop dates filled in and costs recorded. The manager sees that the school spent a total of ₹1,85,000 on vehicle maintenance this month. Two records still show Pending with no in-service dates — the manager follows up with the drivers to find out why those vehicles never went to the workshop. The data provides a clear picture of fleet maintenance activity and costs.

**SC-003 — Investigating a Vehicle with No Recent Maintenance**
The School Administrator notices that Bus KL-07 has not had any maintenance record created in the last 6 months. They open the Veh. Maintenance tab, filter by Bus KL-07, and see that the last record was approved in April with a next due date of October. Since it is now November and no new maintenance record exists, it means no service request was raised and approved for this bus. The Administrator flags this to the Transport Manager, who investigates and finds that Bus KL-07 has been running without a scheduled service — a potential safety issue that is now addressed.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Maintenance Record Never Created After Service Request Approval**
The Transport Manager approves a service request for Bus KL-07's engine repair. The approval goes through in the service request system. However, due to a database connection issue or a code error in the `firstOrCreate` call, no maintenance record is created. The manager checks the Veh. Maintenance tab the next day and does not see Bus KL-07's record. There is no warning or notification that the automatic creation failed. The manager assumes the approval did not go through and re-approves the service request — creating a second approval entry but still no maintenance record. The vehicle never goes to the workshop because there is no maintenance record tracking it.

**FC-002 — Edit Blocked on a Record That Needs Correction**
The transport clerk enters the wrong workshop name and cost for a maintenance record — "Kiran Auto Works" instead of "Kiran Auto Care" and ₹8,200 instead of ₹8,000. Before the clerk realises the mistake, the Fleet Supervisor approves the record. Now the record is locked — the edit function is blocked because the status is "Approved." The clerk cannot correct the workshop name or the cost. The record sits in the database with incorrect information, and the monthly expense report shows ₹200 more than what was actually paid. There is no mechanism to unlock an approved record or to make corrections after approval without directly modifying the database.

**FC-003 — Cascade Update Silently Overwrites Service Request Data**
When the Fleet Supervisor approves a maintenance record, the system automatically updates the linked service request — setting `service_completion_date`, `request_approval_status`, and `vehicle_status`. However, if the service request had already been manually updated by someone else (for example, the Transport Manager had already set the vehicle status to "In Workshop" separately), the cascade overwrites that data. The Transport Manager's manual update is lost without warning. There is no conflict detection or notification that the cascade override occurred.

**FC-004 — Pending Records With No Activity Accumulate Unnoticed**
Multiple service requests are approved over several weeks, creating maintenance records for each one. However, several vehicles never actually go to the workshop. Their maintenance records remain in Pending status with no in-service dates, no workshop details, and no costs. Over time, the Pending count grows to 15 or 20 records. The Fleet Supervisor does not regularly check the Veh. Maintenance tab, so these abandoned records accumulate. When the month-end report is generated, the Pending records are excluded from cost totals, but they clutter the list and make it harder to find active records. There is no automated alert or escalation for maintenance records that remain Pending beyond a configurable number of days.
