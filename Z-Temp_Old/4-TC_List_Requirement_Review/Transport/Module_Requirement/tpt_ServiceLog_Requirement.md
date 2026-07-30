# Service Log — Business Requirements

## What This Screen Does

The Service Log screen records every service or repair request raised for a school vehicle. Each request captures which vehicle needs attention, the reason for the service (scheduled maintenance, breakdown, or an issue detected during a daily inspection), the current condition of the vehicle (whether it is due for service, currently being serviced, or already done), and the approval status of the request. A service request can be created manually by the Transport Manager or triggered automatically by the system when a daily vehicle inspection records a failure. Once a request is approved, the system automatically creates a maintenance record so the workshop team knows what work needs to be done.

Without this screen, vehicle service requests would be handled through informal channels — a driver telling the Transport Manager about a strange noise, a handwritten note left on the dashboard, or an email that gets buried in the inbox. There would be no way to track which requests have been approved, which vehicles are waiting for service, or whether a vehicle that failed its morning inspection is already booked into the workshop. The Service Log turns scattered repair requests into a structured queue that ensures no vehicle with a known issue remains on the road unrepaired.

The screen appears in Vehicle Management → Service Log tab, where it shows a list of service requests with search and filter options.

---

## Default Data Load

When the Transport Manager opens Vehicle Management and clicks the Service Log tab, the system loads the most recent service requests — 10 per page — showing the vehicle registration number, the reason for the request, the vehicle status (Due for Service, In-Service, or Service Done), the request date, and the current approval status (Approved, Pending, or Rejected). A search box at the top allows searching by vehicle registration number. A status filter dropdown lets the manager view only Pending, Approved, or Rejected requests.

---

## When This Screen Is Used

- **Vehicle Has a Mechanical Issue** — During the morning trip, Driver Venkatesh hears a grinding noise from the left front wheel of Bus KL-05. He reports it to the Transport Manager as soon as he returns to school. Mrs. Desai opens the Service Log, clicks Add Request, selects Bus KL-05, enters "Grinding noise from left front wheel — possible brake or bearing issue" as the reason, and saves the request with a Pending status.

- **Daily Inspection Fails Automatically Creates a Service Request** — Before the morning run, Driver Venkatesh performs the daily vehicle inspection for Bus KL-07 and marks the tyre condition as "Failed." When he submits the inspection, the system automatically creates a service request for Bus KL-07 with the reason "Inspection Failed — Tyre Condition." Mrs. Desai does not need to create this request manually — it appears in the Service Log automatically.

- **Scheduled Maintenance Is Due** — Mrs. Desai checks the vehicle master and sees that Bus KL-12 is due for its 5,000 km service. She opens the Service Log, creates a request for "Scheduled 5,000 km maintenance — oil change, filter check, brake inspection," and sets the vehicle status to "Due for Service." The request sits Pending until the Fleet Supervisor approves it.

- **Approving Requests and Dispatching to Workshop** — Every afternoon, Mr. Sharma, the Fleet Supervisor, opens the Service Log, reviews all Pending requests, and approves those that are urgent or scheduled. Once he approves a request, the system automatically creates a maintenance record that the workshop team can see in the Vehicle Maintenance screen. If a request seems unnecessary or the reported issue cannot be reproduced, he rejects it with a note.

---

## Key Fields at a Glance

**Vehicle and Request Information**
Every service request must be linked to a specific vehicle — you cannot create a request without saying which bus or van needs attention. The reason for the request is captured as free text so the Transport Manager can describe the issue in plain language, whether it is "Engine overheating after 30 minutes of driving" or "Scheduled 10,000 km service." The date of the request is recorded automatically when the request is created.

**Vehicle Status**
The current condition of the vehicle is captured through a dropdown with three options: "Due for Service" means the vehicle needs work but has not been sent to the workshop yet; "In-Service" means the vehicle is currently in the workshop being repaired; "Service Done" means the work is complete and the vehicle is back on the road. This status helps the Transport Manager see at a glance how many vehicles are waiting, how many are in the workshop, and how many are ready.

**Approval Status and Approval Details**
Every service request starts with "Pending" approval status. An authorised person must approve the request before any work begins. When they approve, the system records who approved it and when. The approval step is a checkpoint — it prevents unnecessary or duplicate service requests from reaching the workshop. Until a request is approved, no maintenance record is created and no work is scheduled.

---

## Business Rules and Conditions

**Approval Creates a Maintenance Record Automatically**
When a service request is approved, the system checks whether a maintenance record already exists for that request. If one does not exist, it creates one automatically. This means the workshop team does not have to wait for someone to manually create a maintenance record after approval — the system does it for them. However, if a maintenance record already exists (for example, if it was created manually before approval), the system will not create a duplicate.

**Service Requests Can Be Created Manually or Automatically**
There are two ways a service request enters the system. The first is manual — the Transport Manager opens the Service Log and fills in the details. The second is automatic — when a driver submits a daily vehicle inspection with a "Failed" status, the system creates a service request in the background with the inspection result as the reason. This ensures that no failed inspection is ignored or forgotten. 🔴 **However, if the system creates a service request from a failed inspection and the same vehicle fails inspection again the next day, a second duplicate service request may be created. There is no check to prevent duplicate requests from the same issue.**

**Vehicle Status Tracks the Service Lifecycle**
The three vehicle status values — Due for Service, In-Service, Service Done — are not automatically advanced by the system. If a request is approved and the vehicle is sent to the workshop, someone must manually change the status from "Due for Service" to "In-Service." Similarly, when the vehicle returns from the workshop, someone must change the status to "Service Done." 🔴 **The system does not automatically update the vehicle status when a maintenance record is completed. This depends entirely on someone remembering to update the dropdown.**

**Approval Is a Separate Permission from General CRUD**
The ability to create, edit, or delete service requests is controlled by one set of permissions. The ability to approve or reject a request is controlled by a separate set of permissions. This means a Transport Manager who creates service requests cannot necessarily approve them, and a Fleet Supervisor who approves them cannot necessarily create them. This separation ensures that no single person can create and approve their own request without a second authorised person reviewing it.

**Search Only Supports Vehicle Registration Number**
When searching the service log, the system looks for matches in the vehicle's registration number only. It does not search by reason, vehicle status, approval status, or date. If a manager wants to find all requests with "brake" in the reason or all requests from last week, there is no built-in way to do so through the search box.

**Request Reason Is Free Text with No Enforcement**
The reason field is a plain text area. The Transport Manager can type anything — a detailed description, a single word, or even leave it empty. 🔴 **There is no minimum length, no required level of detail, and no suggestion list of common issues. A request with a vague reason like "Check vehicle" can be submitted and approved, leaving the workshop team unsure what work is actually needed.**

---

## Workflow Steps

**Creating a Service Request from a Driver's Report**
Driver Venkatesh reports that Bus KL-05's air conditioner is not cooling properly. Mrs. Desai opens the Service Log tab, clicks Add Request, selects "KL-05 (KA-01-EX-1234)" from the vehicle dropdown — only active vehicles are shown. She types "AC not cooling — air conditioning system needs inspection and repair" as the reason. She leaves the vehicle status as "Due for Service." She clicks Save. The request appears in the list with a yellow "Pending" badge. The Fleet Supervisor will review it later.

**Approving a Service Request and Dispatching to Workshop**
Mr. Sharma, the Fleet Supervisor, opens the Service Log at 2:00 PM. He sees three Pending requests. He reviews the first one — Bus KL-05 with an AC issue. He knows the school has a warranty service agreement with the AC vendor, so this cannot be handled by the school's workshop. He approves the request anyway because the approval is needed to create the maintenance record and track the issue. The system creates a maintenance record automatically. He then opens the second request — Bus KL-07 with a "Failed tyre inspection" flag — and approves it as urgent because the vehicle cannot be on the road with a failed tyre.

**Completing Service and Updating Vehicle Status**
The workshop finishes the tyre replacement on Bus KL-07. The mechanic informs Mrs. Desai. She opens the Service Log, finds the request for Bus KL-07, and changes the vehicle status from "Due for Service" to "Service Done." She does the same for Bus KL-05's AC repair. Both requests now show "Service Done" with a green badge. The approval status remains "Approved" — that never changes after approval.

---

## Example Scenario

Green Valley School operates a fleet of 12 buses and 2 vans. Every morning before the first trip, each driver performs a daily vehicle inspection using the Daily Vehicle Inspection screen. On Tuesday morning, Driver Venkatesh inspects Bus KL-07 (registration KA-01-EX-5678) and finds that the front left tyre has a visible bulge on the sidewall. He marks the tyre condition as "Failed" and submits the inspection. The system automatically creates a service request for Bus KL-07 with the reason "Inspection Failed — Tyre Condition" and a Pending approval status.

Mrs. Desai, the Transport Manager, receives a notification that a service request has been created automatically. She opens the Service Log, sees the request for Bus KL-07, and enters a more detailed reason: "Front left tyre has a bulge on the sidewall — needs immediate replacement. Vehicle should not be used until repaired." She also sets the vehicle status to "Due for Service."

At 10:00 AM, Mr. Sharma, the Fleet Supervisor, opens the Service Log and sees the request for Bus KL-07. He approves it. The system immediately creates a maintenance record in the Vehicle Maintenance screen. The workshop team sees the new record and dispatches a mechanic to replace the tyre.

By 2:00 PM, the tyre is replaced. The mechanic informs Mrs. Desai, who opens the Service Log and changes the vehicle status from "Due for Service" to "Service Done." The vehicle is back on the road for the afternoon trip. The service request remains in the system as a permanent record of the issue, the approval, and the repair.

---

## Related Screens

- **Vehicle Master** — Each service request is linked to a specific vehicle registered here. The vehicle's registration number and details are displayed alongside each request.
- **Vehicle Management Dashboard** — The dashboard may show counts of pending and approved service requests, giving a quick overview of how many vehicles need attention.
- **Daily Vehicle Inspection** — A failed inspection in this screen triggers automatic creation of a service request. The inspection record is linked to the service request so the Transport Manager can see exactly what failed.
- **Vehicle Maintenance** — When a service request is approved, a maintenance record is automatically created in this screen. The workshop team uses this screen to track the actual repair work. The service request and the maintenance record are linked to each other.

---

## Requirements

- Controller: `TptVehicleServiceRequestController` with full resource methods plus `trashed`, `restore`, `forceDelete`, `updateStatus` (for approve/reject)
- Hub tab data: Loaded within Vehicle Management with search and status filters
- Model: `TptVehicleServiceRequest` (table: `tpt_vehicle_service_request`) — SoftDeletes, status defaults to Pending
- Relations: belongsTo inspection (`TptDailyVehicleInspection`), belongsTo approvedBy (`User`), belongsTo vehicleStatus (`Dropdown` — sys_dropdown), hasOne vehicleMaintenance (`TptVehicleMaintenance`)
- Form Request: Validates vehicle, reason, vehicle_status, request_date, request_approval_status
- Two Policies: one for CRUD (`tenant.vehicle-service-request.*`), one for approval (`tenant.vehicle-service-approval.*`)
- Activity logging: On Stored, Updated (field-level), Trashed, Restored, Deleted, StatusUpdated
- Permissions: `tenant.vehicle-service-request.{viewAny, view, create, update, delete, restore, forceDelete}`
- Approval Permissions: `tenant.vehicle-service-approval.{viewAny, approve, reject}`
- Business Logic: Approval triggers `firstOrCreate` on `TptVehicleMaintenance`
- Auto-creation: From `TptDailyVehicleInspectionController@store()` when inspection status is 'Failed'

---

## Who Can Access

- **Transport Manager** — Full control over service requests. They can create new requests manually, edit existing requests (including updating the reason or vehicle status), soft-delete incorrect or duplicate requests, restore accidentally deleted requests, and permanently remove test data. They cannot approve or reject requests — that requires the Fleet Supervisor or another authorised approver. This is the primary user who manages the service queue.

- **Fleet Supervisor** — Can view all service requests and change the approval status from Pending to Approved or Rejected after reviewing the reported issue. They can also update the vehicle status (Due for Service / In-Service / Service Done) to reflect the current state of the vehicle. They cannot create, edit, or delete requests.

- **School Administrator** — Read-only access to the service log. They can view requests and review the history of service and repairs across the fleet, but cannot create, edit, approve, or delete any records.

- **Driver** — Does not have access to this screen. Drivers perform daily vehicle inspections, and if those inspections fail, a service request is created automatically. Drivers do not interact with the Service Log directly.

Behind the scenes, each action is protected by a permission check. If a user tries to perform an action they are not authorised for, the system displays an "Access Denied" message.

---

## Logic Flow

When the Transport Manager clicks the Service Log tab in Vehicle Management, the system loads the most recent service requests from the database — 10 per page — along with each request's linked vehicle information and inspection details if the request was auto-created. The list shows the vehicle registration number, the reason for the request, the vehicle status as a coloured badge (Due for Service — orange, In-Service — blue, Service Done — green), the request date, and the approval status as another coloured badge (Pending — yellow, Approved — green, Rejected — red).

When the manager clicks "Add Request," a form appears with a dropdown list for selecting the vehicle (only active vehicles are shown). The manager types the reason for the service in a text area, selects the vehicle status from a dropdown, and the system automatically sets the request date to today and the approval status to Pending. When they click Save, the system checks that the vehicle exists, that the reason is provided, and that the vehicle status is one of the three valid options. If everything is valid, the request is saved, and the action is recorded in the activity log.

When a service request is created automatically from a failed daily inspection, the system creates the request in the background at the same time the inspection is submitted. The inspection record is linked to the service request so the Transport Manager can see which inspection triggered the request. The reason is pre-filled with a summary of the inspection failure. The request starts with Pending status just like a manually created request.

When the Fleet Supervisor clicks the Approve button next to a pending request, the system updates the approval status to "Approved," records who approved it and when, and then checks whether a maintenance record already exists for this service request. If no maintenance record exists, the system creates one automatically. The new maintenance record is linked to the service request and starts with its own default status, ready for the workshop team. If a maintenance record already exists, the system skips the creation step and logs the approval only.

When the Fleet Supervisor clicks Reject, the system updates the approval status to "Rejected." No maintenance record is created. The request remains in the list so there is a record that the issue was raised and rejected, but no workshop work is scheduled.

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Vehicle | Must be selected and must exist in the fleet | "Please select a vehicle." |
| Reason for Service | Must be provided | "Please enter the reason for the service request." |
| Vehicle Status | Must be selected from Due for Service, In-Service, or Service Done | "Please select a vehicle status." |
| Request Date | Set automatically to current date — not user-editable | N/A |
| Approval Status | Set automatically to Pending — not user-editable on create | N/A |
| Inspection Link | Optional — if provided from auto-creation, must reference a valid inspection record | "The linked inspection record is invalid." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Vehicle not selected | "Please select a vehicle." — the form does not submit | Data entry error |
| Reason is empty or only spaces | "Please enter the reason for the service request." — the form blocks submission | Data entry error |
| Vehicle status is not one of the three valid options | Validation error — the form blocks submission | Data entry error |
| User tries to approve without approval permission | System shows "Access Denied" | Permission error |
| Auto-creation from failed inspection fails silently | The inspection is submitted, but no service request is created. The Transport Manager never knows the vehicle failed inspection and the issue is never tracked. 🔴 **No notification or alert is generated when auto-creation fails. The failed inspection appears normal, but the service request is missing.** | System gap — silent failure on auto-creation |
| Duplicate service requests for the same issue | A vehicle fails the same inspection item two days in a row. The system creates a service request on day one and another on day two for the same issue. 🔴 **No deduplication check exists. The workshop team sees two separate requests for the same tyre bulge.** | System gap — no duplicate detection |
| Service request approved but maintenance record creation fails | The approval status changes to "Approved," but no maintenance record is created. The workshop team never receives the work order. 🔴 **There is no fallback or retry mechanism if the maintenance record creation fails after approval.** | System gap — maintenance record not created |
| Vehicle status never updated after repair | The workshop finishes the repair, but nobody updates the vehicle status from "In-Service" to "Service Done." The request stays "In-Service" indefinitely. 🔴 **No reminder or automatic status update when maintenance is completed.** | Process gap — manual status update |
| Reason too vague to be useful | A request with reason "Check noise" is approved and sent to the workshop. The mechanic arrives but does not know which noise, when it happens, or under what conditions. 🔴 **No minimum length or quality check on the reason field.** | Data entry gap — vague descriptions accepted |

---

## Success Scenarios — When Everything Works

**SC-001 — Failed Inspection Creates a Service Request, Gets Approved, Vehicle Repaired**
On Wednesday morning, Driver Venkatesh inspects Bus KL-07 and finds the front left tyre has a bulge. He marks it as Failed. The system creates a service request automatically. Mr. Sharma, the Fleet Supervisor, opens the Service Log at 9:30 AM, sees the request, and approves it. The system creates a maintenance record. The workshop replaces the tyre by 1:00 PM. Mrs. Desai updates the vehicle status to "Service Done." Bus KL-07 is back on the road for the afternoon route. Total time from inspection to completion: 4 hours.

**SC-002 — Transport Manager Creates a Service Request for Scheduled Maintenance**
Mrs. Desai knows that Bus KL-12 is due for its 5,000 km service. She opens the Service Log, creates a request with reason "Scheduled 5,000 km maintenance — oil change, oil filter, air filter, brake inspection," and saves it. Mr. Sharma approves the request in the afternoon. The system creates a maintenance record. The workshop schedules the service for the weekend when the bus is not in use. The vehicle status remains "Due for Service" until the weekend, when Mrs. Desai changes it to "In-Service" and later to "Service Done."

**SC-003 — Rejected Request Is Corrected and Re-Submitted**
Driver Venkatesh reports a strange noise from the engine of Bus KL-05. Mrs. Desai creates a service request with reason "Engine noise." Mr. Sharma reviews it and rejects it because the reason is too vague — the workshop team will not know what to look for. Mrs. Desai receives the rejection, calls Venkatesh for more details, updates the reason to "High-pitched squealing noise from engine belt area when accelerating — heard during morning trip on HAL Road," and saves the change. Mr. Sharma approves the updated request. The workshop dispatches a mechanic who finds a loose alternator belt and tightens it.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Auto-Creation from Failed Inspection Fails Silently**
Driver Venkatesh completes the morning inspection for Bus KL-07 and marks the brake condition as "Failed." The inspection is saved successfully, but due to a system error in the background, no service request is created. Neither Venkatesh nor Mrs. Desai receives any indication that the auto-creation failed. The bus continues to run with failed brakes because nobody knows a service request should have been created. The next day, the same bus fails brake inspection again, and again no service request is created. The issue goes unaddressed for three days until a more serious inspection failure — or an accident — forces attention.

**FC-002 — Duplicate Service Requests for the Same Issue**
Bus KL-07 has a tyre bulge that is detected during the morning inspection on Tuesday. The system creates a service request. The request is still Pending on Wednesday morning because Mr. Sharma has not reviewed it yet. On Wednesday, the same driver inspects the same bus, finds the same tyre bulge, and marks it as Failed again. The system creates a second service request for the same issue. Now there are two requests in the system for the same tyre. Mr. Sharma approves both. The system creates two separate maintenance records. The workshop replaces the same tyre twice. The school pays for the repair twice.

**FC-003 — Approved Service Request Never Reaches the Workshop**
Mr. Sharma approves a service request for Bus KL-05's AC issue. The system attempts to create a maintenance record but encounters an error — perhaps a database connection issue or a validation problem with the maintenance record data. The approval status changes to "Approved," so everyone believes the request has been processed. However, no maintenance record is created. The workshop team checks their queue and sees nothing. Bus KL-05's AC remains broken. Drivers and passengers endure the heat for days before someone realises the maintenance record was never created.

**FC-004 — Vehicle Status Never Updated After Repair**
The workshop completes the repair on Bus KL-07's tyre. The vehicle is back on the road. However, Mrs. Desai is busy with end-of-month reports and forgets to update the vehicle status from "In-Service" to "Service Done." The Service Log shows Bus KL-07 as "In-Service" for the next two weeks. When someone runs a fleet status report, it incorrectly shows that Bus KL-07 is still in the workshop. The school's management questions why a bus is in the workshop for two weeks for a simple tyre replacement. The data is misleading because the vehicle status was never updated to reflect reality.
