# Digital Notice Board & School Events — Requirements

## What It Does
Two features for school-wide announcements:

1. **Notice Board** — Digital notice board with pinning, emergency bypass, display date control, and audience targeting. Emergency notices bypass display date constraints.
2. **School Events** — Public-facing calendar events (PTM, Sports Day, Exams, Holidays) with NTF notification blast capability.

## Database Fields

### fof_notices

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `title` | VARCHAR(200) | Required. |
| `content` | LONGTEXT | Required. Rich text HTML. |
| `category` | ENUM('Academic','Administrative','Sports','Cultural','Holiday','Emergency','Other') | Required. |
| `audience` | ENUM('All','Students','Staff','Parents') | Default 'All'. |
| `display_from` | DATE | Required. Notice visible from this date. |
| `display_until` | DATE | Nullable. NULL = no expiry. |
| `is_pinned` | TINYINT(1) | Default 0. Always shown at top. |
| `is_emergency` | TINYINT(1) | Default 0. Bypasses display date constraints per BR-FOF-014. |
| `attachment_media_id` | INT UNSIGNED FK → `sys_media` | Nullable. |
| `status` | ENUM('Active','Archived') | Default 'Active'. |

### fof_school_events

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `event_name` | VARCHAR(200) | Required. |
| `event_type` | ENUM('Academic','Sports','Cultural','PTM','Holiday','Exam','Admission','Other') | Required. |
| `start_date` | DATE | Required. |
| `end_date` | DATE | Required. Must be >= start_date. |
| `description` | TEXT | Nullable. |
| `venue` | VARCHAR(200) | Nullable. |
| `audience` | ENUM('All','Students','Staff','Parents') | Default 'All'. |
| `is_public` | TINYINT(1) | Default 0. Visible on public-facing website. |
| `notification_sent` | TINYINT(1) | Default 0. NTF blast dispatched. |

## Business Rules

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-FOF-014 | Emergency notices always visible regardless of display_until | Query excludes `display_until` check when `is_emergency = 1` |

**Notice Display Logic**
- Active notices: `status = 'Active'`, `display_from <= today`, and (`display_until IS NULL` OR `display_until >= today` OR `is_emergency = 1`)
- Pinned notices displayed first (ordered by `is_pinned DESC`, then `created_at DESC`)
- Emergency notices always shown regardless of expiry

**School Events**
- Calendar view (FullCalendar.js) with colour-coded event types
- Toggle for public visibility
- NTF blast button per event (one-time, sets `notification_sent = 1`)

## CRUD Operations

**Notices**
- `POST /front-office/notices` — validates title, content, category, display_from
- `PUT /front-office/notices/{notice}` — update existing notice
- `DELETE /front-office/notices/{notice}` — soft delete
- List: Active notices (pinned first) + Archived tab

**School Events**
- `POST /front-office/school-events` — validates event_name, start_date, end_date (>= start_date), event_type
- `PUT /front-office/school-events/{event}` — update event
- Calendar / list toggle view

## Permissions

| Operation | Permission Key |
|---|---|
| View notices & events | `frontoffice.notice.view` |
| Create/update notices & events | `frontoffice.notice.create` |
| Delete notices | `frontoffice.notice.delete` |
