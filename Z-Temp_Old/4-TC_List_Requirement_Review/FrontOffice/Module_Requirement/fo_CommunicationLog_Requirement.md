# Email & SMS Logs — Business Requirements

## What This Screen Does

The Email & SMS Logs tab shows sent communication history split into two columns: Recent Emails and Recent SMS. Staff can compose new communications via a modal with Email/SMS channel tabs, selecting recipient groups and entering subject/message.

## When This Screen Is Used

- **Bulk Communication**: Sending emails/SMS to All_Parents, All_Staff, All_Students
- **Communication Audit**: Viewing sent message history
- **Templates**: Reusing email templates for common messages

## Key Fields

- **channel** (enum) — Email, SMS
- **subject** (string 255) — Email subject or SMS identifier
- **body** (text) — Message content
- **recipient_group** (string) — Target group label
- **template_id** (FK → fof_email_templates, nullable)
- **total_recipients / sent_count / failed_count** — Delivery stats
- **sent_at** (timestamp, nullable)

## Business Rules

**Compose Modal:** Modal with two panes (Email / SMS tabs). Email requires Subject + Body (textarea). SMS has max 160 chars with form hint.

**Recipient Groups:** Email — All_Parents, All_Staff, All_Students, Custom. SMS — same plus Custom_Numbers.

**Logs View:** Side-by-side layout. Each side shows Subject/Message, To (recipient_group), Status badge (currently N/A), Sent time (diffForHumans). "View all" links to full log pages.

**Email Templates:** `EmailTemplate` model (name, subject, body, module) with toggleStatus. Accessed via `route('fof.communication.email.templates')`.

## Requirements

- MUST display in Communication tab group as two-column layout (Email left, SMS right)
- MUST authorize via `frontoffice.communication.*` policy gates
- MUST show compose modal with Email/SMS channel tabs
- MUST validate SMS body max 160 characters
- MUST show recent logs with diffForHumans timestamps
- MUST filter by channel (Email/SMS/All)
- MUST link to full email/SMS log pages
- MUST support email templates management
