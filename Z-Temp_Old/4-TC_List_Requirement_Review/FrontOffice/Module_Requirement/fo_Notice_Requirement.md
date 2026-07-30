# Notice Board — Business Requirements

## What This Screen Does

The Notice Board tab manages school notices displayed to staff/students/parents. Notices have title, content, category, audience targeting, display period, pinning, and emergency flags. Emergency notices bypass display period restrictions.

## When This Screen Is Used

- **Daily Announcements**: Morning assembly notices, schedule changes
- **Emergency Alerts**: Urgent closure, safety alerts (always visible)
- **Pinned Items**: Important reminders that stay at top

## Key Fields

- **title** (string 200) — Notice title
- **content** (text) — Full notice content
- **category** (string 100, nullable) — e.g., Academic, Administrative, Sports
- **audience** (string 50, nullable) — Target audience
- **is_pinned** (boolean) — Pinned notices visually highlighted
- **is_emergency** (boolean) — Emergency badge + always visible
- **display_from** (date, nullable) — When to start showing
- **display_until** (date, nullable) — When to stop showing
- **attachment_media_id** — Spatie Media Library attachment

## Business Rules

**Emergency Visibility (BR-FOF-014):** `scopeVisible()` ensures emergency notices are **always** visible regardless of `display_until`. Non-emergency notices respect `display_from` ≤ now and `display_until` ≥ now.

**Pinned:** `is_pinned` shows a blue "Pinned" badge with thumbtack icon.

**Category:** Free-text field (not enum) — badge styled as `bg-light text-dark border`.

**Attachment:** Single file via Spatie Media Library `notice_attachment` collection.

## Requirements

- MUST display in Communication tab group as paginated table
- MUST authorize via `frontoffice.notice.*` policy gates
- MUST show emergency badge (red) with exclamation icon for emergency notices
- MUST show pinned badge (blue) with thumbtack for pinned notices
- MUST respect display period for non-emergency notices
- MUST show emergency notices regardless of display_until
- MUST support single file attachment
- MUST search by title
- MUST support status filter: Active/Inactive
