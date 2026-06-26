# Complete DDL Schema Explanation
---------------------------------

Table-by-Table Purpose & Field Explanation

## ntf_channel_master
**Purpose:** 
  Defines all available communication channels with their capabilities, limits, and costs.
    - tenant_id: Multi-tenant isolation
    - channel_type: Categorizes for processing strategy
    - priority_order: Determines channel selection order
    - fallback_channel_id: Auto-failover on delivery failure
    - rate_limit/daily_limit/monthly_limit: Usage controls
    - cost_per_unit: For cost tracking and billing

## ntf_provider_master
**Purpose:** 
  Manages external service provider configurations
    - Encrypted credential storage: Provider priority for load balancing
    - JSON configuration for provider-specific parameters: Enables hot-swapping between providers

## ntf_notifications
**Purpose:** 
  Central registry for all notification requests

**Calculated Fields:**
    - recurring_executed_count: Incremented by scheduler on each execution
    - total_recipients: COUNT from resolved_recipients
    - sent_count: COUNT from delivery_logs WHERE stage = 'SENT'
    - delivered_count: COUNT from delivery_logs WHERE stage = 'DELIVERED'
    - read_count: COUNT from delivery_logs WHERE read_at IS NOT NULL
    - click_count: COUNT from delivery_logs WHERE clicked_at IS NOT NULL
    - estimated_cost: SUM(channel.cost_per_unit * total_recipients)
    - actual_cost: SUM(delivery_logs.cost)
    - notification_status_id: DRAFT, SCHEDULED, PROCESSING, COMPLETED, PARTIAL, FAILED, CANCELLED, EXPIRED
    - is_manual: Manually created
    - created_by: User who created the notification
    - approved_by: User who approved the notification
    - approved_at: Timestamp when the notification was approved
    - processed_at: Timestamp when the notification was processed
    - completed_at: Timestamp when the notification was completed
    - is_active: Whether the notification is active
    - created_at: Timestamp when the notification was created
    - updated_at: Timestamp when the notification was updated
    - deleted_at: Timestamp when the notification was deleted
    - sent_count: COUNT from delivery_logs WHERE stage = 'SENT'
    - delivered_count: COUNT from delivery_logs WHERE stage = 'DELIVERED'
    - read_count: COUNT from delivery_logs WHERE read_at IS NOT NULL
    - click_count: COUNT from delivery_logs WHERE clicked_at IS NOT NULL
    - estimated_cost: SUM(channel.cost_per_unit * total_recipients)
    - actual_cost: SUM(delivery_logs.cost)

## ntf_notification_channels
**Purpose:** 
  Links notifications to channels with template overrides

    - sending_order: Sequence for fallback scenarios
    - next_retry_at: Exponential backoff scheduling

## ntf_target_groups
**Purpose:** 
  Reusable audience segments

    - group_type: STATIC (fixed list) or DYNAMIC (query-based)
    - dynamic_query: SQL/JSON for runtime resolution
    - total_members: Recalculated on refresh

## ntf_notification_targets
**Purpose:** 
  Target definitions for each notification

    - Supports both individual IDs and group references
    - estimated_count: Pre-resolution estimate
    - actual_count: Post-resolution actual count

## ntf_user_devices
**Purpose:** 
  Push notification device registry

    - Multi-device support per user
    - Device type differentiation
    - Last active tracking for active targeting

## ntf_user_preferences
**Purpose:** 
  User-level opt-in/out and delivery rules

    - GDPR compliance timestamps
    - Contact value overrides
    - Quiet hours with timezone support
    - Digest preferences
  

## ntf_templates
**Purpose:** 
  Notification content templates with versioning

    - Versioned template history
    - Placeholder validation
    - Approval workflow
    - Effective date ranges
    - Dual format support (HTML/Plain)

## ntf_resolved_recipients
**Purpose:** 
  Materialized view of who gets what, when

    - Pre-rendered personalized content
    - Batch grouping for bulk operations
    - Processing status tracking

## ntf_delivery_queue
**Purpose:** 
  Work queue for notification workers

    - Priority-based processing
    - Worker lock mechanism
    - Retry scheduling
    - Dead letter isolation

## ntf_delivery_logs
**Purpose:** 
  Complete audit trail of all deliveries

    - Full lifecycle tracking (queued→sent→delivered→read→clicked)
    - Provider correlation IDs
    - Performance metrics (duration_ms)
    - Cost tracking per message
    - IP/User agent for engagement

## ntf_notification_threads & Members
**Purpose:** 
  Conversation grouping

    - Thread parent-child hierarchy
    - Digest grouping
    - Conversation threading

## ntf_schedule_audit
**Purpose:** 
  Recurring notification execution history

    - Instance tracking
    - Execution status
    - Error logging

