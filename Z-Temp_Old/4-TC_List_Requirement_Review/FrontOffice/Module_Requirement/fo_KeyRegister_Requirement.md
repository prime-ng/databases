# Key Register — Business Requirements

## What This Screen Does

The Key Register tracks physical keys for school premises. Keys have Available, Issued, or Overdue status. Staff can register new keys, issue keys to staff with expected return dates, and process returns. Overdue keys are highlighted with red danger styling.

## When This Screen Is Used

- **Key Inventory**: Maintaining a register of all physical keys
- **Key Issuance**: Issuing keys to staff with expected return dates
- **Overdue Tracking**: Identifying keys not returned on time
- **Audit Trail**: History of key movements

## Key Fields

- **key_label** (string) — Key name/description
- **key_tag_number** (string, nullable) — Key code/tag number
- **key_type** (string, nullable) — e.g., Master, Cabinet, Classroom
- **status** (enum) — Available, Issued, Lost, Damaged, Retired
- **issued_to_user_id** (FK → sys_users, nullable)
- **issued_at** (datetime, nullable)
- **expected_return_at** (datetime, nullable)
- **returned_at** (datetime, nullable)
- **remarks** (text, nullable)

## Business Rules

**Three Sections:** Available (green success border with "Issue" button) → Issued (blue primary border with "Return" button) → Overdue (red danger border with "Return" button). Each shows count header.

**Overdue:** Keys where status=Issued and `expected_return_at < now()` appear in the Overdue section with red border and "Overdue" badge. The `expected_return_at` value is shown in red.

**Issue Modal:** Opens per available key, requires `expected_return_at` (datetime). Uses `fof.keys.issue` route (PATCH).

**Return Modal:** Opens per issued/overdue key with optional remarks. Uses `fof.keys.return` route (PATCH).

**Register Modal:** Creates new key with `key_label` (required) and `key_tag_number` (optional).

## Requirements

- MUST display in Registers tab group with Available → Issued → Overdue sections
- MUST authorize via `frontoffice.key-register.*` policy gates
- MUST show overdue keys in red danger section at top
- MUST support Issue action (sets status=Issued, issued_at, expected_return_at)
- MUST support Return action (sets status=Available, returned_at)
- MUST support status toggle via Ajax
- MUST register new keys via modal form
- MUST search across key_label, key_tag_number, status
