# Key Management Register — Requirements

## What It Does
Tracks physical keys (classroom, lab, vehicle, cabinet, store) issued to staff. A key can only be in one status at a time. Keys past expected return time are auto-flagged as `Overdue`. `NULL` in `issued_to_user_id` means the key is currently available.

## Database Fields

### fof_key_register

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `key_label` | VARCHAR(100) | Required. e.g., "Science Lab A Key". |
| `key_tag_number` | VARCHAR(30) | Required. Physical tag/number. |
| `key_type` | ENUM('Room','Lab','Vehicle','Cabinet','Store','Other') | Required. |
| `issued_to_user_id` | INT UNSIGNED FK → `sys_users` | Nullable. NULL = key available. |
| `purpose` | VARCHAR(200) | Nullable. Reason for issue. |
| `issued_at` | DATETIME | Nullable. Issue timestamp. |
| `expected_return_at` | DATETIME | Nullable. |
| `returned_at` | DATETIME | Nullable. Actual return timestamp. |
| `status` | ENUM('Available','Issued','Overdue','Lost') | Default 'Available'. |

## Business Rules

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-FOF-012 | Key can only be issued if status = 'Available' | `issue` route checks and blocks if Issued/Overdue/Lost |

**Status Lifecycle**
```
Available → Issued → Overdue (auto when past expected_return_at)
                → Lost (manual)
                → Returned → Available
```

**Issue Flow**
1. Pre-condition: `status = 'Available'`
2. Sets `issued_to_user_id`, `purpose`, `issued_at = NOW()`, `expected_return_at`
3. Status becomes 'Issued'

**Return Flow**
1. Pre-condition: `status` is 'Issued' or 'Overdue'
2. Sets `returned_at = NOW()`, `issued_to_user_id = NULL`
3. Status becomes 'Available'

**Overdue Detection**
- Automated: keys where `status = 'Issued'` and `expected_return_at < NOW()` are flagged Overdue
- Can be run via scheduled check or checked on dashboard load
- API endpoint: `GET /api/v1/front-office/keys/overdue`

## CRUD Operations

**Add Key**
- `POST /front-office/keys` — creates a new key record with key_label, key_tag_number, key_type

**Issue Key**
- `PATCH /front-office/keys/{key}/issue` — checks Available status, sets issue details

**Return Key**
- `PATCH /front-office/keys/{key}/return` — clears issued_to, sets returned_at, status → Available

**Mark Lost**
- Manual status update to 'Lost'

**List**
- Status badges: Available (green) / Issued (blue) / Overdue (red) / Lost (gray)
- Issue/return actions inline

## Permissions

| Operation | Permission Key |
|---|---|
| View key register | `frontoffice.visitor.view` |
| Add/issue/return keys | `frontoffice.visitor.create` |
