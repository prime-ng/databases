# Notification Log — Business Requirements

## What This Screen Does

The Notification Log screen is a read-only window into every notification that the system sends during a trip's lifecycle. When a trip starts, when the bus approaches a stop, when it arrives, when it is delayed, or when a trip is cancelled — each of these events triggers a notification, and this screen records what was sent, to whom, through which channel, and whether it was delivered successfully.

Without this screen, notifications would happen invisibly. Parents would receive messages on their phones, the school app would show alerts, but no one at the school would have a way to check whether a particular parent was notified about a trip delay, or whether the SMS for a trip cancellation actually went through. If a parent complained that they never received a notification that the bus was delayed, the school would have no proof that a notification was sent. The Notification Log turns invisible digital messages into a visible, auditable record.

This screen is purely for viewing and auditing. No one can create, edit, or delete notification records. They simply appear in the log as the system sends them. The Transport Manager can open the log at any time to see what notifications have gone out, filter by type or date, and confirm that parents and staff are being kept informed.

---

## Default Data Load

When an authorised person opens the Notification Log tab, the system loads the most recent notifications — 10 per page — showing the trip route, the student name, the boarding stop, the type of notification (with a clear label: TripStart, ApproachingStop, ReachedStop, Delayed, or Cancelled), the time it was sent, and four coloured status indicators — one each for App notification, SMS, Email, and WhatsApp. Each indicator shows NotRegistered (grey), Sent (green), or Failed (red).

A filter dropdown at the top allows the user to choose a specific notification type: All (shows everything), TripStart, ApproachingStop, ReachedStop, Delayed, or Cancelled. A date range filter narrows the results by sent time. A search box allows searching by student name, trip route, or stop name.

---

## When This Screen Is Used

- **Checking Whether a Delay Notification Was Sent** — Bus KL-05 is 10 minutes late reaching the "HAL Road" stop because of traffic. The system determines that the bus is more than 5 minutes late and sends a "Delayed" notification through all available channels. A parent calls Mrs. Desai to say they did not receive the alert. Mrs. Desai opens the Notification Log, filters by "Delayed," finds the entry for the student at the HAL Road stop, and sees that the SMS status shows "Failed" — the SMS gateway had a temporary issue. She can see that the App notification was "Sent" and advises the parent to check the school app instead.

- **Auditing Notifications for a Specific Trip** — The School Administrator wants to verify that all parents on Bus KL-07's route received a "TripStart" notification this morning. They open the Notification Log, search by trip route "KL-07," and filter by type "TripStart." The list shows every student on that trip, when the notification was sent, and whether each channel (App, SMS, Email, WhatsApp) delivered successfully. Any failures are immediately visible.

- **Investigating a Parent Complaint** — A parent claims they never received any notification that the school bus was cancelled on a particular day. Mrs. Desai opens the Notification Log, filters by the student's name, and finds the "Cancelled" notification entry. The record shows that the App notification was "Sent," but the SMS status is "Failed" because the parent's phone number may have changed. The record proves that the school did attempt to notify the parent through the app. The parent is reminded to keep their contact details updated in the school system.

- **Monitoring Notification Channel Health** — The Fleet Supervisor notices that several SMS notifications have been showing "Failed" status over the past week. They open the Notification Log and filter by the past 7 days with SMS status "Failed." The list shows 23 failed SMS deliveries. They report this to the IT department, who discover that the SMS gateway provider's API key has expired. Without the Notification Log, no one would know that SMS notifications have been silently failing for a week.

---

## Key Fields at a Glance

**Trip and Student Information**
Every notification is linked to a specific trip, student, and boarding stop. The log shows which trip triggered the notification, which student (or their parent) was the intended recipient, and which boarding stop the notification is about. For example, a "ReachedStop" notification is about a specific student's stop, not the entire trip.

**Notification Type**
Five types of notifications are tracked:
- **TripStart** — Sent when the bus begins its trip. Parents are notified that the bus has left the depot and is on its way.
- **ApproachingStop** — Sent when the bus leaves the previous stop and is heading towards the next one. Parents know the bus is coming soon.
- **ReachedStop** — Sent when the bus arrives at the stop. Parents know the bus is there and their child should board.
- **Delayed** — Sent instead of "ReachedStop" when the bus arrives at a stop more than 5 minutes late. Parents know the bus is delayed, not just arriving.
- **Cancelled** — Sent when the trip is cancelled entirely. Parents know their child will not be picked up or dropped off by the school bus.

**Sent Time**
The exact date and time the notification was dispatched from the system. This is the moment the system attempted to send, not necessarily when the recipient received it (which depends on the delivery channel).

**Delivery Channel Statuses**
Four independent delivery channels are tracked for each notification:
- **App Notification** — A push notification sent to the parent's school app. Status: NotRegistered (the parent does not use the app), Sent, or Failed.
- **SMS** — A text message sent to the parent's registered mobile number. Status: NotRegistered (no mobile number on file), Sent, or Failed.
- **Email** — An email sent to the parent's registered email address. Status: NotRegistered (no email on file), Sent, or Failed.
- **WhatsApp** — A WhatsApp message sent to the parent's registered number. Status: NotRegistered (no WhatsApp number or not opted in), Sent, or Failed.

Each channel is tracked independently. A notification can be Sent via App and WhatsApp but Failed via SMS — the log shows all four statuses side by side.

---

## Business Rules and Conditions

**No Create, Edit, or Delete**
The Notification Log is strictly read-only. Records are created automatically by the system when notifications are sent. No user can add, modify, or remove entries. If a notification was not sent, there will simply be no record in the log. There is no way to manually create a notification record to cover up a missed notification.

**Delayed Replaces ReachedStop When the Bus Is Late**
When the bus reaches a stop more than 5 minutes behind schedule, the system sends a "Delayed" notification instead of a "ReachedStop" notification. This is automatic based on the difference between the scheduled arrival time and the actual arrival time. If the bus is 6 minutes late, parents receive "Delayed" — not "ReachedStop." This distinction is important: parents need to know whether the bus is on time or running late, because the two situations require different actions.

**Notifications Are Triggered by Trip Lifecycle Events**
Notifications are not sent randomly. They are triggered by specific events in the trip lifecycle:
1. Start Trip → Sends "TripStart" notification to all parents of students on that trip.
2. Reach Stop → Sends "ReachedStop" notification (or "Delayed" if more than 5 minutes late) to the parents of students boarding at that stop.
3. Leave Stop (depart for next stop) → Sends "ApproachingStop" notification to the parents of students at the next stop.
4. Trip Cancelled → Sends "Cancelled" notification to all parents of students on that trip.

Each notification record captures the exact trigger point and the students affected.

**Each Channel Is Independent**
The four delivery channels operate independently. A notification may succeed on WhatsApp but fail on SMS. The log records the actual outcome for each channel. The system does not retry failed channels automatically — if the SMS gateway fails, the failure is recorded and it is up to the Transport Manager or IT department to investigate and resolve the root cause.

**NotRegistered Indicates Missing Contact Information**
If a channel shows "NotRegistered," it means the parent does not have contact information configured for that channel — no phone number for SMS, no email address for Email, no WhatsApp number, or the school app is not installed or not linked. This is not a delivery failure; it means the system did not attempt to send through that channel because the recipient was not reachable through it.

---

## Workflow Steps

**TripStart Notifications — Morning Departure**
It is 6:30 AM. Bus KL-05 begins its morning route. The driver taps "Start Trip" on the system. Instantly, the system identifies all students assigned to this trip and their parents' contact details. For each student, it sends a TripStart notification through all four channels: App, SMS, Email, and WhatsApp. Within seconds, the Notification Log shows entries for all 25 students on Bus KL-05, each with the sent time and the delivery status for each channel. Mrs. Desai can see that 23 of 25 parents received the notification everywhere, 1 parent's SMS failed (wrong number), and 1 parent has no WhatsApp registered.

**Delayed Notification — Bus Running Late**
Bus KL-07 is stuck in traffic and arrives at the "Madiwala" stop 8 minutes late. The system detects that the actual arrival time is more than 5 minutes after the scheduled time. Instead of a "ReachedStop" notification, it sends a "Delayed" notification to the parents of students who board at Madiwala. The Notification Log shows "Delayed" instead of "ReachedStop" for these entries. Parents see: "Bus KL-07 is delayed by 8 minutes at Madiwala stop."

**ApproachingStop Notification — On the Way**
After picking up students at Madiwala, Bus KL-05 departs for the next stop, "HAL Road." As the bus leaves Madiwala, the system sends "ApproachingStop" notifications to the parents of students waiting at HAL Road. The log records each notification with type "ApproachingStop." Parents at HAL Road know the bus is coming and can time their arrival at the stop.

**Cancelled Notification — Trip Called Off**
A sudden heavy rainstorm forces the school to declare a holiday. Mrs. Desai cancels all afternoon drop-off trips. The system sends "Cancelled" notifications to all parents of students on the cancelled trips. The Notification Log shows hundreds of entries — one per student — all with type "Cancelled" and the current timestamp. Parents who check the app or receive the SMS know that the bus will not come.

---

## Example Scenario

Green Valley School uses notifications to keep parents informed about their children's bus trips. Every morning and afternoon, the system sends hundreds of notifications across four channels.

One Tuesday morning, Bus KL-05 starts its route at 6:30 AM. Mrs. Desai opens the Notification Log at 7:00 AM to check that all morning notifications went through. She sets the filter to "Today" and sees:

- **TripStart** — 25 notifications sent at 6:30 AM. App: 25 Sent, SMS: 24 Sent + 1 Failed, Email: 22 Sent + 3 NotRegistered, WhatsApp: 20 Sent + 5 NotRegistered.
- **ApproachingStop** — 6 notifications sent as the bus moved between stops.
- **ReachedStop** — 5 notifications sent. One stop shows "Delayed" because the bus arrived 7 minutes late due to traffic.

She notices the SMS failure. The parent's mobile number is incorrect in the system. She makes a note to follow up with the parent to update their contact details. The parent calls later saying they did not get an SMS that the bus was approaching — Mrs. Desai explains that the App notification was sent successfully and suggests enabling app notifications.

The log provides proof for every notification. If any parent claims they were not informed, Mrs. Desai can open the log, search for that parent's child, and see exactly what was sent, when, and through which channels.

---

## Related Screens

- **Trip Management** — Notifications are triggered by trip lifecycle events (Start Trip, Reach Stop, Leave Stop, Cancel Trip).
- **Stoppage Status** — The source of arrival time data. If the driver marks a stop as reached at a certain time, the system compares it to the scheduled time to determine whether to send "ReachedStop" or "Delayed."
- **Student/Parent Records** — Contact information (phone, email, WhatsApp, app registration) determines which channels are available for each recipient.
- **Communication Settings** — The school may configure which channels are active or the delay threshold (currently 5 minutes) for triggering "Delayed" notifications.

---

## Requirements

- Table: `tpt_notification_log`
- Columns: `student_session_id`, `trip_id`, `boarding_stop_id`, `notification_type` (TripStart / ApproachingStop / ReachedStop / Delayed / Cancelled), `sent_time`, `app_notification_status`, `sms_notification_status`, `email_notification_status`, `whatsapp_notification_status` (each: NotRegistered / Sent / Failed)
- Read-only: No create, edit, or delete actions available to users
- Notification triggers: Start Trip → TripStart, Reach Stop → ReachedStop (or Delayed if >5 min late), Leave Stop → ApproachingStop (for next stop), Trip Cancelled → Cancelled
- Filter by notification type (All / TripStart / ApproachingStop / ReachedStop / Delayed / Cancelled)
- Date range filter by sent time
- Search by student name, trip route, stop name
- Permissions: `tenant.notification-log.viewAny`

---

## Who Can Access

- **Transport Manager** — Read-only access. Can view all notification records, use filters and search to find specific entries, and use the log for auditing parent communication. This is the primary user who checks whether notifications are being delivered correctly.

- **Fleet Supervisor** — Read-only access. Can view notification records to verify that delayed and cancellation notifications were sent. Cannot export or modify records.

- **School Administrator** — Read-only access. Can view the notification log for auditing purposes, such as confirming that the school properly notified parents about a trip cancellation. This may be important for regulatory compliance or parent complaints.

- **Driver** — Does not have access to this screen. Drivers trigger notifications through their actions (starting a trip, reaching a stop) but do not need to see the log.

Behind the scenes, the permission check is simple: any user with `tenant.notification-log.viewAny` permission can see everything. There is no per-record restriction — either you can view the log or you cannot.

---

## Logic Flow

When an authorised person opens the Notification Log tab, the system loads recent notification records from the database — 10 per page — showing the trip route, student name, boarding stop name, notification type with a coloured label, sent time, and four status badges for the delivery channels. The records are sorted by sent time in descending order, with the most recent notifications at the top.

When a filter is applied (for example, selecting "Delayed" from the type dropdown), the system filters the records to show only those with the matching notification type. The date range filter further narrows results to notifications sent within the specified period. The search box looks for matches in the student name, trip route, or stop name.

When a user clicks on a notification record, a detail panel opens showing the full information: the trip details, student details, boarding stop details, the exact sent time, the notification type, and the delivery status for all four channels with individual timestamps where available.

The system does not allow any modifications to the records. The create, edit, delete, and restore buttons simply do not exist in this screen. Even users with full administrative permissions cannot modify notification logs — the records are system-generated and system-protected.

---

## Validate Before Save

There is no validation for this screen because there is no user data entry. The only "validation" happens in the background when the system creates notification records automatically:

| Field | What the System Checks |
|-------|----------------------|
| Notification Type | Must be one of the five valid types (TripStart, ApproachingStop, ReachedStop, Delayed, Cancelled) |
| Trip | Must exist and be in a state that triggers notifications |
| Student Session | Must be a valid student session linked to the trip |
| Boarding Stop | Must be a valid stop on the trip route |
| Channel Status | Each channel status must be NotRegistered, Sent, or Failed — validated before saving |
| Sent Time | Automatically set to the current server time — cannot be overridden |

---

## Error Handling — What Can Go Wrong

This screen has fewer error scenarios than others because the user does not enter data. The errors that can occur are related to what the user sees — or does not see — in the log.

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| No notifications found for the selected filters | "No notifications match your search criteria." — the list is empty | User expectation — the trip may not have triggered notifications yet |
| A notification shows "Failed" for SMS | The log clearly shows the red "Failed" badge next to the SMS channel | Delivery failure — user must investigate the SMS gateway or contact details |
| A parent claims they received no notification | The log shows "Sent" for all channels — the parent may have missed the notification, or the device may not have displayed it | Discrepancy — the system records show delivery, but the user experience contradicts it |
| The log does not show a notification the user expected to see | If a trip event did not trigger a notification (for example, a driver did not properly mark a stop as reached), there will be no record | Missing trigger — the trip event may not have been captured correctly |
| A notification shows "NotRegistered" for all channels | The student's parent has no contact information configured in the system | Data gap — parent contact details are missing |
| User tries to edit or delete a record | No such buttons exist in the interface. If the user tries to manipulate the URL directly, the system returns "Not Found" or "Method Not Allowed" | Workflow error — read-only screen cannot be modified |

---

## Success Scenarios — When Everything Works

**SC-001 — Morning TripStart Notifications Delivered Successfully**
Mrs. Desai opens the Notification Log at 7:00 AM and sees that all 150 TripStart notifications for the morning trips were sent successfully. App, SMS, Email, and WhatsApp all show "Sent" for every parent. She closes the log knowing that every parent has been informed that the buses are on their way.

**SC-002 — Delayed Notification Replaces ReachedStop for Late Bus**
Bus KL-03 arrives at the "JP Nagar" stop 6 minutes late. The system sends a "Delayed" notification instead of "ReachedStop." Parents at JP Nagar receive the delay alert and know to expect the bus a few minutes later. The Notification Log shows "Delayed" for these entries. No parent calls to ask why the bus has not arrived — the notification has already informed them.

**SC-003 — Failed SMS Channel Identified and Fixed**
Mrs. Desai notices that several SMS notifications have been showing "Failed" status. She investigates and discovers that the SMS provider's account has insufficient balance. She contacts the accounts department to recharge the account. The next day, the SMS statuses return to "Sent." Without the Notification Log, the SMS failures would have gone unnoticed, and parents relying on SMS would not have received any notifications.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Notification Record Shows "Sent" but Parent Did Not Receive**
The Notification Log shows that an SMS was "Sent" successfully, but the parent insists they never received it. The system records only that the SMS gateway accepted the message and returned a success code. It does not know whether the parent's phone actually received and displayed the message. If the parent's phone was switched off, out of network range, or the message was blocked by their carrier, the log would still show "Sent." The school cannot rely solely on the log to prove delivery — they can only prove that an attempt was made and the gateway reported success.

**FC-002 — ApproachingStop Notification Sent Before Bus Is Ready to Leave**
The system sends "ApproachingStop" notifications when the bus departs from the previous stop. But if the driver marks the previous stop as completed too early — for example, while still waiting for a student to board — the "ApproachingStop" notification is sent prematurely. Parents arrive at the stop and wait for a bus that has not actually left the previous stop yet. The Notification Log shows "ApproachingStop" with the early timestamp, creating a misleading record of when the approach happened.

**FC-003 — No Notification Sent if Driver Skips a Trip Event**
If a driver forgets to mark a stop as "Reached" in the Stoppage Status screen, the system does not trigger any notification. No "ReachedStop" or "Delayed" notification is sent. Parents at that stop receive nothing. The Notification Log has no record for that stop because the trigger event never happened. An empty log does not tell Mrs. Desai whether notifications were sent and failed — it simply shows nothing. She would only notice the gap if she specifically checks that stop and sees it is missing from the log.

**FC-004 — Cancellation Notification Sent Only Through Some Channels**
A trip is cancelled due to an emergency, and the system sends "Cancelled" notifications to all parents. However, the WhatsApp channel is temporarily down. Parents who rely on WhatsApp do not receive the cancellation. The Notification Log shows "WhatsApp: Failed" for all entries, but Mrs. Desai does not check the log until the next day. By then, several parents have already sent their children to the stop. The log records the failure, but it does not trigger any alert or retry mechanism.
