# Screen Design Specification: Notification Log
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Audit trail of all notifications sent to stakeholders (trip start, approaching stop, delayed trips, emergency alerts, fee reminders). Backed by `tpt_notification_log`.

### 1.2 User Roles & Permissions
| Role | Create | View | Update | Delete | print | Export | Import |
|------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| PG Support   |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| School Admin |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✓    |  ✗    |
| Principal    |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✓    |  ✗    |
| Teacher      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Student      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Parents      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |

### 1.3 Data Context

Database Table: `tpt_notification_log`
├── id (BIGINT PRIMARY KEY)
├── recipient_id (FK -> `std_students.id` or `hrm_employees.id` or email, nullable)
├── recipient_type (ENUM: STUDENT, PARENT, DRIVER, ADMIN, PRINCIPAL, TEACHER)
├── notification_type (ENUM: TRIP_START, APPROACHING_STOP, TRIP_COMPLETED, TRIP_DELAYED, EMERGENCY, FEE_REMINDER, MAINTENANCE_DUE, INCIDENT, OTHER)
├── entity_type (ENUM: TRIP, VEHICLE, STUDENT, ROUTE, INCIDENT)
├── entity_id (BIGINT)
├── message (TEXT)
├── channel (ENUM: EMAIL, SMS, PUSH, IN_APP)
├── sent_timestamp (DATETIME)
├── read_timestamp (DATETIME, nullable)
├── delivery_status (ENUM: SENT, DELIVERED, FAILED, BOUNCED)
├── delivery_attempts (INT, default 1)
├── last_retry_timestamp (DATETIME, nullable)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Notification Log Dashboard
**Route:** `/transport/notifications`

#### 2.1.1 Layout (Notification History)
```
┌───────────────────────────────────────────────────────────────────────────┐
│ TRANSPORT > NOTIFICATION LOG                                     │
├───────────────────────────────────────────────────────────────────────────┤
│ TYPE: [All ▼]  RECIPIENT: [All ▼]  CHANNEL: [All ▼]            │
│ STATUS: [All ▼]  DATE: [Last 7 days ▼]                          │
│ [Resend Failed] [Export] [Analytics]                            │
├───────────────────────────────────────────────────────────────────────────┤
│ Time       | Recipient      | Type               | Channel | Status
├───────────────────────────────────────────────────────────────────────────┤
│ 07:15 AM   | Parent (Ravi)  | TRIP_START         | SMS     | ✓ Delivered
│ 07:22 AM   | Parent (Aarav) | APPROACHING_STOP   | PUSH    | ✓ Delivered
│ 07:30 AM   | Parent (Aarav) | TRIP_COMPLETED     | PUSH    | ✓ Delivered
│ 07:30 AM   | Parents (All)  | FEE_REMINDER       | EMAIL   | ✓ Delivered
│ 07:35 AM   | Driver (Ravi)  | EMERGENCY          | SMS+PUSH| ✓ Delivered
│ 06:50 AM   | Parent (Bhavna)| TRIP_DELAYED       | SMS     | ✗ Failed
│
│ [View Details] [Resend] [View Message]
│
└───────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Notification Details
#### 2.2.1 Full Notification Card
```
┌────────────────────────────────────────────────────────┐
│ NOTIFICATION DETAIL                                 [✕]│
├────────────────────────────────────────────────────────┤
│ NOTIFICATION ID: NOT-2025-5432
│ Type: TRIP_START
│ Status: DELIVERED
│
│ RECIPIENT
│ Name: Ravi Kumar (Parent)
│ Contact: ravi.kumar@email.com / +91-98765-43210
│ Recipient Type: PARENT
│
│ CONTENT
│ Trip: Trip-123 (Route A - Morning)
│ Message: "Your child's bus (BUS-101) has started from
│          the depot. Expected arrival at school: 07:35 AM"
│
│ DELIVERY
│ Channels: SMS, PUSH
│ Sent: 2025-12-01 06:45:30 AM
│ Read: 2025-12-01 06:46:15 AM
│ Delivery Status: DELIVERED
│ Delivery Attempts: 1
│
│ RELATED ENTITY
│ Trip: Trip-123 (Route A - Morning)
│ Vehicle: BUS-101
│ Student: Aarav Patel
│
│ [Resend] [View Analytics] [Mark as Read]
│
└────────────────────────────────────────────────────────┘
```

### 2.3 Failed Notification Retry
#### 2.3.1 Retry Management
```
┌────────────────────────────────────────────────┐
│ RESEND NOTIFICATION                         [✕]│
├────────────────────────────────────────────────┤
│ ORIGINAL NOTIFICATION
│ ID: NOT-2025-5432
│ Type: TRIP_DELAYED
│ Recipient: Parent (Bhavna Gupta)
│ Sent: 2025-12-01 06:50 AM
│ Status: FAILED (SMS)
│
│ FAILURE REASON
│ Invalid phone number
│
│ RETRY OPTIONS
│ Contact: [+91-98765-43211 ▼]  [Update Contact]
│ Channel: [SMS ▼]
│
│ NEW MESSAGE (can edit)
│ "Trip-125 has been delayed by 15 minutes due to
│  traffic on Main Road. New ETA: 07:40 AM"
│
├────────────────────────────────────────────────┤
│ [Cancel]  [Send SMS]  [Send Email]  [Send Both]
└────────────────────────────────────────────────┘
```

### 2.4 Notification Analytics
#### 2.4.1 Dashboard Summary
```
NOTIFICATION ANALYTICS - Last 30 Days
────────────────────────────────────────────────────
TOTAL NOTIFICATIONS SENT: 2,450
├─ Delivered: 2,380 (97.1%)
├─ Failed: 45 (1.8%)
├─ Bounced: 25 (1.0%)

BY TYPE
├─ TRIP_START: 450 (18%)
├─ TRIP_COMPLETED: 450 (18%)
├─ APPROACHING_STOP: 900 (37%)
├─ FEE_REMINDER: 300 (12%)
├─ OTHER: 350 (15%)

BY CHANNEL
├─ SMS: 1,200 (49%) [98.5% delivery]
├─ PUSH: 900 (37%) [96.0% delivery]
├─ EMAIL: 300 (12%) [99.0% delivery]
├─ IN_APP: 50 (2%) [100% delivery]

TOP RECIPIENTS
├─ Ramesh Kumar (Parent): 125 notifications
├─ Priya Sharma (Parent): 112 notifications
├─ Anita Verma (Parent): 98 notifications
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Notification
```json
POST /api/v1/transport/notifications
{
  "recipient_id": 1,
  "recipient_type": "PARENT",
  "notification_type": "TRIP_START",
  "entity_type": "TRIP",
  "entity_id": 123,
  "message": "Your child's bus has started from the depot",
  "channel": "SMS",
  "sent_timestamp": "2025-12-01T06:45:30Z",
  "delivery_status": "SENT"
}

Response:
{
  "id": 5432,
  "recipient_id": 1,
  "notification_type": "TRIP_START",
  "channel": "SMS",
  "delivery_status": "SENT",
  "sent_timestamp": "2025-12-01T06:45:30Z",
  "created_at": "2025-12-01T06:45:30Z"
}
```

### 3.2 Get Notification Log
```json
GET /api/v1/transport/notifications?notification_type={type}&delivery_status={status}&from_date={date}

Response:
{
  "data": [
    {
      "id": 5432,
      "recipient_id": 1,
      "recipient_name": "Ravi Kumar",
      "recipient_type": "PARENT",
      "notification_type": "TRIP_START",
      "channel": "SMS",
      "message": "Your child's bus has started",
      "sent_timestamp": "2025-12-01T06:45:30Z",
      "read_timestamp": "2025-12-01T06:46:15Z",
      "delivery_status": "DELIVERED"
    }
  ],
  "pagination": {"page": 1, "per_page": 50, "total": 2450}
}
```

### 3.3 Update Notification Status
```json
PATCH /api/v1/transport/notifications/{id}
{
  "delivery_status": "DELIVERED",
  "read_timestamp": "2025-12-01T06:46:15Z"
}
```

### 3.4 Resend Failed Notification
```json
POST /api/v1/transport/notifications/{id}/resend
{
  "recipient_contact": "+91-98765-43211",
  "channel": "SMS"
}

Response:
{
  "id": 5432,
  "delivery_status": "SENT",
  "delivery_attempts": 2,
  "last_retry_timestamp": "2025-12-01T07:00:00Z"
}
```

---

## 4. USER WORKFLOWS

### 4.1 Auto-Send Notifications
```
1. Trip starts (06:45 AM)
2. System auto-creates notification records
3. Sends to all parents of students on trip
4. Multiple channels: SMS + PUSH
5. Delivery status tracked
6. Read status tracked (push opens)
```

### 4.2 Monitor Delivery
```
1. Admin opens Notification Log
2. Views notifications sent today
3. Filters by type (e.g., TRIP_START) or status (FAILED)
4. Identifies any failed deliveries
5. Clicks [Resend] on failed notifications
6. Enters corrected contact info
7. Resends notification
```

### 4.3 View Analytics
```
1. Manager opens notification dashboard
2. Clicks [Analytics]
3. Views delivery rate (97.1% delivered)
4. Analyzes by notification type and channel
5. Exports report
6. Identifies high-failure channels for improvement
```

---

## 5. VISUAL DESIGN GUIDELINES

- Color-code status: SENT (gray), DELIVERED (green), FAILED (red), BOUNCED (orange)
- Channel indicators with icons (SMS, email, push, etc.)
- Delivery time displayed clearly
- Read/unread status visible

---

## 6. ACCESSIBILITY & USABILITY

- Date/time pickers for filtering
- Dropdown for notification type and channel
- Clear message preview
- Keyboard shortcuts for retry [R], view details [V]

---

## 7. TESTING CHECKLIST

- [ ] Create notification for trip start
- [ ] Notification sent to all relevant parents
- [ ] Delivery status tracked correctly
- [ ] Read timestamp captured when parent opens push
- [ ] Failed notifications flagged in dashboard
- [ ] Resend failed notification with corrected contact
- [ ] Analytics dashboard calculates delivery rate correctly
- [ ] Export to CSV includes all notification fields

---

## 8. FUTURE ENHANCEMENTS

1. Template-based notifications (reduce manual entry)
2. Scheduled notifications (send at optimal time)
3. Multi-language support (SMS in regional languages)
4. Personalized message preferences (by parent)
5. Notification analytics by recipient (engagement tracking)
6. A/B testing notification content (improve open rates)

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
