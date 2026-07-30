# Student Boarding & Unboarding — Business Requirements

## What This Screen Does

The Student Board/Unboard screen records which students boarded which bus at which stop, and later unboarded at which stop, for each trip. It creates a complete attendance trail for every student who uses the school transport system — showing exactly when and where each child got on and off the bus.

This screen serves two purposes. First, it provides accountability: if a parent claims their child did not board the bus at the usual stop, the Transport Manager can check the boarding log to see whether and when the child was scanned. Second, it enables safety monitoring: the system can verify that every student who boarded in the morning also unboarded at their designated drop stop in the afternoon. A child left on the bus at the end of a route would be detected because their unboarding record would be missing.

The screen appears as one tab within the Trip Management hub, loaded by the `TripMgmtController`.

---

## Default Data Load

When the user opens Trip Management and clicks the Student Bord Unbord tab, the system shows filter controls to select a trip (by date, route, and shift) or a specific date range. After selection, the system loads all boarding log records for the selected trip, showing each student's name, boarding stop, boarding time, unboarding stop, unboarding time, and the device used for scanning.

If no boarding logs exist yet for the selected trip, a "Generate Boarding Log" button is displayed.

---

## When This Screen Is Used

- **Generating Boarding Logs Before a Trip** — Before the morning shift begins, the Transport Manager generates the boarding log for each trip. The system looks up all students who are allocated to that route and creates a boarding log record for each one. The records start with empty boarding and unboarding times — they will be filled in when the driver scans each student's QR code or RFID card at the stop.

- **Recording Boarding During a Trip** — When the bus reaches a stop, the driver uses the mobile app to scan each boarding student's ID card (QR code or RFID). The system looks up the student in the boarding log for that trip and records the boarding time, the current stop as the boarding stop, and the device used for scanning.

- **Recording Unboarding During the Afternoon Drop** — In the afternoon, when the bus reaches each drop stop, the driver scans each student's card as they get off. The system records the unboarding time and the current stop as the unboarding stop in the same log record that was created for the morning boarding.

- **Investigating a Missing Student** — A parent calls the school office saying their child did not come home on the bus. The Transport Manager opens the boarding log for the child's route, checks whether the child boarded in the morning (boarding time exists) and whether the child unboarded at the usual stop in the afternoon (unboarding time exists). If the child boarded but did not unboard, it triggers an alert that the child may still be on the bus.

---

## Key Fields at a Glance

**Student Identity**
Each boarding log record is linked to a specific student and their academic session record. The student's name, class, and section are displayed alongside the boarding data for easy identification.

**Boarding Information**
Four fields capture the boarding event:
- Boarding Route: The route the student used to get to school
- Boarding Trip: The specific trip the student boarded
- Boarding Stop: The stop where the student got on the bus
- Boarding Time: The date and time when the student's card was scanned

**Unboarding Information**
Four parallel fields capture the unboarding event in the same record:
- Unboarding Route: The route the student used to return home
- Unboarding Trip: The specific trip the student unboarded from
- Unboarding Stop: The stop where the student got off the bus
- Unboarding Time: The date and time when the student's card was scanned for unboarding

This design means a single record tracks the student's complete journey for a given day — from home to school (boarding) and school to home (unboarding) — in one place.

**Device Tracking**
The device used for scanning (a registered tablet or phone from the Device Setup screen) can optionally be recorded. This helps identify which device captured each boarding or unboarding event, useful for troubleshooting if a particular device has scanning issues.

---

## Business Rules and Conditions

**Boarding Logs Are Generated from Student Allocations**
The "Generate Boarding Log" function does not guess which students should be on a trip. It looks up the Student Route Allocation table (`tpt_student_route_allocation_jnt`) to find all students who are actively allocated to the selected route. Only those students get boarding log records. If a student is not allocated to the route, they will not appear in the log.

**Duplicate Records Are Prevented**
If boarding logs have already been generated for a trip, the Generate function skips existing records. It only creates records for students who do not yet have a log entry for that trip. This prevents duplicate entries when the Generate button is clicked multiple times.

**Same Record Tracks Both Boarding and Unboarding**
Unlike a separate check-in and check-out system, the boarding log uses a single record per student per day to track both events. When the student boards in the morning, the boarding fields are populated. When the same student unboards in the afternoon, the unboarding fields in the same record are populated. This makes it easy to see the complete journey at a glance.

**Students Can Board and Unboard at Different Stops**
The system supports different stops for boarding and unboarding. A student might board at "Indiranagar Main Road" in the morning but unboard at "School Main Gate" in the afternoon (for students who go to a different location after school). The boarding and unboarding stop fields are independent.

**Device Tracking Is Optional**
Recording which device performed the scan is optional. If the driver is using a personal phone that is not registered in the Device Setup, the device field can be left blank and the record will still save correctly.

---

## Workflow Steps

**Generating the Boarding Log for a Morning Trip**
It is 6:30 AM. Mrs. Desai opens the Student Bord Unbord tab and selects the MG Road Morning Pickup trip for today. The table is empty. She clicks "Generate Boarding Log." The system looks up all student allocations for the MG Road route — 42 students are found. It creates 42 boarding log records, one for each student, with the trip date and route information pre-filled. The boarding time and stop fields are empty, waiting for the driver to scan each student.

**Scanning Students at a Stop During the Trip**
Driver Venkatesh arrives at Indiranagar Main Road. He opens the attendance scanning feature on his tablet. Students line up and tap their RFID cards against the reader. Each scan records the student's boarding stop as "Indiranagar Main Road" and the boarding time as the current time. If a student's name does not appear in the list (they are not allocated to this route), the system shows an alert. After all 7 students at this stop have boarded, Venkatesh drives to the next stop.

**Recording Unboarding in the Afternoon**
In the afternoon, Venkatesh drives the return route. At each stop, students tap their cards as they get off the bus. The system looks up the existing boarding log record for each student and updates the unboarding fields: unboarding stop, unboarding time. If a student exits at a different stop than their designated drop stop, the system still records the unboarding — it does not block the scan, but the Transport Manager can review the discrepancy later.

**Investigating a Child Who Did Not Unboard**
At the end of the afternoon route, the system checks whether all students who boarded in the morning have an unboarding record. Student Aarav Sharma boarded at 7:15 AM on the MG Road route but has no unboarding record. An alert appears on the dashboard. Mrs. Desai calls the driver and asks him to check the bus. Aarav had fallen asleep and was still on the bus. The driver wakes him and helps him off at the next stop.

---

## Example Scenario

Green Valley School's MG Road Morning Pickup route has 42 students who board at 6 different stops. Driver Venkatesh uses a tablet registered in the Device Setup to scan students.

At 6:45 AM, Mrs. Desai generates the boarding log for this trip. The system creates 42 records — one for each allocated student. At 6:50 AM, Venkatesh reaches the first stop (Indiranagar Main Road). Seven students board, each tapping their RFID card. The system records:
- Student Priya Sharma: Boarded at Indiranagar Main Road, 6:52 AM, device: Tablet-001
- Student Rahul Verma: Boarded at Indiranagar Main Road, 6:53 AM, device: Tablet-001

At the second stop (MG Road Signal), 12 more students board. One student, Arjun, does not have a card today — he forgot it at home. Venkatesh manually selects Arjun's name from a list and marks him as boarded. The system records the boarding without a device scan.

By 7:30 AM, all 42 students are on the bus and the trip arrives at school.

In the afternoon, the return trip begins. At each stop, students tap their cards to unboard. By 4:00 PM, 41 students have unboarded. Student Aarav has no unboarding record. The system flags this. Venkatesh checks the bus and finds Aarav asleep in the back seat. He wakes him and marks him as unboarded at the school stop.

The day's boarding data is complete — all 42 students have a full boarding and unboarding record.

---

## Related Screens

- **Daily Trip** — The trip record that boarding logs are linked to.
- **Device Setup** — The tablets and phones used for scanning students are registered here.
- **Stopage Status Update** — The timeline where stop events are recorded, which links to boarding events at each stop.

---

## Requirements

- Controller: `StudentBoardingController` with methods: `studentBordingStore()` (generate logs), `studentBordingEdit()` (get single record), `studentBordUnbordUpdate()` (update record)
- Hub query: `TripMgmtController@tripBordUnbord()` (loads data with student details)
- Model: `StudentBoardingLog` (table: `tpt_student_boarding_log`) — SoftDeletes
- Source data: `TptStudentAllocationJnt` (student route allocations) for generating logs
- Permissions: `tenant.student.bording.viewAny`, `tenant.student.bording.create`, `tenant.student.bording.update`
- Activity logging: ✅ Present on create and update

---

## Who Can Access

- **Transport Manager** — Full access. Can generate boarding logs, edit records, and investigate discrepancies.

- **Driver** — Can scan students for boarding and unboarding using the mobile app. Limited to their assigned trips for the current date.

- **Fleet Supervisor** — Read-only access to view boarding records for operational monitoring.

- **School Administrator** — Read-only access to view boarding and unboarding data for safety reporting.

Behind the scenes, each action is protected by a permission check.

---

## Logic Flow

When the user opens the Student Bord Unbord tab and selects a trip, the system queries the StudentBoardingLog table for all records linked to that trip, eager-loading the student details (name, class, section) and stop information. Each record shows whether boarding and unboarding have been recorded.

If no records exist, the "Generate Boarding Log" button is displayed. When clicked, the system queries the Student Route Allocation table to find all students allocated to the selected route for the current academic session. For each student found, it checks whether a boarding log record already exists for this trip and student combination. If a record exists, the student is skipped. If not, a new record is created with the trip date, route, and student information pre-filled. All records are created in a single operation.

The system then tracks two separate update paths:
- Boarding update: When a student's card is scanned at a stop, the system finds the student's boarding log record for the current trip and updates the boarding_stop_id, boarding_time, and optionally device_id.
- Unboarding update: When a student's card is scanned during the return trip, the system finds the same record and updates the unboarding_stop_id and unboarding_time.

For editing, the user can manually adjust any boarding or unboarding field — for example, to correct a time or change a stop — and the change is logged in the activity log.

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Student | Must exist in the system | "Student not found." |
| Boarding Stop | Must be a valid stop on the route | "Please select a valid boarding stop." |
| Boarding Time | Must be a valid datetime | "Please enter a valid boarding time." |
| Unboarding Stop | Must be a valid stop | "Please select a valid unboarding stop." |
| Unboarding Time | Must be a valid datetime | "Please enter a valid unboarding time." |
| Device | Optional — if provided, must be a registered device | "The selected device is not registered." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Student not allocated to this route | "Student is not allocated to this route." — cannot generate log | Business rule |
| Duplicate boarding scan | The student's boarding time is already recorded — the system may overwrite or skip | Data integrity gap |
| Student forgot ID card | Driver can manually select student from a list and mark boarded | Fallback procedure |
| Device not registered | Scanner shows "Device not recognised" — boarding still recorded but without device link | Operational issue |
| Student scans at wrong stop | The system records the boarding at whichever stop the driver is currently at — no validation that this is the student's designated stop | 🔴 Gap — no stop matching |
| Unboarding forgotten | No automatic alert — relies on manual review | 🔴 Gap — missing safety check |

---

## Success Scenarios — When Everything Works

**SC-001 — Full Day of Boarding and Unboarding Recorded**
All 42 students on the MG Road route are scanned during the morning boarding and again during the afternoon unboarding. Each student has a complete record: boarding stop, boarding time, unboarding stop, unboarding time, and scanning device. The Transport Manager reviews the log at the end of the day and confirms that every student who boarded also unboarded. No alerts are triggered.

**SC-002 — Missing Student Detected Through Log Review**
At the end of the afternoon route, the system detects that student Aarav boarded at 7:15 AM but has no unboarding record. An alert appears on the dashboard. The driver is contacted and finds Aarav asleep on the bus. The child is safely returned home. The incident is recorded in the activity log.

**SC-003 — Manual Boarding for Student Without ID Card**
Student Arjun forgot his RFID card. The driver selects Arjun's name from a manual list on the tablet and marks him as boarded. The system records the boarding without a device scan. Arjun's boarding is captured successfully, and his unboarding is recorded normally in the afternoon.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Student Scans at the Wrong Stop**
Student Riya usually boards at Indiranagar Main Road, but today she was at a friend's house near Church Street and boarded there instead. When she taps her card at Church Street, the system records her boarding stop as Church Street — even though her allocated stop is Indiranagar Main Road. There is no validation to check whether the student is boarding at their designated stop. The Transport Manager only discovers the mismatch if they manually compare the boarding log against the student's allocation.

**FC-002 — Driver Forgets to Record Unboarding for a Stop**
At the end of a long afternoon route, driver Venkatesh is tired and forgets to scan students at the last stop. He simply lets everyone off and closes the trip. None of the students at that stop have unboarding records. The system does not alert Venkatesh at the time — it only shows the missing records when someone reviews the log later. Parents who track their child's bus status see "Child boarded but not yet unboarded" even though the child is at home.

**FC-003 — Boarding Log Generated for Wrong Date**
Mrs. Desai accidentally selects tomorrow's date instead of today's when generating the boarding log. The records are created with tomorrow's date. When today's trip runs, the driver scans students but cannot find their records because they are dated tomorrow. The driver must manually mark each student, and Mrs. Desai must delete and regenerate the logs with the correct date.

**FC-004 — Student Boarding Record Overwritten by Mistake**
A student scans their card twice at the same stop — once when they board and accidentally again while still on the bus. The second scan overwrites the boarding time with the later time. The record now shows a later boarding time than the actual time the student boarded. There is no check to prevent a second boarding scan for the same trip.