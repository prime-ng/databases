---
globs: ["Modules/StudentFee/**", "database/migrations/tenant/*fee*", "database/migrations/tenant/*fin_*"]
---

# StudentFee Module Rules

## Module Context
- 9 controllers, 20 models, 0 services
- Table prefix: `fin_*` (~21 tables)
- Route prefix: `/student-fee/*`
- Status: ~80% complete

## Key Tables
- `fin_fee_structure_masters`, `fin_fee_structure_details`
- `fin_fee_head_masters`, `fin_fee_group_masters`
- `fin_fee_invoices`, `fin_fee_receipts`, `fin_fee_transactions`
- `fin_fee_concession_types`, `fin_fee_scholarships`
- `fin_fee_fine_rules`, `fin_fee_fine_transactions`

## Business Rules
- Fee structures are school-specific — never share across tenants
- Fee heads defined per school
- Concession types per school
- Fine rules per school
- Invoices track: student, academic session, installment, amount, discount, fine, net payable

## Missing Features
- Payment gateway integration flow (SEC-004 breaks Razorpay webhooks)
- Bulk invoice generation
- Comprehensive reporting

## Known Bug
- BUG-007: `Student::currentFeeAssignment()` crashes if no current session — needs `?->id`
