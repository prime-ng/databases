# PaymentRequest_TcList

## Module: Accounting → Transactions → Payment Requests

---

## Overview

Payment Requests is **not a separate CRUD feature**. It is a **read-only dashboard view** that displays records from the `acc_event_processing_log` table — the same table used by the Event Mapping system to track voucher generation attempts.

There is:
- No dedicated controller (data loaded via `AccDashboardController@transactions`)
- No dedicated model (uses `EventProcessingLog` model)
- No dedicated request/policy/CRUD
- No create/edit/delete for payment requests

The tab shows **3 sub-tabs**:
1. **All Requests** — every `EventProcessingLog` record
2. **Approved** — `status = 'Processed'` (voucher was created)
3. **Rejected** — `status = 'Failed'` (voucher creation failed)

---

## 1. Business Conditions

### 1.1 Database Schema — acc_event_processing_log

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | bigint unsigned | PK, auto-increment |
| BC-DB-02 | module_event_id | bigint unsigned | NOT NULL, FK → acc_module_events(id) ON DELETE RESTRICT |
| BC-DB-03 | source_model | varchar(100) | NOT NULL |
| BC-DB-04 | source_id | bigint unsigned | NOT NULL |
| BC-DB-05 | payload_json | json | NULLABLE |
| BC-DB-06 | voucher_id | bigint unsigned | NULLABLE, FK → acc_vouchers(id) ON DELETE SET NULL |
| BC-DB-07 | status | tinyint unsigned | NOT NULL, FK → acc_accounting_status_masters(id) ON DELETE RESTRICT |
| BC-DB-08 | error_message | text | NULLABLE |
| BC-DB-09 | retry_count | tinyint unsigned | DEFAULT 0 |
| BC-DB-10 | processed_at | timestamp | NULLABLE |
| BC-DB-11 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-12 | created_by | int unsigned | NULLABLE |
| BC-DB-13 | created_at | timestamp | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-14 | updated_at | timestamp | Auto-updated |
| BC-DB-15 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-16 | INDEX idx_acc_epl_event | module_event_id | FK index |
| BC-DB-17 | INDEX idx_acc_epl_source | (source_model, source_id) | Duplicate guard |
| BC-DB-18 | INDEX idx_acc_epl_voucher | voucher_id | FK index |
| BC-DB-19 | INDEX idx_acc_epl_status | status | Filtering |
| BC-DB-20 | INDEX idx_acc_epl_pending | (status, retry_count) | Job queue |
| BC-DB-21 | ENGINE=InnoDB | — | Transaction support |

### 1.2 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Sub-tab: All Requests | Paginated list of all logs, newest first |
| BC-BIZ-02 | Sub-tab: Approved | Filtered `status = 'Processed'`, paginated |
| BC-BIZ-03 | Sub-tab: Rejected | Filtered `status = 'Failed'`, paginated |
| BC-BIZ-04 | Status display | Processed→"Approved" (green), Failed→"Rejected" (red), Skipped→warning, Pending→secondary |
| BC-BIZ-05 | Module badge | Shows `module_code` from related `ModuleEvent` |
| BC-BIZ-06 | Voucher link | If `voucher_id` exists, shows "View Voucher" link to show page |
| BC-BIZ-07 | Error message | If `error_message` exists, shows truncated error text |
| BC-BIZ-08 | Timestamps | Shows created_at + relative time for processed_at |
| BC-BIZ-09 | Search by source_model | Filters logs by `source_model LIKE ?` or `status LIKE ?` |

---

## 2. Test Case List

### 2.1 Positive Test Cases

| TC ID | Description | Expected Result | V2 Test | Status |
|-------|-------------|----------------|---------|--------|
| TC-P01 | All Requests tab loads | Paginated list of processing logs with status badges, module badges, source info. | test_all_requests_tab_loads | ✅ |
| TC-P02 | Approved sub-tab loads | Only Processed logs shown with green "Approved" badge | test_approved_tab_loads | ✅ |
| TC-P03 | Rejected sub-tab loads | Only Failed logs shown with red "Rejected" badge | test_rejected_tab_loads | ✅ |
| TC-P04 | Voucher link for processed records | Clicking "View Voucher" opens correct voucher show page | test_voucher_link_works | ✅ |
| TC-P05 | Error message display for failed records | Failed logs show truncated error_message with tooltip | test_error_message_displayed | ✅ |
| TC-P06 | Search by source model | Search matches source_model or status | test_search_payment_requests | ✅ |
| TC-P07 | Badge counts on sub-tabs | All/Approved/Rejected tab badges show correct counts | test_subtab_badge_counts | ✅ |
| TC-P08 | Empty state per sub-tab | Each sub-tab shows appropriate "No ... Requests" message when empty | test_empty_state | ✅ |

### 2.2 Negative Test Cases

| TC ID | Description | Expected Result | V2 Test | Status |
|-------|-------------|----------------|---------|--------|
| TC-N01 | Empty database — all tabs show empty state | "No Payment Requests Yet", "No Approved Requests", "No Rejected Requests" | test_all_tabs_empty | ✅ |
| TC-N02 | Search with no results | Empty state shown on all sub-tabs | test_search_no_results | ✅ |
| TC-N03 | No voucher_id for pending/failed | No "View Voucher" link shown; error message shown if available | test_pending_no_voucher_link | ✅ |

### 2.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | Status |
|-------|----------|-------------|----------------|--------|
| TC-D01 | A | New payment request appears after event trigger | Event Mapping processes source record → new log appears in All tab | ⏸️ |
| TC-D02 | B | Status changes after voucher creation | Pending→Processed with voucher_id after successful event processing | ⏸️ |
| TC-D03 | C | Failed request shows error message | Event processing error → Failed status with error_message | ⏸️ |

---

## 3. V2 Test Method Index

| # | Method | Category |
|---|--------|----------|
| 01–08 | test_all_tabs, search, badges, links, empty | Positive (8) |
| 09–11 | test_empty_db, no_results, pending_no_voucher | Negative (3) |
| 12–14 | test_dependency_event_processing | Dependency (3) |

---

## 4. Coverage Summary

| Category | Total TCs | Coverage |
|----------|-----------|----------|
| Positive | 8 | 100% |
| Negative | 3 | 100% |
| Dependency | 3 | 0% |
| **Total** | **14** | **79%** |

---

## 5. Route Reference

There is no dedicated route for Payment Requests. Data is loaded via:
```
GET /accounting/transactions?tab=payment-request → accounting.menu.transactions
```

No separate controller, model, policy, or CRUD routes.

---

## 6. Development Issues Found

| ID | Issue | Severity | Status |
|----|-------|----------|--------|
| DEV-01 | Status display label mismatch: DB value 'Processed' displayed as "Approved", 'Failed' as "Rejected". Confusing — status labels don't match DB values. | Medium | Open |
| DEV-02 | No detail view — can't inspect full payload_json or error_message without going to DB | Low | Open |
| DEV-03 | No retry action — failed requests can't be retried from the UI | Medium | Open |

---

## 7. Known Issues Summary

| ID | Issue | Status |
|----|-------|--------|
| KN-01 | Status labels renamed for display ("Processed"→"Approved", "Failed"→"Rejected") — may confuse users who know the DB values | Open |
| KN-02 | No detail/expand view for individual logs — payload and full error not inspectable | Open |
| KN-03 | No retry mechanism for failed requests via UI | Open |
