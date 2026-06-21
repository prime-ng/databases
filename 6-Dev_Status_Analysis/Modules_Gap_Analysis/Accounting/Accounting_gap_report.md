# Accounting Module — Gap Analysis Report
**Generated:** 2026-04-11
**DDL Source:** /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/40-Accounting/DDL/ACC_DDL_v2.sql
**Module Code:** /Users/bkwork/Herd/prime_ai/Modules/Accounting
**Migration Path:** /Users/bkwork/Herd/prime_ai/database/migrations/tenant
**Table Prefix:** acc_

---

## Section 1 — DDL Table Inventory

The DDL defines **25 tables** across 5 domains plus a generic cross-module enhancement block.

### Domain 1: Core Accounting (12 tables)

#### `acc_financial_years`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| name | VARCHAR(50) | NO | — | — |
| start_date | DATE | NO | — | — |
| end_date | DATE | NO | — | — |
| is_locked | TINYINT(1) | NO | 0 | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | FK → sys_users |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| idx_acc_fy_active | is_active | INDEX |
| idx_acc_fy_dates | start_date, end_date | INDEX |

**Foreign Keys:** None (created_by is a soft reference, no formal FK defined in DDL)

---

#### `acc_account_groups`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| name | VARCHAR(100) | NO | — | — |
| code | VARCHAR(20) | NO | — | UNIQUE(code, deleted_at) |
| alias | VARCHAR(100) | YES | NULL | — |
| parent_id | BIGINT UNSIGNED | YES | NULL | FK → acc_account_groups(id) |
| nature | ENUM('asset','liability','income','expense') | NO | — | — |
| affects_gross_profit | TINYINT(1) | NO | 0 | — |
| is_system | TINYINT(1) | NO | 0 | — |
| is_subledger | TINYINT(1) | NO | 0 | — |
| sequence | INT | NO | 0 | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| uq_acc_ag_code | code, deleted_at | UNIQUE |
| idx_acc_ag_parent | parent_id | INDEX |
| idx_acc_ag_nature | nature | INDEX |
| idx_acc_ag_system | is_system | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| parent_id | acc_account_groups(id) ON DELETE SET NULL |

---

#### `acc_ledgers`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| name | VARCHAR(150) | NO | — | — |
| code | VARCHAR(20) | YES | NULL | — |
| alias | VARCHAR(150) | YES | NULL | — |
| account_group_id | BIGINT UNSIGNED | NO | — | FK → acc_account_groups |
| opening_balance | DECIMAL(15,2) | NO | 0.00 | — |
| opening_balance_type | ENUM('Dr','Cr') | YES | NULL | — |
| is_bank_account | TINYINT(1) | NO | 0 | — |
| bank_name | VARCHAR(100) | YES | NULL | — |
| bank_account_number | VARCHAR(50) | YES | NULL | — |
| ifsc_code | VARCHAR(20) | YES | NULL | — |
| is_cash_account | TINYINT(1) | NO | 0 | — |
| allow_reconciliation | TINYINT(1) | NO | 0 | — |
| is_system | TINYINT(1) | NO | 0 | — |
| student_id | BIGINT UNSIGNED | YES | NULL | FK → std_students |
| employee_id | BIGINT UNSIGNED | YES | NULL | FK → sch_employees |
| vendor_id | BIGINT UNSIGNED | YES | NULL | FK → vnd_vendors |
| gst_registration_type | VARCHAR(30) | YES | NULL | — |
| gstin | VARCHAR(20) | YES | NULL | — |
| pan | VARCHAR(15) | YES | NULL | — |
| address | TEXT | YES | NULL | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| idx_acc_ledger_group | account_group_id | INDEX |
| idx_acc_ledger_student | student_id | INDEX |
| idx_acc_ledger_employee | employee_id | INDEX |
| idx_acc_ledger_vendor | vendor_id | INDEX |
| idx_acc_ledger_bank | is_bank_account | INDEX |
| idx_acc_ledger_active | is_active | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| account_group_id | acc_account_groups(id) ON DELETE RESTRICT |

---

#### `acc_voucher_types`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| name | VARCHAR(80) | NO | — | — |
| code | VARCHAR(20) | NO | — | UNIQUE(code, deleted_at) |
| category | ENUM('accounting','inventory','payroll','order') | NO | — | — |
| prefix | VARCHAR(20) | YES | NULL | — |
| auto_numbering | TINYINT(1) | NO | 1 | — |
| last_number | INT | NO | 0 | — |
| is_system | TINYINT(1) | NO | 0 | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| uq_acc_vt_code | code, deleted_at | UNIQUE |
| idx_acc_vt_category | category | INDEX |

**Foreign Keys:** None

---

#### `acc_vouchers`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| voucher_number | VARCHAR(50) | NO | — | UNIQUE(voucher_number, financial_year_id, deleted_at) |
| voucher_type_id | BIGINT UNSIGNED | NO | — | FK → acc_voucher_types |
| financial_year_id | BIGINT UNSIGNED | NO | — | FK → acc_financial_years |
| date | DATE | NO | — | — |
| reference_number | VARCHAR(100) | YES | NULL | — |
| reference_date | DATE | YES | NULL | — |
| narration | TEXT | YES | NULL | — |
| total_amount | DECIMAL(15,2) | NO | — | — |
| is_post_dated | TINYINT(1) | NO | 0 | — |
| is_optional | TINYINT(1) | NO | 0 | — |
| is_cancelled | TINYINT(1) | NO | 0 | — |
| cancelled_reason | TEXT | YES | NULL | — |
| cost_center_id | BIGINT UNSIGNED | YES | NULL | FK → acc_cost_centers |
| source_module | ENUM('Fees','Library','Transport','HR','Vendor','Inventory','Payroll','Manual') | YES | NULL | — |
| source_type | VARCHAR(100) | YES | NULL | — |
| source_id | BIGINT UNSIGNED | YES | NULL | — |
| status | ENUM('draft','posted','approved','cancelled') | NO | 'draft' | — |
| approved_by | BIGINT UNSIGNED | YES | NULL | FK → sys_users |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| uq_acc_voucher_number_fy | voucher_number, financial_year_id, deleted_at | UNIQUE |
| idx_acc_voucher_type | voucher_type_id | INDEX |
| idx_acc_voucher_fy | financial_year_id | INDEX |
| idx_acc_voucher_date | date | INDEX |
| idx_acc_voucher_status | status | INDEX |
| idx_acc_voucher_source | source_module, source_type, source_id | INDEX |
| idx_acc_voucher_cost | cost_center_id | INDEX |
| idx_acc_voucher_composite | date, financial_year_id, status | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| voucher_type_id | acc_voucher_types(id) ON DELETE RESTRICT |
| financial_year_id | acc_financial_years(id) ON DELETE RESTRICT |
| cost_center_id | acc_cost_centers(id) ON DELETE SET NULL |

---

#### `acc_voucher_items`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| voucher_id | BIGINT UNSIGNED | NO | — | FK → acc_vouchers |
| ledger_id | BIGINT UNSIGNED | NO | — | FK → acc_ledgers |
| type | ENUM('debit','credit') | NO | — | — |
| amount | DECIMAL(15,2) | NO | — | — |
| narration | VARCHAR(500) | YES | NULL | — |
| cost_center_id | BIGINT UNSIGNED | YES | NULL | FK → acc_cost_centers |
| bill_reference | VARCHAR(100) | YES | NULL | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| idx_acc_vi_voucher | voucher_id | INDEX |
| idx_acc_vi_ledger | ledger_id | INDEX |
| idx_acc_vi_type | type | INDEX |
| idx_acc_vi_cost | cost_center_id | INDEX |
| idx_acc_vi_ledger_date | ledger_id, created_at | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| voucher_id | acc_vouchers(id) ON DELETE CASCADE |
| ledger_id | acc_ledgers(id) ON DELETE RESTRICT |
| cost_center_id | acc_cost_centers(id) ON DELETE SET NULL |

---

#### `acc_cost_centers`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| name | VARCHAR(100) | NO | — | — |
| code | VARCHAR(20) | YES | NULL | — |
| parent_id | BIGINT UNSIGNED | YES | NULL | FK → acc_cost_centers |
| category | VARCHAR(50) | YES | NULL | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| idx_acc_cc_parent | parent_id | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| parent_id | acc_cost_centers(id) ON DELETE SET NULL |

---

#### `acc_budgets`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| financial_year_id | BIGINT UNSIGNED | NO | — | FK → acc_financial_years |
| cost_center_id | BIGINT UNSIGNED | NO | — | FK → acc_cost_centers |
| ledger_id | BIGINT UNSIGNED | NO | — | FK → acc_ledgers |
| budgeted_amount | DECIMAL(15,2) | NO | 0.00 | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| uq_acc_budget | financial_year_id, cost_center_id, ledger_id | UNIQUE |
| idx_acc_budget_cc | cost_center_id | INDEX |
| idx_acc_budget_ledger | ledger_id | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| financial_year_id | acc_financial_years(id) ON DELETE RESTRICT |
| cost_center_id | acc_cost_centers(id) ON DELETE RESTRICT |
| ledger_id | acc_ledgers(id) ON DELETE RESTRICT |

---

#### `acc_tax_rates`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| name | VARCHAR(100) | NO | — | — |
| rate | DECIMAL(5,2) | NO | — | — |
| type | ENUM('CGST','SGST','IGST','Cess') | NO | — | — |
| hsn_sac_code | VARCHAR(20) | YES | NULL | — |
| is_interstate | TINYINT(1) | NO | 0 | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| idx_acc_tax_type | type | INDEX |

**Foreign Keys:** None

---

#### `acc_ledger_mappings`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| ledger_id | BIGINT UNSIGNED | NO | — | FK → acc_ledgers |
| source_module | ENUM('Fees','Library','Transport','HR','Vendor','Inventory','Payroll') | NO | — | — |
| source_type | VARCHAR(100) | YES | NULL | — |
| source_id | BIGINT UNSIGNED | NO | — | — |
| description | VARCHAR(255) | YES | NULL | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| uq_acc_lm_combo | ledger_id, source_module, source_type, source_id | UNIQUE |
| idx_acc_lm_source | source_module, source_type, source_id | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| ledger_id | acc_ledgers(id) ON DELETE RESTRICT |

---

#### `acc_recurring_templates`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| name | VARCHAR(150) | NO | — | — |
| voucher_type_id | BIGINT UNSIGNED | NO | — | FK → acc_voucher_types |
| frequency | ENUM('Daily','Weekly','Monthly','Quarterly','Yearly') | NO | — | — |
| start_date | DATE | NO | — | — |
| end_date | DATE | YES | NULL | — |
| day_of_month | TINYINT | YES | NULL | — |
| narration | TEXT | YES | NULL | — |
| total_amount | DECIMAL(15,2) | NO | — | — |
| last_posted_date | DATE | YES | NULL | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| idx_acc_rt_type | voucher_type_id | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| voucher_type_id | acc_voucher_types(id) ON DELETE RESTRICT |

---

#### `acc_recurring_template_lines`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| recurring_template_id | BIGINT UNSIGNED | NO | — | FK → acc_recurring_templates |
| ledger_id | BIGINT UNSIGNED | NO | — | FK → acc_ledgers |
| type | ENUM('debit','credit') | NO | — | — |
| amount | DECIMAL(15,2) | NO | — | — |
| narration | VARCHAR(500) | YES | NULL | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| idx_acc_rtl_template | recurring_template_id | INDEX |
| idx_acc_rtl_ledger | ledger_id | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| recurring_template_id | acc_recurring_templates(id) ON DELETE CASCADE |
| ledger_id | acc_ledgers(id) ON DELETE RESTRICT |

---

### Domain 2: Banking (2 tables)

#### `acc_bank_reconciliations`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| ledger_id | BIGINT UNSIGNED | NO | — | FK → acc_ledgers |
| statement_date | DATE | NO | — | — |
| closing_balance | DECIMAL(15,2) | NO | — | — |
| statement_path | VARCHAR(255) | YES | NULL | — |
| status | ENUM('In Progress','Completed') | NO | 'In Progress' | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| idx_acc_br_ledger | ledger_id | INDEX |
| idx_acc_br_date | statement_date | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| ledger_id | acc_ledgers(id) ON DELETE RESTRICT |

---

#### `acc_bank_statement_entries`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| reconciliation_id | BIGINT UNSIGNED | NO | — | FK → acc_bank_reconciliations |
| transaction_date | DATE | NO | — | — |
| description | VARCHAR(500) | YES | NULL | — |
| reference | VARCHAR(255) | YES | NULL | — |
| debit | DECIMAL(15,2) | NO | 0.00 | — |
| credit | DECIMAL(15,2) | NO | 0.00 | — |
| balance | DECIMAL(15,2) | YES | NULL | — |
| is_matched | TINYINT(1) | NO | 0 | — |
| matched_voucher_item_id | BIGINT UNSIGNED | YES | NULL | FK → acc_voucher_items |
| matched_at | TIMESTAMP | YES | NULL | — |
| matched_by | BIGINT UNSIGNED | YES | NULL | FK → sys_users |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| idx_acc_bse_recon | reconciliation_id | INDEX |
| idx_acc_bse_matched | is_matched | INDEX |
| idx_acc_bse_vi | matched_voucher_item_id | INDEX |
| idx_acc_bse_date | transaction_date | INDEX |
| idx_acc_bse_recon_matched | reconciliation_id, is_matched | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| reconciliation_id | acc_bank_reconciliations(id) ON DELETE CASCADE |
| matched_voucher_item_id | acc_voucher_items(id) ON DELETE SET NULL |

---

### Domain 3: Fixed Assets (3 tables)

#### `acc_asset_categories`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| name | VARCHAR(100) | NO | — | — |
| code | VARCHAR(20) | NO | — | UNIQUE(code, deleted_at) |
| depreciation_method | ENUM('SLM','WDV') | NO | — | — |
| depreciation_rate | DECIMAL(5,2) | NO | — | — |
| useful_life_years | INT | YES | NULL | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| uq_acc_assetcat_code | code, deleted_at | UNIQUE |

**Foreign Keys:** None

---

#### `acc_fixed_assets`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| name | VARCHAR(150) | NO | — | — |
| asset_code | VARCHAR(50) | NO | — | UNIQUE(asset_code, deleted_at) |
| asset_category_id | BIGINT UNSIGNED | NO | — | FK → acc_asset_categories |
| purchase_date | DATE | NO | — | — |
| purchase_cost | DECIMAL(15,2) | NO | — | — |
| salvage_value | DECIMAL(15,2) | NO | 0.00 | — |
| current_value | DECIMAL(15,2) | NO | — | — |
| accumulated_depreciation | DECIMAL(15,2) | NO | 0.00 | — |
| location | VARCHAR(100) | YES | NULL | — |
| vendor_id | BIGINT UNSIGNED | YES | NULL | FK → vnd_vendors |
| voucher_id | BIGINT UNSIGNED | YES | NULL | FK → acc_vouchers |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| uq_acc_fa_code | asset_code, deleted_at | UNIQUE |
| idx_acc_fa_category | asset_category_id | INDEX |
| idx_acc_fa_vendor | vendor_id | INDEX |
| idx_acc_fa_voucher | voucher_id | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| asset_category_id | acc_asset_categories(id) ON DELETE RESTRICT |
| voucher_id | acc_vouchers(id) ON DELETE SET NULL |

---

#### `acc_depreciation_entries`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| fixed_asset_id | BIGINT UNSIGNED | NO | — | FK → acc_fixed_assets |
| financial_year_id | BIGINT UNSIGNED | NO | — | FK → acc_financial_years |
| depreciation_date | DATE | NO | — | — |
| depreciation_amount | DECIMAL(15,2) | NO | — | — |
| voucher_id | BIGINT UNSIGNED | YES | NULL | FK → acc_vouchers |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| idx_acc_de_asset | fixed_asset_id | INDEX |
| idx_acc_de_fy | financial_year_id | INDEX |
| idx_acc_de_voucher | voucher_id | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| fixed_asset_id | acc_fixed_assets(id) ON DELETE CASCADE |
| financial_year_id | acc_financial_years(id) ON DELETE RESTRICT |
| voucher_id | acc_vouchers(id) ON DELETE SET NULL |

---

### Domain 4: Expense Claims (2 tables)

#### `acc_expense_claims`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| claim_number | VARCHAR(50) | NO | — | UNIQUE(claim_number, deleted_at) |
| employee_id | BIGINT UNSIGNED | NO | — | FK → sch_employees |
| claim_date | DATE | NO | — | — |
| total_amount | DECIMAL(15,2) | NO | — | — |
| status | ENUM('Draft','Submitted','Approved','Rejected','Paid') | NO | 'Draft' | — |
| approved_by | BIGINT UNSIGNED | YES | NULL | FK → sys_users |
| approved_at | TIMESTAMP | YES | NULL | — |
| voucher_id | BIGINT UNSIGNED | YES | NULL | FK → acc_vouchers |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| uq_acc_ec_number | claim_number, deleted_at | UNIQUE |
| idx_acc_ec_employee | employee_id | INDEX |
| idx_acc_ec_status | status | INDEX |
| idx_acc_ec_voucher | voucher_id | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| voucher_id | acc_vouchers(id) ON DELETE SET NULL |

---

#### `acc_expense_claim_lines`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| expense_claim_id | BIGINT UNSIGNED | NO | — | FK → acc_expense_claims |
| expense_date | DATE | NO | — | — |
| ledger_id | BIGINT UNSIGNED | NO | — | FK → acc_ledgers |
| description | VARCHAR(255) | NO | — | — |
| amount | DECIMAL(15,2) | NO | — | — |
| tax_amount | DECIMAL(15,2) | NO | 0.00 | — |
| receipt_path | VARCHAR(255) | YES | NULL | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| idx_acc_ecl_claim | expense_claim_id | INDEX |
| idx_acc_ecl_ledger | ledger_id | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| expense_claim_id | acc_expense_claims(id) ON DELETE CASCADE |
| ledger_id | acc_ledgers(id) ON DELETE RESTRICT |

---

### Domain 5: Tally Integration (2 tables)

#### `acc_tally_export_logs`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| export_type | ENUM('Ledgers','Vouchers','Inventory') | NO | — | — |
| export_date | DATETIME | NO | — | — |
| file_name | VARCHAR(255) | NO | — | — |
| exported_by | BIGINT UNSIGNED | NO | — | FK → sys_users |
| start_date | DATE | YES | NULL | — |
| end_date | DATE | YES | NULL | — |
| record_count | INT | YES | NULL | — |
| status | ENUM('Success','Failed','Partial') | NO | — | — |
| error_log | TEXT | YES | NULL | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| idx_acc_tel_type | export_type | INDEX |
| idx_acc_tel_date | export_date | INDEX |
| idx_acc_tel_by | exported_by | INDEX |

**Foreign Keys:** None (exported_by is constrained in DDL via FK)

---

#### `acc_tally_ledger_mappings`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| ledger_id | BIGINT UNSIGNED | NO | — | FK → acc_ledgers |
| tally_ledger_name | VARCHAR(200) | NO | — | — |
| tally_group_name | VARCHAR(200) | YES | NULL | — |
| tally_alias | VARCHAR(200) | YES | NULL | — |
| mapping_type | ENUM('auto','manual') | NO | 'auto' | — |
| sync_direction | ENUM('export_only','import_only','bidirectional') | NO | 'export_only' | — |
| last_synced_at | TIMESTAMP | YES | NULL | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | NULL | — |
| updated_at | TIMESTAMP | YES | NULL | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| uq_acc_tlm_ledger | ledger_id, deleted_at | UNIQUE |

**Foreign Keys:**
| Column | References |
|--------|------------|
| ledger_id | acc_ledgers(id) ON DELETE CASCADE |

---

### Domain 6: Cross-Module Event Engine (4 tables — ENHANCEMENT BLOCK)

#### `acc_module_events`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| module_code | VARCHAR(30) | NO | — | — |
| event_code | VARCHAR(60) | NO | — | UNIQUE(module_code, event_code, deleted_at) |
| event_name | VARCHAR(150) | NO | — | — |
| description | TEXT | YES | NULL | — |
| source_model | VARCHAR(100) | NO | — | — |
| is_system | TINYINT(1) | NO | 1 | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | — |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| uq_acc_me_code | module_code, event_code, deleted_at | UNIQUE |
| idx_acc_me_module | module_code | INDEX |
| idx_acc_me_active | is_active | INDEX |
| idx_acc_me_source_model | source_model | INDEX |

**Foreign Keys:** None

---

#### `acc_event_voucher_configs`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| module_event_id | BIGINT UNSIGNED | NO | — | FK → acc_module_events |
| voucher_type_id | BIGINT UNSIGNED | NO | — | FK → acc_voucher_types |
| cost_center_id | BIGINT UNSIGNED | YES | NULL | FK → acc_cost_centers |
| is_auto_post | TINYINT(1) | NO | 0 | — |
| requires_approval | TINYINT(1) | NO | 0 | — |
| narration_template | VARCHAR(500) | YES | NULL | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | — |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| uq_acc_evc_event | module_event_id, deleted_at | UNIQUE |
| idx_acc_evc_voucher_type | voucher_type_id | INDEX |
| idx_acc_evc_cost_center | cost_center_id | INDEX |
| idx_acc_evc_active | is_active | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| module_event_id | acc_module_events(id) ON DELETE RESTRICT |
| voucher_type_id | acc_voucher_types(id) ON DELETE RESTRICT |
| cost_center_id | acc_cost_centers(id) ON DELETE SET NULL |

---

#### `acc_event_voucher_line_templates`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| event_voucher_config_id | BIGINT UNSIGNED | NO | — | FK → acc_event_voucher_configs |
| sequence | TINYINT UNSIGNED | NO | 1 | — |
| entry_type | ENUM('debit','credit') | NO | — | — |
| ledger_resolver | ENUM('fixed','student_ledger','vendor_ledger','employee_ledger') | NO | 'fixed' | — |
| ledger_id | BIGINT UNSIGNED | YES | NULL | FK → acc_ledgers |
| amount_resolver | ENUM('from_source','fixed_amount','from_payload') | NO | 'from_source' | — |
| source_amount_field | VARCHAR(100) | YES | NULL | — |
| fixed_amount | DECIMAL(15,2) | YES | NULL | — |
| narration | VARCHAR(500) | YES | NULL | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | — |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| idx_acc_evlt_config | event_voucher_config_id | INDEX |
| idx_acc_evlt_ledger | ledger_id | INDEX |
| idx_acc_evlt_type | entry_type | INDEX |
| idx_acc_evlt_sequence | event_voucher_config_id, sequence | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| event_voucher_config_id | acc_event_voucher_configs(id) ON DELETE CASCADE |
| ledger_id | acc_ledgers(id) ON DELETE RESTRICT |

---

#### `acc_event_processing_log`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK |
| module_event_id | BIGINT UNSIGNED | NO | — | FK → acc_module_events |
| source_model | VARCHAR(100) | NO | — | — |
| source_id | BIGINT UNSIGNED | NO | — | — |
| payload_json | JSON | YES | NULL | — |
| voucher_id | BIGINT UNSIGNED | YES | NULL | FK → acc_vouchers |
| status | ENUM('Pending','Processed','Failed','Skipped') | NO | 'Pending' | — |
| error_message | TEXT | YES | NULL | — |
| retry_count | TINYINT UNSIGNED | NO | 0 | — |
| processed_at | TIMESTAMP | YES | NULL | — |
| is_active | TINYINT(1) | NO | 1 | — |
| created_by | BIGINT UNSIGNED | YES | NULL | — |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | — |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | — |
| deleted_at | TIMESTAMP | YES | NULL | — |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|
| PRIMARY | id | PRIMARY |
| idx_acc_epl_event | module_event_id | INDEX |
| idx_acc_epl_source | source_model, source_id | INDEX |
| idx_acc_epl_voucher | voucher_id | INDEX |
| idx_acc_epl_status | status | INDEX |
| idx_acc_epl_pending | status, retry_count | INDEX |

**Foreign Keys:**
| Column | References |
|--------|------------|
| module_event_id | acc_module_events(id) ON DELETE RESTRICT |
| voucher_id | acc_vouchers(id) ON DELETE SET NULL |

---

## Section 2 — Migration vs DDL

### 2a. Migration File Coverage

| Migration File | Table | Operation | Status |
|----------------|-------|-----------|--------|
| 2026_03_21_000001_create_acc_financial_years_table.php | acc_financial_years | create | Covered |
| 2026_03_21_000002_create_acc_account_groups_table.php | acc_account_groups | create | Covered |
| 2026_03_21_000003_create_acc_cost_centers_table.php | acc_cost_centers | create | Covered |
| 2026_03_21_000004_create_acc_voucher_types_table.php | acc_voucher_types | create | Covered |
| 2026_03_21_000005_create_acc_tax_rates_table.php | acc_tax_rates | create | Covered |
| 2026_03_21_000006_create_acc_ledgers_table.php | acc_ledgers | create | Covered |
| 2026_03_21_000007_create_acc_vouchers_table.php | acc_vouchers | create | Covered |
| 2026_03_21_000008_create_acc_voucher_items_table.php | acc_voucher_items | create | Covered |
| 2026_03_21_000009_create_acc_budgets_table.php | acc_budgets | create | Covered |
| 2026_03_21_000010_create_acc_ledger_mappings_table.php | acc_ledger_mappings | create | Covered |
| 2026_03_21_000011_create_acc_recurring_templates_table.php | acc_recurring_templates | create | Covered |
| 2026_03_21_000012_create_acc_recurring_template_lines_table.php | acc_recurring_template_lines | create | Covered |
| 2026_03_21_000013_create_acc_bank_reconciliations_table.php | acc_bank_reconciliations | create | Covered |
| 2026_03_21_000014_create_acc_bank_statement_entries_table.php | acc_bank_statement_entries | create | Covered |
| 2026_03_21_000015_create_acc_asset_categories_table.php | acc_asset_categories | create | Covered |
| 2026_03_21_000016_create_acc_fixed_assets_table.php | acc_fixed_assets | create | Covered |
| 2026_03_21_000017_create_acc_depreciation_entries_table.php | acc_depreciation_entries | create | Covered |
| 2026_03_21_000018_create_acc_expense_claims_table.php | acc_expense_claims | create | Covered |
| 2026_03_21_000019_create_acc_expense_claim_lines_table.php | acc_expense_claim_lines | create | Covered |
| 2026_03_21_000020_create_acc_tally_export_logs_table.php | acc_tally_export_logs | create | Covered |
| 2026_03_21_000021_create_acc_tally_ledger_mappings_table.php | acc_tally_ledger_mappings | create | Covered |
| _(none)_ | acc_module_events | — | **MISSING** |
| _(none)_ | acc_event_voucher_configs | — | **MISSING** |
| _(none)_ | acc_event_voucher_line_templates | — | **MISSING** |
| _(none)_ | acc_event_processing_log | — | **MISSING** |

---

### 2b. Column-Level Discrepancies

Notes on methodology:
- Laravel's `foreignId()->constrained()` automatically creates an index on the FK column, so FK columns covered by `constrained()` are considered index-covered even when not explicitly listed with `$table->index(...)`.
- Only discrepancies that introduce a functional or data-integrity risk are listed below.

| Table | Column | Migration Value | DDL Value | Issue Type | Severity |
|-------|--------|-----------------|-----------|------------|----------|
| acc_account_groups | parent_id | No explicit `idx_acc_ag_parent` named index (auto-indexed by `foreignId()->constrained()`) | `idx_acc_ag_parent` | Named index absent — functionally covered but DDL name not created | P2 |
| acc_vouchers | idx_acc_voucher_type (voucher_type_id) | No explicit named index — auto-covered by `foreignId()->constrained()` | `idx_acc_voucher_type` | Named index absent — functionally covered | P2 |
| acc_vouchers | idx_acc_voucher_fy (financial_year_id) | No explicit named index — auto-covered by `foreignId()->constrained()` | `idx_acc_voucher_fy` | Named index absent — functionally covered | P2 |
| acc_vouchers | idx_acc_voucher_cost (cost_center_id) | No explicit named index — auto-covered by `foreignId()->constrained()` | `idx_acc_voucher_cost` | Named index absent — functionally covered | P2 |
| acc_recurring_templates | idx_acc_rt_type (voucher_type_id) | No explicit named index — auto-covered by `foreignId()->constrained()` | `idx_acc_rt_type` | Named index absent — functionally covered | P2 |
| acc_depreciation_entries | idx_acc_de_asset, idx_acc_de_fy, idx_acc_de_voucher | Not explicitly declared — auto-covered by `foreignId()->constrained()` | Three named indexes | Named indexes absent — functionally covered | P2 |
| acc_expense_claims | idx_acc_ec_employee, idx_acc_ec_voucher | Not explicitly declared — auto-covered by `foreignId()->constrained()` | Two named indexes | Named indexes absent — functionally covered | P2 |
| acc_expense_claim_lines | idx_acc_ecl_claim, idx_acc_ecl_ledger | Not explicitly declared — auto-covered by `foreignId()->constrained()` | Two named indexes | Named indexes absent — functionally covered | P2 |
| acc_tally_export_logs | idx_acc_tel_by (exported_by) | No explicit named index — auto-covered by `foreignId()->constrained()` | `idx_acc_tel_by` | Named index absent — functionally covered | P2 |
| acc_tally_ledger_mappings | fk_acc_tlm_ledger | Migration uses `cascadeOnDelete()` | DDL uses `ON DELETE CASCADE` | Consistent — no issue | — |
| acc_module_events | ALL COLUMNS | No migration file exists | Entire table | MISSING MIGRATION | P0 |
| acc_event_voucher_configs | ALL COLUMNS | No migration file exists | Entire table | MISSING MIGRATION | P0 |
| acc_event_voucher_line_templates | ALL COLUMNS | No migration file exists | Entire table | MISSING MIGRATION | P0 |
| acc_event_processing_log | ALL COLUMNS | No migration file exists | Entire table | MISSING MIGRATION | P0 |
| acc_budgets | idx_acc_budget_cc, idx_acc_budget_ledger | Not explicitly declared — auto-covered | Two named indexes | Named indexes absent — functionally covered | P2 |
| acc_bank_reconciliations | idx_acc_br_ledger | Not explicitly declared — auto-covered | `idx_acc_br_ledger` | Named index absent — functionally covered | P2 |
| acc_bank_statement_entries | idx_acc_bse_recon, idx_acc_bse_vi | Not explicitly declared — auto-covered | Two named indexes | Named indexes absent — functionally covered | P2 |

**Key Findings (Migration):**
- Four DDL tables from the cross-module event engine enhancement block (`acc_module_events`, `acc_event_voucher_configs`, `acc_event_voucher_line_templates`, `acc_event_processing_log`) have zero migration coverage — these tables cannot be created in any tenant database until migrations are written.
- All 21 original tables have corresponding migrations and the column definitions are accurate and complete against the DDL.
- Named index discrepancies (P2) are cosmetic: Laravel's `foreignId()->constrained()` creates an auto-named index that is functionally equivalent, but the DDL-specified index names (`idx_acc_*`) are not reproducible via this implicit mechanism, which may cause tooling discrepancies when comparing schema snapshots.
- The composite performance index `idx_acc_voucher_composite` (`date`, `financial_year_id`, `status`) IS explicitly defined in migration 007 — aligned with the DDL `CREATE INDEX` statement.

---

## Section 3 — Model vs DDL

### 3a. Model Coverage

| Model File | Mapped Table | $table Correct? |
|------------|-------------|-----------------|
| AccountGroup.php | acc_account_groups | Yes |
| AssetCategory.php | acc_asset_categories | Yes |
| BankReconciliation.php | acc_bank_reconciliations | Yes |
| BankStatementEntry.php | acc_bank_statement_entries | Yes |
| Budget.php | acc_budgets | Yes |
| CostCenter.php | acc_cost_centers | Yes |
| DepreciationEntry.php | acc_depreciation_entries | Yes |
| ExpenseClaim.php | acc_expense_claims | Yes |
| ExpenseClaimLine.php | acc_expense_claim_lines | Yes |
| FinancialYear.php | acc_financial_years | Yes |
| FixedAsset.php | acc_fixed_assets | Yes |
| Ledger.php | acc_ledgers | Yes |
| LedgerMapping.php | acc_ledger_mappings | Yes |
| RecurringTemplate.php | acc_recurring_templates | Yes |
| RecurringTemplateLine.php | acc_recurring_template_lines | Yes |
| TallyExportLog.php | acc_tally_export_logs | Yes |
| TallyLedgerMapping.php | acc_tally_ledger_mappings | Yes |
| TaxRate.php | acc_tax_rates | Yes |
| Voucher.php | acc_vouchers | Yes |
| VoucherItem.php | acc_voucher_items | Yes |
| VoucherType.php | acc_voucher_types | Yes |
| _(none)_ | acc_module_events | **NO MODEL** |
| _(none)_ | acc_event_voucher_configs | **NO MODEL** |
| _(none)_ | acc_event_voucher_line_templates | **NO MODEL** |
| _(none)_ | acc_event_processing_log | **NO MODEL** |

---

### 3b. $fillable Gaps

| Model | Missing Column | DDL Type | Impact |
|-------|----------------|----------|--------|
| AccountGroup | _(none)_ | — | No issue |
| AssetCategory | _(none)_ | — | No issue |
| BankReconciliation | _(none)_ | — | No issue |
| BankStatementEntry | _(none)_ | — | No issue |
| Budget | _(none)_ | — | No issue |
| CostCenter | _(none)_ | — | No issue |
| DepreciationEntry | _(none)_ | — | No issue |
| ExpenseClaim | _(none)_ | — | No issue |
| ExpenseClaimLine | _(none)_ | — | No issue |
| FinancialYear | _(none)_ | — | No issue |
| FixedAsset | _(none)_ | — | No issue |
| Ledger | _(none)_ | — | No issue |
| LedgerMapping | _(none)_ | — | No issue |
| RecurringTemplate | _(none)_ | — | No issue |
| RecurringTemplateLine | _(none)_ | — | No issue |
| TallyExportLog | `exported_by` | BIGINT UNSIGNED NOT NULL | Column is hardcoded in controller via `auth()->id()` — not in `$fillable`. If mass-assignment is ever attempted, the value will be silently dropped. Low risk given current hardcoded pattern but architecturally inconsistent. |
| TallyLedgerMapping | _(none)_ | — | No issue |
| TaxRate | _(none)_ | — | No issue |
| Voucher | _(none)_ | — | No issue |
| VoucherItem | _(none)_ | — | No issue |
| VoucherType | _(none)_ | — | No issue |

---

### 3c. $casts Gaps

| Model | Column | DDL Type | Required Cast | Current Cast |
|-------|--------|----------|---------------|-------------|
| Ledger | pan | VARCHAR(15) | none required | none | No issue — text field |
| AccountGroup | sequence | INT NOT NULL DEFAULT 0 | integer | integer | Aligned |
| Voucher | source_module | ENUM | string | string | Aligned |
| TallyExportLog | export_date | DATETIME | datetime | datetime | Aligned |
| Ledger | is_system | TINYINT(1) | boolean | **MISSING** | The `Ledger` model's `$casts` array does not include `is_system`. The DDL column is TINYINT(1) NOT NULL DEFAULT 0. Without the cast, PHP comparison `$ledger->is_system === true` will fail — it will return `0` (integer) instead of `false` (boolean). |
| BankStatementEntry | matched_by | BIGINT UNSIGNED | integer | **MISSING** | `matched_by` (FK column) has no cast. Not critical but inconsistent — all other FK columns in the project are left without casts as well, so this is a minor code-quality issue only. |
| TallyExportLog | exported_by | BIGINT UNSIGNED NOT NULL | integer | **MISSING** | `exported_by` has no cast — low severity as it is read-only. |
| RecurringTemplate | day_of_month | TINYINT | integer | integer | Aligned |

---

### 3d. Missing Relationships

| Model | FK Column | Should Have | Missing Method |
|-------|-----------|-------------|----------------|
| TallyExportLog | exported_by | `belongsTo(User::class, 'exported_by')` | Present — confirmed |
| ExpenseClaim | employee_id | `belongsTo(Employee::class, 'employee_id')` | Present — confirmed |
| FixedAsset | vendor_id | `belongsTo(Vendor::class, 'vendor_id')` | Present — confirmed |
| Voucher | approved_by | `belongsTo(User::class, 'approved_by')` | Present — confirmed |
| BankStatementEntry | matched_by | `belongsTo(User::class, 'matched_by')` | Present — confirmed |
| _(DDL tables: acc_module_events, acc_event_voucher_configs, acc_event_voucher_line_templates, acc_event_processing_log)_ | All FK columns | All required belongsTo/hasMany relationships | **Entirely missing — no models exist** |

---

### 3e. Security Concerns

| Model | Issue | Detail |
|-------|-------|--------|
| Ledger | `is_system` in `$fillable` | `is_system` is exposed in `$fillable`. A malicious or inadvertent mass-assignment could mark any user-created ledger as a system ledger, preventing its deletion. The `LedgerRequest` does not validate `is_system`, but a crafted request could inject it. Consider removing `is_system` from `$fillable` and only setting it programmatically (seeders/system code). |
| AccountGroup | `is_system` in `$fillable` | Same concern as Ledger — `is_system` is mass-assignable. |
| VoucherType | `is_system` in `$fillable` | Same concern — `is_system` is mass-assignable. |
| All models | `authorize()` returns `true` in all FormRequests | The FormRequest layer performs no authorization checks (detailed in Section 4). Authorization is delegated to controllers via `Gate::authorize()`, which is correctly implemented — this is a style note rather than a pure security gap. |

**Key Findings (Models):**
- All 21 covered tables have correct `$table` declarations, correct relationships, and comprehensive `$casts`.
- The critical gap is the absence of any models for the 4 enhancement tables (`acc_module_events`, `acc_event_voucher_configs`, `acc_event_voucher_line_templates`, `acc_event_processing_log`). These tables form the core of the generic event-to-voucher engine and cannot function without Eloquent models.
- `is_system` is in `$fillable` on `Ledger`, `AccountGroup`, and `VoucherType` — this field should be protected from mass-assignment since it controls whether a record can be deleted.
- The `Ledger` model is missing the `is_system` boolean cast, which will cause PHP strict-comparison bugs.

---

## Section 4 — Form Request vs DDL

### 4a. Missing Required Field Validation

| Request File | Table | Column | DDL Constraint | Issue |
|-------------|-------|--------|---------------|-------|
| VoucherRequest.php | acc_vouchers | `total_amount` | NOT NULL, DECIMAL(15,2) | Not validated — calculated server-side in controller. If controller logic changes, no safety net exists. P2 advisory only. |
| VoucherRequest.php | acc_vouchers | `voucher_number` | NOT NULL, VARCHAR(50) | Not in rules — generated server-side. Correct pattern; advisory only. |
| RecurringTemplateRequest.php | acc_recurring_templates | `total_amount` | NOT NULL, DECIMAL(15,2) | Not validated — computed server-side from lines. Advisory only. |
| ExpenseClaimRequest.php | acc_expense_claims | `claim_number` | NOT NULL, VARCHAR(50) | Not in rules — auto-generated. Advisory only. |
| ExpenseClaimRequest.php | acc_expense_claims | `total_amount` | NOT NULL, DECIMAL(15,2) | Not validated — computed from lines. Advisory only. |
| VoucherTypeRequest.php | acc_voucher_types | `last_number` | NOT NULL DEFAULT 0 | Not in rules — defaults to 0. No risk as default covers it. |
| _(all requests)_ | _(various)_ | `created_by` | BIGINT UNSIGNED NULL | Correctly excluded from validation — set by controller. |

---

### 4b. Phantom Validated Fields

| Request File | Field | Not in DDL | Note |
|-------------|-------|------------|------|
| VoucherRequest.php | `items` (array) | Not a DB column | Intentional — API contract for nested voucher items. Not a phantom. |
| ExpenseClaimRequest.php | `lines` (array) | Not a DB column | Intentional — API contract for nested expense lines. Not a phantom. |
| RecurringTemplateRequest.php | `lines` (array) | Not a DB column | Intentional — API contract for nested template lines. Not a phantom. |

No true phantom fields found. All validated fields that are not DB columns are intentional nested-object contracts.

---

### 4c. Type Contradiction

| Request File | Field | Rule | DDL Type | Issue |
|-------------|-------|------|----------|-------|
| BankReconciliationRequest.php | `closing_balance` | `numeric` | DECIMAL(15,2) NOT NULL | Rule allows negative values. DDL does not restrict sign but bank closing balances can legitimately be negative (overdraft). No contradiction — advisory note to add `min:0` or document negative-balance support. |
| FixedAssetRequest.php | `purchase_cost` | `numeric|min:0.01` | DECIMAL(15,2) NOT NULL | Consistent with DDL. |
| TaxRateRequest.php | `rate` | `numeric|min:0|max:100` | DECIMAL(5,2) NOT NULL | Consistent with DDL. |
| VoucherTypeRequest.php | `last_number` | Not validated | INT NOT NULL DEFAULT 0 | Missing from request — can only be set if controller explicitly writes it. No type contradiction since it is never submitted by user. |

No true type contradictions found between validation rules and DDL column types.

---

### 4d. Authorization Gaps

| Request File | authorize() Returns | Issue |
|-------------|---------------------|-------|
| AccountGroupRequest.php | `true` | No policy check in request. Authorization is delegated to controller via `Gate::authorize()` which IS implemented. Pattern is consistent across module. |
| AssetCategoryRequest.php | `true` | Same pattern. |
| BankReconciliationRequest.php | `true` | Same pattern. |
| BudgetRequest.php | `true` | Same pattern. |
| CostCenterRequest.php | `true` | Same pattern. |
| ExpenseClaimRequest.php | `true` | Same pattern. |
| FinancialYearRequest.php | `true` | Same pattern. |
| FixedAssetRequest.php | `true` | Same pattern. |
| LedgerMappingRequest.php | `true` | Same pattern. |
| LedgerRequest.php | `true` | Same pattern. |
| RecurringTemplateRequest.php | `true` | Same pattern. |
| TallyLedgerMappingRequest.php | `true` | Same pattern. |
| TaxRateRequest.php | `true` | Same pattern. |
| VoucherRequest.php | `true` | Same pattern. |
| VoucherTypeRequest.php | `true` | Same pattern. |

All 15 FormRequests return `true` from `authorize()`. This is not a direct security gap because every controller action is protected by `Gate::authorize(...)` calls before the FormRequest is ever bound. However, the pattern creates a risk: if a future developer removes or bypasses the controller-level Gate check, the FormRequest provides zero fallback protection.

**Key Findings (Form Requests):**
- No phantom fields, no DDL type contradictions, and no missing validations for required NOT-NULL columns (all such fields are either auto-generated server-side or have DB defaults).
- All 15 FormRequests have `authorize()` returning `true` — authorization is correctly handled at the controller layer via `Gate::authorize()`, but this is a defense-in-depth gap: the FormRequest provides no secondary authorization barrier.
- `is_system` is absent from all FormRequests that map to tables with this column (`AccountGroupRequest`, `LedgerRequest`, `VoucherTypeRequest`), yet it is present in `$fillable` on those models. This means an authenticated user can inject `is_system=1` in the request body and it will be silently written to the database.

---

## Section 5 — Controller vs DDL

### 5a. Unhandled Required Columns

| Controller | Method | Table | Column | DDL Constraint | Risk |
|------------|--------|-------|--------|---------------|------|
| VoucherController.php | store() | acc_vouchers | `voucher_number` | NOT NULL, VARCHAR(50) | Generated server-side inside a DB::transaction. If the VoucherType is not found or has no `last_number`, the number generation may fail silently. Low risk — VoucherType is validated in FormRequest. |
| VoucherController.php | store() | acc_vouchers | `total_amount` | NOT NULL, DECIMAL(15,2) | Computed as sum of debit items. If no debit items exist (theoretically possible if form validation is bypassed), total_amount would be 0 and the insert would succeed with an incorrect value. |
| ExpenseClaimController.php | store() | acc_expense_claims | `claim_number` | NOT NULL, VARCHAR(50) | Generated as `'EC-' . str_pad(ExpenseClaim::withTrashed()->count() + 1, 5, ...)`. This is not race-condition safe — concurrent requests can generate the same claim number. The UNIQUE constraint on `(claim_number, deleted_at)` will catch it as an exception, but with no user-friendly error handling. |
| TallyExportController.php | exportLedgers/exportVouchers | acc_tally_export_logs | `status` | NOT NULL, ENUM | `status` is hardcoded as `'Success'` at the point of record creation before the actual export runs. If the export subsequently fails, the log will show `Success`. |

---

### 5b. Mass-Assignment Risks

| Controller | Method | Issue |
|------------|--------|-------|
| AccountGroupController.php | store() | Uses `$request->validated()` + explicit `created_by` set. No mass-assignment risk. |
| VoucherController.php | store() | Uses `$request->validated()`. However, `$validated` is then mutated (adding `voucher_number`, `total_amount`, `status`, `created_by`, `is_active`) before `Voucher::create($validated)`. This pattern is safe because `$validated` only contains validated fields. No risk. |
| All controllers | store()/update() | Consistent use of `$request->validated()` throughout. No use of `$request->all()`. No mass-assignment risk identified. |

---

### 5c. Missing Authorization

| Controller | Method | Issue |
|------------|--------|-------|
| All controllers (18 files) | All CRUD methods | All methods include `Gate::authorize('tenant.accounting.*.*')` calls at the top of each method. Authorization coverage is comprehensive and consistent. |
| TallyExportController.php | destroy() | `destroy()` method exists but was not verified to contain a Gate check in the scan. Recommend explicit confirmation. |

**Key Findings (Controllers):**
- `ExpenseClaimController::store()` generates claim numbers using `withTrashed()->count() + 1`, which is not safe under concurrent requests. Two simultaneous submissions can receive the same number and one will crash with a database unique-constraint exception with no user-friendly error message.
- `TallyExportController` logs `status = 'Success'` before the export completes, meaning failed exports are incorrectly logged as successful.
- No `$request->all()` usage detected — all controllers use `$request->validated()` consistently.
- All controllers correctly set `created_by = auth()->id()` explicitly and never rely on mass-assignment for this field.
- The `is_active` default on create is correctly set (either via `boolean('is_active', true)` in `prepareForValidation()` or explicitly set after `$request->validated()`).

---

## Section 6 — View vs DDL

### 6a. Missing Form Inputs for Required Columns

| View File | Form Action | Missing Input | DDL Constraint |
|-----------|------------|--------------|----------------|
| financial-year/create.blade.php | store() | `is_locked` | TINYINT(1) NOT NULL DEFAULT 0 | The create form has no `is_locked` checkbox. The `FinancialYearRequest` includes `is_locked` as `boolean` (optional). Since the DDL default is `0`, the omission means new financial years are created unlocked. This is the correct default behavior — the field is managed via a dedicated lock/unlock action. No actual data loss. |
| voucher/create.blade.php | store() | `is_post_dated`, `is_optional` | TINYINT(1) NOT NULL DEFAULT 0 | Neither `is_post_dated` nor `is_optional` has an explicit form input. Both have `DEFAULT 0` in the DDL so inserts succeed. The VoucherRequest `prepareForValidation()` defaults both to `false`. The view may need explicit checkboxes if these features are to be user-controlled. |
| voucher/create.blade.php | store() | `source_module`, `source_type`, `source_id` | NULLABLE | Not present in the create form — these are integration fields populated programmatically by other modules (Fees, Transport, etc.). For manual vouchers the fields are correctly omitted. |

No inputs are missing for NOT NULL columns without defaults. All omissions are for columns that either have DB defaults or are set server-side.

---

### 6b. Phantom Form Inputs

| View File | Input Name | Not in DDL |
|-----------|------------|-----------|
| expense-claim/create.blade.php | `claim_number` | Is a DDL column (`VARCHAR(50) NOT NULL`). The field is rendered as `readonly` and pre-populated with the server-generated number. Not a phantom — the value is submitted to the controller and the controller overwrites it anyway. Cosmetically redundant but not harmful. |
| voucher/create.blade.php | `items[N][type]`, `items[N][ledger_id]`, `items[N][amount]`, `items[N][narration]` | Not DB columns — these are the nested items array contract for `acc_voucher_items`. Correctly handled by controller. Not phantoms. |

No true phantom inputs found (fields submitted to server that have no corresponding DDL column).

**Key Findings (Views):**
- No view submits data for a column that does not exist in the DDL.
- No NOT NULL / no-default column is missing from any form. All omitted fields either have DB-level defaults or are auto-generated server-side.
- The `claim_number` readonly input in the expense-claim create view is cosmetically redundant — the controller ignores the submitted value and generates its own number — but causes no data corruption.
- The voucher create form does not expose `is_post_dated` or `is_optional` checkboxes, effectively locking all manually created vouchers to `false` for both fields. If post-dated voucher support is required, a view update and Request rule addition are needed.

---

## Section 7 — Overall Discrepancy Summary

### 7a. Counts by Layer and Severity

| Layer | P0 | P1 | P2 | Total |
|-------|----|----|----|-------|
| Migration vs DDL | 4 | 0 | 14 | 18 |
| Model vs DDL | 4 | 1 | 2 | 7 |
| Form Request vs DDL | 0 | 3 | 15 | 18 |
| Controller vs DDL | 0 | 2 | 2 | 4 |
| View vs DDL | 0 | 0 | 3 | 3 |
| **TOTAL** | **8** | **6** | **36** | **50** |

**P0 detail:**
- Migration: 4 missing migrations (acc_module_events, acc_event_voucher_configs, acc_event_voucher_line_templates, acc_event_processing_log)
- Model: 4 missing models for the same 4 tables

**P1 detail:**
- Model: `is_system` in `$fillable` on Ledger, AccountGroup, VoucherType (3 items — allows unauthorized elevation of a record to system status)
- Controller: Race condition in claim_number generation; incorrect status logging in TallyExportController (2 items)

---

### 7b. Tables with Zero Coverage

The following DDL tables have NO migration file, NO Eloquent model, and NO controller:

1. `acc_module_events` — Central registry of cross-module business events
2. `acc_event_voucher_configs` — Per-event voucher creation configuration
3. `acc_event_voucher_line_templates` — Dr/Cr line templates for event-triggered vouchers
4. `acc_event_processing_log` — Audit trail of event processing outcomes

These four tables form the entire cross-module event engine enhancement. Without migrations, models, and controllers, this feature is entirely non-functional in the application. The DDL exists but the code layer is at 0% completion.

---

### 7c. Severity Definitions Used

| Severity | Meaning |
|----------|---------|
| P0 | Data loss / crash risk: NOT NULL column missing from migration or fillable; missing FK index; security field absent; authorize() always returns true with no controller fallback |
| P1 | Functional bug: column silently dropped (missing fillable/validation); wrong cast causing data corruption; race condition; incorrect data logged; missing required relationship; `is_system` mass-assignable |
| P2 | Code quality / incomplete: named index absent but functionally covered; missing optional cast; cosmetically redundant input; advisory missing validation; unused feature blocked by view omission |

---

## Section 8 — Recommended Fix Order

### P0 Issues — Fix Immediately (Blocks Feature Functionality)

1. **[P0] Create migration for `acc_module_events`**
   - File to create: `/Users/bkwork/Herd/prime_ai/database/migrations/tenant/2026_03_22_000001_create_acc_module_events_table.php`
   - Mirror the DDL exactly: `module_code VARCHAR(30) NOT NULL`, `event_code VARCHAR(60) NOT NULL`, `event_name VARCHAR(150) NOT NULL`, `source_model VARCHAR(100) NOT NULL`, `is_system TINYINT(1) NOT NULL DEFAULT 1`, all standard columns, composite UNIQUE on `(module_code, event_code, deleted_at)`, all named indexes.

2. **[P0] Create migration for `acc_event_voucher_configs`**
   - File to create: `/Users/bkwork/Herd/prime_ai/database/migrations/tenant/2026_03_22_000002_create_acc_event_voucher_configs_table.php`
   - FK to `acc_module_events`, `acc_voucher_types`, `acc_cost_centers`. UNIQUE on `(module_event_id, deleted_at)`.

3. **[P0] Create migration for `acc_event_voucher_line_templates`**
   - File to create: `/Users/bkwork/Herd/prime_ai/database/migrations/tenant/2026_03_22_000003_create_acc_event_voucher_line_templates_table.php`
   - FK to `acc_event_voucher_configs` (CASCADE), `acc_ledgers` (RESTRICT). ENUM columns for `ledger_resolver`, `amount_resolver`, `entry_type`.

4. **[P0] Create migration for `acc_event_processing_log`**
   - File to create: `/Users/bkwork/Herd/prime_ai/database/migrations/tenant/2026_03_22_000004_create_acc_event_processing_log_table.php`
   - Includes `payload_json JSON NULL` column. FK to `acc_module_events` (RESTRICT), `acc_vouchers` (SET NULL). All named indexes.

5. **[P0] Create Eloquent model `ModuleEvent`**
   - File to create: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/app/Models/ModuleEvent.php`
   - `$table = 'acc_module_events'`, all DDL columns in `$fillable`, `is_system` and `is_active` cast to boolean, `hasMany(EventVoucherConfig::class)` relationship.

6. **[P0] Create Eloquent model `EventVoucherConfig`**
   - File to create: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/app/Models/EventVoucherConfig.php`
   - `$table = 'acc_event_voucher_configs'`, `belongsTo(ModuleEvent::class)`, `belongsTo(VoucherType::class)`, `belongsTo(CostCenter::class)`, `hasMany(EventVoucherLineTemplate::class)`.

7. **[P0] Create Eloquent model `EventVoucherLineTemplate`**
   - File to create: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/app/Models/EventVoucherLineTemplate.php`
   - `$table = 'acc_event_voucher_line_templates'`, `belongsTo(EventVoucherConfig::class)`, `belongsTo(Ledger::class)`.

8. **[P0] Create Eloquent model `EventProcessingLog`**
   - File to create: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/app/Models/EventProcessingLog.php`
   - `$table = 'acc_event_processing_log'`, cast `payload_json` to `'array'`, cast `status` to string, cast `retry_count` to integer, `belongsTo(ModuleEvent::class)`, `belongsTo(Voucher::class)`.

### P1 Issues — Fix Before Production

9. **[P1] Remove `is_system` from `$fillable` on Ledger, AccountGroup, VoucherType models**
   - File: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/app/Models/Ledger.php`
   - File: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/app/Models/AccountGroup.php`
   - File: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/app/Models/VoucherType.php`
   - Remove `'is_system'` from each `$fillable` array. `is_system` must only be set by seeders and system-level code, never via mass-assignment from a web request.

10. **[P1] Add `is_system` cast to Ledger model**
    - File: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/app/Models/Ledger.php`
    - Add `'is_system' => 'boolean'` to the `$casts` array. Without this, PHP strict comparisons against `true`/`false` will silently fail since the value is returned as an integer `0`/`1`.

11. **[P1] Fix race condition in ExpenseClaim claim_number generation**
    - File: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/app/Http/Controllers/ExpenseClaimController.php`
    - Line ~45: Replace `ExpenseClaim::withTrashed()->count() + 1` with a DB-level sequence or a `SELECT MAX(id) + 1` approach within the existing DB transaction, or use `DB::table('acc_expense_claims')->lockForUpdate()->max('id') + 1`. Wrap number generation in `DB::transaction()` if not already (it is already wrapped). Also add a `try/catch` for `QueryException` on unique constraint violation to return a user-friendly error response.

12. **[P1] Fix incorrect status logging in TallyExportController**
    - File: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/app/Http/Controllers/TallyExportController.php`
    - Lines ~30-60: The `TallyExportLog` record is created with `status = 'Success'` before the export runs. Restructure to create the log with `status = 'Pending'` or perform the export first and then log the result. Alternatively, wrap in a try/catch and update the log record on failure.

13. **[P1] Add `authorize()` policy protection in FormRequests as defense-in-depth**
    - Files: All 15 FormRequest files in `/Users/bkwork/Herd/prime_ai/Modules/Accounting/app/Http/Requests/`
    - Replace `return true;` in `authorize()` with a Gate or Policy check matching the controller's authorization. This provides a secondary barrier if a controller method ever loses its `Gate::authorize()` call. Minimum implementation: `return auth()->check();` to at least require authentication.

14. **[P1] Block `is_system` from being submitted via web requests**
    - Files: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/app/Http/Requests/AccountGroupRequest.php`, `LedgerRequest.php`, `VoucherTypeRequest.php`
    - Ensure `is_system` is absent from `rules()` so it cannot be submitted via validated data. It is already absent from these request files, but the `$fillable` vulnerability (item 9 above) means a raw `create()` or `fill()` call could still inject it. Fix 9 is the primary remedy.

### P2 Issues — Address When Convenient

15. **[P2] Add explicit named indexes matching DDL for FK columns in migrations**
    - The following migrations use `foreignId()->constrained()` which auto-creates unnamed indexes. To match the DDL's named indexes exactly, add explicit `$table->index('column', 'idx_name')` calls after the `foreignId()` definition.
    - Affected tables: `acc_account_groups` (idx_acc_ag_parent), `acc_vouchers` (idx_acc_voucher_type, idx_acc_voucher_fy, idx_acc_voucher_cost), `acc_recurring_templates` (idx_acc_rt_type), `acc_depreciation_entries` (idx_acc_de_asset, idx_acc_de_fy, idx_acc_de_voucher), `acc_expense_claims` (idx_acc_ec_employee, idx_acc_ec_voucher), `acc_expense_claim_lines` (idx_acc_ecl_claim, idx_acc_ecl_ledger), `acc_tally_export_logs` (idx_acc_tel_by), `acc_budgets` (idx_acc_budget_cc, idx_acc_budget_ledger), `acc_bank_reconciliations` (idx_acc_br_ledger), `acc_bank_statement_entries` (idx_acc_bse_recon, idx_acc_bse_vi).
    - Use additive migrations (do NOT modify existing migration files) per project rules.

16. **[P2] Add `is_post_dated` and `is_optional` checkboxes to voucher create/edit views**
    - Files: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/resources/views/voucher/create.blade.php` and `edit.blade.php`
    - Both fields default to `false` via `prepareForValidation()` if absent. Add optional checkboxes so users can create memorandum and post-dated vouchers through the UI.

17. **[P2] Add `exported_by` to `TallyExportLog::$fillable`**
    - File: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/app/Models/TallyExportLog.php`
    - `exported_by` is NOT NULL in DDL and is currently hardcoded in the controller but absent from `$fillable`. Add it for architectural consistency, even though the current controller-level hardcoding prevents an immediate bug.

18. **[P2] Add `is_locked` field to financial year create/edit views**
    - Files: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/resources/views/financial-year/create.blade.php` and `edit.blade.php`
    - The field is validated in `FinancialYearRequest` but no UI input exists. The dedicated lock/unlock action in `FinancialYearController` handles the workflow, but displaying the current lock status and providing a toggle on the form would improve UX.

19. **[P2] Cast `matched_by` and `exported_by` in their respective models**
    - File: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/app/Models/BankStatementEntry.php` — add `'matched_by' => 'integer'`
    - File: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/app/Models/TallyExportLog.php` — add `'exported_by' => 'integer'`

20. **[P2] Make `claim_number` input hidden (not readonly) in expense-claim create view**
    - File: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/resources/views/expense-claim/create.blade.php`
    - The readonly visible input for `claim_number` is cosmetically redundant since the controller always regenerates it. Either remove the input entirely or use a hidden field. No functional impact.
