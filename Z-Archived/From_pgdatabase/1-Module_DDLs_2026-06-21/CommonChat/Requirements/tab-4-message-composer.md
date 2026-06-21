# CommonChat Tab 4: Message Composer

The message composer is the input area at the bottom of every conversation view. It allows the user to type and send text messages, attach files, and reply to previous messages. It is the primary interaction point for all chat communication.

---

## How It Works

The composer is a fixed input bar at the bottom of the chat window. It contains a multi-line text input field where the user can type their message, an attachment button (paperclip icon), and a send button (arrow or paper plane icon). As the user types, the input field expands vertically up to a maximum of 5 lines, after which it becomes scrollable.

When the user clicks the attachment button, a file picker opens for selecting an image or document. Once selected, a file preview chip appears above the input field showing the filename, file size, and a remove button. The user can then type an accompanying message or send just the file. The send button is disabled when both the text field is empty and no file is attached.

If the user wishes to reply to a specific earlier message, they click the reply icon on that message. A "replying to" bar appears above the composer showing the original message author and a snippet of the original message text. The user types their reply and sends it; it appears threaded below the original message.

---

## Important Business Rules

- The message body cannot be empty unless a file attachment is present. At least one of body or attachment is required.
- Maximum message text length is 5,000 characters. Enforced at the FormRequest level.
- Message body is stored as plain text only. No HTML is allowed to prevent cross-site scripting. Emoji characters are stored as UTF-8.
- The send button is disabled when validation would fail (empty body, no attachment) to provide immediate visual feedback.
- Sending a message to an archived conversation is rejected with HTTP 422 and a clear validation error.
- Sending a message to a conversation the user is not a participant of returns HTTP 403.
- When replying, the parent message must belong to the same conversation. Cross-conversation replies are not allowed.
- Reply depth is limited to one level. A user cannot reply to a reply. If the parent message has been deleted, it is shown as "Deleted message" in the reply context.
- All message sends use AJAX; there is no full page reload. The new message appears in the conversation immediately after a successful server response.

---

## Database Columns & Behavior

### cht_messages
- `id` — BIGINT UNSIGNED PK. Auto-increment message identifier.
- `conversation_id` — BIGINT UNSIGNED FK. The conversation this message is sent to.
- `sender_id` — INT UNSIGNED FK. The authenticated user sending the message.
- `parent_message_id` — BIGINT UNSIGNED FK NULL. Set when the user is replying to a previous message. Must reference a message in the same conversation.
- `body` — VARCHAR(2000) NULL. Plain text message content. Max 5,000 chars enforced at validation. NULL when only a file attachment is sent.
- `message_type` — ENUM('Text','Attachment','System'). Set to 'Text' for text-only, 'Attachment' when a file is attached, 'System' for auto-generated events.
- `is_deleted` — TINYINT(1) DEFAULT 0. Always 0 on new messages.
- `created_at` — TIMESTAMP. Set automatically on insert. Used for chronological order.

### cht_attachments
- `id` — BIGINT UNSIGNED PK. Attachment identifier.
- `message_id` — BIGINT UNSIGNED FK. Links to the message this file belongs to.
- `file_name` — VARCHAR(255). Original filename, sanitised server-side.
- `file_path` — VARCHAR(500). Storage path relative to tenant disk root.
- `file_size` — INT UNSIGNED. File size in bytes. Displayed as human-readable label (e.g., "2.4 MB").
- `mime_type` — VARCHAR(100). Server-validated MIME type. Determines icon and preview rendering.
- `media_id` — INT UNSIGNED NULL. Spatie Media Library ID for the stored file.
- `thumbnail_media_id` — INT UNSIGNED NULL. Media ID for generated thumbnail (images only).

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|-------|---------|------------|-------|
| Idle (empty) | User types text | Composing (text entered) | Send button remains disabled if no text and no file |
| Composing (text entered) | User clears input | Idle (empty) | Send button disabled |
| Idle / Composing | User selects attachment file | File attached (preview shown) | Upload begins; progress indicator shown |
| File attached | Upload completes | Ready to send | Send button enabled if body present OR file uploaded |
| File attached | User removes file | Idle / Composing | File chip removed; send button re-evaluated |
| Ready to send | User clicks Send | Sending (AJAX in flight) | Button disabled; loading spinner shown |
| Sending | Server returns 200 OK | Sent (message added to conversation) | Input cleared; file chip removed; scroll to bottom |
| Sending | Server returns error | Error state | Error toast shown; message not sent; user can retry |
| Any state | User clicks reply on earlier message | Reply mode active | "Replying to" bar shown above composer |
| Reply mode active | User sends message | Reply sent (threaded) | `parent_message_id` set on new message |
| Reply mode active | User closes reply bar | Previous state restored | `parent_message_id` cleared |

- The composer input expands vertically up to 5 lines then becomes scrollable. Implemented via CSS `max-height` + `overflow-y: auto`.
- File upload uses AJAX (multipart/form-data) with a progress event listener updating a progress bar. The message is only created after the upload completes.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|----------------|------|---------------|
| Send (empty) | Both body AND attachment missing | "Type a message or attach a file to send." |
| Message body length | Max 5,000 characters (FormRequest) | "Message cannot exceed 5,000 characters." |
| HTML in body | Plain text only; HTML stripped/escaped | N/A — server-side sanitisation |
| Archived conversation | Send to archived conversation rejected | "Cannot send messages to an archived conversation." |
| Non-participant send | User not in `cht_participants` | 403 Forbidden — "You are not a participant in this conversation." |
| Cross-conversation reply | `parent_message_id` must reference same `conversation_id` | "Cannot reply to a message from a different conversation." |
| Reply depth | Parent message must have `parent_message_id IS NULL` | "You can only reply to top-level messages, not to other replies." |
| Deleted parent reply | Parent `is_deleted = 1` | Display "Deleted message" in reply context bar |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| CommonChat | `cht_messages` | `conversation_id` → `cht_conversations.id` | Message storage for conversation |
| CommonChat | `cht_messages` | `sender_id` → `sys_users.id` | Message author identity |
| CommonChat | `cht_messages` | `parent_message_id` → `cht_messages.id` | Reply threading (self-referencing FK) |
| CommonChat | `cht_attachments` | `message_id` → `cht_messages.id` | File metadata for attachment messages |
| CommonChat | `cht_participants` | `conversation_id`, `user_id` | Membership verification before send |
| CommonChat | `cht_conversations` | `is_archived` | Read-only check before send |
| Spatie Media Library | `cht_attachments.media_id` | FK to `media.id` | Actual file storage |

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| Send text message | Active conversation participant | Implicit — `cht_participants` membership + `left_at IS NULL` |
| Send attachment | Active conversation participant + permission allowed | `cht_permission_config.can_send_attachment` per role-pair |
| Reply to message | Active conversation participant | Implicit — membership check |
| Upload file | Active conversation participant | Implicit — membership check; size/MIME enforced server-side |
| View file attachment | Active conversation participant | Implicit — membership check; URL access protected
