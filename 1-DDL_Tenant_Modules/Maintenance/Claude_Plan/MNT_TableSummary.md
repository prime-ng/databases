# MNT — Maintenance Module Table Summary
**11 tables | Prefix:** `mnt_` | **Database:** `tenant_db` | **Generated:** 2026-03-27

---

## Table Inventory

| # | Table | Domain | Description |
|---|---|---|---|
| 1 | `mnt_asset_categories` | Asset Management | Category master with default priority, SLA hours, keyword-to-priority rules, and multi-level escalation config |
| 2 | `mnt_assets` | Asset Management | School asset register with location, depreciation fields (SLM/WDV), QR code reference, and accumulated maintenance cost |
| 3 | `mnt_asset_depreciation` | Asset Management | Immutable annual depreciation records (SLM/WDV); UNIQUE (asset_id, financial_year); FAC hook scaffold |
| 4 | `mnt_tickets` | Ticket Management | Core corrective ticket — 7-state FSM, auto-priority from keywords, SLA tracking, escalation_level flag |
| 5 | `mnt_ticket_assignments` | Ticket Management | Full assignment history per ticket; is_current=1 marks active technician; full audit trail retained |
| 6 | `mnt_ticket_time_logs` | Ticket Management | Per-session time and parts log; hours_spent + parts_cost drive ticket totals |
| 7 | `mnt_breakdown_history` | Ticket Management | Immutable breakdown event log; auto-inserted by TicketService on Resolved with asset_id (BR-MNT-014) |
| 8 | `mnt_pm_schedules` | Preventive Maintenance | Recurring PM schedule definitions with checklist_items_json and next_due_date per asset |
| 9 | `mnt_pm_work_orders` | Preventive Maintenance | Auto-generated PM work orders by daily cron; checklist_completion_json; Overdue set by MarkOverduePmWorkOrdersJob |
| 10 | `mnt_amc_contracts` | Contracts & Work Orders | Annual Maintenance Contracts; renewal_alert_sent_60/30/7 flags prevent duplicate NTF dispatches |
| 11 | `mnt_work_orders` | Contracts & Work Orders | External vendor work orders; optional link to ticket/AMC; DomPDF printable; actual_cost rolled to asset |

---

## Audit Column Exceptions (DDL Rule 14)

| Table | Missing Columns | Reason |
|---|---|---|
| `mnt_asset_depreciation` | `is_active`, `updated_by`, `deleted_at` | Immutable annual record — one per (asset_id, financial_year); never updated or soft-deleted |
| `mnt_breakdown_history` | `is_active`, `deleted_at` | Immutable event log — auto-inserted by system; historical record must be preserved |

---

## Cross-Module FK Summary

| Column | Belongs To | References | Type |
|---|---|---|---|
| `auto_assign_role_id` | `mnt_asset_categories` | `sys_roles.id` | BIGINT UNSIGNED |
| `assign_to_role_id` | `mnt_pm_schedules` | `sys_roles.id` | BIGINT UNSIGNED |
| `qr_code_media_id` | `mnt_assets` | `sys_media.id` | INT UNSIGNED |
| `photo_media_id` | `mnt_assets` | `sys_media.id` | INT UNSIGNED |
| `document_media_id` | `mnt_amc_contracts` | `sys_media.id` | INT UNSIGNED |
| `vendor_id` | `mnt_amc_contracts` | `vnd_vendors.id` | INT UNSIGNED |
| `vendor_id` | `mnt_work_orders` | `vnd_vendors.id` | INT UNSIGNED |
| `requester_user_id` | `mnt_tickets` | `sys_users.id` | BIGINT UNSIGNED |
| `assigned_to_user_id` | `mnt_tickets` | `sys_users.id` | BIGINT UNSIGNED |
| `assigned_to_user_id` | `mnt_ticket_assignments` | `sys_users.id` | BIGINT UNSIGNED |
| `assigned_by_user_id` | `mnt_ticket_assignments` | `sys_users.id` | BIGINT UNSIGNED |
| `logged_by_user_id` | `mnt_ticket_time_logs` | `sys_users.id` | BIGINT UNSIGNED |
| `assigned_to_user_id` | `mnt_pm_work_orders` | `sys_users.id` | BIGINT UNSIGNED |
| `created_by` / `updated_by` | All tables | `sys_users.id` | BIGINT UNSIGNED |

---

## Files Generated

| File | Location |
|---|---|
| `MNT_FeatureSpec.md` | `2-Claude_Plan/MNT_FeatureSpec.md` |
| `MNT_DDL_v1.sql` | `2-Claude_Plan/MNT_DDL_v1.sql` |
| `MNT_Migration.php` | `2-Claude_Plan/MNT_Migration.php` (copy to `database/migrations/tenant/2026_03_27_000000_create_mnt_tables.php`) |
| `Seeders/MntAssetCategorySeeder.php` | `2-Claude_Plan/Seeders/` → `Modules/Maintenance/Database/Seeders/` |
| `Seeders/MntSeederRunner.php` | `2-Claude_Plan/Seeders/` → `Modules/Maintenance/Database/Seeders/` |
