# StudentFee Module — Requirements Index

## Purpose
Master index of all requirement files for the StudentFee module. Each file documents the business purpose, database fields, business rules, CRUD operations, and permissions for one feature area.

---

## Feature Area → Requirement File Map

| # | Feature Area | File | Status |
|---|---|---|---|
| 1 | **Fee Heads** | `fee-heads.md` | ✅ Documented |
| 2 | **Fee Groups** | `fee-groups.md` | ✅ Documented |
| 3 | **Fee Structures** | `fee-structures.md` | ✅ Documented |
| 4 | **Fee Installments** | `fee-installments.md` | ✅ Documented |
| 5 | **Fee Concessions** | `fee-concessions.md` | ✅ Documented |
| 6 | **Fee Fines (Late Fee)** | `fee-fines.md` | ✅ Documented |
| 7 | **Student Fee Assignments** | `fee-assignments.md` | ✅ Documented |
| 8 | **Fee Invoicing** | `fee-invoicing.md` | ✅ Documented |
| 9 | **Fee Payments & Receipts** | `fee-payments.md` | ✅ Documented |
| 10 | **Payment Reconciliation & Gateway** | `fee-reconciliation.md` | ✅ Documented |
| 11 | **Fee Refunds** | `fee-refunds.md` | ✅ Documented |
| 12 | **Scholarships** | `fee-scholarships.md` | ✅ Documented |
| 13 | **Name Removal & Defaulters** | `fee-name-removal.md` | ✅ Documented |
| 14 | **Dashboard & Reports** | `fee-dashboard.md` | ✅ Documented |

---

## Module Statistics

| Metric | Count |
|---|---|
| Module Name | StudentFee |
| Database Tables | 24 (fee_* prefix) |
| Models | 24 |
| Controllers | 16 |
| Web Routes | ~100+ (resources + custom + soft-delete) |
| API Routes | 5 (apiResource) |
| View Files | ~60+ across 20+ subdirectories |
| Policies | 14 |
| Form Requests | 0 (inline validation) |
| Services | 3 (FeeFineService, FeeInvoiceService, FeeScholarshipService) |
| Events | 0 (EventServiceProvider with empty listen, auto-discover enabled) |
| Console Commands | 1 (fee:apply-fines) |
| Migration Files | 24 (all .bk — backup/source) |

---

## Key Subsystems

### Master Data
- **Fee Heads**: 10+ head types with tax, frequency, refundable flags
- **Fee Groups**: 6 groups bundling heads (Academic Core, Annual, Transport, Hostel, Activity, Exam)
- **Fee Structures**: Per-class + session + category fee packages with effective dating
- **Fee Installments**: Configurable payment schedules (typically 4 quarterly at 25% each)

### Student Assignment
- Individual and bulk assignment of fee structures to students
- Optional head/group opt-in/out
- Mid-year join proration

### Financial Operations
- **Invoices**: Auto-generated, 6-status lifecycle, bulk generation
- **Payments**: Multi-mode (cash/cheque/online/DD), per-head allocation, receipt generation
- **Fines**: Configurable rules (percentage daily, flat), recurring, grace periods, ApplyFines command
- **Concessions**: Percentage/fixed, per-total/per-head/per-group, approval workflow

### Compliance & Reconciliation
- **Payment Reconciliation**: Cheque lifecycle (deposit→clear→bounce→resubmit)
- **Gateway Logs**: Full request/response capture for online payments
- **Refunds**: 4-stage approval workflow, multiple refund modes

### Scholarships
- Fund pool management with auto-deduction on approval
- Multi-stage application workflow with review committee
- Approval history audit trail

### Governance
- Name removal for chronic defaulters with re-admission tracking
- Defaulter history aggregation with risk scoring

---

## Critical Notes

**Route Prefix**: All tenant-scoped under `student-fee/` with middleware: `web, InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive, auth, verified`

**Gate Permissions**: Uses `tenant.fee-{feature}.{action}` pattern. 14 policies with 14 methods each.

**Editable Flag**: `fee_structures` and `fee_invoices` cannot be edited or deleted if they have downstream dependencies (assignments for structures, payments for invoices).

**Generated Columns**: `fee_invoices.balance_amount` is a MySQL stored generated column (`total_amount - paid_amount`) — cannot be directly updated.

**Mid-Year Join**: When a student joins mid-year, fees are prorated. The `fee_start_date` and `proration_percentage` track the adjusted amount.

**ApplyFines Command**: Scheduled command `fee:apply-fines` runs daily to auto-apply late fees. Has `--dry-run` mode for preview and `--rule` flag for targeting specific rules.

**Migration Status**: All 24 migration files have `.bk` extension — they appear to be source/backup copies. The actual migrations may be in a different location or pending publication.

**Typo Folders**: Two view folders have typos: `fee-reciept/` (missing `p`) and `fee-transaction-detiils/` (extra `i`).
