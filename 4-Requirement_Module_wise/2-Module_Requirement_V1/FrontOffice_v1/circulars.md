# Circular Management — Requirements

## What It Does
Official school circulars with full lifecycle management: Draft → Approval → Distribution → Recall. Supports rich text content, PDF attachments, audience targeting (Parents, Staff, Both, Specific Class/Section), and automated NTF distribution (Email + SMS per recipient).

**Circular Distributions** is an append-only immutable log — no soft delete, no update/delete routes.

## Database Fields

### fof_circulars

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `circular_number` | VARCHAR(30) | Required. Unique. Auto-generated: `CIR-YYYY-NNNN`. |
| `title` | VARCHAR(200) | Required. |
| `subject` | VARCHAR(300) | Required. |
| `body` | LONGTEXT | Required. Rich text HTML. |
| `audience` | ENUM('Parents','Staff','Both','Specific_Class','Specific_Section') | Required. |
| `audience_filter_json` | JSON | Nullable. Class/section IDs for Specific_* audiences. |
| `effective_date` | DATE | Required. |
| `expires_on` | DATE | Nullable. |
| `attachment_media_id` | INT UNSIGNED FK → `sys_media` | Nullable. Optional PDF attachment. |
| `status` | ENUM('Draft','Pending_Approval','Approved','Distributed','Recalled') | Default 'Draft'. |
| `approved_by` | INT UNSIGNED FK → `sys_users` | Nullable. |
| `approved_at` | DATETIME | Nullable. |
| `distributed_at` | DATETIME | Nullable. |
| `distributed_by` | INT UNSIGNED FK → `sys_users` | Nullable. |

### fof_circular_distributions (Append-Only)

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `circular_id` | BIGINT UNSIGNED FK → `fof_circulars` | Required. |
| `recipient_user_id` | INT UNSIGNED FK → `sys_users` | Required. |
| `channel` | ENUM('Email','SMS','Push') | Required. |
| `status` | ENUM('Queued','Sent','Delivered','Failed') | Default 'Queued'. |
| `sent_at` | TIMESTAMP | Nullable. |
| `delivered_at` | TIMESTAMP | Nullable. |
| `read_at` | TIMESTAMP | Nullable. |
| `ntf_log_id` | BIGINT UNSIGNED | Nullable. NTF module reference. |

**Exception:** This table has no `deleted_at`, no `updated_by` — it is an immutable append-only log.

## Business Rules

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-FOF-008 | Circular editing blocked once status is Approved or Distributed | `update` route returns HTTP 403 for status ≥ Approved |

**Lifecycle (Strict FSM)**
```
Draft → Pending_Approval → Approved → Distributed → [Recalled]
                                              ↕
                                         Recalled
```
- `update` available only in Draft and Pending_Approval statuses
- `approve`: Pre-condition status = 'Pending_Approval'
- `distribute`: Pre-condition status = 'Approved'
- `recall`: Available from Distributed status (already-sent NTFs cannot be recalled)

**Distribution Flow**
1. `CircularService::distribute()` validates status = 'Approved'
2. Resolves recipient list from audience:
   - Parents/Both: all parent sys_users with students in target classes
   - Staff/Both: all staff sys_users
   - Specific_Class/Section: filter by audience_filter_json
3. In a DB transaction:
   - For each recipient: INSERT circular_distribution (Queued), dispatch NTF job per channel
   - UPDATE circular status = 'Distributed', distributed_at = NOW(), distributed_by

## CRUD Operations

**Create**
- `POST /front-office/circulars` — validates title, subject, body, audience, effective_date; generates circular_number CIR-YYYY-NNNN

**Edit**
- `PUT /front-office/circulars/{circular}` — blocked if status ≥ Approved (BR-FOF-008)

**Approve**
- `PATCH /front-office/circulars/{circular}/approve` — sets approved_by, approved_at, status = 'Approved'

**Distribute**
- `PATCH /front-office/circulars/{circular}/distribute` — triggers bulk NTF dispatch

**List**
- Tabs: Draft / Pending Approval / Approved / Distributed
- Status badges; approve/distribute buttons per status

## Permissions

| Operation | Permission Key |
|---|---|
| View circulars | `frontoffice.circular.view` |
| Create/update circular | `frontoffice.circular.create` |
| Approve circular | `frontoffice.circular.approve` |
| Distribute circular | `frontoffice.circular.distribute` |
