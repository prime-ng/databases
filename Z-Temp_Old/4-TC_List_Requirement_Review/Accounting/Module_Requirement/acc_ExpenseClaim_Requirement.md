# Expense Claim — Business Requirements

## What This Screen Does

The Expense Claim screen manages employee expense reimbursement requests. It supports a complete workflow: Draft → Submitted → Approved (with optional approval levels) → Paid. On approval, the system auto-generates a payment voucher. Claims can be partially paid.

## When This Screen Is Used

- **When employees incur business expenses** and need reimbursement (travel, supplies, etc.).
- **At month-end** when processing bulk expense claims.
- **When approving/rejecting** expense claims from subordinates.
- **When making payments** for approved expense claims.

## Key Fields

- **Claim Code** (string, unique) — Auto-generated claim identifier
- **Employee** (FK → hrs_employees) — Claimant
- **Claim Date** (date) — Date of claim submission
- **Total Amount** (decimal 15,2) — Sum of all claim items
- **Paid Amount** (decimal 15,2) — Amount actually paid (partial payment supported)
- **Status** (enum: draft/submitted/approved/paid/rejected/cancelled) — Lifecycle state
- **Approved By / Approved At** — Approval trail
- **Paid By / Paid At** — Payment trail
- **Narration** (text, nullable)

**Claim Items (Child):**
- **Expense Date** (date)
- **Ledger** (FK → acc_ledgers) — Expense account
- **Amount** (decimal 15,2)
- **Description** (text)
- **Receipt Attachment** (media, nullable)

## Business Rules

**Complete Workflow:**
Draft → Submit → Approve (with optional multi-level approval) → Paid. Status transitions are strictly enforced. Voucher is auto-generated on approval.

**Auto-Voucher on Approval:**
When an expense claim is approved, the system automatically creates and posts a payment voucher using the claim's expense ledgers and employee's payable ledger. The voucher references the claim code.

**Partial Payment:**
An approved claim can be partially paid. The `paid_amount` tracks cumulative payments. When `paid_amount = total_amount`, status moves to "paid."

**Delete Guard:**
Claims in "draft" or "rejected" status can be deleted. Claims in "submitted" or "approved" cannot be deleted. "Paid" claims are locked.

**Critical is_approved Guard:**
The `is_approved` property guard in the controller may be broken or reference a non-existent column, allowing unauthorized status transitions.

**Critical Broken Show View:**
The show view's workflow action buttons may not correctly reflect the current status, potentially allowing users to submit already-approved claims or approve already-paid claims.

## Workflow

1. User navigates to Accounting → Transactions → Expense Claims.
2. Tab filters: All, Draft, Submitted, Approved, Paid, Rejected.
3. User creates a claim: adds items with expense date, ledger, amount, description, optional receipt attachment.
4. Submits for approval. Approver reviews items and either approves or rejects.
5. On approval, system auto-creates payment voucher.
6. Finance user processes payment (full or partial).
7. Payment updates paid_amount. When fully paid, status = "paid."

## Requirements

- MUST display at `/accounting/expense-claim?tab=expense-claims` with status sub-tabs
- MUST authorize via `tenant.accounting.expense-claim.*` policy gates
- MUST enforce strict status transitions (draft → submitted → approved → paid)
- MUST auto-generate payment voucher on approval
- MUST support partial payment with paid_amount tracking
- MUST prevent modification of approved/paid claims
- MUST prevent deletion of submitted/approved claims
- MUST support receipt attachment via media library
- MUST support is_active toggle via Ajax
- MUST support soft delete with trash view, restore, forceDelete
- **CRITICAL:** Fix broken `is_approved` property guard
- **CRITICAL:** Fix show view workflow action buttons
