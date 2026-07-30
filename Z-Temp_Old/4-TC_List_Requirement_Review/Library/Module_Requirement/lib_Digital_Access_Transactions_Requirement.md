# Digital Access Transactions — Business Requirements

## What This Screen Does

The Digital Access Transactions screen shows all active and historical digital resource access sessions. When a digital access request is approved, a transaction record is created with the member, book, digital resource, access type (Download or Read_Online), start time, and calculated expiry (based on the member's `digital_access_days`). The librarian can view the full list of active sessions — who is currently accessing which e-book, when access was granted, when it expires, and when the member last viewed the resource. Active sessions can be revoked by the librarian with a mandatory revocation reason, which immediately terminates the member's access, logs the revocation in `LibTransactionHistory`, and sends a notification to the member. The system also accepts heartbeat updates from the client-side viewer to track `total_view_duration_sec` and `last_accessed_at` for analytics.

---

## When This Screen Is Used

- When the librarian wants to see who is currently viewing or downloading e-books
- When the librarian needs to revoke someone's access immediately (e.g., member left the school, policy violation)
- When checking if concurrent license limits are being reached for a specific digital resource
- When viewing access history for audit, fine calculation, or reporting
- When the client-side viewer sends periodic heartbeat updates to track reading duration

## Default Data Load

The Digital Access Transactions screen opens as a tab pane within the Library Operations hub page (`library.transactionsIndex`). When the `digital-access` tab is active, the controller loads all transactions with eager-loaded member/user, book, digital resource, access request, grantedBy, and statusMaster relationships, ordered by latest first, paginated at 15 per page (`da_tx_page` paginator name). Filters support search by member name, book title, or access type, status filter (with special handling for 'revoked' — checks `revoked_at IS NOT NULL`), and access type dropdown filter.

---

---

## Key Fields at a Glance

**Core References**
Every transaction links to a `member_id` (FK to `lib_members`), `book_id` (FK to `lib_books_master`), `digital_resource_id` (FK to `lib_digital_resources`), and optionally `access_request_id` (FK to the originating `lib_digital_access_requests`). The `access_type` is an ENUM('Download', 'Read_Online') that determines what kind of access was granted.

**Access Window**
`access_start_at` (DATETIME, NOT NULL) records when access began. `access_expires_at` (DATETIME, nullable) records when access will expire — NULL means permanent access with no expiry. `last_accessed_at` tracks the member's most recent activity.

**Download Tracking**
Seven fields track download activity: `is_downloaded` (boolean), `download_count`, `first_downloaded_at`, `last_downloaded_at`, `last_download_ip` (VARCHAR 45), `last_download_device` (ENUM: Desktop/Mobile/Tablet/Other), `last_download_user_agent` (VARCHAR 500), and `download_history_json` (JSON array of download events).

**Online View Tracking**
`view_count`, `total_view_duration_sec` (updated via heartbeat endpoint), `last_view_ip`, and `last_view_device` (ENUM: Desktop/Mobile/Tablet/Kiosk/Other) track online reading sessions.

**Grant and Revocation**
`granted_by_id` (FK to `sys_users`) records who approved the access. `revoked_by_id`, `revoked_by_system` (boolean — true if auto-revoked by background service), `revoked_at`, and `revocation_reason` (VARCHAR 255) track revocation details.

**Status**
`status` is an FK to `lib_library_status_masters.id` for `Digital Access Transaction Status` — possible codes: 'Active', 'Expired', 'Revoked', 'Completed'. The `getStatusBadgeAttribute()` method on the model renders appropriate HTML badges (e.g., Active = green, Expired = dark, Revoked = secondary).

---

## Business Rules and Conditions

**Status Transitions**
Status follows: `Active` → `Expired` (scheduled job when `access_expires_at < NOW()`), `Active` → `Revoked` (manual librarian action), `Active` → `Completed` (member explicitly closes or license is consumed). Once revoked, access cannot be restored — the member must submit a new request.

**Revocation Process**
Revocation requires a mandatory `revocation_reason` (validated: required|string|max:500). The `revokeTransaction()` method in `LibDigitalAccessRequestController` captures OLD state before update, sets `revoked_at`, `revoked_by_id`, `revoked_by_system` (false for manual), and `revocation_reason`. It then creates a `LibTransactionHistory` record with `digital_book_action_type = 'Access_Revoked'` containing both old and new values as JSON. A notification event `LIBRARY_DIGITAL_ACCESS_REVOKED` is sent to the member.

**Heartbeat Tracking**
The `heartbeat()` method accepts `total_duration_sec` (required|integer|min:1) from the client-side viewer JS and updates `total_view_duration_sec` and `last_accessed_at` on the transaction record. No authentication is performed beyond route model binding — the endpoint is designed for authenticated viewer sessions only.

**Device Detection**
The model's static `detectDevice(?string $userAgent)` method parses the User-Agent string to classify the device as Desktop, Mobile, Tablet, or Other. This is called during download and view tracking to populate the device type fields.

**No Direct Create via UI**
Transactions are only created programmatically through the approval flow in `LibDigitalAccessRequestController::approve()`. There is no standalone create form for transactions. The only direct librarian actions are viewing, filtering, revoking, and heartbeat updates.

---

## Workflow Steps

1. Transaction is automatically created when a digital access request is approved
2. Librarian navigates to Library Operations → Digital Access tab
3. View the list of all transactions with member name, book title, access type, start/expiry dates, and status
4. Filter by member name, book title, status, or access type
5. For active sessions, click **Revoke** opens a modal requiring a revocation reason
6. Enter the reason and confirm — the session is immediately revoked:
   a. `revoked_at`, `revoked_by_id`, `revocation_reason` are set
   b. `LibTransactionHistory` records the revocation with old/new state
   c. Notification sent to the member
7. Expired transactions are automatically handled by a scheduled background job
8. Heartbeat updates from the client-side viewer keep `total_view_duration_sec` and `last_accessed_at` current

---

## Example Scenario

A teacher's digital access to "Advanced Physics" was approved last week with a 30-day access window. The teacher has been reading the e-book online, and the client-side viewer sends heartbeat updates every 60 seconds, accumulating a total viewing duration of 4 hours. The teacher leaves the school mid-term. The librarian navigates to Digital Access Transactions, finds the active session, clicks Revoke, enters "Teacher has resigned — access must be terminated," and confirms. The system immediately sets `revoked_at` to now, logs the before-and-after state to `LibTransactionHistory`, and sends the teacher a notification: "Your access for 'Advanced Physics' has been revoked. Reason: Teacher has resigned." The teacher can no longer open the e-book.

---

## Related Screens

- **Digital Access Requests** — Origin of transactions (approval creates these records)
- **Digital Resources** — The resources being accessed
- **Digital Access Request Types** — Define the access type mapping
- **Library Operations Hub** — Parent hub containing the Digital Access tab
- **Transaction History** — Audit trail records created during grant and revocation

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibDigitalAccessRequestController` (handles transactions via `revokeTransaction()` and `heartbeat()`)
**Model:** `Modules\Library\Models\LibDigitalAccessTransaction` (table: `lib_digital_access_transactions`)
**Request:** None — revocation and heartbeat validation are inline in controller methods
**Policy:** None — uses `Gate::authorize()` with string permissions
**Route:** `POST /lib-digital-access-transactions/{id}/revoke` and `POST /lib-digital-access-transactions/{id}/heartbeat`

Key controller methods (shared with Digital Access Requests):
- `revokeTransaction($id, Request)` — Validates revocation_reason (required|string|max:500), captures old state, updates revoked fields, creates LibTransactionHistory (Access_Revoked), sends notification, permission: `tenant.lib-digital-access-requests.update`
- `heartbeat($id, Request)` — Validates total_duration_sec (required|integer|min:1), updates total_view_duration_sec and last_accessed_at, returns JSON success

The hub query (in `LibraryController::transactionIndex`) loads transactions with: member.user, book, digitalResource, accessRequest, grantedBy, statusMaster. Paginated at 15 with 'da_tx_page' paginator name.

---

## Who Can Access

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.lib-digital-access-transactions.*` | Full access (bypasses policy via Gate::before) |
| Library Admin | `tenant.lib-digital-access-transactions.*` | View all transactions + revoke access |
| Librarian | `tenant.lib-digital-access-transactions.viewAny`, `.view` | View only (revoke delegated to admin) |
| Library Assistant | `tenant.lib-digital-access-transactions.viewAny`, `.view` | View only |

**Note:** The `revokeTransaction()` method uses `Gate::authorize('tenant.lib-digital-access-requests.update')` — so the permission to revoke is tied to the Digital Access Requests update permission, not the transactions permission.

---

## How This Screen Works — Logic Flow (Non-Technical)

When a member's digital access request is approved, the system automatically creates an access session record with a start time and an expiry date calculated from the member's membership plan. The librarian can see all active and past sessions in a table — who accessed what, when the access expires, and when they last viewed it. Active sessions show a "Revoke" button. Clicking it asks for a reason, and when confirmed, the access is immediately cut off. The system logs exactly what changed and notifies the member. The viewing duration is updated live as the member reads the e-book online, with the browser sending small updates to the server every minute or so. Expired sessions are marked automatically by a background job that checks the expiry date against the current time.

---

## Validate Before Save

| # | Field | Rule | Error Message |
|---|---|---|---|
| 1 | revocation_reason | Required, string, max:500 | The revocation reason field is required. |
| 2 | total_duration_sec | Required, integer, min:1 | Invalid duration value. |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Revoke — validation fails | The revocation reason field is required. | 422 (JSON or redirect) |
| Revoke — transaction not found | No query results for model [LibDigitalAccessTransaction] | 404 |
| Heartbeat — validation fails | The total duration sec must be at least 1. | 422 (JSON) |
| Heartbeat — transaction not found | No query results for model [LibDigitalAccessTransaction] | 404 (JSON) |
| Gate authorization fails (revoke) | This action is unauthorized. | 403 |

---

## Success Scenarios

**SC-001: Revoke an active transaction**
1. Librarian finds an active session for a member who left the school
2. Clicks Revoke, enters reason "Member resigned", confirms
3. System updates: `revoked_at = now()`, `revoked_by_id = librarian`, `revoked_by_system = false`, `revocation_reason = "Member resigned"`
4. LibTransactionHistory records old and new state with action_type 'Access_Revoked'
5. Notification sent to member: "Your access for 'Book Title' has been revoked."
6. Success flash or JSON response: "Digital access revoked successfully."

**SC-002: Heartbeat updates viewing duration**
1. Member reads an e-book online for 30 minutes
2. Client-side JS sends heartbeat POST with `total_duration_sec = 1800`
3. System updates `total_view_duration_sec` to 1800 and `last_accessed_at` to now
4. JSON response: `{ success: true }`

---

## Failure Scenarios

**FC-001: Revoke without providing a reason**
1. Librarian clicks Revoke but leaves the reason field empty
2. Controller validation fails: "The revocation reason field is required."
3. Transaction remains active

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | lib_digital_access_transactions | Main transaction table with access window, download/view tracking, revocation fields |
| Table | lib_digital_access_requests | Parent request (optional FK: access_request_id, SET NULL on delete) |
| Table | lib_digital_resources | The resource being accessed (FK: digital_resource_id, RESTRICT on delete) |
| Table | lib_books_master | Book record (FK: book_id, RESTRICT on delete) |
| Table | lib_members | Member accessing (FK: member_id, RESTRICT on delete) |
| Table | lib_membership_types | Defines digital_access_days for expiry calculation |
| Table | lib_library_status_masters | Dynamic status (Digital Access Transaction Status) |
| Table | lib_transaction_history | Audit trail for access grants and revocations |
| Table | sys_users | Tracks granted_by and revoked_by |
| Module | Library Operations Hub | Parent hub containing the Digital Access tab |
| Module | Library Digital Access Requests | Source of transaction creation |
| Module | Notifications | Sends revocation notification events |
