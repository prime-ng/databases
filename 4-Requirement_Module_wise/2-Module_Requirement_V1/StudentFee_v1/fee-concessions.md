# Fee Concessions — Requirements

## What It Does
Defines discount/concession types applicable to student fees. Supports percentage or fixed amount discounts applied to total fee, specific heads, or specific groups. Concessions can require approval workflow with role-based authorization. Student-level concession applications with approval/rejection workflow.

Features:
- 7 standard concession types: Sibling (10%), Merit (25%), Staff (50%), Financial Aid (₹5,000), Sports (15%), Alumni (5%), Special
- Percentage or fixed amount discount
- Applicable on: total fee, specific heads, or specific groups
- Configurable max cap amount
- Optional approval workflow with role-based level
- Student concession application with Pending/Approved/Rejected workflow
- Soft-delete with full restore

## Database Fields

**fee_concession_types**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `code` | VARCHAR(50) | Required. Short code: `SIBLING`, `MERIT`, `STAFF`, `FINANCIAL_AID`, `SPORTS`, `ALUMNI`, `SPECIAL`. |
| `name` | VARCHAR(200) | Required. Display name. |
| `concession_category_id` | BIGINT UNSIGNED FK → `sys_dropdowns` | Required. Category classification. |
| `discount_type` | ENUM | `Percentage`, `Fixed Amount`. |
| `discount_value` | DECIMAL(10,2) | Required. If Percentage: e.g., 10.00 = 10%. If Fixed: e.g., 5000.00. |
| `applicable_on` | ENUM | `Total Fee`, `Specific Heads`, `Specific Groups`. |
| `max_cap_amount` | DECIMAL(12,2) | Nullable. Maximum discount amount cap. |
| `requires_approval` | BOOLEAN | Default false. Whether concession needs approval. |
| `approval_level_role_id` | BIGINT UNSIGNED FK → `sys_roles` | Nullable. Which role can approve. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**fee_concession_applicable_heads** (Junction)

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `concession_type_id` | BIGINT UNSIGNED FK → `fee_concession_types` | Required. |
| `head_id` | BIGINT UNSIGNED FK → `fee_head_masters` | Nullable. Specific head mapping. |
| `group_id` | BIGINT UNSIGNED FK → `fee_group_masters` | Nullable. Specific group mapping. |

**fee_student_concessions**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_assignment_id` | BIGINT UNSIGNED FK → `fee_student_assignments` | Required. |
| `concession_type_id` | BIGINT UNSIGNED FK → `fee_concession_types` | Required. |
| `approved_by` | BIGINT UNSIGNED FK → `sys_users` | Nullable. Set on approval. |
| `approved_at` | DATETIME | Nullable. Set on approval. |
| `approval_status` | ENUM | `Pending`, `Approved`, `Rejected`. |
| `rejection_reason` | VARCHAR(255) | Nullable. |
| `discount_amount` | DECIMAL(10,2) | Nullable. Computed discount amount. |
| `remarks` | TEXT | Nullable. |
| `created_by` | BIGINT UNSIGNED FK → `sys_users` | Who applied the concession. |

## Business Rules

**Discount Computation**
- `Percentage` type on `Total Fee`: `discount = total_fee × (discount_value / 100)`
- `Percentage` type on `Specific Heads`: `discount = sum(specific_head_amounts) × (discount_value / 100)`
- `Fixed Amount` type: `discount = min(discount_value, total_fee)` — direct amount
- If `max_cap_amount` is set: `discount = min(computed_discount, max_cap_amount)`

**Applicable On Behavior**
- `Total Fee`: Discount applies to the entire fee amount
- `Specific Heads`: Discount applies only to mapped heads (via `fee_concession_applicable_heads.head_id`)
- `Specific Groups`: Discount applies only to mapped groups (via `fee_concession_applicable_heads.group_id`)

**Student Concession Workflow**
1. Admin creates a `FeeStudentConcession` linked to a student's fee assignment
2. Default status: `Pending`
3. If `requires_approval = false`: discount is auto-approved (status → `Approved`)
4. If `requires_approval = true`: approval from the specified role is required
5. Approve: sets `approved_by`, `approved_at`, status → `Approved`
6. Reject: sets `rejection_reason`, status → `Rejected`
7. Once approved, `discount_amount` is computed and stored

**Concession Stacking**
- Multiple concessions can be applied to the same student assignment
- But only one concession of a given type per assignment
- Discounts are additive (not compound)

## CRUD Operations

**List Concession Types**
- Shows: code, name, type, value, applicable on, approval required

**Create Concession Type**
- Validation: discount_type in Percentage/Fixed Amount, applicable_on in enum
- If applicable_on = Specific Heads: select heads/ groups to map
- Approval toggle shows role selector

**List Student Concessions**
- Shows: student, concession type, discount amount, approval status
- Filterable by: approval status, student, concession type

**Create Student Concession**
- Select: student assignment, concession type
- Discount amount auto-computed and previewed

**Approve / Reject**
- Via update: set status to Approved or Rejected
- If approved: `discount_amount` is finalized, used in invoice computation

## Permissions

| Operation | Permission Key |
|---|---|
| View concession types | `tenant.fee-concession-type.viewAny` |
| Manage concession types | `tenant.fee-concession-type.*` |
| View student concessions | `tenant.fee-student-concession.viewAny` |
| Create / Update student concessions | `tenant.fee-student-concession.*` |
