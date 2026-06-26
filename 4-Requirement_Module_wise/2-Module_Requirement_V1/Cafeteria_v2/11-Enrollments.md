# Enrollments — Business Requirements

## What This Screen Does

The Enrollments screen tracks which students or staff members are subscribed to which meal plan, their enrollment period, and current status. Each enrollment links a subscriber to a plan with a defined start and end date.

---

## When This Screen Is Used

- A parent wants to subscribe their child to a meal plan
- A student's subscription needs to be paused (e.g., on a school trip)
- A subscription is expiring and needs to be renewed
- Admin wants to see all students with active subscriptions for billing
- A staff member needs to be enrolled in a staff meal plan

---

## Key Fields at a Glance

**Plan**
Which subscription plan the subscriber is enrolled in.

**Subscriber**
Either a student OR a staff member — mutually exclusive, not both.

**Meal Card**
Optional — the meal card from which the plan fee will be deducted.

**Period**
Start Date (required) and End Date (nullable — defaults to plan's term end).

**Status**
- Active: Subscription active — subscriber gets meals as per the plan.
- Paused: Temporarily suspended.
- Cancelled: Permanently terminated. Reason required.
- Expired: End date passed — auto-set by nightly cron.

**Cancellation Reason**
Required when status changes to Cancelled.

---

## Business Rules and Conditions

**Mutual Exclusivity**
Must be either a student or a staff member, not both. Both filled = error. Neither filled = error.

**Enrollment Lifecycle:**
- Active ↔ Paused: Can toggle unless expired.
- Active → Cancelled: Permanent. Reason required.
- Active / Paused → Expired: Auto by nightly cron when end_date < today().
- Cancelled → (no transitions).

**Auto-Expiry Cron**
Nightly cron checks Active/Paused enrollments where end_date < today() and marks them Expired with audit logging.

---

## Workflow Steps

**Enrolling a Student**
Search student → select plan → optionally select meal card for fee deduction → set enrollment period → submit as Active.

**Pausing an Enrollment**
Pause enrollment (e.g., student on exchange program). Benefits suspended. Can resume later.

**Resuming an Enrollment**
Resume a paused enrollment unless already expired.

**Cancelling an Enrollment**
Cancel with required reason. Permanent — cannot be reactivated.

**Viewing Expired Enrollments**
Filter by status. Renew by creating a new enrollment record.

---

## Example Scenario

Student Priya's parents subscribe to Full Day Meal Plan (₹2,500/month).
- Enrolled: Jun 1, 2026 to Mar 31, 2027. Status: Active.
- Monthly fee deducted from Priya's meal card.
- Mid-term: Priya goes on 2-week vacation → admin pauses enrollment → no charge during pause → resumed on return.
- March 31: Nightly cron marks as Expired. Admin creates new enrollment for next year.

---

## Related Screens

- **Subscription Plans** — Plans define what the enrollment covers
- **Meal Cards** — Plan fees deducted from the student's meal card
- **Meal Attendance** — Attendance can verify subscription usage
