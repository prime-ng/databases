MNT Module — All Phases Complete
                                                                                     
  Output directory: 5-Work-In-Progress/Maintenance/2-Claude_Plan/
                                                                                     
  ┌────────────────────────────────────┬───────┬──────────────────────────────────┐
  │                File                │ Phase │             Purpose              │  
  ├────────────────────────────────────┼───────┼──────────────────────────────────┤
  │                                    │       │ Entity specs, ERD, 16 BRs, FSMs, │
  │ MNT_FeatureSpec.md                 │ 1     │  permission matrix, service      │
  │                                    │       │ architecture                     │  
  ├────────────────────────────────────┼───────┼──────────────────────────────────┤
  │                                    │       │ 11 CREATE TABLE statements,      │  
  │ MNT_DDL_v1.sql                     │ 2     │ Layer 1→7 order, all FKs and     │
  │                                    │       │ indexes                          │  
  ├────────────────────────────────────┼───────┼──────────────────────────────────┤  
  │                                    │       │ Laravel Blueprint migration (INT │
  │ MNT_Migration.php                  │ 2     │  UNSIGNED PKs, DDL Rule 14       │  
  │                                    │       │ exceptions)                      │  
  ├────────────────────────────────────┼───────┼──────────────────────────────────┤
  │                                    │       │ 11-table inventory, audit        │  
  │ MNT_TableSummary.md                │ 2     │ exceptions, cross-module FK      │  
  │                                    │       │ types                            │
  ├────────────────────────────────────┼───────┼──────────────────────────────────┤  
  │ Seeders/MntAssetCategorySeeder.php │ 2     │ 9 asset categories with          │
  │                                    │       │ keyword-priority JSON            │
  ├────────────────────────────────────┼───────┼──────────────────────────────────┤
  │ Seeders/MntSeederRunner.php        │ 2     │ Master seeder runner             │
  ├────────────────────────────────────┼───────┼──────────────────────────────────┤  
  │                                    │       │ 9 controllers, 5 services, 11    │
  │ MNT_Dev_Plan.md                    │ 3     │ FormRequests, ~35 views, 71      │  
  │                                    │       │ routes, 11 phases, testing       │
  │                                    │       │ strategy                         │  
  └────────────────────────────────────┴───────┴──────────────────────────────────┘

  Copy to Laravel repo when ready:                                                   
  - MNT_Migration.php →
  database/migrations/tenant/2026_03_27_000000_create_mnt_tables.php                 
  - Seeders/*.php → Modules/Maintenance/Database/Seeders/
  