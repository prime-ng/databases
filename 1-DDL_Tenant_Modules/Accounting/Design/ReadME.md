# Files Detail of Accounting Module
===================================

---------------------------------------------------------------------------------------------------------
## Important Information:
-------------------------
1. I have made 1 below Change in DDL after creating Migration, whcih you need to adjust.
    - In Table - acc_vouchers
    - Old Filed - `source_module`     VARCHAR(50) NULL COMMENT 'StudentFee, Payroll, Inventory, Transport, Manual',
    - new Field - `source_module`     ENUM('Fees','Library','Transport','HR','Vendor','Inventory','Payroll','Manual') NULL COMMENT 'Source module for integration',

2. There some chnages we need to perform `sch_employees`. SQL Script to make thoses is there "pgdatabase/1-Module_DDLs/20-Accounting/DDL/ACC_SchEmployees_Enhancement.sql"
    - Execute it

---------------------------------------------------------------------------------------------------------

## Read Below files to understand what has been already created and what information all files are having.

1. /pgdatabase/1-Module_DDLs/20-Accounting/Design/Initial_Plan_v4.md
2. /pgdatabase/1-Module_DDLs/20-Accounting/Design/Account_Requirement_v4.md

┌─────┬──────────────────────────────────┬───────────────────────────────────────┬───────────────────────────────────────────────────────────────────────────┐
│  #  │               File               │               Location                │                                Description                                │
├─────┼──────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────┤
│ 1   │ ACC_DDL_v1.sql                   │ 1-DDL_Tenant_Modules/20-Account/DDL/  │ 21 CREATE TABLE statements + 3 performance indexes                        │
├─────┼──────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────┤
│ 2   │ ACC_Migration.php                │ 5-Work-In-Progress/20-Accounting/DDL/ │ Laravel migration (21 tables + sch_employees ALTER with hasColumn guards) │
├─────┼──────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────┤
│ 3   │ ACC_SchEmployees_Enhancement.sql │ 1-DDL_Tenant_Modules/20-Account/DDL/  │ Standalone ALTER TABLE (14 columns)                                       │
├─────┼──────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────┤
│ 4   │ ACC_TableSummary.md              │ 5-Work-In-Progress/20-Accounting/DDL/ │ One-line summary per table                                                │
├─────┼──────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────┤
│ 5   │ AccountGroupSeeder.php           │ ACC_Seeders/                          │ 32 groups (Tally 28 + 4 school-specific)                                  │
├─────┼──────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────┤
│ 6   │ VoucherTypeSeeder.php            │ ACC_Seeders/                          │ 10 voucher types with prefixes                                            │
├─────┼──────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────┤
│ 7   │ TaxRateSeeder.php                │ ACC_Seeders/                          │ 5 GST rates                                                               │
├─────┼──────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────┤
│ 8   │ CostCenterSeeder.php             │ ACC_Seeders/                          │ 10 cost centers                                                           │
├─────┼──────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────┤
│ 9   │ DefaultLedgerSeeder.php          │ ACC_Seeders/                          │ 11 default ledgers (Cash, GST/PF/ESI Payable, etc.)                       │
├─────┼──────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────┤
│ 10  │ TallyLedgerMappingSeeder.php     │ ACC_Seeders/                          │ 11 auto-mapped Tally names                                                │
├─────┼──────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────┤
│ 11  │ AssetCategorySeeder.php          │ ACC_Seeders/                          │ 5 categories (Furniture SLM 10%, IT WDV 40%, etc.)                        │
└─────┴──────────────────────────────────┴───────────────────────────────────────┴───────────────────────────────────────────────────────────────────────────┘
