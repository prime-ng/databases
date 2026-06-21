# Postal & Dispatch Registers — Requirements

## What It Does
Two separate but related registers for school correspondence tracking:

1. **Postal Register** — Inward/outward mail and courier items with acknowledgement locking
2. **Dispatch Register** — Official outgoing correspondence log (letters, notices, certificates, etc.)

## Database Fields

### fof_postal_register

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `postal_type` | ENUM('Inward','Outward') | Required. Direction. |
| `postal_number` | VARCHAR(30) | Required. Unique. Auto-generated: `IN-YYYY-NNNN` or `OUT-YYYY-NNNN`. |
| `postal_date` | DATE | Required. |
| `sender_name` | VARCHAR(100) | Nullable. For Inward. |
| `sender_address` | VARCHAR(200) | Nullable. |
| `recipient_name` | VARCHAR(100) | Nullable. For Outward. |
| `recipient_address` | VARCHAR(200) | Nullable. |
| `document_type` | ENUM('Letter','Courier','Parcel','Government_Notice','Cheque','Legal','Other') | Required. |
| `subject` | VARCHAR(200) | Required. |
| `courier_company` | VARCHAR(100) | Nullable. |
| `tracking_number` | VARCHAR(100) | Nullable. |
| `department` | VARCHAR(100) | Nullable. |
| `assigned_to_user_id` | INT UNSIGNED FK → `sys_users` | Nullable. Staff assigned to follow up. |
| `acknowledgement_by` | VARCHAR(100) | Nullable. Person who acknowledged receipt. |
| `acknowledged_at` | DATETIME | Nullable. Once set, record is locked (BR-FOF-009). |
| `remarks` | TEXT | Nullable. |

### fof_dispatch_register

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `dispatch_number` | VARCHAR(30) | Required. Unique. Auto-generated: `DSP-YYYY-NNNN`. |
| `dispatch_date` | DATE | Required. |
| `addressee_name` | VARCHAR(100) | Required. |
| `addressee_address` | VARCHAR(200) | Nullable. |
| `subject` | VARCHAR(200) | Required. |
| `document_type` | ENUM('Letter','Notice','Legal','Certificate','Report','Circular','Other') | Required. |
| `dispatch_mode` | ENUM('Hand','Post','Courier','Email','Fax') | Required. |
| `reference_number` | VARCHAR(100) | Nullable. |
| `copy_retained` | TINYINT(1) | Default 1. Copy kept at school. |
| `dispatched_by` | INT UNSIGNED FK → `sys_users` | Nullable. |
| `remarks` | TEXT | Nullable. |

## Business Rules

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-FOF-009 | Postal record locked after acknowledgement — no further edits | `acknowledged_at` set once; update route checks and blocks if already set |

**Postal Register Locking**
- Acknowledgement sets `acknowledged_at = NOW()` and `acknowledgement_by`
- Once acknowledged, the record is immutable (edit blocked at controller level)
- Index has Inward/Outward tabs with date and type filters

## CRUD Operations

**Postal Register**
- `POST /front-office/postal-register` — creates with auto-generated postal_number (IN- or OUT- prefix)
- `PATCH /front-office/postal-register/{postal}/acknowledge` — locks the record
- List: Inward/Outward tabs, filterable by date and document type

**Dispatch Register**
- `POST /front-office/dispatch-register` — creates with auto-generated DSP-YYYY-NNNN
- List: filterable by date, dispatch mode, document type

## Permissions

| Operation | Permission Key |
|---|---|
| View registers | `frontoffice.visitor.view` |
| Create/acknowledge | `frontoffice.visitor.create` |
