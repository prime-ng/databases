# Business Requirements Document (BRD)
## Module: Notification
### Feature: Delivery Queue & Recipient Resolution

---

## 1. Executive Summary
This is the invisible "Engine Room" of the module. It translates high-level campaigns into individual message packets, processes them sequentially, handles API failures, and tracks delivery receipts.

## 2. Business Motive & Rules
- **Throttling:** Sending 10,000 emails instantly will get the school's IP blacklisted. The queue ensures messages trickle out according to the `rate_limit_per_minute`.
- **Resilience:** Network errors happen. The queue must automatically retry failed messages up to a maximum limit before marking them as dead.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Resolved Recipients (`ntf_resolved_recipients`)
- Managed by `ResolvedRecipientController.php`.
- When a Notification is approved, the Engine "explodes" the Target Group into individual `ntf_resolved_recipients`.
- Fetches the user's actual contact info based on channel (e.g., checks User profile for phone number if Channel is SMS).
- Checks User Preferences. If the user opted-out of SMS, this specific recipient record is marked as skipped.

### FR-02: Delivery Queue Processing (`ntf_delivery_queue`)
- Managed by `DeliveryQueueController.php`.
- Items are inserted into the queue with a `queue_status` (PENDING).
- **Worker Lock:** Before processing, the worker sets `locked_by` and `locked_at` to prevent dual-sending from parallel workers.
- **Retry Logic:** If delivery fails (e.g., Twilio 500 error), `attempt_count` increments. If `attempt_count < max_attempts`, sets `next_attempt_at` based on `retry_delay_minutes`.
- Updates the parent `ntf_notifications` tracking counters (`sent_count`, `failed_count`).

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Throttled Queue Processing
**As a** System Admin,
**I want** the delivery queue to respect the channel's rate limits,
**So that** we don't violate our AWS SES sending limits.

**Acceptance Criteria:**
- **Given** an email channel with a limit of 100/minute, **When** a queue of 500 emails is processed, **Then** the worker dispatches exactly 100 emails, pauses, and processes the next batch the following minute.
