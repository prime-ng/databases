# School Events — Business Requirements

## What This Screen Does

The School Events tab manages school-wide events (sports day, parent-teacher meets, holidays, etc.). Events are split into Upcoming (start_date ≥ today) and Past sections. Events have type, venue, audience targeting, and public visibility flags.

## When This Screen Is Used

- **Event Calendar**: Planning upcoming school events
- **Event History**: Reviewing past events
- **Public Events**: Events visible on public-facing pages

## Key Fields

- **event_name** (string 200) — Event name
- **description** (text, nullable) — Event description
- **event_type** (string 100, nullable) — e.g., Cultural, Sports, Academic
- **start_date** (date) — When event starts
- **end_date** (date, nullable) — When event ends
- **venue** (string 200, nullable) — Location
- **audience** (string 50, nullable) — Target audience
- **is_public** (boolean) — Visible on public pages
- **notification_sent** (boolean) — Whether notification was sent

## Business Rules

**Upcoming vs Past:** `scopeUpcoming()` returns events where `start_date >= today`. View splits into Upcoming Events section (green header) and Past Events section (gray header).

**No Time Field:** Event time was removed (commented out in view); only date + venue shown.

**Notification Tracking:** `notification_sent` boolean tracks whether a push/email notification was dispatched.

## Requirements

- MUST display in Communication tab group with Upcoming + Past sections
- MUST authorize via `frontoffice.school-event.*` policy gates
- MUST show upcoming events first (green header) then past events (gray header)
- MUST show venue with location-dot icon
- MUST show "Public" badge for public events
- MUST search across event name, description, venue
- MUST support status filter: Active/Inactive
- MUST paginate past events
