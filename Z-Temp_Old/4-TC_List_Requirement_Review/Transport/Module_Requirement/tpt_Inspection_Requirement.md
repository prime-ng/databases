# Daily Vehicle Inspection — Business Requirements

## What This Screen Does

The Daily Vehicle Inspection screen is the pre-trip safety checklist that must be completed for every school bus before it leaves the depot. It checks 14 critical safety items: tyres, lights (headlights and tail lights separately), brakes, engine, battery, fire extinguisher, first aid kit, seat belts, wipers, mirrors, steering wheel, emergency tools, and overall cleanliness. Each item is marked either OK or Not OK. The driver or inspector records the odometer reading and fuel level, and the inspection is assigned a status of Passed, Failed, or Pending.

This screen is the single most important safety feature in the Transport module. Without it, a bus could leave the depot with faulty brakes, an expired fire extinguisher, or broken seat belts — and nobody in the system would know. The inspection creates a mandatory checkpoint before every trip, ensuring that no vehicle starts its route without a documented safety check.

**Critical automation**: If an inspection is marked as Failed, the system immediately performs three actions — it creates a service request for the identified issues, marks the vehicle as Not Available so it cannot be assigned to any trip, and links the service request back to this inspection for traceability.

The screen appears in two contexts:
1. **Vehicle Management → Inspection tab** — A paginated list loaded by `VehicleMgmtController@dailyInspectionQuery()`.
2. **Standalone CRUD** — Full resource via `TptDailyVehicleInspectionController` with create/edit/show/trash/restore/forceDelete and status update.

---

## Default Data Load

When the user opens Vehicle Management and clicks the Inspection tab, the system loads the most recent inspection records — 10 per page — showing the vehicle registration number, driver name, inspection date and time, overall status (Passed/Failed/Pending), and whether any issues were found. A search box allows searching by vehicle registration number or driver name. A status filter lets the user view only Passed, Failed, or Pending inspections.

When accessed through the standalone menu, the same list appears with the same filtering options.

---

## When This Screen Is Used

- **Morning Pre-Trip Inspection** — Before Bus KL-05 leaves the depot at 7:00 AM, the driver or a designated inspector walks around the bus and checks all 14 safety items. They open the Inspection tab, select the vehicle, and go through the checklist. If all items are OK, they mark the inspection as Passed and the bus departs. If any item is Not OK — for example, the right tail light is broken — they mark it as Failed, and the bus is immediately taken out of service.

- **Post-Repair Re-Inspection** — After a bus has been repaired at the workshop, it needs a fresh inspection before it can return to service. The inspector creates a new inspection record for the same vehicle, confirms all items are OK, and marks it Passed. The system automatically makes the vehicle Available again once the repair is verified.

- **Random Safety Audit** — The Fleet Supervisor conducts unannounced spot checks on buses that have already passed their morning inspection. They create an additional inspection record to verify that safety items are still functional after the bus has been on the road.

- **Incident Investigation Follow-Up** — After a minor accident involving Bus KL-07, the Transport Manager orders a detailed inspection to check if any safety item contributed to the incident. The inspection results become part of the incident documentation.

---

## Key Fields at a Glance

**Vehicle and Driver Information**
Every inspection is linked to a specific vehicle and the driver who will operate it. Only vehicles that are currently marked as Available in the Vehicle Master appear in the vehicle selection dropdown — a vehicle already in the workshop cannot be inspected until it is marked Available again.

**Safety Checklist — 14 Items**
The heart of the inspection is a 14-item checklist, each with a simple OK or Not OK toggle. The items cover every critical safety aspect of a school bus:

- **Tyres**: Are all tyres properly inflated with sufficient tread depth?
- **Headlights and Tail Lights**: Are all front and rear lights working? (Tracked separately)
- **Brakes**: Do the brakes engage properly without unusual noise or delay?
- **Engine**: Does the engine start without unusual sounds or warning lights?
- **Battery**: Is the battery terminal clean and the charge sufficient?
- **Fire Extinguisher**: Is the fire extinguisher present, charged, and within its expiry date?
- **First Aid Kit**: Is the first aid kit present and fully stocked?
- **Seat Belts**: Are all seat belts functional with no frayed straps or broken buckles?
- **Wipers**: Do the windshield wipers work and clear the glass effectively?
- **Mirrors**: Are all mirrors (rear-view, side-view) properly adjusted and intact?
- **Steering Wheel**: Does the steering respond smoothly without excessive play?
- **Emergency Tools**: Are the emergency hammer, door release, and hazard triangle present?
- **Cleanliness**: Is the bus interior and exterior reasonably clean and free of hazards?

**Checklist Results**
Along with the individual item statuses, the inspector can mark whether any issues were found overall. If issues are found, a mandatory description field requires the inspector to explain what is wrong — for example, "Right tail light broken — needs replacement." An optional remarks field allows additional notes like "Driver reported unusual engine noise during yesterday's trip."

**Odometer and Fuel Reading**
The current odometer reading and fuel level are recorded at the time of inspection. The odometer reading helps track when the next service is due. The fuel level reading confirms the bus has enough fuel for its scheduled trips.

**Inspection Outcome and Authorisation**
Every inspection has one of three statuses: Pending (incomplete), Passed (all critical items OK, vehicle cleared for service), or Failed (one or more items Not OK, vehicle grounded). When a Failed inspection is saved, the system records who inspected it and when. If the inspection is Passed, no inspector details are recorded — only the status.

---

## Business Rules and Conditions

**Failed Inspection Triggers Automatic Service Request**
This is the most important rule in the entire inspection system. When an inspection is saved with a "Failed" status, the system automatically performs three actions:
1. It deletes any existing pending service requests that were already linked to this same inspection (to avoid duplicate work orders).
2. It creates a new service request with the issue description as the reason for service.
3. It changes the vehicle's availability status to Not Available — the vehicle is immediately grounded and cannot be assigned to any trip until the issue is resolved.

This automation ensures that a safety issue is never ignored or forgotten. The moment a bus fails inspection, a repair request exists in the system and the bus is blocked from service.

**Issue Description Becomes Mandatory on Failure**
If the inspector marks the overall inspection as Failed, they must provide a written description of what issues were found. The form enforces this — if the status is "Failed" and the issues description is blank, the system refuses to save.

**Available Vehicles Only for New Inspections**
The vehicle dropdown on the create form only shows vehicles that are currently marked as Available. A vehicle that is already in the workshop (marked Not Available) cannot be inspected until it is made available again. This prevents redundant inspections for vehicles that are already grounded.

**No Re-inspection Required After Repair**
When a vehicle's service request is completed and its availability is manually restored by the Transport Manager through the Vehicle Master screen, a fresh inspection is not automatically triggered. The manager must remember to create a new Passed inspection before the bus is assigned to trips again.

**Boolean Fields Are Normalised**
Each of the 14 checklist items is stored as a Yes/No value in the database. The form accepts various input formats ("true", "false", "1", "0", "yes", "no") and converts them all to the standard 1 (OK) or 0 (Not OK) format before saving.

---

## Workflow Steps

**Performing a Morning Pre-Trip Inspection**
It is 6:45 AM. Driver Venkatesh reports for duty and walks to Bus KL-05. Before he can start the engine and drive to the first pickup stop, he must complete the daily vehicle inspection. He opens the Inspection tab on his tablet and clicks Add Inspection. He selects KL-05 from the vehicle dropdown (only available vehicles are listed). The date and time are auto-filled to the current moment. He enters the odometer reading: 1,25,340 km. The fuel gauge shows three-quarters full, so he enters 75% as the fuel level.

He goes through the 14-item checklist one by one, tapping OK for each item: tyres OK, lights OK, brakes OK, engine OK, battery OK, fire extinguisher OK, first aid kit OK, seat belts OK, headlights OK, tail lights OK, wipers OK, mirrors OK, steering OK, emergency tools OK. Cleanliness OK. He sets the overall result to Passed and saves.

The inspection is recorded. Bus KL-05 is cleared for today's route. Venkatesh starts the engine and drives to the first pickup stop.

**A Bus Fails Inspection — Automatic Service Request Created**
At 7:00 AM, Driver Suresh reports that Bus KL-07's right tail light is broken and the brake pedal feels spongy. He goes through the inspection checklist: most items are OK, but he marks tail lights as Not OK and brakes as Not OK. He sets the overall result to Failed. The issues description field becomes mandatory — he types "Right tail light bulb broken. Brake pedal has excessive travel — needs immediate attention."

When he clicks Save, three things happen instantly:
1. The system creates a service request with the issue description as the reason.
2. The system marks Bus KL-07 as Not Available — it will not appear in any trip assignment dropdowns.
3. The service request appears in the Service Log tab with a Pending approval status.

The bus stays grounded until the workshop replaces the tail light and services the brakes. Only after the Transport Manager receives the completed service report and manually restores availability can the bus return to service.

**Reviewing Inspection History**
After an incident, the Transport Manager wants to check whether Bus KL-07 had any prior inspection failures. They open the Inspection tab, search for KL-07, and see all inspections for this bus in chronological order. The inspection from two days ago shows a Passed status with no issues. The inspection from today shows a Failed status with the brake and tail light issues. This history becomes part of the incident investigation record.

---

## Example Scenario

Green Valley School's fleet of 12 buses undergoes daily pre-trip inspections. Every morning between 6:30 AM and 7:30 AM, each driver completes the 14-item checklist for their assigned vehicle.

On Monday morning, Bus KL-05 (registration KA-01-EX-1234) passes inspection with all 14 items OK at 6:45 AM. Driver Venkatesh takes the bus on its route without issues.

Bus KL-07 (registration KA-01-EX-5678) fails inspection at 7:10 AM. Driver Suresh reports that the right tail light is not working and the brake pedal feels spongy. The inspection records both issues, the system automatically creates a service request, and Bus KL-07 is grounded.

Bus KL-09 passes inspection at 6:50 AM, but the driver notes in the remarks that the fuel level is only 20% and the bus may need refuelling before the afternoon shift. The inspector makes a mental note to check fuel levels after the morning route.

By 7:30 AM, 11 buses have passed inspection and are on the road. One bus (KL-07) is grounded. The Transport Manager receives a notification through the Service Log that a new service request has been created for KL-07. The workshop is alerted, and a mechanic begins working on the tail light and brakes.

---

## Related Screens

- **Service Log** — When an inspection fails, a service request is automatically created here for workshop follow-up.
- **Vehicle Master** — The vehicle's availability status is set to Not Available when an inspection fails and restored when the vehicle is repaired.
- **Vehicle Management Dashboard** — The dashboard's pending data widget shows the count of failed inspections that need attention.
- **Fuel Log** — The odometer reading recorded during inspection can be cross-referenced with fuel log entries for mileage tracking.

---

## Requirements

- Controller: `TptDailyVehicleInspectionController` with full resource methods plus `trashed`, `restore`, `forceDelete`, `updateStatus`
- Hub tab data: Loaded via `VehicleMgmtController@dailyInspectionQuery()` with search by vehicle registration or driver name
- Model: `TptDailyVehicleInspection` (table: `tpt_daily_vehicle_inspection`) — SoftDeletes, 14 boolean condition fields, status defaults to Pending
- Form Request: `TptDailyVehicleInspectionRequest` — validates all fields; issues_description becomes required if status is Failed
- Policy: `TransportDailyVehicleInspectionPolicy` (`tenant.daily-vehicle-inspection.*`)
- Activity logging: ✅ Present on Created, Updated (field-level changes), Trashed, Restored, ForceDeleted, StatusUpdated
- Permissions: `tenant.daily-vehicle-inspection.{viewAny, view, create, update, delete, restore, forceDelete, approve}`

---

## Who Can Access

- **Transport Manager** — Full access to all inspection records. They can view inspection history, create new inspections, edit existing ones, soft-delete incorrect entries, restore deleted ones, and permanently remove test data. They are also responsible for restoring vehicle availability after a failed inspection's repairs are completed.

- **Fleet Supervisor** — Can view all inspection records and create new inspections during spot checks or audits. They can also change the inspection status. However, they cannot delete or permanently remove inspection records.

- **Driver** — Can create new inspections for their assigned vehicle and view their own inspection history. They cannot edit or delete inspections once saved. This is the primary user who completes the daily checklist.

- **Inspector / Safety Officer** — Can create and view inspections but cannot edit or delete them. This role is for designated safety personnel who may conduct random audits independently of the drivers.

- **School Administrator** — Read-only access to inspection records for compliance reporting and audit purposes.

Behind the scenes, each action is protected by a permission check. If a user tries to perform an action they are not authorised for, the system displays an "Access Denied" message.

---

## Logic Flow

When the user clicks the Inspection tab in Vehicle Management, the system loads the most recent inspection records — 10 per page — along with the linked vehicle and driver information. Each row shows the vehicle registration number, driver name, inspection date and time, overall status (with a coloured badge), and whether any issues were found. A search box allows typing a vehicle registration number or driver name to narrow the list.

When the user clicks "Add Inspection," a form appears with a vehicle dropdown (showing only vehicles marked as Available) and a driver dropdown (showing all registered staff). The date and time defaults to the current moment. The inspector then goes through the 14-item checklist, tapping OK or Not OK for each item. At the bottom, they set the overall result: Passed, Failed, or Pending. If they select Failed, the issues description field becomes mandatory — they must explain what is wrong.

When the user clicks Save, the system checks whether the inspection status is "Failed." If it is, the system performs three automatic actions in sequence: it deletes any existing pending service requests linked to this inspection (to prevent duplicates), creates a new service request with the issue description as the reason, and marks the vehicle as Not Available in the Vehicle Master. The inspection is saved, the service request is created, and the vehicle is grounded — all in a single save operation. If the status is "Passed" or "Pending," the inspection is saved without any automatic actions.

When the user clicks Edit on an existing inspection, the form loads with all 14 checklist items pre-filled. The user can change any OK/Not OK toggles. If they change the overall status from Passed to Failed, the same automatic actions (service request creation, vehicle grounding) are triggered again. If they change from Failed to Passed, the system does not automatically restore the vehicle's availability — the Transport Manager must do that manually through the Vehicle Master.

For delete, restore, and permanent delete, the behaviour is standard: soft deletion hides the record in the Trash folder, restore brings it back, and force delete removes it permanently.

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Vehicle | Must be selected from Available vehicles only | "Please select a vehicle." |
| Driver | Optional — if provided, must be a valid staff member | "The selected driver is invalid." |
| Inspection Date | Must be a valid date and time | "Please enter a valid inspection date." |
| Odometer Reading | Optional — if provided, must be a number | "The odometer reading must be a valid number." |
| Fuel Level | Optional — if provided, must be a valid percentage | "Please enter a valid fuel level." |
| 14 Checklist Items | Each item is optional — can be left blank for items not checked | — |
| Issues Description | Becomes mandatory if the overall status is "Failed" | "Please describe the issues found." |
| Overall Status | Must be Passed, Failed, or Pending | "Please select an inspection status." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Inspection marked Failed but no issues described | "Please describe the issues found." — the form blocks submission | Validation — required field on failure |
| Vehicle not selected | "Please select a vehicle." — form does not submit | Data entry error |
| Invalid odometer format | Validation error — form blocks submission | Data entry error |
| User tries to inspect a vehicle that is Not Available | The vehicle does not appear in the dropdown — the user cannot select it | Business rule — only available vehicles shown |
| Permission denied on create | System shows "Access Denied" | Permission error |
| Inspection edited from Passed to Failed — vehicle availability not changed | The system creates a service request but does not change the vehicle's availability status automatically on edit (only on initial save) | 🔴 Gap — edit does not trigger full automation |
| Inspection edited from Failed to Passed — vehicle not restored to Available | The system does not restore vehicle availability when status changes from Failed to Passed. The Transport Manager must manually restore it. | 🔴 Gap — no automatic recovery |
| Multiple failed inspections for the same vehicle on the same day | Each failed inspection creates a separate service request — there is no check to prevent duplicate service requests for the same issue | 🔴 Gap — duplicate prevention missing |

---

## Success Scenarios — When Everything Works

**SC-001 — Full Fleet Passes Morning Inspection**
At 6:30 AM, all 12 buses in the Green Valley fleet undergo their daily pre-trip inspections. Each driver goes through the 14-item checklist. All 12 buses pass — every safety item is OK, no issues found. The system records 12 Passed inspections. All 12 buses are cleared for their morning routes and depart on time. The day's operations begin without a hitch.

**SC-002 — Failed Inspection Triggers Automatic Repair**
Bus KL-07's driver notices the right tail light is broken during the morning inspection. He marks tail lights as Not OK and sets the overall result to Failed. He describes the issue: "Right tail light bulb broken — needs replacement." When he saves, the system automatically creates a service request and marks KL-07 as Not Available. The workshop supervisor sees the service request appear in the Service Log within seconds. By 9:00 AM, the bulb is replaced, the brake system is checked, and the supervisor marks the vehicle as Available again after a quick re-inspection confirms everything is working.

**SC-003 — Inspection History Used for Incident Investigation**
After a minor sideswipe incident involving Bus KL-09, the Transport Manager reviews the inspection history for that vehicle. The inspection from that morning shows all 14 items as OK, with the mirrors specifically marked as properly adjusted. The inspection record helps establish that the vehicle was in safe condition at the start of the day, and the incident was not caused by a pre-existing mechanical defect.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Driver Marks All Items OK Without Actually Inspecting**
A driver is in a hurry and simply taps "OK" for all 14 items without walking around the bus. The system has no way to verify that the driver actually performed the inspection — there is no timer, no photo requirement, and no GPS location check. A bus with a flat tyre or a missing first aid kit could pass inspection because the driver did not check but the system thinks they did.

**FC-002 — Edit from Passed to Failed Does Not Fully Ground the Vehicle**
An inspector initially passes a bus, but later realises they missed a broken tail light. They edit the inspection from Passed to Failed. The system creates a service request for the new failure, but it does not automatically change the vehicle's availability status to Not Available — that only happens on the initial save. The bus could remain marked as Available in the system and be assigned to an afternoon trip even though it has a confirmed safety defect.

**FC-003 — Duplicate Service Requests for the Same Issue**
A bus fails inspection, and a service request is automatically created. The inspector then edits the inspection — perhaps to add more detail to the issue description — and saves again. The system creates a second service request for the same issue because it only deletes existing pending requests linked to this inspection at store time, not at update time. The workshop now sees two work orders for the same faulty tail light.

**FC-004 — Vehicle Stays Grounded After Repairs (No Automatic Recovery)**
A bus fails inspection, gets repaired, and the service request is marked as completed in the Service Log. However, completing the service request does not automatically restore the vehicle's availability status. The Transport Manager must remember to open the Vehicle Master, find the bus, and manually toggle its availability back to Available. If the manager forgets, the bus stays grounded even though the repair is done — and nobody gets an alert that a repaired vehicle is waiting to be cleared for service.