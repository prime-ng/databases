# CommonChat Tab 7: Message Search & History

This screen allows users to search through their entire chat history across all conversations they are a member of. The search scans message text and returns matching results with context, helping users quickly find past discussions, decisions, or shared information.

---

## How It Works

The user accesses search from the dashboard via a search bar at the top of the screen. As they type, the system begins searching through all messages in all conversations they participate in. Results are displayed as a list, with each result showing the matched message text (with the search term highlighted), the conversation name it belongs to, the sender's name, and the timestamp.

Below each matched message, the system shows two previous messages and two following messages as context, so the user can understand the surrounding conversation without having to open the full chat. The user can click any result to jump directly to that message within its conversation, with the conversation scrolled to the correct position.

The user can optionally filter results by a specific conversation or by date range. The search respects all access controls — a user will never see results from conversations they are not a member of.

---

## Important Business Rules

- Search is limited to conversations the requesting user is currently an active participant of. This is enforced at every search query.
- Deleted messages (`is_deleted = 1`) are excluded from search results entirely.
- The search scans message body text using a LIKE search on the `cht_messages.body` column.
- A maximum of 50 search results is returned per query. If more matches exist, the user is prompted to narrow their search.
- Cross-conversation search is supported within the user's own conversations. Cross-tenant search is not possible.
- Each result includes up to 2 context messages before and 2 after the matched message, fetched via a separate query against the same conversation.
- Search results include the conversation name (or the other participant's name for DMs) and the sender's display name.
- The search does not search through file names or attachment content in Phase 1. Only message body text is searched.
- The user must type at least 2 characters before search is triggered to avoid returning too many results.

---

## Database Columns & Behavior

### cht_messages
- `id` — BIGINT UNSIGNED PK. Message identifier. Used to link search results to the actual message.
- `conversation_id` — BIGINT UNSIGNED FK. Filters search to only conversations the user belongs to.
- `sender_id` — INT UNSIGNED FK. Displayed alongside the result. JOINed to sys_users for the sender name.
- `body` — VARCHAR(2000) NULL. The searchable content. Searched with LIKE %term% pattern.
- `is_deleted` — TINYINT(1). Excluded from search when 1.
- `message_type` — ENUM('Text','Attachment','System'). System messages and attachment-only messages may have NULL body and are generally not useful search targets.
- `created_at` — TIMESTAMP. Displayed with the result. Used for sort order within result sets.

### cht_conversations
- `id` — BIGINT UNSIGNED PK. Used for JOIN and display.
- `conversation_type` — ENUM('Direct','Group','Announcement'). Determines how the conversation name is displayed.
- `name` — VARCHAR(150) NULL. Shown for groups and announcements. For DMs, the display name is derived from sys_users.

### cht_participants
- `id` — BIGINT UNSIGNED PK. Used to verify user membership before returning search results.
- `conversation_id` — BIGINT UNSIGNED FK. JOINed to messages for membership check.
- `user_id` — INT UNSIGNED FK. The searching user's ID. Only conversations where this user has an active (left_at IS NULL) participant record are searchable.
- `left_at` — TIMESTAMP NULL. Participants who have left a group cannot search that group's messages.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|-------|---------|------------|-------|
| Idle (no search) | User types ≥2 characters in search bar | Searching (debounced) | Debounce timer (300ms) before API call |
| Searching | API returns results | Results displayed | List with matched message + 2 context messages before/after |
| Searching | API returns no results | Empty results state | "No messages found matching your search." |
| Results displayed | User types additional characters | Refine search | New API call with updated query string |
| Results displayed | User clears search input | Idle (no search) | Results cleared |
| Results displayed | User clicks a result | Navigate to conversation | Conversation opened and scrolled to the matched message position |
| Results displayed | User applies conversation filter | Filtered results | API call with `conversation_id` parameter |
| Results displayed | User applies date range filter | Filtered results | API call with `date_from` / `date_to` parameters |

- The search uses `LIKE %term%` on `cht_messages.body`. For Phase 1, no full-text index or Elasticsearch is used. Performance considerations: large message volumes may require moving to MySQL FULLTEXT index or dedicated search service in Phase 2.
- Context messages (2 before, 2 after) are fetched via a separate query on the same `conversation_id` using `created_at` ordering. Only non-deleted messages are returned as context.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|----------------|------|---------------|
| Minimum query length | Must be ≥ 2 characters | "Please enter at least 2 characters to search." |
| Maximum results | Cap at 50 results per query | "Too many results. Please refine your search." |
| Membership filter | Only conversations where user is active participant (`left_at IS NULL`) | N/A — silent filter; no error returned |
| Deleted messages | `is_deleted = 1` excluded from search | N/A — silent exclusion |
| Cross-conversation search | All user's active conversations are searchable | N/A — no restriction beyond membership |
| Cross-tenant search | Not supported | N/A — tenant-scoped data only |
| Attachment content search | Not searched in Phase 1 | N/A — phase limitation |
| Context message visibility | Context messages obey same `is_deleted` filter | N/A — silent exclusion |
| Left group messages | `left_at` IS NOT NULL → group excluded from search | N/A — silent exclusion |
| No results | Query returns empty set | "No messages found matching your search." |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| CommonChat | `cht_messages` | `conversation_id` → `cht_conversations.id` | Search target; JOIN for conversation filter |
| CommonChat | `cht_messages` | `sender_id` → `sys_users.id` | Display sender name alongside result |
| CommonChat | `cht_conversations` | `id` | Conversation name display; type differentiation (DM vs Group) |
| CommonChat | `cht_participants` | `conversation_id`, `user_id` | Membership verification gate |
| System | `sys_users` | N/A (JOIN on `sender_id`) | Sender display name; DM partner name derivation |

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| Search messages | Any active conversation participant | Implicit — must have `left_at IS NULL` in `cht_participants` |
| Filter by conversation | Any active participant of that conversation | Implicit — membership check on filter parameter |
| Click result to navigate | Any active participant of the result's conversation | Implicit — membership check on navigation |
| Search across all conversations | Any user with at least one active conversation | Implicit — scope limited to user's active memberships
