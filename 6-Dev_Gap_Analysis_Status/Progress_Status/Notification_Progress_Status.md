# Notification Module — Business Requirements Status (Simple Overview)

> **Plain English Summary** — What works, what's missing, and how it will work.

---

## 📊 Overall Status: 55% Complete

```
████████████████████████████████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 55% Built                        45% Pending
```

---

## ✅ What Is Already Built (Working Now)

### 1. Channel Management — ✅ 100%
**What it does:** School can define which communication channels they support — Email, SMS, WhatsApp, In-App notifications, and Push notifications.

**How it works:** Admin goes to Settings → Notification Channels, adds channels like "Email" or "SMS", sets how many times to retry if sending fails, and which backup channel to use if primary fails.

### 2. Provider Management — ✅ 80% (CRUD works, sending not connected)
**What it does:** School can store API credentials for service providers like Twilio (SMS), AWS SES (Email), MSG91 (SMS), Firebase (Push).

**How it works:** Admin goes to Providers, adds provider name, selects which channel it belongs to, enters API key and endpoint. Provider can be marked as PRIMARY, SECONDARY, or BACKUP.

> ⚠️ **Note:** Credentials can be saved but the system doesn't actually use them to send messages yet. Also, passwords are stored as plain text (not encrypted).

### 3. Templates — ✅ 90%
**What it does:** School can create message templates with placeholders like `{{student_name}}`, `{{amount}}`, `{{date}}` that get replaced with real values when sending.

**How it works:** 
- Admin creates template in DRAFT status
- Writes subject and message body with `{{placeholders}}`
- Submits for approval
- Approver reviews and approves/rejects
- Only approved templates are used for sending
- Old versions are preserved when template is updated
- Templates can be duplicated for quick creation

**Example:**
> Template: "Dear {{parent_name}}, your child {{student_name}} has been marked absent today."
> When sending: "Dear Mr. Sharma, your child Rahul has been marked absent today."

### 4. Target Groups — ✅ 80%
**What it does:** School can create groups of recipients to send notifications to. Groups can be Static (manual selection) or Dynamic (based on rules).

**How it works:** Admin creates a group like "All Hostel Wardens" or "All Class 10 Students". For dynamic groups, they define rules like "Students where class = 10". The system stores the group but doesn't yet calculate who is in it.

> ⚠️ **Note:** For Static groups, there's no way to add individual members yet. For Dynamic groups, the system doesn't run the query to find members.

### 5. Notification Targets — ✅ 80%
**What it does:** When creating a notification, school can define who should receive it — either a Target Group or specific individuals.

**How it works:** Admin creates a notification, selects "Send to Group" and picks a group. The system stores this information but doesn't yet resolve it into actual recipient names.

### 6. Notifications — ✅ 80%
**What it does:** School can create notification campaigns — one-time or recurring messages to be sent to selected recipients.

**How it works:** Admin fills title, description, selects template, sets priority, picks channels (Email, SMS, etc.), selects target group, and submits. The notification is saved but **not actually sent** through the real channels.

### 7. User Preferences — ✅ 100%
**What it does:** Each user can control how they receive notifications — which channels to use, quiet hours (don't disturb at night), daily digest mode.

**How it works:** 
- Users can enable/disable specific channels
- Set quiet hours (e.g., 10 PM to 7 AM)
- Choose to receive daily digest instead of real-time
- Override contact details (different email/phone for notifications)

### 8. Resolved Recipients — ✅ 80%
**What it does:** Shows the final list of people who will receive a notification, with personalized content.

**How it works:** Lists notification recipients with their delivery status. Can mark recipients as "processed" but this doesn't trigger actual sending.

### 9. Delivery Queue — ✅ 80%
**What it does:** A queue of messages waiting to be sent, with retry management.

**How it works:** Shows pending/sent/failed/retry counts. Admin can manually process, retry, or cancel queue items. But no automatic worker processes the queue.

### 10. Delivery Logs — ⚠️ 30%
**What it does:** Record of all sent notifications with delivery status.

**How it works:** Views exist to display delivery logs, but there's no controller to render them. Currently only Email and In-App notifications create log entries.

### 11. Notification Threads — ✅ 100%
**What it does:** Groups related notifications into threads (conversations, digests, or broadcasts).

**How it works:** Admin creates threads, adds notifications to them, sets sequence order. Supports parent-child hierarchy for threaded conversations.

### 12. Event Dispatch Pipeline — ✅ 100%
**What it does:** Other modules can trigger notifications with a single line of code.

**How it works:** Any module calls `Notification::dispatch('event_code', $data)` and the system fires an event, which is picked up by a background worker. This pipeline works end-to-end.

### 13. Email Sending — ✅ Working
**What it does:** Sends emails using Laravel's built-in mail system.

**How it works:** When a notification event is triggered for the EMAIL channel, the system finds the matching template, replaces placeholders with real values, and sends the email. Delivery is logged.

### 14. In-App Notifications — ✅ Working
**What it does:** Shows notifications inside the application (bell icon / notification dropdown).

**How it works:** When a notification event is triggered for the IN_APP channel, the system creates a database notification visible in the user's notification center.

---

## ❌ What Is NOT Built (Pending Work)

### 1. SMS Sending — ❌ NOT STARTED
**What's missing:** The system cannot send SMS messages. When SMS channel is selected, it just logs "SMS not implemented" and does nothing.

**How it will work:** 
- School configures an SMS provider (Twilio, MSG91, TextLocal) in Provider settings
- When a notification is created for SMS channel, the system:
  1. Takes the resolved recipient list
  2. Picks the PRIMARY SMS provider
  3. Calls the provider's API to send the message
  4. If primary fails, automatically tries SECONDARY provider
  5. Logs success/failure in delivery logs
  6. Retries up to 3 times if failed
- SMS providers send delivery status updates back to the system (delivered, failed, pending)

**Business value:** Emergency alerts, attendance notifications, fee reminders — most parents prefer SMS.

### 2. WhatsApp Sending — ❌ NOT STARTED
**What's missing:** Cannot send WhatsApp messages. Same as SMS — just a log placeholder.

**How it will work:**
- School configures WhatsApp Business API provider (Meta/Facebook)
- Templates must be pre-approved by Meta (WhatsApp template approval process)
- System sends messages via WhatsApp Business API
- Supports text, images, and interactive buttons
- Delivery receipts and read receipts tracked
- Very high open rates (>95%) compared to email

**Business value:** Most popular messaging app in India. Ideal for parent communication.

### 3. Push Notifications — ❌ NOT STARTED
**What's missing:** Cannot send push notifications to mobile apps. The device registration table exists but has no management interface.

**How it will work:**
- When parents install the school mobile app, their device gets registered in the system
- When a notification needs to be sent:
  1. System finds all active devices for the recipient
  2. Sends via Firebase Cloud Messaging (Android) or Apple Push Service (iOS)
  3. Removes expired/invalid device tokens automatically
- Push notifications appear as pop-up alerts on the phone

**Business value:** Real-time alerts even when the app is closed. Urgent notices, instant updates.

### 4. Delivery Queue Worker — ❌ NOT STARTED
**What's missing:** The delivery queue exists but nobody is working on it. Items sit in the queue forever.

**How it will work:**
- A background worker (like a robot) runs continuously
- Every few seconds, it checks the queue for pending items
- Picks up the highest priority items first
- Attempts to send via the configured provider
- On success: marks as SENT, logs delivery
- On failure: retries up to 3 times with increasing delays
- After max retries: marks as FAILED, notifies admin
- The worker runs 24x7 and processes thousands of messages per minute

### 5. Webhook Receiver — ❌ NOT STARTED
**What's missing:** The system cannot receive delivery status updates from providers.

**How it will work:**
- When an email is sent via AWS SES, SES sends back a notification saying "delivered" or "bounced"
- When an SMS is sent via Twilio, Twilio sends back "delivered" or "failed"
- A webhook receiver (like a mailbox) listens for these updates
- Updates the delivery status in the system
- If bounced: marks as BOUNCED, optionally stops sending to that address
- If complaint (spam): marks as COMPLAINT, blacklists the recipient

**Business value:** Know exactly which messages were delivered, which bounced, and why.

### 6. Recurring/Scheduled Notifications — ❌ NOT STARTED
**What's missing:** Can't schedule notifications for future delivery or recurring patterns.

**How it will work:**
- Admin creates a notification and sets "Schedule Type" to:
  - **Immediate:** Send right away
  - **Scheduled:** Send on a specific date/time (e.g., "Send on June 1 at 9 AM")
  - **Recurring:** Send repeatedly (e.g., "Send every Monday at 8 AM")
- A cron job runs every minute, checks for due notifications
- If a scheduled notification is due, it starts the delivery pipeline
- If recurring, it creates a new instance and increments the counter
- Failed schedules are retried, logged in schedule audit

**Business value:** Automated fee reminders on due dates, daily attendance reports, weekly digest.

### 7. Target Group Member Management — ❌ NOT STARTED
**What's missing:** Static groups can be created but members can't be added.

**How it will work:**
- After creating a Static group, admin can add/remove members
- Member selection via user search and multi-select
- Dynamic groups automatically resolve members based on rules
- Member count is calculated and displayed

### 8. Rate Limiting — ❌ NOT STARTED
**What's missing:** Schools can send unlimited messages without any control.

**How it will work:**
- Each channel has limits: messages per minute, per day, per month
- Before sending, the system checks if the limit is reached
- If limit reached: queues the message for next cycle
- Admin gets alerts when approaching limits
- Prevents unexpected bills from messaging providers

### 9. Provider Credential Encryption — ❌ NOT STARTED
**What's missing:** API keys and secrets are stored as plain text in the database.

**How it will work:**
- When admin saves provider credentials, they are automatically encrypted
- When the system needs to use them, they are decrypted in memory
- Even database admins cannot see the actual API keys
- Follows security best practices

### 10. Cost Tracking — ❌ NOT STARTED
**What's missing:** No way to know how much was spent on messaging.

**How it will work:**
- Each provider has a cost per message (e.g., ₹0.05 per SMS, ₹0.30 per WhatsApp)
- Before sending: system estimates the cost
- After sending: system calculates actual cost
- Monthly cost reports by channel and module
- Budget alerts when approaching configured limits

---

## 📋 Tab-by-Tab Quick Status

```
┌────────────────────────────┬──────────┬──────────────────────────────────┐
│ Tab Name                   │ Status   │ Key Missing                     │
├────────────────────────────┼──────────┼──────────────────────────────────┤
│ Channel Master             │ ✅ 100%  │ Nothing                         │
│ Provider Master            │ ⚠️ 80%   │ Encryption, no real sending     │
│ Templates                  │ ✅ 90%   │ Preview/test-send               │
│ Target Groups              │ ⚠️ 80%   │ Can't add members               │
│ Notification Targets       │ ⚠️ 80%   │ Can't resolve to actual people  │
│ Notifications              │ ⚠️ 80%   │ Can't actually send             │
│ User Preferences           │ ✅ 100%  │ Nothing                         │
│ Resolved Recipients        │ ⚠️ 80%   │ Can't process                   │
│ Delivery Queue             │ ⚠️ 80%   │ No worker to process            │
│ Delivery Logs              │ ❌ 30%   │ No controller                   │
│ Notification Threads       │ ✅ 100%  │ Nothing                         │
│ User Devices               │ ❌ 0%    │ No interface at all             │
│ Schedule Audit             │ ❌ 0%    │ Nothing exists                  │
└────────────────────────────┴──────────┴──────────────────────────────────┘
```

---

## 🏗️ What Gets Built In Each Phase

### Phase 1: Make It Actually Send (Week 1 — ~3 days)
```
Task                          | Hours | Business Benefit
──────────────────────────────┼───────┼─────────────────────
Encrypt provider passwords    │ 2     | Security — API keys protected
SMS delivery (Twilio, MSG91)  │ 4     | Can send SMS to parents
WhatsApp delivery (Meta API)  │ 4     | Can send WhatsApp messages
Push notification (Firebase)  │ 4     | Mobile app alerts
Queue worker (auto-sender)    │ 6     | Messages actually go out
                              │───────│
                   Total      │ 20 hrs│
```

**After Phase 1:** School can send Email, SMS, WhatsApp, and Push notifications. Messages go out automatically.

### Phase 2: Complete The Pipeline (Week 2 — ~3 days)
```
Task                          | Hours | Business Benefit
──────────────────────────────┼───────┼─────────────────────
Target group member management│ 3     | Can add people to groups
Auto-resolve recipients       │ 3     | Know exactly who gets what
Personalize messages          │ 2     | Each person sees their name
Delivery status callbacks     │ 4     | Know if message was delivered
Delivery Logs controller      │ 2     | Can view delivery history
                              │───────│
                   Total      │ 14 hrs│
```

**After Phase 2:** Full send-receive-track cycle works from creation to delivery confirmation.

### Phase 3: Advanced Features (Week 3 — ~3 days)
```
Task                          | Hours | Business Benefit
──────────────────────────────┼───────┼─────────────────────
Schedule notifications        │ 4     | Send at specific time
Recurring notifications       │ 4     | Auto reminders every day/week/month
Rate limiting                 │ 3     | Control costs, prevent abuse
Device registration API       │ 4     | Mobile app push notifications
Daily digest                  │ 3     | Batch notifications into summary
                              │───────│
                   Total      │ 18 hrs│
```

**After Phase 3:** Automated scheduling, cost control, mobile app support, daily digests.

---

## 🎯 Quick Summary for Management

### What's Working Today
✅ School can set up channels (Email, SMS, WhatsApp, Push)  
✅ School can add provider API credentials (Twilio, AWS, etc.)  
✅ School can create message templates with placeholders  
✅ School can create target groups (Static and Dynamic)  
✅ **Email sending works**  
✅ **In-App notifications work** (bell icon inside the system)  
✅ User preference management (opt-in/out, quiet hours)  
✅ Notification threads for grouping messages  
✅ Event system — other modules can trigger notifications  

### What's NOT Working Today
❌ **SMS sending** — Cannot send SMS  
❌ **WhatsApp sending** — Cannot send WhatsApp  
❌ **Push notifications** — Cannot send to mobile app  
❌ **Auto-processing** — Queue exists but no worker processes it  
❌ **Delivery tracking** — Cannot receive delivery confirmations  
❌ **Scheduling** — Cannot schedule future notifications  
❌ **Recurring** — Cannot set daily/weekly/monthly auto-send  
❌ **Member management** — Cannot add people to static groups  
❌ **Rate limits** — No control over message volume  
❌ **Cost tracking** — No idea how much is being spent  

### Why It Matters
```
                   │  Email  │  SMS  │  WhatsApp  │  In-App  │  Push  │
───────────────────┼─────────┼───────┼────────────┼──────────┼────────│
Works Now?         │   ✅    │   ❌  │     ❌     │    ✅    │   ❌   │
Parent Reach Rate  │   60%   │  95%  │    98%     │   30%    │   70%  │
Cost per message   │   Free  │ ₹0.05 │   ₹0.30    │   Free   │  Free  │
Urgent Alerts?     │   Slow  │ Fast  │   Instant  │   Slow   │ Instant│
```

**Bottom Line:** The notification system has a solid foundation — all the setup screens work. What's missing is the actual delivery engine. With about **50 hours of development time**, we can have a fully functional multi-channel notification system that can reach parents on their preferred channel.
