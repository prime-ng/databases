# CommonChat Tab 5: File & Media Sharing

This screen handles the upload, display, and management of file attachments within chat messages. Users can attach images, documents, and other supported file types to their messages. Attachments appear inline in the conversation — images as preview thumbnails and documents as file cards with a download link.

---

## How It Works

When the user clicks the attachment icon in the message composer, their operating system file picker opens. They can select a single file from their device. Once selected, the file is uploaded to the server and a preview appears in the conversation. Image files (JPEG, PNG, GIF, WebP) are displayed as inline previews with a lightbox click-to-expand feature. Document files (PDF, Word, Excel) are shown as file cards with an appropriate icon (PDF icon, Word icon, etc.), the original filename, and the file size.

After the file is attached to the message and the user sends it, the system stores the file using Spatie Media Library in the tenant-specific storage directory. A corresponding row is inserted into `cht_attachments` with metadata about the file. Thumbnails are generated for image files to improve conversation-loading performance. If the message is later deleted, the file URL is no longer served but the attachment metadata row is retained.

---

## Important Business Rules

- Allowed image types: JPEG, PNG, GIF, WebP. Allowed document types: PDF, DOC, DOCX, XLS, XLSX.
- MIME type validation is performed server-side based on the file content, not just the file extension.
- Maximum file size is controlled by `cht_settings.max_file_attachment_size_mb` (default 10 MB). Audio and video have separate size settings.
- Only one attachment per message is supported in Phase 1. The attachment button is disabled after a file is selected.
- The send button remains disabled until the file upload completes. A progress indicator shows upload status.
- File URL access is restricted to conversation participants. Direct URL access without authentication returns 403.
- When a message is soft-deleted, the attachment URL returns null. The attachment metadata row remains in the database for audit purposes.
- Files are stored in the tenant-specific directory: `storage/tenant_{uuid}/chat-attachments/`. Cross-tenant file access is not possible.
- Virus or malware scanning is performed on upload (integration with school's security infrastructure where available).

---

## Database Columns & Behavior

### cht_attachments
- `id` — BIGINT UNSIGNED PK. Attachment record identifier.
- `message_id` — BIGINT UNSIGNED FK. The message this file belongs to. Cascade-deleted if the message is hard-deleted.
- `file_name` — VARCHAR(255). Original client-provided filename, sanitised server-side before storage.
- `file_path` — VARCHAR(500). Storage path relative to tenant disk root. Example: "chat-attachments/2026/05/14/abc123_report.pdf".
- `file_size` — INT UNSIGNED. File size in bytes. Used for display labels and size validation.
- `mime_type` — VARCHAR(100). Server-validated MIME type. Determines UI rendering (preview vs. icon).
- `media_id` — INT UNSIGNED NULL. Spatie Media Library media.id reference.
- `thumbnail_media_id` — INT UNSIGNED NULL. Spatie media.id for auto-generated image thumbnail. NULL for non-image files.
- `is_active` — TINYINT(1) DEFAULT 1. Soft toggle for attachment visibility.

### cht_messages
- `id` — BIGINT UNSIGNED PK. Parent message identifier.
- `message_type` — ENUM('Text','Attachment','System'). Set to 'Attachment' when a file is included.
- `body` — VARCHAR(2000) NULL. Optional accompanying text for the attachment.
- `is_deleted` — TINYINT(1). When 1, attachment URLs are no longer served by the accessor.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|-------|---------|------------|-------|
| No attachment | User clicks attachment icon | File picker open | Operating system native file dialog |
| File selected | User picks valid file | Upload in progress | Progress indicator shown; send button disabled |
| Upload in progress | Upload completes successfully | Attachment staged (preview shown) | File chip with filename, size, and remove button |
| Upload in progress | Upload fails (network/validation) | Upload error | Error toast; user can retry or cancel |
| Attachment staged | User clicks send | Message + attachment sent | `cht_messages` + `cht_attachments` row created |
| Attachment staged | User clicks remove on chip | No attachment | Staged file deleted from temp storage |
| Attachment sent | User deletes message (soft-delete) | Attachment hidden | `cht_messages.is_deleted = 1`; URL accessor returns null |
| Attachment sent | Message hard-purged by retention job | Attachment deleted | Cascade delete from `cht_messages` |

- Image files generate a thumbnail (`thumbnail_media_id`) on upload for use in inline previews. Thumbnail generation runs as a queued job to avoid blocking the upload response.
- Documents (PDF, DOC, DOCX, XLS, XLSX) display as file cards with a MIME-type-determined icon. No thumbnail is generated.
- Lightbox click-to-expand feature for images opens the full-resolution file in an overlay modal.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|----------------|------|---------------|
| Allowed MIME types | JPEG, PNG, GIF, WebP, PDF, DOC, DOCX, XLS, XLSX only | "File type is not supported. Allowed types: JPEG, PNG, GIF, WebP, PDF, DOC, DOCX, XLS, XLSX." |
| MIME type spoofing | Server-side content sniffing, not extension-based | "File type could not be verified. Please upload a valid file." |
| File size | Max `cht_settings.max_file_attachment_size_mb` (default 10 MB) | "File exceeds the maximum allowed size of {size} MB." |
| Multiple attachments (Phase 1) | Only 1 attachment per message | "Only one attachment per message is supported." — button disabled after first selection |
| Deleted message access | `is_deleted = 1` → URL returns null | N/A — attachment accessor returns null silently |
| Non-participant download | Direct URL hit without auth/membership | 403 Forbidden |
| Cross-tenant access | Files in `storage/tenant_{uuid}/chat-attachments/` | N/A — tenant-isolated storage; cross-tenant access impossible |
| Virus/malware | File flagged by security scanner | "The file could not be uploaded due to security concerns." |
| Corrupt image | Thumbnail generation fails | Falls back to generic file icon; no preview |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| CommonChat | `cht_attachments` | `message_id` → `cht_messages.id` | Links file metadata to parent message |
| CommonChat | `cht_messages` | `message_type = 'Attachment'` | Sets message type to indicate attachment presence |
| Spatie Media Library | `cht_attachments.media_id` | FK to `media.id` | Actual file binary storage |
| Spatie Media Library | `cht_attachments.thumbnail_media_id` | FK to `media.id` | Generated image thumbnail |
| CommonChat | `cht_settings` | `max_file_attachment_size_mb` | Size limit configuration |
| System | `sys_users` | N/A (via cht_participants.user_id) | Membership verification for file access |
| School security infra | External virus scanner | N/A | Hooked via event/listener on upload complete |

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| Upload attachment | Active conversation participant | `cht_permission_config.can_send_attachment` per role-pair |
| Download/view attachment | Active participant of the parent conversation | Implicit — membership + conversation access |
| Delete attachment (via message delete) | Message sender or Group Admin | Implicit — `sender_id` match or group admin role |
| View inline image preview | Active conversation participant | Implicit — membership check |
| Admin purge attachments | Super Admin (via retention job) | System-level scheduled job
