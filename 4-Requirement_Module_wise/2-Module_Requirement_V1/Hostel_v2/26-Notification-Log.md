# Notification Log — Business Requirements

## What This Screen Does

The Notification Log screen records every notification dispatched by the Hostel module. This includes SMS, email, push notifications, WhatsApp, and in-app/portal notifications sent to students, parents, wardens, and administrators. The log provides delivery status tracking and a complete communication audit trail.

---

## When This Screen Is Used

- Verifying that a notification was sent to a parent
- Checking delivery status of an alert
- Reviewing notification history for a specific student or incident
- Audit: Proving that parents were notified about an incident
- Troubleshooting failed notifications

---

## Key Fields

- **Recipient** — Who the notification was sent to (student, parent, warden, etc.)
- **Channel** — SMS / Email / Push / WhatsApp / In-App / Portal
- **Notification Type** — Leave Approval / Incident Alert / SLA Breach / Complaint Update / Overdue Return / Attendance Alert / Sick Bay Notification / Fee Reminder / Other
- **Subject** — Notification subject/title
- **Body** — Content of the notification
- **Reference Entity** — Which record triggered this (complaint ID, incident ID, etc.)
- **Sent At** — When it was dispatched
- **Delivered At** — When delivery was confirmed (nullable)
- **Read At** — When recipient read/viewed (for in-app/portal)
- **Status** — Queued / Sent / Delivered / Failed / Read
- **Error Message** — If failed, the error details

---

## Business Rules

- All notification channels are logged regardless of delivery success
- Failed notifications are automatically retried (up to 3 times)
- Delivery status is updated via callback/webhook where available (SMS, email)
- Notification log is retained for minimum 6 months
- Searchable by recipient, date range, notification type, and status
- Parent consent notifications for incidents must be confirmed delivered

---

## Related Screens

- **Audit Log** (Tab 25) — Audit trail for actions that triggered notifications
- **All screens** — Various screens trigger notifications logged here
