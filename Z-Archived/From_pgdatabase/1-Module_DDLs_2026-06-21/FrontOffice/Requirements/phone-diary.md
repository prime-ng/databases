# Phone Call Log (Phone Diary) — Requirements

## What It Does
Records incoming and outgoing phone calls handled by the front desk. Supports action tracking — calls requiring follow-up can be flagged and later marked as completed. Inline create form embedded in the index page for quick logging.

## Database Fields

### fof_phone_diary

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `call_type` | ENUM('Incoming','Outgoing') | Required. Direction of call. |
| `call_date` | DATE | Required. Date of call. |
| `call_time` | TIME | Required. Time of call. |
| `caller_name` | VARCHAR(100) | Required. Caller name (Incoming) or person called (Outgoing). |
| `caller_number` | VARCHAR(15) | Nullable. Phone number. |
| `caller_organization` | VARCHAR(100) | Nullable. Organization of caller. |
| `recipient_name` | VARCHAR(100) | Nullable. Staff who took/made the call. |
| `recipient_user_id` | INT UNSIGNED FK → `sys_users` | Nullable. Linked staff member. |
| `purpose` | VARCHAR(200) | Required. Call purpose summary. |
| `message` | TEXT | Nullable. Full call notes. |
| `action_required` | TINYINT(1) | Default 0. 1 = follow-up pending. |
| `action_notes` | TEXT | Nullable. What action is required. |
| `action_completed` | TINYINT(1) | Default 0. 1 = action resolved. |

## Business Rules
- `action_required = 1` highlights the entry in the list for attention
- `action_completed` can be toggled by PATCH to resolve the follow-up
- `call_type` determines context: Incoming → caller is external; Outgoing → school initiated the call

## CRUD Operations

**Log Call**
- `POST /front-office/phone-diary` — inline form embedded in index page
- No dedicated create page (inline create only)

**Mark Action Completed**
- `PATCH /front-office/phone-diary/{phoneDiary}` — toggles `action_completed = 1`

**List**
- Filter tabs: Incoming / Outgoing
- Action-required entries highlighted
- Search by caller name, recipient, date range

## Permissions

| Operation | Permission Key |
|---|---|
| View phone diary | `frontoffice.visitor.view` |
| Log/update calls | `frontoffice.visitor.create` |
