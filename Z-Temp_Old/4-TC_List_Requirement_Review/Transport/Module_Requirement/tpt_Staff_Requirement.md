# Staff (Personnel) — Business Requirements

## What This Screen Does

The Staff screen manages all transport personnel — drivers, helpers, and transport managers — in a unified profile system. It stores personal details, government ID numbers (Aadhaar, PAN, etc.), driving licence information, police verification status, assigned vehicle, and scanned document uploads. Each personnel record can be linked to a system user login for app-based attendance. The screen also supports printing transport staff ID cards via the template engine.

Without this screen, the Transport Manager would have to juggle paper files for every driver's licence, police verification certificates, and photo IDs scattered across multiple physical folders — making it nearly impossible to quickly verify who is qualified to drive, whose licence is expiring next month, or whether a new hire has completed their background check before being assigned to a route with 40 school children on board.

The screen appears in two contexts:
1. **As a tab in Transport Master** — Shows a paginated list of all personnel with search and filter, loaded by `TransportMasterController`.
2. **As a standalone CRUD** — Full `DriverHelperController` resource with create, edit, show, trash, restore, force-delete, toggle-status, and ID-card-print actions.

---

## Default Data Load

When the Transport Manager opens Transport Master and clicks the Staff tab, the system loads the list of all drivers, helpers, and transport managers — 10 records per page — along with their assigned vehicle names and linked user accounts. A search box at the top lets the manager type a staff name or personnel code to find a specific person.

For the Add and Edit forms, the system prepares two dropdown lists in advance: a list of all active vehicles (so the manager can assign a staff member to a bus), and a list of all employees in the Transport department (so the manager can link the staff member to a system login account for the mobile app).

---

## When This Screen Is Used

- **Hiring a New Driver** — The school has hired a new driver named Rajesh who has 5 years of experience driving school buses in Bengaluru. Before Rajesh can be assigned to any route, the Transport Manager must create his personnel record in the system. This includes entering his full name, contact number, role (Driver, Helper, or Both), driving licence number and its expiry date, months of driving experience, police verification status, and uploading scanned copies of his photo, licence, and police verification certificate. Without this record, Rajesh does not exist in the system — he cannot be assigned to a vehicle, cannot receive attendance scans, and cannot be issued an ID card.

- **Renewing a Driver's Expiring Licence** — A driver named Suresh has a licence that expires in two weeks. He has renewed it at the RTO and given the new licence document to the Transport Manager. The manager opens Suresh's record, updates the licence expiry date to the new date (which is 5 years from now), and uploads the scanned copy of the renewed licence. The system automatically removes the old scanned copy and stores the new one. This renewal is important because if the licence is not updated in the system, the Dashboard cannot alert the manager when it expires — and an expired licence means Suresh cannot legally drive.

- **Printing a Staff ID Card** — The school requires all transport staff to wear visible ID cards while on duty. When a new ID card is needed (for a new hire, or because the old card was lost or damaged), the manager opens the staff record and clicks "Print ID Card." The system generates a card using the school's official template, showing the staff member's photo, name, role, personnel code, and assigned vehicle. The manager can print this card directly from the browser.

- **Assigning Staff to Routes and Vehicles** — Before the morning shift begins, the Transport Manager needs to decide which driver and which helper will handle which bus and which route. They open the Driver-Route-Vehicle Assignment screen and select staff members from the list — but only staff members who have been registered here first will appear in that dropdown. If a new driver was hired but never registered in the Staff screen, the assignment screen will not show them, and the morning trip cannot proceed.

---

## Key Fields at a Glance

**Personnel Identity and Role**
Every transport staff member receives a system-generated personnel code in the format `PER-YYYYMMDD-NNN`, for example `PER-20260721-003` for the third staff member registered on July 21, 2026. This code acts as the permanent employee reference across all transport operations. The staff member's full name is captured along with an optional contact phone number. The role field determines whether the person works as a Driver (operates the vehicle), a Helper (assists with boarding and attendance), or Both (drives and assists on different routes). The ID card technology field selects how this staff member's identity card works — QR code (scanned by a phone camera), RFID (tapped against a reader), NFC (wireless tap), or Barcode (laser-scanned).

**Government ID Documents**
Optional fields capture the staff member's official identification: the type of document (Aadhaar Card, Driving Licence Number, PAN Card, Voter ID, or Passport) and the corresponding ID number. These are stored as plain text without encryption — a noted compliance gap under data protection regulations.

**Driving Licence Information**
For staff members whose role includes driving, two fields are mandatory: the driving licence number and its expiry date. The system validates that the expiry date is in the future at the time of creation — a driver whose licence has already expired cannot be registered with a valid status. Months of driving experience is an optional field capturing how long the person has been professionally driving.

**Vehicle Assignment**
A staff member can be optionally linked to a specific vehicle. Three rules govern this assignment: (1) an inactive staff member cannot have an assigned vehicle, (2) only one active driver and one active helper can be assigned to the same vehicle — you cannot have two drivers for the same bus, (3) if the staff member is linked to a system user account, that user cannot be assigned to more than one vehicle.

**Police Verification**
A boolean flag records whether the staff member has completed a police background verification. This is a critical safety check for anyone working with school children, but the current system does not raise any alerts or warnings for unverified personnel — the flag is stored but not actively enforced on the dashboard or during assignment.

**Residential Address**
A free-text address field of up to 512 characters captures the staff member's residence. This is used for emergency contact and as part of the printed ID card template.

**User Account Linkage**
An optional link to a system user account (`user_id`) enables the staff member to log into the mobile driver/helper app for attendance scanning and route information. Without this link, the staff member cannot use the app.

**Document Uploads**
Five document types can be uploaded as scanned copies: a personnel photograph, the identity card document, the driving licence scan, the police verification certificate, and an address proof document. Each type has a boolean flag in the database tracking whether it has been uploaded, though these flags operate independently from the media file storage.

---

## Business Rules and Conditions

**Personnel Code Auto-Generation (BR-TPT-015)**
Every time a new staff record is created, the system automatically generates a unique personnel code in the format `PER-YYYYMMDD-NNN`. The `NNN` part is a zero-padded daily sequential counter — the first person registered today gets `001`, the second gets `002`, and so on. Because two Transport Managers could theoretically create records at the exact same moment, the system uses a database row lock (`lockForUpdate()`) inside a transaction to ensure the counter never produces duplicate codes. This code becomes the permanent employee reference used in attendance logs, ID cards, and route assignments, so it must never collide.

**Licence Expiry — Point-in-Time Validation Only (BR-TPT-003)**
When a new driver is created or an existing driver's licence is updated, the system checks that the `license_valid_upto` date is after today. This prevents someone from entering an already-expired licence at registration time. However, there is no ongoing enforcement. If a driver's licence expires six months after being entered into the system, nothing prevents that driver from being assigned to a trip the next day. The system does not re-check the expiry date at the point of trip assignment, meaning a driver with an expired licence can legally be put behind the wheel of a school bus according to the system, even though this would be a serious legal and safety violation in practice.

**Police Verification Flag — Stored But Not Enforced (BR-TPT-004)**
The `police_verification_done` boolean exists in the database to track whether the staff member has cleared their background check. However, no alarm bell rings anywhere in the system when an unverified person is assigned to a route. The dashboard does not display a counter of pending verifications, the staff list does not highlight unverified records, and the assignment screen does not block an unverified helper from being put on a bus with children. The data is captured but unused for decision-making.

**One Driver Per Vehicle**
The system enforces that a given vehicle can have at most one active driver and one active helper assigned at any time. This prevents conflicts like two drivers both believing they are responsible for the morning route on bus number 5, or two helpers both reporting for duty on the same bus while another bus has none.

**Inactive Staff Cannot Keep a Vehicle**
If a staff member's record is deactivated (set to inactive), their vehicle assignment must be cleared. This prevents a terminated driver from still appearing as the responsible person for a bus in system reports.

**One System User, One Vehicle**
If a staff member has a linked system user account (for the mobile attendance app), that user can only be assigned to one vehicle at a time. This prevents a single driver from receiving push notifications and attendance data for two different buses simultaneously.

**Sensitive Data Stored in Plain Text (BR-TPT-021 — NOT IMPLEMENTED)**
Government ID numbers (Aadhaar, PAN), driving licence numbers, and device push notification tokens are classified as sensitive personal data under India's DPDP Act. In the current implementation, all of these fields are stored in the database as plain UTF-8 strings without any encryption at rest. Furthermore, the user interface displays the full values without masking — anyone who can see the Staff edit screen can read the complete Aadhaar number of every driver. This is a compliance gap that needs to be addressed.

**Licence Number Uniqueness**
The driving licence number, if provided, must be globally unique across all personnel records. This prevents the same licence from being registered for two different drivers, which could otherwise create confusion during traffic enforcement checks.

---

## Workflow Steps

**Creating a Personnel Record**
The Transport Manager clicks Add Staff. The create form loads with dropdowns: role (Driver/Helper/Both), ID card type (QR/RFID/NFC/Barcode), assigned vehicle (active vehicles only), linked user (employees in transport department). The manager fills in the form, optionally uploads documents. On submit, the system generates the personnel code in a DB transaction (with row lock), creates the record, uploads media files, logs the activity, and redirects to Transport Master.

**Editing a Personnel Record**
The Edit form pre-populates all fields. Vehicle and user dropdowns filter the same way as create. On update, the system captures original values for change tracking, replaces any uploaded files (clears old collection, uploads new), updates upload flags to true for replaced files, logs changes, and redirects.

**Soft-Deleting a Personnel Record**
The Delete action sets `is_active = false`, calls soft delete, and logs the activity. The record goes to trash.

**Printing an ID Card**
The Print ID Card button opens `printIdCard($id)`. The system looks up a `TemplatePurpose` with code `TRANSPORT_STAFF_ID_CARD`, finds the active template assignment, renders the template via `TemplateEngine` with the staff ID as context, and displays the rendered card in a print-friendly view.

---

## Example Scenario

Green Valley School is expanding its fleet and needs two new drivers and one new helper for the upcoming academic year. The Transport Manager, Mrs. Desai, has completed the interviews and background checks. Today, she is registering the new hires in the system.

The first new hire is Rajesh Kumar, a driver with 5 years of experience driving school buses in Bengaluru. Mrs. Desai opens the Staff tab and clicks Add Staff. She enters Rajesh's full name, selects "Driver" as his role, and chooses "QR Code" as his ID card type (the school uses QR-based attendance scanning). She enters his driving licence number — KA-01-2024001234 — which is valid until December 31, 2028. She notes that he has 60 months (5 years) of driving experience, confirms that his police verification has been completed, and enters his residential address. 

She uploads two document scans: Rajesh's photograph and his driving licence. She does not upload an identity card document or address proof today — those will be collected later. When she clicks Save, the system automatically generates a personnel code for Rajesh: PER-20260721-004 (the fourth person registered on July 21, 2026). The activity log records "Driver/Helper created successfully" with Mrs. Desai's name and the current timestamp.

Rajesh now appears in the staff list. Mrs. Desai can immediately assign him to a vehicle in the Driver-Route-Vehicle Assignment screen, and Rajesh can be issued a printed ID card. Two days later, when Rajesh's police verification certificate arrives, Mrs. Desai will edit his record and upload the scanned copy.

The second driver and the helper are registered similarly. By the end of the day, all three new staff members are in the system, ready for the new academic term.

---

## Related Screens

- **Dashboard** — The main operational screen that ideally should show warnings for staff members who have not completed police verification or whose driving licences are expiring soon. Currently, the dashboard does not display these warnings — the Transport Manager must manually check each record.

- **Driver-Route-Vehicle Assignment** — The screen where the Transport Manager decides which driver and helper will handle which route each day. Only staff members registered here appear in the assignment dropdowns.

- **Driver Attendance** — A separate screen where driver and helper attendance is tracked, either through mobile device scans or manual entry by the Transport Manager. Each attendance record is linked to a specific staff member registered here.

---

## Requirements

- Controller: `DriverHelperController` with full resource methods plus `trashed()`, `restore()`, `forceDelete()`, `toggleStatus()`, `printIdCard()`
- Hub tab data: `TransportMasterController@index()` loads `DriverHelper::with(['vehicle','user'])->paginate(10)`
- Route: `Route::resource('driver-helper', DriverHelperController::class)` + trash/restore/forceDelete/toggleStatus routes
- Permission gates: `tenant.driver-helper.viewAny`, `tenant.driver-helper.view`, `tenant.driver-helper.create`, `tenant.driver-helper.update`, `tenant.driver-helper.delete`, `tenant.driver-helper.restore`, `tenant.driver-helper.forceDelete`
- Form request: `DriverHelperRequest` — validates all fields, enforces role-based licence requirements, vehicle role conflict, inactive-no-vehicle, user single-assignment
- Policy: `DriverHelperPolicy` (tenant.driver-helper.*)
- Activity logging: ✅ `store` (Stored), `update` (Updated with field-level changes), `destroy` (Trashed), `restore` (Restored), `forceDelete` (Deleted). ❌ `toggleStatus` — missing activityLog call

---

## Who Can Access

- **Transport Manager** — Has full access to all staff records. They can create new driver and helper profiles, edit existing records, upload and replace documents, soft-delete old records, restore accidentally deleted ones, permanently remove test entries, toggle active status, and print ID cards. This is the primary user who manages the transport staff.

- **Fleet Supervisor** — Can view all staff details and update operational fields like phone number, address, and assigned vehicle. They can also print ID cards. However, they cannot delete or permanently remove any staff records or change critical fields like driving licence numbers.

- **School Administrator** — Has read-only access to the staff list. They can view who is employed as a driver or helper and check licence expiry and police verification status, but cannot make any changes.

- **Driver / Helper** — Does not have access to this screen. Staff members see their own information only through the mobile app, where they can view their assigned routes and vehicles.

Behind the scenes, each action is protected by a permission check. If a user tries to perform an action they are not authorised for — for example, a Fleet Supervisor trying to delete a driver — the system displays an "Access Denied" message.

---

## Logic Flow

When the Transport Manager clicks the Staff tab on Transport Master, the system loads the personnel list from the database — 10 records at a time — showing each staff member's name, role, personnel code, assigned vehicle, and linked user account. The list can be filtered using the search box at the top.

When the manager clicks "Add Staff," the system prepares a blank form and fills two important dropdown lists: the list of active vehicles (so the manager can assign the new hire to a specific bus), and the list of employees who belong to the Transport department (so the manager can optionally link the staff member to a system login account for the mobile attendance app).

The manager fills in the staff member's details: name, contact number, role, ID card technology type, driving licence information (if the role is Driver or Both), months of experience, police verification status, residential address, and optionally links them to a vehicle and a user account. They can also upload up to five types of scanned documents: a photograph, an identity card, the driving licence, a police verification certificate, and an address proof.

When the manager clicks Save, the system first generates a unique personnel code. It does this by looking at how many people were registered today so far, adding one to that count, and formatting it as PER-YYYYMMDD-NNN — for example, PER-20260721-004 for the fourth person registered on July 21, 2026. To prevent two Transport Managers from accidentally getting the same code if they register staff at the exact same moment, the system temporarily locks this counting process so only one code is generated at a time.

After generating the code, the system checks all the entered data for correctness: the name must be provided, the role must be Driver/Helper/Both, the ID card type must be one of the four supported technologies (QR, RFID, NFC, Barcode), the licence number (if required) must be unique and not already used by another driver, the licence expiry date must be in the future, and if a vehicle is assigned, the manager cannot assign a vehicle to an inactive staff member, and only one driver and one helper can be assigned to the same vehicle. If anything is wrong, the form highlights the problem fields and refuses to save.

If everything is correct, the system creates the personnel record, stores any uploaded documents, records the action in the activity log, and returns the manager to the staff list where the new member now appears.

When the manager edits an existing record, the form loads with all current values pre-filled. If the manager replaces a document (for example, uploading a renewed licence scan), the system removes the old file before storing the new one. It also notes which fields changed in the activity log — for example, "Licence valid upto changed from 2025-12-31 to 2030-12-31."

When the manager clicks Delete, the system does not erase the record. Instead, it marks the staff member as inactive and hides them from the main list. The record stays in the Trash folder with all its data intact. To see trashed records, the manager switches to the Trash view, where they can either Restore a record (which brings it back but keeps it inactive) or permanently delete it (which also removes all uploaded documents).

When the manager clicks the status toggle next to a staff member in the list, the system flips the active status from Yes to No (or No to Yes) and updates the list immediately without reloading the page. However, unlike most other actions in this screen, the status toggle does not record anything in the activity log — so there is no audit trail of who deactivated a staff member or when.

For printing an ID card, the manager clicks the Print ID Card button. The system looks up the school's configured ID card template for transport staff, fills it with the staff member's data (name, photo, personnel code, role, assigned vehicle), and opens a print-friendly page in the browser.

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Full Name | Must be provided, maximum 80 characters | "Please enter the staff member's name." |
| Role | Must be Driver, Helper, or Both | "Please select a valid role." |
| ID Card Type | Must be QR, RFID, NFC, or Barcode | "Please select an ID card technology type." |
| Driving Licence Number | Required if the role includes driving; must be unique across all staff records | "This licence number is already registered to another staff member." |
| Licence Expiry Date | Required if the role includes driving; must be a future date | "The licence expiry date must be a date after today." |
| Phone Number | Optional — maximum 20 characters | — |
| Assigned Vehicle | Optional — if provided, must be an existing active vehicle | "The selected vehicle does not exist." |
| Linked User Account | Optional — if provided, must be an existing system user | "The selected user account is invalid." |
| Active Status | Must be Yes or No | "The active status must be yes or no." |
| **Vehicle Conflict Check** | An inactive staff member cannot keep an assigned vehicle | "Inactive personnel cannot be assigned to a vehicle." |
| **Role Conflict Check** | A vehicle can have at most one active Driver and one active Helper | "This vehicle already has an active Driver assigned." |
| **User Conflict Check** | A system user account can be linked to only one vehicle at a time | "This user is already assigned to another vehicle." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| An inactive staff member is assigned to a vehicle | "Inactive personnel cannot be assigned to a vehicle." — the form blocks submission | Business rule violation — prevented before saving |
| Two drivers assigned to the same vehicle | "This vehicle already has an active Driver assigned." — the form blocks submission | Business rule violation — prevented before saving |
| A user account linked to two different vehicles | "This user is already assigned to another vehicle." — the form blocks submission | Business rule violation — prevented before saving |
| Duplicate driving licence number | "This licence number is already registered to another staff member." — the form blocks submission | Data entry error — prevented before saving |
| Licence expiry date is in the past | "The licence expiry date must be a date after today." — the form blocks submission | Data entry error — prevented before saving |
| User tries to access the Staff screen without permission | The system shows a blank "Access Denied" page | Permission error — system blocks the action |
| Status toggle performed without audit trail | The staff member's active status changes, but the activity log does not record who made the change or when | 🔴 Gap — missing audit entry for toggle |
| Expired licence not checked at trip assignment time | A driver whose licence expired 6 months ago can still be assigned to drive a morning route because the system only checks the licence date at registration time, not before each trip | 🔴 Gap — compliance risk |
| Personal ID numbers stored in readable form | Government ID numbers like Aadhaar and PAN are stored in the database as regular text without any encryption. Anyone with database access can read complete ID numbers | 🔴 Gap — data privacy risk |
| Unverified staff not flagged anywhere | Staff members who have not completed police verification do not show any warning badge on the dashboard or in the staff list. The Transport Manager must check each record manually | 🔴 Gap — missing safety alert |

---

## Success Scenarios — When Everything Works

**SC-001 — Registering a New Driver with Full Documentation**
The Transport Manager registers a new driver named Rajesh. He fills in all the required fields: name, role, driving licence number (which is unique and not used by anyone else), licence expiry date (set to 5 years in the future), police verification status (completed), and uploads two scanned documents — a passport-size photograph and a copy of the driving licence. The system generates a unique personnel code PER-20260721-005, saves the record, stores both document scans, and logs the creation. Rajesh now appears in the staff list with all his details visible, and his police verification shows as complete.

**SC-002 — Renewing a Driver's Expired Licence**
A driver named Suresh has renewed his driving licence at the RTO. The Transport Manager opens Suresh's record, enters the new licence expiry date (5 years from now), and uploads the scanned copy of the renewed licence. The system removes the old scanned copy from storage, saves the new one, and records in the activity log: "Licence valid upto changed from 2025-06-30 to 2030-06-30." Suresh's record now shows the updated expiry date, and the Dashboard will generate alerts closer to the new expiry date.

**SC-003 — Printing an ID Card for a New Hire**
The Transport Manager has just registered a new helper named Priya. Before Priya can start work, she needs an official school ID card. The manager opens Priya's record and clicks "Print ID Card." The system pulls up the school's configured template for transport staff ID cards, fills it with Priya's name, photograph, personnel code, role (Helper), and assigned vehicle, and opens a print-friendly page in the browser. The manager clicks Print, and the card is ready to be laminated and issued.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Driver with Expired Licence Assigned to a Route**
A driver named Vinod was registered two years ago with a valid licence. His licence expired three months ago, but nobody updated it in the system. Because the system only checks that the licence is valid at the time of registration (and does not re-check it before each trip assignment), Vinod can still be selected as the driver for a morning route carrying 40 school children. The only way this gets caught is if the Transport Manager manually checks Vinod's licence date before assigning him — a safety gap that relies entirely on human diligence.

**FC-002 — Aadhaar Numbers and Licence Numbers Stored Without Encryption**
The system stores government ID numbers — including Aadhaar numbers, PAN card numbers, and driving licence numbers — as plain readable text in the database. If the database were ever compromised, this sensitive personal information would be exposed. Additionally, when a Transport Manager opens a staff record, the full Aadhaar number is displayed on screen without any masking (like showing only the last 4 digits). This does not comply with India's data protection requirements for sensitive personal data.

**FC-003 — Unverified Helper Assigned to a Route Without Warning**
A new helper named Arun was hired two weeks ago, but his police verification certificate has not yet arrived from the authorities. The Transport Manager assigned him to a route anyway because the system did not show any warning or alert about the missing verification. The staff list shows `police_verification_done = No`, but there is no red badge, no dashboard counter, and no filter to highlight this. The manager would need to check every staff record individually to find who is still unverified.

**FC-004 — Staff Member Deactivated Without Audit Trail**
The Transport Manager toggles a driver's status from Active to Inactive using the toggle switch. The status changes correctly — the driver disappears from assignment dropdowns. However, unlike every other action in this screen (creating, editing, deleting, restoring), the toggle does not record anything in the activity log. If the manager is later asked "Who deactivated this driver and when?" there is no record to answer the question.

---

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `tpt_vehicle` | FK Table | `assigned_vehicle_id` → `id` ON DELETE SET NULL |
| `sys_users` | FK Table | `user_id` → `id` ON DELETE SET NULL |
| `Employee` (SchoolSetup) | Module | User filtering by transport department |
| `TemplateEngine` (Template) | Module | ID card rendering |
| `TemplatePurpose` (Template) | Module | ID card template lookup |
| `tpt_driver_route_vehicle_jnt` | Child Table | Driver/helper assignments |
| `tpt_trip` | Child Table | Trips as driver/helper |
| `tpt_driver_attendance` | Child Table | Attendance records |
| `tpt_trip_incidents` | Child Table | Incidents linked via trips |

**Table:** `tpt_personnel`

| Column | Type | Details |
|--------|------|---------|
| id | INT UNSIGNED PK | Auto-increment |
| user_id | INT UNSIGNED NULL FK | → `sys_users.id` SET NULL |
| user_qr_code | VARCHAR(30) NOT NULL | Auto-generated personnel code |
| id_card_type | ENUM('QR','RFID','NFC','Barcode') | Card technology |
| name | VARCHAR(100) NOT NULL | Full name |
| phone | VARCHAR(30) NULL | Contact number |
| id_type | VARCHAR(20) NULL | ID document type |
| id_no | VARCHAR(100) NULL | ID number (Aadhaar/PAN/etc.) |
| role | VARCHAR(20) NOT NULL | Driver / Helper / Transport Manager |
| license_no | VARCHAR(50) NULL UNIQUE | Driving licence number |
| license_valid_upto | DATE NULL | Licence expiry |
| assigned_vehicle_id | INT UNSIGNED NULL FK | → `tpt_vehicle.id` SET NULL |
| driving_exp_months | SMALLINT UNSIGNED NULL | Experience in months |
| police_verification_done | TINYINT(1) DEFAULT 0 | Police background check |
| address | VARCHAR(512) NULL | Address |
| id_card_upload | TINYINT(1) DEFAULT 0 | ID card upload flag |
| photo_upload | TINYINT(1) DEFAULT 0 | Photo upload flag |
| driving_license_upload | TINYINT(1) DEFAULT 0 | Licence upload flag |
| police_verification_upload | TINYINT(1) DEFAULT 0 | Police verification upload flag |
| address_proof_upload | TINYINT(1) DEFAULT 0 | Address proof upload flag |
| is_active | TINYINT(1) DEFAULT 1 | Activity flag |
| created_at | TIMESTAMP | — |
| updated_at | TIMESTAMP | — |
| deleted_at | TIMESTAMP NULL | Soft deletes |
