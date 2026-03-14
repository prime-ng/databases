# Notification Module – Complete Process Flow & Lifecycle

## High-Level Architectural Position

┌─────────────┐
│ Any ERP     │
│ Module      │
│ (Exam/Fee)  │
└─────┬───────┘
      │ Event Trigger
      ▼
┌─────────────────────┐
│ Notification Engine │  ← Common Service (Domain Layer)
└─────┬───────────────┘
      │
      ▼
┌──────────────────────────────────────────┐
│ Notification Tables (Tenant DB)          │
│ ntf_notifications                        │
│ ntf_notification_targets                 │
│ ntf_notification_channels                │
│ ntf_templates                            │
│ ntf_user_preferences                     │
│ ntf_delivery_logs                        │
└──────────────────────────────────────────┘

### Key Principle
 - No ERP module directly sends SMS / Email.
 - All modules raise events → Notification Engine decides.

### How Different Modules Use the Notification Module

Every module sends one standard payload:
```
Notification::dispatch([
    'tenant_id'        => 5,
    'source_module'    => 'EXAM',
    'event_code'       => 'EXAM_SCHEDULE_PUBLISHED',
    'title'            => 'Exam Schedule Released',
    'template_code'    => 'EXAM_SCHEDULE',
    'priority'         => 'HIGH',
    'targets'          => [...],
    'channels'         => ['APP','SMS','EMAIL'],
    'schedule_at'      => null,
    'meta'             => [... variables ...]
]);
```

### Module-wise Examples

| Module	    | Trigger Event	        | Target	            | Channel
|---------------|-----------------------|-----------------------|----------------
| Exam	        | Exam Published	    | Class/Section	        | App + SMS
| Fee	        | Fee Due	            | Student + Parent	    | App + WhatsApp
| Attendance	| Absent	            | Parent	            | App + SMS
| Transport	    | Bus Delay             | Route Students	    | App + SMS
| Complaint	    | Escalation	        | Staff Role	        | App + Email
| Result	    | Result Declared	    | Student	            | App + SMS
| Leave	        | Approval	            | Staff	                | App + SMS
| Hostel	    | Outing Alert	        | Parent	            | WhatsApp
| Transport	    | Bus Delay             | Route Students	    | App + SMS
| Complaint	    | Escalation	        | Staff Role	        | App + Email
| Result	    | Result Declared	    | Student	            | App + SMS
| Leave	        | Approval	            | Staff	                | App + SMS
| Hostel	    | Outing Alert	        | Parent	            | WhatsApp

### Complete Notification Lifecycle (Step-by-Step)

1. Event Trigger
2. Notification Engine Decides
3. Notification Created
4. Notification Sent
5. Notification Delivered
6. Notification Failed
7. Notification Updated
8. Notification Deleted



#### STEP 1 — Event Raised by Any Module

    Example: Exam Module
        ```php
        ExamController → Exam Published
        ```

    - No SMS / Email sent here
    - Only event creation

#### STEP 2 — Notification Record Created

    Table: ntf_notifications
        ```sql
        INSERT INTO ntf_notifications
        (tenant_id, source_module, title, template_id, priority_id, scheduled_at)
        ```

    - This creates one logical notification.

#### STEP 3 — Target Audience Definition

    Table: ntf_notification_targets

    Examples:

    | target_type	          | target_reference_id |
    |-------------------------|---------------------|
    | CLASS	                  | 10                  |
    | SECTION	              | 4                   |
    | USER	                  | 125                 |
    | ROLE	                  | TEACHER             |

    - At this stage:
    - No users resolved yet
    - Just rules

#### STEP 4 — Channel Selection

    Table: ntf_notification_channels

    | Channel	| Status  |
    |-----------|---------|
    | APP	    | PENDING |
    | SMS	    | PENDING |
    | EMAIL	    | PENDING |

#### STEP 5 — Scheduler / Queue Picks Notification

    Laravel:

    ```bash
    php artisan schedule:run
    php artisan queue:work
    ```

    Query:
        ```sql
        SELECT * FROM ntf_notifications
        WHERE scheduled_at IS NULL OR scheduled_at <= NOW();
        ```

#### STEP 6 — Audience Resolution (Critical Step)

    Application Layer resolves:

    | Target Type	| Resolution Logic    |
    |---------------|---------------------|
    | USER	        | Direct              |
    | ROLE	        | Join users_roles    |
    | CLASS	        | students → users      |
    | SUBJECT	    | subject_students    |
    | ENTIRE_SCHOOL | all active users      |

    Resolved users inserted as:
        ```sql
        ntf_notification_targets.resolved_user_id
        ```
 
#### STEP 7 — User Preference Check

    Table: ntf_user_preferences

    For each resolved user:
     - Is channel enabled?
     - Is quiet hour active?
     - Is DND?

    If blocked → skipped

#### STEP 8 — Template Rendering

    Table: ntf_templates
        "Dear {{student_name}}, your exam starts on {{date}}"

    Merged using:
        Blade / Mustache / Twig

#### STEP 9 — Delivery Execution

    Each channel handled separately:

    | Channel	| Executor         |
    |-----------|------------------|
    | APP	    | DB insert        |
    | SMS	    | Provider API     |
    | WhatsApp	| Meta API         |
    | Email	    | SMTP / SES       |

    Status updated in:
        ```sql
        ntf_notification_channels
        ```

#### STEP 10 — Delivery Log Created

    Table: ntf_delivery_logs

    Tracks:
     - Sent
     - Failed
     - Read
     - Clicked

Used for:
    - Audit
    - Analytics
    - Parent acknowledgments

#### STEP 11 — Retry Logic

If failed:
    retry_count < max_retry

Re-queued automatically.

#### STEP 12 — Expiry Enforcement

```sql
    expires_at < NOW()
```

Notification stops.

#### 4. Complete Notification State Machine

        CREATED
        │
        ▼
        SCHEDULED
        │
        ▼
        TARGET_RESOLVED
        │
        ▼
        QUEUED
        │
        ▼
        SENT ─────► READ
        │
        ▼
        FAILED ───► RETRIED

#### 5. Permission & Security Flow

| Role	    | Permission          |
|-----------|---------------------|
| Admin	    | Create all          |
| Teacher	| Class notifications |
| Staff	    | Department          |
| Parent	| Read only           |
| Student	| Read only           |

Enforced via:
  - Role + Module Permission 
  - Confidentiality Level

#### 6. Reporting & Analytics Ready

| Metric		          | Source                    |
|-------------------------|---------------------------|
| Delivery rate	          | ntf_delivery_logs         |
| Channel performance	  | ntf_notification_channels |
| Read %	              | delivery_status           |
| Module usage	          | source_module             |

