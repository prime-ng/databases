# Cross-Module Event Mapping — Business Requirements

## Business Need
Many financial transactions originate in other modules — a library fine, a transport fee registration, a vendor invoice — and must automatically create accounting entries. Rather than writing custom integration code for each module, the Event Mapping system provides a configurable, event-driven mechanism: any module can trigger accounting voucher creation by firing an event, and the system looks up the pre-configured voucher template to post the correct Dr/Cr entries.

## Business Objectives
- Allow any module to trigger accounting entries without custom integration code
- Support multi-line vouchers with dynamic ledger and amount resolution
- Track all event processing with success/failure logging
- Provide admin configuration for which events create which vouchers
- Handle automatic retry for failed processing

## User Stories

**As School Accountant,** I want to:
- View all registered module events and their current voucher configurations
- Configure which voucher type and ledgers are used when a specific event fires
- Set up multi-line Dr/Cr templates for each event
- Decide whether vouchers should be auto-posted or created as draft for review
- Review the event processing log to see what was processed, skipped, or failed
- Retry failed event processing

**As Module Developer (Library/Transport/Payroll/etc.),** I want to:
- Register new events that my module can fire (event code, source model, description)
- Fire an event with minimal payload: `(module_code, event_code, source_id, payload_data)`
- Let the Accounting module handle the voucher creation — no direct DB access needed

## Key Business Rules

**Event → Voucher Flow**
1. Source module fires an event with (module_code, event_code, source_id, payload)
2. System checks if the event is registered and active
3. System looks up the configured voucher template for this event
4. For each template line, the system resolves:
   - **Ledger:** Fixed ledger, or dynamically resolved from the source record (student ledger, vendor ledger, employee ledger)
   - **Amount:** Fixed amount, or read from the source record, or from the event payload
5. System creates the voucher (optionally auto-posts it)
6. Result is logged to the processing log

**Ledger Resolution Strategies**
| Strategy | What It Does |
|---|---|
| Fixed | Use a pre-configured ledger (e.g., "Library Fine Income" is always used) |
| Student Ledger | Find the ledger linked to the student involved in the event |
| Vendor Ledger | Find the ledger linked to the vendor involved in the event |
| Employee Ledger | Find the ledger linked to the employee involved in the event |

**Duplicate Guard**
- The same source record CAN fire the same event multiple times (e.g., pickup point changed twice)
- Each event instance creates a separate processing log entry
- No uniqueness constraint — intentional to allow re-processing

**Processing Log Statuses**
| Status | Meaning |
|---|---|
| Pending | Event received, awaiting processing |
| Processed | Voucher created successfully |
| Failed | Error occurred (invalid config, missing ledger, etc.) |
| Skipped | No active configuration found for this event |

## Seeded Events

| Module | Event | What Triggers It |
|---|---|---|
| Library | Late Return Fine | Staff/student returns book after due date |
| Library | Lost Book Fine | Book is reported lost |
| Library | Damaged Book Fine | Book is returned damaged |
| Library | Membership Fee | New library membership/ renewal |
| Transport | New Registration | Student registers for transport route |
| Transport | Pickup Change | Student's pickup point changes |
| Transport | Mode Change | Student changes transport mode (bus/walk/van) |

## Stakeholders

| Stakeholder | Interest |
|---|---|
| School Accountant | Configures event-to-voucher mappings, reviews processing log |
| Module Developers | Register events, fire events during business operations |
| School Admin / Bursar | Oversees that all module transactions are properly accounted |

## Permissions

| Role | Access |
|---|---|
| School Admin | Full access to configure event mappings |
| Accountant | View event mappings, review processing log |
