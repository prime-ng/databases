# ERP Architect GPT - Student Fee Management Module
## Complete Data Dictionary

---

## TABLE OF CONTENTS

1. [Master Configuration Tables](#1-master-configuration-tables)
   - [fee_head_master](#fee_head_master)
   - [fee_group_master](#fee_group_master)
   - [fee_group_heads_jnt](#fee_group_heads_jnt)
   - [fee_structure_master](#fee_structure_master)
   - [fee_structure_details](#fee_structure_details)
   - [fee_installments](#fee_installments)
   - [fee_fine_rules](#fee_fine_rules)
   - [fee_concession_types](#fee_concession_types)
   - [fee_concession_applicable_heads](#fee_concession_applicable_heads)

2. [Student Assignment Tables](#2-student-assignment-tables)
   - [fee_student_assignments](#fee_student_assignments)
   - [fee_student_concessions](#fee_student_concessions)

3. [Transaction Tables](#3-transaction-tables)
   - [fee_invoices](#fee_invoices)
   - [fee_transactions](#fee_transactions)
   - [fee_transaction_details](#fee_transaction_details)
   - [fee_receipts](#fee_receipts)

4. [Fine Management Tables](#4-fine-management-tables)
   - [fee_fine_transactions](#fee_fine_transactions)
   - [fee_name_removal_log](#fee_name_removal_log)

5. [Payment Gateway Tables](#5-payment-gateway-tables)
   - [fee_payment_gateway_logs](#fee_payment_gateway_logs)

6. [Scholarship Tables](#6-scholarship-tables)
   - [fee_scholarships](#fee_scholarships)
   - [fee_scholarship_applications](#fee_scholarship_applications)
   - [fee_scholarship_approval_history](#fee_scholarship_approval_history)

---

## 1. MASTER CONFIGURATION TABLES

### fee_head_master

**Table Purpose:** Stores the core building blocks of all fees. Each record represents a distinct type of fee that can be charged to students (e.g., Tuition, Transport, Hostel). This table acts as the central repository for all possible fee components across the institution.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each fee head record |
| `head_code` | VARCHAR(50) | NO | UNIQUE | - | Business-friendly unique code (e.g., 'TUIT', 'TRAN') used in reports and API calls for quick reference |
| `head_name` | VARCHAR(100) | NO | - | - | Display name shown in UI (e.g., 'Tuition Fee', 'Transport Fee') |
| `head_type` | ENUM('Tuition', 'Transport', 'Hostel', 'Library', 'Sports', 'Exam', 'Activity', 'Lab', 'Development', 'Other') | NO | Index | - | Categorizes fee head for reporting and filtering. Helps in generating head-type wise reports |
| `frequency` | ENUM('One-time', 'Monthly', 'Quarterly', 'Half-Yearly', 'Yearly') | NO | - | 'Monthly' | Defines how often this fee is charged. Used by invoice generation logic to create recurring invoices |
| `is_refundable` | BOOLEAN | NO | - | FALSE | Indicates if the fee is refundable (like Caution Money) vs non-refundable (like Tuition). Used during student withdrawal |
| `tax_applicable` | BOOLEAN | NO | - | FALSE | Flag to indicate if tax (GST) should be applied to this fee head |
| `tax_percentage` | DECIMAL(5,2) | YES | - | 0.00 | Tax rate to apply if tax_applicable is TRUE |
| `account_head_code` | VARCHAR(50) | YES | - | NULL | Maps to accounting system's chart of accounts for financial reporting integration |
| `display_order` | INT | NO | - | 0 | Controls sorting order in dropdowns and UI lists |
| `description` | TEXT | YES | - | NULL | Detailed explanation of what this fee covers |
| `is_active` | BOOLEAN | NO | Index | TRUE | Soft delete flag - TRUE for active, FALSE for deactivated (kept for historical data) |
| `created_by` | INT UNSIGNED | YES | - | NULL | User ID who created this record (FK to sys_users) |
| `updated_by` | INT UNSIGNED | YES | - | NULL | User ID who last updated this record |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |
| `deleted_at` | TIMESTAMP | YES | - | NULL | Soft delete timestamp - NULL means active record |

---

### fee_group_master

**Table Purpose:** Defines logical groupings of fee heads to simplify fee structure creation. For example, an "Academic Package" might combine Tuition + Library + Lab fees. This allows schools to offer bundled fee packages to students.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each fee group |
| `group_code` | VARCHAR(50) | NO | UNIQUE | - | Business code for the group (e.g., 'ACADEMIC', 'TRANSPORT') |
| `group_name` | VARCHAR(100) | NO | - | - | Display name shown in UI (e.g., 'Academic Package') |
| `description` | TEXT | YES | - | NULL | Detailed description of what the group includes |
| `is_mandatory` | BOOLEAN | NO | - | TRUE | If TRUE, students must take this group. If FALSE, students can opt out |
| `display_order` | INT | NO | - | 0 | Controls sorting in UI dropdowns |
| `is_active` | BOOLEAN | NO | Index | TRUE | Soft delete flag |
| `created_by` | INT UNSIGNED | YES | - | NULL | User ID who created this record |
| `updated_by` | INT UNSIGNED | YES | - | NULL | User ID who last updated this record |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |
| `deleted_at` | TIMESTAMP | YES | - | NULL | Soft delete timestamp |

---

### fee_group_heads_jnt

**Table Purpose:** Junction table that maps fee heads to fee groups (Many-to-Many relationship). Also stores group-specific configuration like whether a head is optional within the group and its default amount.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each group-head mapping |
| `group_id` | BIGINT UNSIGNED | NO | FK | - | References the fee group (fee_group_master.id) |
| `head_id` | BIGINT UNSIGNED | NO | FK | - | References the fee head (fee_head_master.id) |
| `is_optional` | BOOLEAN | NO | - | FALSE | Within this group, can student opt out of this specific head? |
| `default_amount` | DECIMAL(10,2) | YES | - | NULL | Default amount for this head when part of this group (can be overridden in structure) |
| `display_order` | INT | NO | - | 0 | Order within the group for UI display |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |

---

### fee_structure_master

**Table Purpose:** Defines the complete fee structure for a specific combination of academic session, class, student category, and board. This is the template that determines how much students in a particular category should pay.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each fee structure |
| `academic_session_id` | INT UNSIGNED | NO | FK | - | References the academic session (sch_org_academic_sessions_jnt.id) |
| `class_id` | INT UNSIGNED | NO | FK | - | References the class (sch_classes.id) |
| `student_category_id` | INT UNSIGNED | YES | FK | NULL | References student category from sys_dropdown_table (General/OBC/SC/ST). NULL means applicable to all |
| `board_type` | VARCHAR(50) | YES | - | NULL | Board type (CBSE/ICSE/State). NULL means applicable to all |
| `structure_name` | VARCHAR(100) | NO | - | - | Descriptive name for this structure (e.g., "Class 10 CBSE General 2026-27") |
| `effective_from` | DATE | NO | - | - | Date from which this structure becomes valid |
| `effective_to` | DATE | YES | - | NULL | Date until which this structure is valid. NULL means indefinitely valid |
| `total_fee_amount` | DECIMAL(12,2) | YES | - | NULL | Pre-calculated sum of all heads for quick access (denormalized for performance) |
| `is_active` | BOOLEAN | NO | Index | TRUE | Soft delete flag |
| `created_by` | INT UNSIGNED | YES | - | NULL | User ID who created this record |
| `updated_by` | INT UNSIGNED | YES | - | NULL | User ID who last updated this record |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |
| `deleted_at` | TIMESTAMP | YES | - | NULL | Soft delete timestamp |

---

### fee_structure_details

**Table Purpose:** Line items of the fee structure. Stores individual fee heads and their amounts for each fee structure master record. This is where the actual fee amounts are defined.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each fee structure detail |
| `fee_structure_id` | BIGINT UNSIGNED | NO | FK | - | References the fee structure master (fee_structure_master.id) |
| `head_id` | BIGINT UNSIGNED | NO | FK | - | References the fee head (fee_head_master.id) |
| `group_id` | BIGINT UNSIGNED | YES | FK | NULL | References the fee group if this head came from a group. NULL means direct head assignment |
| `amount` | DECIMAL(10,2) | NO | - | - | The actual fee amount for this head in this structure |
| `is_optional` | BOOLEAN | NO | - | FALSE | Whether this specific head is optional in this structure |
| `tax_included` | BOOLEAN | NO | - | FALSE | Whether the amount already includes tax (vs tax to be added) |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |

---

### fee_installments

**Table Purpose:** Defines how the total fee is split into installments for a given fee structure. Stores due dates, percentages, and amounts for each installment.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each installment |
| `fee_structure_id` | BIGINT UNSIGNED | NO | FK | - | References the fee structure (fee_structure_master.id) |
| `installment_no` | INT | NO | - | - | Sequential number (1,2,3...) for ordering |
| `installment_name` | VARCHAR(100) | NO | - | - | Display name (e.g., "Term 1", "Diwali Installment") |
| `due_date` | DATE | NO | - | - | Date by which this installment must be paid |
| `percentage_due` | DECIMAL(5,2) | NO | - | - | Percentage of total fee due in this installment |
| `amount_due` | DECIMAL(10,2) | YES | - | NULL | Calculated amount (total_fee * percentage_due / 100). Stored for performance |
| `grace_days` | INT | NO | - | 0 | Number of days after due date before fines apply |
| `is_active` | BOOLEAN | NO | - | TRUE | Whether this installment is active |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |

---

### fee_fine_rules

**Table Purpose:** Defines rules for calculating late payment fines. Supports complex tiered structures (e.g., 10% for days 1-10, 20% for days 11-30, etc.) and actions like name removal after certain days.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each fine rule |
| `rule_name` | VARCHAR(100) | NO | - | - | Descriptive name (e.g., "Late Fee Tier 1") |
| `applicable_on` | ENUM('Fee Structure', 'Installment', 'Head') | NO | - | 'Installment' | What this rule applies to: Fee Structure, Installment, or Head |
| `applicable_id` | BIGINT UNSIGNED | NO | Index | - | ID of the entity (based on applicable_on) this rule applies to |
| `fine_type` | ENUM('Percentage', 'Fixed', 'Percentage+Capped') | NO | - | - | Type of fine: Percentage, Fixed, or Percentage with Cap |
| `fine_value` | DECIMAL(10,2) | NO | - | - | Value for fine (percentage or fixed amount) |
| `max_fine_amount` | DECIMAL(10,2) | YES | - | NULL | Maximum cap amount for Percentage+Capped type |
| `grace_period_days` | INT | NO | - | 0 | Days after due date before fine starts applying |
| `recurring` | BOOLEAN | NO | - | FALSE | If TRUE, fine applies every day/week; if FALSE, one-time |
| `recurring_interval_days` | INT | YES | - | NULL | If recurring, how many days between applications |
| `max_fine_installments` | INT | YES | - | NULL | Maximum number of times fine can be applied |
| `applicable_from_day` | INT | NO | - | 1 | Starting day after due date when this rule applies |
| `applicable_to_day` | INT | YES | - | NULL | Ending day when this rule applies. NULL means no upper limit |
| `action_on_expiry` | ENUM('None', 'Mark Defaulter', 'Remove Name', 'Suspend') | YES | - | NULL | Action to take when max days reached (Mark Defaulter, Remove Name, Suspend) |
| `is_active` | BOOLEAN | NO | Index | TRUE | Soft delete flag |
| `created_by` | INT UNSIGNED | YES | - | NULL | User ID who created this record |
| `updated_by` | INT UNSIGNED | YES | - | NULL | User ID who last updated this record |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |
| `deleted_at` | TIMESTAMP | YES | - | NULL | Soft delete timestamp |

---

### fee_concession_types

**Table Purpose:** Defines types of concessions/discounts that can be applied to student fees (e.g., Sibling Concession, Merit Scholarship, Staff Concession). Includes approval workflow configuration.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each concession type |
| `concession_code` | VARCHAR(50) | NO | UNIQUE | - | Business code (e.g., 'SIB10', 'MERIT25') |
| `concession_name` | VARCHAR(100) | NO | - | - | Display name (e.g., "Sibling Concession 10%") |
| `concession_category` | ENUM('Sibling', 'Merit', 'Staff', 'Financial Aid', 'Sports', 'Alumni', 'Other') | NO | Index | - | Category for grouping reports (Sibling, Merit, Staff, etc.) |
| `discount_type` | ENUM('Percentage', 'Fixed Amount') | NO | - | - | Whether discount is Percentage or Fixed Amount |
| `discount_value` | DECIMAL(10,2) | NO | - | - | Value of discount (percentage or amount) |
| `applicable_on` | ENUM('Total Fee', 'Specific Heads', 'Specific Groups') | NO | - | - | What this discount applies to: Total Fee, Specific Heads, or Groups |
| `max_cap_amount` | DECIMAL(10,2) | YES | - | NULL | Maximum discount amount (for percentage type) |
| `requires_approval` | BOOLEAN | NO | - | TRUE | Whether this concession needs approval before applying |
| `approval_level` | INT | YES | - | NULL | 1=Class Teacher, 2=Principal, 3=Management |
| `is_active` | BOOLEAN | NO | Index | TRUE | Soft delete flag |
| `created_by` | INT UNSIGNED | YES | - | NULL | User ID who created this record |
| `updated_by` | INT UNSIGNED | YES | - | NULL | User ID who last updated this record |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |
| `deleted_at` | TIMESTAMP | YES | - | NULL | Soft delete timestamp |

---

### fee_concession_applicable_heads

**Table Purpose:** For concessions that apply only to specific fee heads (applicable_on = 'Specific Heads'), this table maps which heads are eligible for the concession.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each concession-head mapping |
| `concession_type_id` | BIGINT UNSIGNED | NO | FK | - | References the concession type (fee_concession_types.id) |
| `head_id` | BIGINT UNSIGNED | NO | FK | - | References the fee head (fee_head_master.id) that this concession applies to |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |

---

## 2. STUDENT ASSIGNMENT TABLES

### fee_student_assignments

**Table Purpose:** Records the actual fee structure assigned to a specific student for a specific academic session. This is where the configured fee structure meets the individual student, including their choices for optional heads/groups.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each student fee assignment |
| `student_id` | INT UNSIGNED | NO | FK | - | References the student (std_students.id) |
| `academic_session_id` | INT UNSIGNED | NO | FK | - | References the academic session (sch_org_academic_sessions_jnt.id) |
| `fee_structure_id` | BIGINT UNSIGNED | NO | FK | - | References the fee structure (fee_structure_master.id) assigned |
| `total_fee_amount` | DECIMAL(12,2) | NO | - | - | Total fee amount after optional selections (denormalized for performance) |
| `opted_heads` | JSON | YES | - | NULL | JSON array of optional head IDs that student selected |
| `opted_groups` | JSON | YES | - | NULL | JSON array of optional group IDs that student selected |
| `assignment_date` | DATE | NO | - | - | Date when this assignment was created |
| `is_active` | BOOLEAN | NO | Index | TRUE | Whether this assignment is currently active |
| `created_by` | INT UNSIGNED | YES | - | NULL | User ID who created this assignment |
| `updated_by` | INT UNSIGNED | YES | - | NULL | User ID who last updated this assignment |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |
| `deleted_at` | TIMESTAMP | YES | - | NULL | Soft delete timestamp |

---

### fee_student_concessions

**Table Purpose:** Tracks concessions/discounts applied to specific student fee assignments. Includes approval workflow status and history.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each student concession |
| `student_assignment_id` | BIGINT UNSIGNED | NO | FK | - | References the student fee assignment (fee_student_assignments.id) |
| `concession_type_id` | BIGINT UNSIGNED | NO | FK | - | References the concession type (fee_concession_types.id) |
| `approved_by` | INT UNSIGNED | YES | FK | NULL | User ID who approved/rejected this concession |
| `approved_at` | TIMESTAMP | YES | - | NULL | Timestamp of approval/rejection action |
| `approval_status` | ENUM('Pending', 'Approved', 'Rejected') | NO | Index | 'Pending' | Current status: Pending, Approved, Rejected |
| `rejection_reason` | TEXT | YES | - | NULL | Reason if rejected |
| `discount_amount` | DECIMAL(10,2) | NO | - | - | Actual discount amount calculated |
| `remarks` | TEXT | YES | - | NULL | Additional notes |
| `created_by` | INT UNSIGNED | YES | - | NULL | User ID who requested/created this concession |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |

---

## 3. TRANSACTION TABLES

### fee_invoices

**Table Purpose:** Represents a bill/invoice generated for a student, typically for a specific installment. Tracks the amount due, payments made, and current status.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each invoice |
| `invoice_no` | VARCHAR(50) | NO | UNIQUE | - | Business-facing invoice number (e.g., "INV-2026-00001") |
| `student_assignment_id` | BIGINT UNSIGNED | NO | FK | - | References the student fee assignment |
| `installment_id` | BIGINT UNSIGNED | YES | FK | NULL | References the installment (NULL for one-time payments) |
| `invoice_date` | DATE | NO | - | - | Date when invoice was generated |
| `due_date` | DATE | NO | - | - | Date by which payment is due |
| `base_amount` | DECIMAL(12,2) | NO | - | - | Original fee amount before concessions/fines |
| `concession_amount` | DECIMAL(12,2) | NO | - | 0.00 | Total concession amount applied to this invoice |
| `fine_amount` | DECIMAL(12,2) | NO | - | 0.00 | Total fine amount applied to this invoice |
| `total_amount` | DECIMAL(12,2) | NO | - | - | Final amount due (base - concession + fine) |
| `paid_amount` | DECIMAL(12,2) | NO | - | 0.00 | Amount paid so far |
| `balance_amount` | DECIMAL(12,2) | GENERATED | - | STORED | Calculated as total_amount - paid_amount |
| `status` | ENUM('Draft', 'Published', 'Partially Paid', 'Paid', 'Overdue', 'Cancelled') | NO | Index | 'Draft' | Current invoice status |
| `invoice_pdf_path` | VARCHAR(255) | YES | - | NULL | File path to generated PDF invoice |
| `generated_by` | INT UNSIGNED | NO | FK | - | User ID who generated this invoice |
| `cancelled_by` | INT UNSIGNED | YES | FK | NULL | User ID who cancelled this invoice |
| `cancellation_reason` | TEXT | YES | - | NULL | Reason for cancellation |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |
| `deleted_at` | TIMESTAMP | YES | - | NULL | Soft delete timestamp |

---

### fee_transactions

**Table Purpose:** Master record of each payment transaction. Captures all details of a payment event, whether online or at counter.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each transaction |
| `transaction_no` | VARCHAR(50) | NO | UNIQUE | - | Business-facing transaction number |
| `student_id` | INT UNSIGNED | NO | FK | - | References the student (std_students.id) |
| `invoice_id` | BIGINT UNSIGNED | NO | FK | - | References the invoice being paid |
| `guardian_id` | INT UNSIGNED | YES | FK | NULL | References the guardian who paid (std_guardians.id) |
| `payment_date` | DATETIME | NO | - | - | Date and time of payment |
| `payment_mode` | ENUM('Cash', 'Cheque', 'DD', 'UPI', 'Credit Card', 'Debit Card', 'Net Banking', 'Wallet') | NO | Index | - | Mode of payment used |
| `payment_reference` | VARCHAR(100) | YES | - | NULL | External reference (Cheque/DD/Transaction ID) |
| `bank_name` | VARCHAR(100) | YES | - | NULL | Bank name for Cheque/DD |
| `cheque_date` | DATE | YES | - | NULL | Date on Cheque/DD |
| `amount` | DECIMAL(12,2) | NO | - | - | Total amount paid |
| `fine_adjusted` | DECIMAL(10,2) | NO | - | 0.00 | Portion of payment that went towards fines |
| `concession_adjusted` | DECIMAL(10,2) | NO | - | 0.00 | Portion of payment that was concession |
| `status` | ENUM('Success', 'Pending', 'Failed', 'Refunded') | NO | Index | 'Pending' | Transaction status |
| `collected_by` | INT UNSIGNED | NO | FK | - | User ID who collected/processed payment |
| `remarks` | TEXT | YES | - | NULL | Additional notes |
| `receipt_generated` | BOOLEAN | NO | - | FALSE | Whether receipt has been generated |
| `receipt_id` | BIGINT UNSIGNED | YES | - | NULL | References the receipt (fee_receipts.id) |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |
| `deleted_at` | TIMESTAMP | YES | - | NULL | Soft delete timestamp |

---

### fee_transaction_details

**Table Purpose:** Splits a transaction into allocations across different fee heads. Allows precise tracking of how much was paid for each fee component.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each transaction detail |
| `transaction_id` | BIGINT UNSIGNED | NO | FK | - | References the master transaction (fee_transactions.id) |
| `head_id` | BIGINT UNSIGNED | NO | FK | - | References the fee head (fee_head_master.id) |
| `amount` | DECIMAL(10,2) | NO | - | - | Amount allocated to this head |
| `fine_amount` | DECIMAL(10,2) | NO | - | 0.00 | Fine portion allocated to this head |
| `concession_amount` | DECIMAL(10,2) | NO | - | 0.00 | Concession portion allocated to this head |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |

---

### fee_receipts

**Table Purpose:** Stores official receipts generated after successful payment. Includes receipt number and path to generated PDF.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each receipt |
| `receipt_no` | VARCHAR(50) | NO | UNIQUE | - | Business-facing receipt number |
| `transaction_id` | BIGINT UNSIGNED | NO | UNIQUE | - | References the transaction (fee_transactions.id) |
| `receipt_date` | DATETIME | NO | - | - | Date and time of receipt generation |
| `receipt_pdf_path` | VARCHAR(255) | YES | - | NULL | File path to generated PDF receipt |
| `receipt_format` | ENUM('Standard', 'Detailed', 'Tax Invoice') | NO | - | 'Standard' | Format/style of receipt |
| `sent_to_parent` | BOOLEAN | NO | - | FALSE | Whether receipt was sent to parent |
| `sent_via` | ENUM('Email', 'SMS', 'WhatsApp', 'Print') | YES | - | NULL | Channel used to send receipt |
| `sent_at` | TIMESTAMP | YES | - | NULL | When receipt was sent |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |

---

## 4. FINE MANAGEMENT TABLES

### fee_fine_transactions

**Table Purpose:** Tracks individual fine applications to students. Records each time a fine is calculated and applied, including waivers.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each fine transaction |
| `student_id` | INT UNSIGNED | NO | FK | - | References the student (std_students.id) |
| `invoice_id` | BIGINT UNSIGNED | NO | FK | - | References the invoice (fee_invoices.id) |
| `fine_rule_id` | BIGINT UNSIGNED | NO | FK | - | References the fine rule that triggered this |
| `fine_date` | DATE | NO | - | - | Date when fine was applied |
| `days_late` | INT | NO | - | - | Number of days payment was late |
| `fine_amount` | DECIMAL(10,2) | NO | - | - | Fine amount calculated |
| `waived` | BOOLEAN | NO | - | FALSE | Whether this fine was waived |
| `waived_by` | INT UNSIGNED | YES | FK | NULL | User ID who waived the fine |
| `waiver_reason` | TEXT | YES | - | NULL | Reason for waiving fine |
| `waived_at` | TIMESTAMP | YES | - | NULL | When fine was waived |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |

---

### fee_name_removal_log

**Table Purpose:** Logs instances where student names are removed from class rolls due to prolonged non-payment. Also tracks re-admission details.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each removal record |
| `student_id` | INT UNSIGNED | NO | FK | - | References the student (std_students.id) |
| `academic_session_id` | INT UNSIGNED | NO | FK | - | References the academic session |
| `removal_date` | DATE | NO | - | - | Date when name was removed |
| `removal_reason` | TEXT | NO | - | - | Reason for removal (typically overdue) |
| `total_due_at_removal` | DECIMAL(12,2) | NO | - | - | Total amount due at time of removal |
| `days_overdue` | INT | NO | - | - | Number of days payment was overdue |
| `triggered_by_rule_id` | BIGINT UNSIGNED | YES | FK | NULL | Fine rule that triggered this removal |
| `re_admission_date` | DATE | YES | - | NULL | Date of re-admission (if applicable) |
| `re_admission_fee_paid` | DECIMAL(10,2) | YES | - | NULL | Re-admission fee paid |
| `re_admission_transaction_id` | BIGINT UNSIGNED | YES | FK | NULL | Transaction ID for re-admission payment |
| `re_activated_date` | DATE | YES | - | NULL | Date when student was re-activated |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |

---

## 5. PAYMENT GATEWAY TABLES

### fee_payment_gateway_logs

**Table Purpose:** Logs all interactions with payment gateways for audit, debugging, and reconciliation purposes. Stores request/response payloads.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each gateway log |
| `transaction_id` | BIGINT UNSIGNED | YES | FK | NULL | References our internal transaction (if created) |
| `gateway_name` | ENUM('Razorpay', 'Paytm', 'CCAvenue', 'BillDesk', 'Other') | NO | - | - | Name of payment gateway used |
| `gateway_transaction_id` | VARCHAR(100) | YES | - | NULL | Transaction ID from gateway |
| `order_id` | VARCHAR(100) | YES | - | NULL | Order ID generated for this payment |
| `payment_id` | VARCHAR(100) | YES | - | NULL | Payment ID from gateway |
| `request_payload` | JSON | YES | - | NULL | Complete request sent to gateway |
| `response_payload` | JSON | YES | - | NULL | Complete response received from gateway |
| `amount` | DECIMAL(12,2) | NO | - | - | Transaction amount |
| `status` | VARCHAR(50) | NO | Index | - | Status from gateway |
| `error_message` | TEXT | YES | - | NULL | Error message if any |
| `ip_address` | VARCHAR(45) | YES | - | NULL | IP address of user making payment |
| `user_agent` | TEXT | YES | - | NULL | User agent/browser information |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |

---

## 6. SCHOLARSHIP TABLES

### fee_scholarships

**Table Purpose:** Defines scholarship/fund programs available to students. Includes fund details, eligibility criteria, and application periods.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each scholarship |
| `scholarship_code` | VARCHAR(50) | NO | UNIQUE | - | Business code for scholarship |
| `scholarship_name` | VARCHAR(100) | NO | - | - | Display name of scholarship |
| `fund_source` | VARCHAR(100) | NO | - | - | Source of funds (Government/Trust/Corporate) |
| `sponsor_name` | VARCHAR(100) | YES | - | NULL | Name of sponsoring organization |
| `total_fund_amount` | DECIMAL(15,2) | YES | - | NULL | Total fund allocated for this scholarship |
| `available_fund` | DECIMAL(15,2) | YES | - | NULL | Remaining available fund |
| `eligibility_criteria` | JSON | NO | - | - | JSON structure containing eligibility rules (academic marks, income, category, etc.) |
| `application_start_date` | DATE | YES | - | NULL | Start date for applications |
| `application_end_date` | DATE | YES | - | NULL | End date for applications |
| `max_amount_per_student` | DECIMAL(10,2) | YES | - | NULL | Maximum amount a student can receive |
| `requires_renewal` | BOOLEAN | NO | - | FALSE | Whether scholarship needs annual renewal |
| `renewal_criteria` | JSON | YES | - | NULL | Criteria for renewal (e.g., minimum marks) |
| `is_active` | BOOLEAN | NO | Index | TRUE | Soft delete flag |
| `created_by` | INT UNSIGNED | YES | - | NULL | User ID who created this record |
| `updated_by` | INT UNSIGNED | YES | - | NULL | User ID who last updated this record |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |
| `deleted_at` | TIMESTAMP | YES | - | NULL | Soft delete timestamp |

---

### fee_scholarship_applications

**Table Purpose:** Stores student applications for scholarships. Tracks application data, documents, and approval status through workflow stages.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each application |
| `scholarship_id` | BIGINT UNSIGNED | NO | FK | - | References the scholarship (fee_scholarships.id) |
| `student_id` | INT UNSIGNED | NO | FK | - | References the student (std_students.id) |
| `application_date` | DATE | NO | - | - | Date when application was submitted |
| `application_data` | JSON | NO | - | - | Student's responses to eligibility criteria |
| `documents_submitted` | JSON | YES | - | NULL | List of documents uploaded with application |
| `current_stage` | INT | NO | - | 1 | Current stage in approval workflow |
| `status` | ENUM('Draft', 'Submitted', 'Under Review', 'Approved', 'Rejected', 'Waitlisted') | NO | Index | 'Draft' | Current application status |
| `review_committee` | JSON | YES | - | NULL | JSON array of committee member user IDs |
| `approved_amount` | DECIMAL(10,2) | YES | - | NULL | Amount approved (if approved) |
| `disbursed` | BOOLEAN | NO | - | FALSE | Whether funds have been disbursed |
| `disbursed_date` | DATE | YES | - | NULL | Date when funds were disbursed |
| `remarks` | TEXT | YES | - | NULL | Additional remarks |
| `created_by` | INT UNSIGNED | YES | - | NULL | User ID who created this application |
| `updated_by` | INT UNSIGNED | YES | - | NULL | User ID who last updated this application |
| `created_at` | TIMESTAMP | YES | - | CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | TIMESTAMP | YES | - | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |

---

### fee_scholarship_approval_history

**Table Purpose:** Tracks the complete approval workflow history for scholarship applications. Provides audit trail of all actions taken.

| Field Name | Data Type | Nullable | Key | Default | Field Purpose / Meaning |
|------------|-----------|----------|-----|---------|------------------------|
| `id` | BIGINT UNSIGNED | NO | PK | AUTO_INCREMENT | Unique identifier for each history record |
| `application_id` | BIGINT UNSIGNED | NO | FK | - | References the scholarship application |
| `stage` | INT | NO | - | - | Stage number in workflow |
| `action_by` | INT UNSIGNED | NO | FK | - | User ID who performed the action |
| `action` | ENUM('Submit', 'Approve', 'Reject', 'Request Info', 'Waitlist') | NO | - | - | Action performed |
| `comments` | TEXT | YES | - | NULL | Comments provided with the action |
| `action_date` | TIMESTAMP | NO | - | CURRENT_TIMESTAMP | When the action was performed |

---

## INDEX SUMMARY

| Table Name | Index Name | Columns | Purpose |
|------------|------------|---------|---------|
| fee_head_master | idx_fee_head_type | head_type | Fast filtering by head type |
| fee_head_master | idx_fee_head_active | is_active | Quick access to active records |
| fee_group_master | idx_fee_group_active | is_active | Quick access to active groups |
| fee_structure_master | idx_fee_structure_session_class | academic_session_id, class_id | Fast lookup of structures by session/class |
| fee_structure_master | idx_fee_structure_active | is_active | Quick access to active structures |
| fee_fine_rules | idx_fine_applicable | applicable_on, applicable_id | Fast lookup of applicable fine rules |
| fee_fine_rules | idx_fine_active | is_active | Quick access to active fine rules |
| fee_concession_types | idx_concession_category | concession_category | Fast filtering by concession category |
| fee_student_assignments | idx_fee_assignment_active | is_active | Quick access to active assignments |
| fee_student_concessions | idx_concession_status | approval_status | Fast lookup of pending approvals |
| fee_invoices | idx_invoice_status | status | Quick filtering by invoice status |
| fee_invoices | idx_invoice_due_date | due_date | Fast lookup of overdue invoices |
| fee_invoices | idx_invoice_student | student_assignment_id | Quick access to student's invoices |
| fee_transactions | idx_transaction_student | student_id | Fast lookup of student transactions |
| fee_transactions | idx_transaction_date | payment_date | Date-range queries for reports |
| fee_transactions | idx_transaction_status | status | Quick filtering by transaction status |
| fee_transactions | idx_transaction_mode | payment_mode | Payment mode analysis |
| fee_fine_transactions | idx_fine_student | student_id | Quick lookup of student fines |
| fee_fine_transactions | idx_fine_date | fine_date | Date-range fine analysis |
| fee_fine_transactions | idx_fine_waived | waived | Quick access to waived fines |
| fee_payment_gateway_logs | idx_gateway_trans | gateway_transaction_id | Reconciliation by gateway transaction ID |
| fee_payment_gateway_logs | idx_gateway_order | order_id | Lookup by order ID |
| fee_payment_gateway_logs | idx_gateway_status | status | Gateway transaction status analysis |
| fee_scholarships | idx_scholarship_active | is_active | Quick access to active scholarships |
| fee_scholarships | idx_scholarship_dates | application_start_date, application_end_date | Find active scholarships by date |
| fee_scholarship_applications | idx_sch_app_status | status | Quick filtering by application status |

---

## FOREIGN KEY RELATIONSHIPS SUMMARY

| Table | Foreign Key | References | Purpose |
|-------|-------------|------------|---------|
| fee_head_master | created_by | sys_users.id | Track who created the record |
| fee_head_master | updated_by | sys_users.id | Track who last updated |
| fee_group_master | created_by | sys_users.id | Track creator |
| fee_group_master | updated_by | sys_users.id | Track updater |
| fee_group_heads_jnt | group_id | fee_group_master.id | Link to fee group |
| fee_group_heads_jnt | head_id | fee_head_master.id | Link to fee head |
| fee_structure_master | academic_session_id | sch_org_academic_sessions_jnt.id | Link to academic session |
| fee_structure_master | class_id | sch_classes.id | Link to class |
| fee_structure_master | student_category_id | sys_dropdown_table.id | Link to category lookup |
| fee_structure_master | created_by | sys_users.id | Track creator |
| fee_structure_master | updated_by | sys_users.id | Track updater |
| fee_structure_details | fee_structure_id | fee_structure_master.id | Link to fee structure |
| fee_structure_details | head_id | fee_head_master.id | Link to fee head |
| fee_structure_details | group_id | fee_group_master.id | Link to fee group |
| fee_installments | fee_structure_id | fee_structure_master.id | Link to fee structure |
| fee_fine_rules | created_by | sys_users.id | Track creator |
| fee_fine_rules | updated_by | sys_users.id | Track updater |
| fee_concession_types | created_by | sys_users.id | Track creator |
| fee_concession_types | updated_by | sys_users.id | Track updater |
| fee_concession_applicable_heads | concession_type_id | fee_concession_types.id | Link to concession |
| fee_concession_applicable_heads | head_id | fee_head_master.id | Link to fee head |
| fee_student_assignments | student_id | std_students.id | Link to student |
| fee_student_assignments | academic_session_id | sch_org_academic_sessions_jnt.id | Link to session |
| fee_student_assignments | fee_structure_id | fee_structure_master.id | Link to fee structure |
| fee_student_assignments | created_by | sys_users.id | Track creator |
| fee_student_assignments | updated_by | sys_users.id | Track updater |
| fee_student_concessions | student_assignment_id | fee_student_assignments.id | Link to student assignment |
| fee_student_concessions | concession_type_id | fee_concession_types.id | Link to concession type |
| fee_student_concessions | approved_by | sys_users.id | Link to approver |
| fee_student_concessions | created_by | sys_users.id | Track requester |
| fee_invoices | student_assignment_id | fee_student_assignments.id | Link to student assignment |
| fee_invoices | installment_id | fee_installments.id | Link to installment |
| fee_invoices | generated_by | sys_users.id | Link to invoice generator |
| fee_invoices | cancelled_by | sys_users.id | Link to canceller |
| fee_transactions | student_id | std_students.id | Link to student |
| fee_transactions | invoice_id | fee_invoices.id | Link to invoice |
| fee_transactions | guardian_id | std_guardians.id | Link to paying guardian |
| fee_transactions | collected_by | sys_users.id | Link to cashier/collector |
| fee_transaction_details | transaction_id | fee_transactions.id | Link to master transaction |
| fee_transaction_details | head_id | fee_head_master.id | Link to fee head |
| fee_receipts | transaction_id | fee_transactions.id | Link to transaction |
| fee_fine_transactions | student_id | std_students.id | Link to student |
| fee_fine_transactions | invoice_id | fee_invoices.id | Link to invoice |
| fee_fine_transactions | fine_rule_id | fee_fine_rules.id | Link to fine rule |
| fee_fine_transactions | waived_by | sys_users.id | Link to waiver approver |
| fee_name_removal_log | student_id | std_students.id | Link to student |
| fee_name_removal_log | academic_session_id | sch_org_academic_sessions_jnt.id | Link to session |
| fee_name_removal_log | triggered_by_rule_id | fee_fine_rules.id | Link to triggering rule |
| fee_name_removal_log | re_admission_transaction_id | fee_transactions.id | Link to re-admission payment |
| fee_payment_gateway_logs | transaction_id | fee_transactions.id | Link to internal transaction |
| fee_scholarships | created_by | sys_users.id | Track creator |
| fee_scholarships | updated_by | sys_users.id | Track updater |
| fee_scholarship_applications | scholarship_id | fee_scholarships.id | Link to scholarship |
| fee_scholarship_applications | student_id | std_students.id | Link to student |
| fee_scholarship_applications | created_by | sys_users.id | Track creator |
| fee_scholarship_applications | updated_by | sys_users.id | Track updater |
| fee_scholarship_approval_history | application_id | fee_scholarship_applications.id | Link to application |
| fee_scholarship_approval_history | action_by | sys_users.id | Link to action performer |

---
*End of Data Dictionary*
