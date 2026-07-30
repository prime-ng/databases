# Vehicle Approval — Business Requirements

## What This Screen Does

The Vehicle Approval tab is the place where service requests for school vehicles are reviewed and decided upon. It is not a separate data entry screen — it is an approval interface that displays pending service requests that have been logged in the Service Log. When an authorised person approves a service request, the system automatically creates a maintenance record so the workshop can begin work. When a request is rejected, it is marked as such and no maintenance record is created.

Without this screen, every service request logged in the system would remain in limbo — there would be no formal process for a supervisor to say "Yes, this bus needs servicing" or "No, this can wait." The workshop would have no way of knowing which requests have been authorised and which are still awaiting review. Service requests would pile up with no clear path from "logged" to "being worked on."

This screen is the bridge between reporting a problem and actually fixing it. It gives the Transport Manager or Fleet Supervisor a single place to review all pending requests, see what each vehicle needs and why, and decide whether to proceed.

---

## Default Data Load

When the Transport Manager opens Vehicle Management and clicks the Veh. Approval tab, the system loads all service requests that have a status of "Pending" — sorted with the most recent requests at the top. Each request shows the date it was logged, the vehicle registration number, the reason for the service, the current vehicle status, the approval status, and the completion date if one has been entered.

A search box at the top allows searching by the reason for service or the vehicle registration number. A filter dropdown lets the manager narrow the list to show All requests, or only Pending, Approved, or Rejected ones.

---

## When This Screen Is Used

- **Reviewing Daily Service Requests** — Every morning, the Fleet Supervisor opens the Veh. Approval tab to see if any new service requests were logged the previous day. Bus KL-05 has a "Brake noise — front left wheel" request from yesterday. The supervisor reviews it, confirms it is a genuine issue, and clicks Approve. A maintenance record is automatically created, and the workshop can begin work.

- **Rejecting Non-Essential Requests** — A driver logs a service request for Bus KL-07: "Seat cushion slightly worn — passenger side, second row." The Fleet Supervisor reviews it and determines this is cosmetic, not urgent. They click Reject, and the request status changes to "Rejected." No maintenance record is created, and no workshop time is wasted on a non-essential repair.

- **End-of-Month Audit** — The School Administrator opens the Veh. Approval tab at the end of the month, sets the filter to "Approved," and reviews all service requests that were approved this month. They can see how many maintenance records were created, which vehicles needed the most attention, and whether any patterns are emerging (for example, the same vehicle appearing with multiple brake-related requests).

- **Checking the Status of a Specific Request** — The Transport Manager remembers that a service request was logged for Van VN-03 last week about an AC issue. They open the Veh. Approval tab, type "VN-03" in the search box, and see that the request is still pending — nobody has reviewed it yet. They flag it for the Fleet Supervisor's attention.

---

## Key Fields at a Glance

**Request Date**
The date on which the service request was originally logged in the Service Log. This tells the approver how long the request has been waiting for a decision. A request that is several days old with a "Pending" status may need to be prioritised.

**Vehicle**
The registration number and identifying details of the vehicle that needs service. Every request is linked to exactly one vehicle — you cannot create an approval without knowing which vehicle needs attention.

**Reason for Service**
A description of what is wrong with the vehicle or what service is needed. This is the information the approver uses to decide whether to approve or reject the request. Examples include "Engine overheating," "Brake pad replacement needed," or "Regular oil change due."

**Current Vehicle Status**
The vehicle's current operational state — for example, "Active" (operating normally), "In Workshop" (under repair), or "Out of Service" (taken off the road). This helps the approver understand whether the vehicle is already in the workshop or still on the road.

**Approval Status**
Shows whether the request is Pending (awaiting review), Approved (cleared for maintenance), or Rejected (declined). The Veh. Approval tab primarily displays Pending requests, but the filter allows viewing all statuses.

**Completion Date**
An optional field showing when the service was completed. This may be blank if the request has not yet been processed through to completion.

**Approve and Reject Buttons**
Each pending request has two buttons. The Approve button turns a request into an active maintenance record. The Reject button marks the request as declined. Once clicked, the buttons become disabled — no further changes can be made through this interface.

---

## Business Rules and Conditions

**Only Pending Requests Can Be Approved or Rejected**
The system will only allow the Approve or Reject action on requests with a "Pending" status. If a request has already been approved or rejected, the buttons are disabled and cannot be clicked. There is no way to approve an already-approved request again, and no way to reject an already-rejected request.

**Approving Creates a Maintenance Record Automatically**
When a request is approved, the system does not just change the status — it also creates a new maintenance record in the TptVehicleMaintenance table. This record is created with specific default values: the initiation date is set to today's date, the type is "General Service," the cost is zero (to be updated later when the actual service cost is known), and the status is "Pending" (meaning the maintenance work has not yet started). The system uses a "first or create" approach, meaning it will not duplicate a maintenance record if one already exists for the same service request.

**Rejecting Does Not Create a Maintenance Record**
If the approver decides the service request is not valid or not urgent, clicking Reject simply changes the status to "Rejected." No maintenance record is created. The request remains in the system for audit purposes but is not acted upon.

**No Undo**
Once a request has been approved or rejected, the status cannot be changed back through the Veh. Approval interface. The buttons become disabled and greyed out. If a mistake is made, it would need to be corrected through a different process — the approval interface itself offers no undo functionality.

**Approved By and Approved At Are Recorded**
When an approver clicks Approve, the system records who approved the request (the logged-in user's name or ID) and the exact date and time of approval. This creates an audit trail so the school can always know who authorised a particular service and when.

**Search by Reason or Vehicle Number**
The search box looks for matches in the reason for service text and the vehicle registration number. It does not search by date, approval status, or completion date. If a manager wants to find all requests from a specific date range, they must scroll through the list or use the filter options.

**Filter by Approval Status**
The filter dropdown allows the manager to view All requests, or only those with a specific approval status (Pending, Approved, or Rejected). This is useful for quickly finding requests that still need attention.

---

## Workflow Steps

**Reviewing and Approving a Pending Service Request**
The Fleet Supervisor opens the Veh. Approval tab. The list shows Bus KL-05 with a request logged two days ago: "Engine oil leak — visible puddle under front of vehicle when parked." The supervisor reads the reason, notes that the vehicle status is "Active" (the bus is still running), and decides this needs immediate attention. They click the Approve button next to this request. A SweetAlert2 confirmation dialog appears: "Are you sure you want to approve this service request?" The supervisor clicks "Yes, approve it." The system updates the request status to "Approved," records the supervisor's name as the approver with the current date and time, and automatically creates a new maintenance record with today's date, type "General Service," cost 0, and status "Pending." The buttons become disabled. The request now shows a green "Approved" badge.

**Reviewing and Rejecting a Non-Essential Request**
The Fleet Supervisor sees a request for Van VN-02: "Dashboard warning light for tyre pressure — light comes on intermittently." The supervisor knows this van has had a sensitive tyre pressure sensor since it was new — the light comes on whenever the temperature changes. The tyres are fine. They click the Reject button. A SweetAlert2 confirmation dialog appears: "Are you sure you want to reject this service request?" The supervisor clicks "Yes, reject it." The system changes the status to "Rejected," records the supervisor's name and the rejection time, and does not create any maintenance record. The buttons become disabled. The request now shows a red "Rejected" badge.

**Searching for a Specific Request**
The Transport Manager remembers that someone logged a request about "brake" issues for one of the buses last week, but cannot remember which bus. They type "brake" in the search box. The list immediately filters to show only requests where the reason contains the word "brake." There are three results — one for Bus KL-05, one for Bus KL-07, and one for Van VN-01. The manager finds the one they were looking for and sees that it is still pending — they flag it for the supervisor.

---

## Example Scenario

Green Valley School operates 12 buses and 2 vans. The Fleet Supervisor, Mr. Sharma, starts each day by checking the Veh. Approval tab for new service requests.

On Monday morning, he opens the tab and sees six pending requests:

- Bus KL-05: "Engine overheating — temperature gauge rising above normal after 30 minutes of driving" (logged Saturday)
- Bus KL-07: "Brake noise — squeaking sound when braking at low speed" (logged Friday)
- Bus KL-12: "Seat belt buckle broken — driver's side, does not click into place" (logged Sunday)
- Van VN-01: "AC not cooling — air is warm even at maximum setting" (logged Saturday)
- Van VN-02: "Tyre pressure warning light intermittent — probably sensor issue" (logged Thursday)
- Bus KL-08: "Regular oil change due — odometer reading close to service interval" (logged Sunday)

Mr. Sharma reviews each one:

1. For Bus KL-05 (engine overheating), he approves immediately — this is a serious issue that could cause engine damage if ignored. A maintenance record is created.

2. For Bus KL-07 (brake noise), he approves — brake issues are safety-critical. A maintenance record is created.

3. For Bus KL-12 (seat belt buckle), he approves — a broken seat belt is a safety violation. A maintenance record is created.

4. For Van VN-01 (AC not cooling), he approves — in the hot climate, a non-functional AC makes the van unusable for students. A maintenance record is created.

5. For Van VN-02 (tyre pressure sensor), he rejects — this is a known recurring issue with this van's sensor, and the tyres are fine. No maintenance record is created.

6. For Bus KL-08 (oil change due), he approves — regular maintenance should never be delayed. A maintenance record is created.

By the end of Monday morning, five new maintenance records have been created, and one request has been rejected. The workshop team can now see which vehicles need attention and plan their week accordingly.

---

## Related Screens

- **Vehicle Management Dashboard** — The dashboard may show the count of pending approvals, giving the Transport Manager a quick overview of how many requests are awaiting review.

- **Service Log** — This is where service requests originate. Every request that appears in the Veh. Approval tab was first created in the Service Log. The Service Log captures the initial report of the issue.

- **Vehicle Master** — Each service request is linked to a specific vehicle registered here. The vehicle's registration number, status, and details are displayed alongside each approval request.

- **Maintenance Records** — When a request is approved, a maintenance record is automatically created. This record can be viewed and managed in the Maintenance section. It starts with default values (today's date, "General Service," cost 0, status "Pending") that can be updated later as the actual service progresses.

---

## Requirements

- Approval interface loads via `VehicleMgmtController@vehicleServiceRequestQuery()` with search and status filters within the Vehicle Management hub
- Standalone approve/reject handled by `TptVehicleServiceRequestController@updateStatus()` for the dedicated view
- On Approve: AJAX POST updates `status = 'Approved'`, sets `approved_by` and `approved_at`, and creates/updates `TptVehicleMaintenance` record via `firstOrCreate` with `initiation_date = today`, `type = 'General Service'`, `cost = 0`, `status = 'Pending'`
- On Reject: Status changes to `'Rejected'`, no maintenance record created
- SweetAlert2 confirmation dialogs before Approve and Reject actions
- Policy: `TransportVehicleServiceApprovalPolicy`
- Permissions: `tenant.vehicle-service-approval.{viewAny, view, approve, reject}`

---

## Who Can Access

- **Transport Manager** — Full access to the Veh. Approval tab. They can view all service requests, approve legitimate requests, and reject requests that are not valid or not urgent. This is the primary user who manages the approval workflow.

- **Fleet Supervisor** — Can view all service requests and change the approval status from Pending to Approved or Rejected. This is the person who typically reviews requests on a daily basis and decides which ones should proceed to maintenance.

- **School Administrator** — Read-only access to the Veh. Approval tab. They can view the list of requests and their approval statuses, but cannot approve or reject any requests. This allows them to audit the approval process without being able to change it.

- **Driver** — Does not have access to this screen. Drivers log service requests through the Service Log and then inform the Transport Manager or Fleet Supervisor verbally or through a note. The review and approval happens in this screen, which drivers cannot access.

Behind the scenes, each action is protected by a permission check. If a user tries to view the tab without the `viewAny` permission, the tab does not appear. If a user tries to approve or reject without the `approve` or `reject` permission, the system displays an "Access Denied" message.

---

## Logic Flow

When the Transport Manager clicks the Veh. Approval tab in Vehicle Management, the system loads all service requests that have a status of "Pending" — these are requests that have been logged in the Service Log but have not yet been reviewed. The list shows the request date, vehicle registration number, reason for service, current vehicle status, approval status (all showing "Pending" by default), and completion date if one exists.

When the manager types a search term, the system filters the list in real time, looking for matches in the reason for service text and the vehicle registration number. If the manager selects a filter option (All, Pending, Approved, Rejected), the system reloads the list showing only requests with the selected approval status. The search and filter can be used together — for example, showing only "Approved" requests that contain the word "brake."

When the manager clicks the Approve button, a SweetAlert2 confirmation dialog appears: "Are you sure you want to approve this service request?" with "Yes, approve it" and "Cancel" buttons. If the manager clicks "Yes, approve it," the system sends an AJAX POST request that updates the service request's status to "Approved," records the current user as the approver with the current date and time, and creates a new maintenance record using a "first or create" approach — if a maintenance record does not already exist for this service request, one is created with today's date as the initiation date, "General Service" as the type, zero as the cost, and "Pending" as the status. The page updates to show the new "Approved" badge and disables both the Approve and Reject buttons.

When the manager clicks the Reject button, another SweetAlert2 confirmation dialog appears: "Are you sure you want to reject this service request?" with "Yes, reject it" and "Cancel" buttons. If the manager clicks "Yes, reject it," the system sends an AJAX POST request that updates the service request's status to "Rejected" and records the current user as the approver with the current date and time. No maintenance record is created. The page updates to show the new "Rejected" badge and disables both buttons.

---

## Validate Before Save

| Action | What the System Checks | Error Message If Wrong |
|--------|----------------------|------------------------|
| Approve | The request must have a "Pending" status | "This request has already been processed." |
| Approve | The user must have the `approve` permission | "Access Denied — you are not authorised to approve service requests." |
| Approve | The service request must exist in the database | "Request not found." |
| Reject | The request must have a "Pending" status | "This request has already been processed." |
| Reject | The user must have the `reject` permission | "Access Denied — you are not authorised to reject service requests." |
| Reject | The service request must exist in the database | "Request not found." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| User clicks Approve on an already-approved request | "This request has already been processed." — the buttons are disabled, so this should not happen under normal circumstances | State error — request no longer pending |
| User clicks Approve without the approve permission | "Access Denied" — the system does not allow the action | Permission error |
| User clicks Reject without the reject permission | "Access Denied" — the system does not allow the action | Permission error |
| AJAX request fails due to network error | A SweetAlert2 error message: "Something went wrong. Please try again." | Network or server error |
| Service request was deleted by another user between loading the page and clicking Approve | "Request not found." | Concurrent modification — data changed by another user |
| Maintenance record creation fails after approval | The service request status is still updated to "Approved," but the maintenance record is not created. The user does not see an error because the approval succeeds — the maintenance creation failure is logged on the server | Partial failure — approval succeeds but maintenance creation fails |

---

## Success Scenarios — When Everything Works

**SC-001 — Approving a Critical Service Request**
A driver logs a service request for Bus KL-05: "Engine overheating — temperature gauge rising above normal." The Fleet Supervisor opens the Veh. Approval tab the next morning, sees the request at the top of the list (sorted by most recent), reviews the reason, and clicks Approve. The SweetAlert2 confirmation appears. The supervisor confirms. The system updates the request status to "Approved," records the supervisor as the approver with the current date and time, and creates a maintenance record with today's date, type "General Service," cost 0, and status "Pending." The workshop team sees the new maintenance record and schedules the engine diagnostic. The bus is repaired within two days.

**SC-002 — Rejecting a Non-Essential Request**
A driver logs a request for Van VN-02: "Dashboard warning light for tyre pressure comes on intermittently." The Fleet Supervisor recognises this as a known quirk of this van's sensitive tyre pressure sensor — the tyres are fine, and this is the third time a request has been logged for the same issue. The supervisor clicks Reject. The SweetAlert2 confirmation appears. The supervisor confirms. The system changes the status to "Rejected" and does not create a maintenance record. No workshop time is wasted on a non-issue.

**SC-003 — Searching and Filtering for Audit**
The School Administrator opens the Veh. Approval tab at the end of the month to review all approved service requests. They set the filter to "Approved" and see 28 requests that were approved this month — covering 15 different vehicles. They search for "brake" and find that 6 of the 28 approved requests were brake-related, spread across 4 different buses. This information is included in the monthly operations report, and the Transport Manager uses it to plan a fleet-wide brake inspection.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Approval Creates Maintenance Record but Approval Status Fails to Update**
The Fleet Supervisor clicks Approve on a pending service request. The SweetAlert2 confirmation appears and the supervisor confirms. However, due to a server-side error, the service request's status is updated to "Approved" but the maintenance record is not created. The supervisor sees the green "Approved" badge and assumes a maintenance record exists — but the workshop never receives the work order. The vehicle's issue goes unaddressed until someone notices that no maintenance was scheduled. There is no visible warning on the screen that the maintenance record creation failed.

**FC-002 — Rejected Request Cannot Be Reversed**
The Fleet Supervisor accidentally clicks Reject on a valid service request for Bus KL-07 (legitimate brake issue). The SweetAlert2 confirmation appears, and the supervisor — distracted — clicks "Yes, reject it" without reading the confirmation. The request status changes to "Rejected," and the buttons become disabled. The supervisor realises the mistake immediately but cannot undo the rejection through the Veh. Approval tab. The driver must log a new service request, and the supervisor must approve it — creating a delay in getting the bus's brakes inspected.

**FC-003 — No Notification When a Request Is Approved or Rejected**
When a service request is approved or rejected, the system does not send any notification to the driver who logged the request. If a driver logs a request for an oil change and the supervisor approves it, the driver has no way of knowing that the approval went through unless they check the Service Log manually or are told verbally. The driver may assume the request is still pending and log a duplicate request, creating confusion in the system. Similarly, if a request is rejected, the driver receives no explanation and may log the same request again.

**FC-004 — Approval Buttons Visible for Non-Pending Requests Due to Page Not Refreshing**
A supervisor opens the Veh. Approval tab and sees a list of pending requests. In another browser tab, another supervisor approves one of the same requests. The first supervisor, still looking at the stale page, sees the Approve and Reject buttons still active for that request. They click Approve, and the system responds with "This request has already been processed." While the system correctly prevents the double approval, the user experience is confusing — the user expected the action to succeed and sees an error instead. The page does not automatically refresh to reflect the status change made by the other user.
