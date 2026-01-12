# Vendor Management Module - Data Dictionary (v2.1)

## Overview
This document details the database schema for the **Vendor Management Module**. The module manages vendor profiles, agreements (contracts), service/product items, usage logging (analytics), invoicing, and payments. It is designed to handle diverse vendor types (Transport, Canteen, Security, Stationary, etc.) and complex billing models.

## Schema Summary

| Table Name | Description | Key Functional Area |
| :--- | :--- | :--- |
| `vnd_vendors` | Master table storing vendor profiles and types. | Vendor Onboarding |
| `vnd_items` | Master table for Services and Products provided by vendors. | Inventory & Service Definitions |
| `vnd_agreements` | Stores contract headers (dates, cycles, payment terms). | Contract Management |
| `vnd_agreement_items_jnt` | detailed line items of an agreement with pricing logic. | Contract Pricing & Context |
| `vnd_usage_logs` | Logs daily usage of services (e.g., Km run, Meals served). | Analytics & Billing |
| `vnd_invoices` | Stores generated vendor bills/invoices. | Accounts Payable |
| `vnd_payments` | Records payments made against invoices. | Accounts Payable |
| `vnd_complaints` | *Deprecated* (Using Common Complaint Module). | Issue Tracking |

---

## Table Details

### 1. `vnd_vendors`
**Purpose**: Central repository for all service providers and suppliers.
**Key Relationships**: 
- Linked to `sys_dropdown_table` for `vendor_type_id`.
- Referenced by `vnd_agreements`, `vnd_invoices`.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique Identifier. |
| `vendor_name` | VARCHAR(100) | Legal name of the vendor (Unique). |
| `vendor_type_id` | BIGINT FK | Links to `sys_dropdown_table`. Defines type: 'Transport', 'Canteen', 'Security', etc. |
| `contact_person` | VARCHAR(100) | Primary point of contact. |
| `gst_number` | VARCHAR(50) | VAT/GST Identification Number. |
| `bank_details` | JSON | Stores structured bank info (Account No, IFSC, Bank Name). |
| `is_active` | BOOLEAN | Status flag. |
| `is_deleted` | BOOLEAN | Soft delete flag. |

---

### 2. `vnd_items`
**Purpose**: Defines the specific "Things" or "Services" a vendor provides. Incorporates inventory hooks for "Consumables" and "Assets".
**Key Relationships**: 
- Linked to `sys_dropdown_table` for `category` and `unit`.
- Referenced by `vnd_agreement_items_jnt`.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique Identifier. |
| `item_code` | VARCHAR(50) | Unique SKU or internal code (Barcode compatible). |
| `item_name` | VARCHAR(100) | Name of the service/product (e.g., "Bus 40 Seater", "A4 Paper"). |
| `item_type` | ENUM | 'SERVICE' or 'PRODUCT'. |
| `item_nature` | ENUM | 'CONSUMABLE', 'ASSET', 'SERVICE', 'NA'. Critical for Inventory tracking. |
| `default_price` | DECIMAL | Standard reference buying price. |
| `reorder_level` | DECIMAL | Inventory hook: Low stock alert threshold. |
| `unit_id` | BIGINT FK | Measurement unit (Km, Month, Visit, Kg). |
| `item_photo_uploaded` | BOOLEAN | Flag acts as a hook to check `sys_media` for images. |

---

### 3. `vnd_agreements`
**Purpose**: Represents the legal/business contract header.
**Key Relationships**: 
- Parent to `vnd_agreement_items_jnt`.
- Links to `vnd_vendors`.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique Identifier. |
| `vendor_id` | BIGINT FK | The vendor this agreement belongs to. |
| `agreement_ref_no` | VARCHAR(50) | Physical/Paper contract reference number. |
| `start_date` | DATE | Effective start date. |
| `end_date` | DATE | Expiration date. |
| `billing_cycle` | ENUM | 'MONTHLY', 'ONE_TIME', 'ON_DEMAND'. Controls invoice generation frequency. |
| `status` | ENUM | 'DRAFT', 'ACTIVE', 'EXPIRED', 'TERMINATED'. |
| `agreement_uploaded` | BOOLEAN | Flag indicating if PDF/Scan is uploaded to `sys_media`. |

---

### 4. `vnd_agreement_items_jnt`
**Purpose**: Junction table linking Agreements to Items with specific pricing models.
**Key Relationships**: 
- Links `vnd_agreements` to `vnd_items`.
- Defines context via `element_entity_type` (e.g., linking a rate to a specific Vehicle).

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique Identifier. |
| `agreement_id` | BIGINT FK | Parent agreement. |
| `item_id` | BIGINT FK | The service/product being contracted. |
| `billing_model` | ENUM | Pricing Logic: 'FIXED' (Flat Fee), 'PER_UNIT' (Rate * Usage), 'HYBRID' (Base + Variable). |
| `fixed_charge` | DECIMAL | Used for FIXED or HYBRID base price. |
| `unit_rate` | DECIMAL | Used for PER_UNIT or HYBRID variable component. |
| `min_guarantee_qty` | DECIMAL | Minimum billable quantity validation logic. |
| `related_entity_type` | BIGINT FK | **Polymorphic Hook**: Links to `sys_dropdown_table` to define what this item applies to (e.g., "Linked to Vehicle"). |
| `related_entity_table`| VARCHAR | Name of the table the entity belongs to (e.g., `tpt_vehicle`). |
| `related_entity_id` | BIGINT | ID of the specific entity (e.g., `vehicle_id=5`). |
| `tax[1-4]_percent` | DECIMAL | Granular tax configuration per line item. |

---

### 5. `vnd_usage_logs`
**Purpose**: Analytics hook to record daily/periodic consumption of services/products. This data drives the "PER_UNIT" and "HYBRID" billing.
**Key Relationships**: 
- Links to `vnd_agreement_items_jnt` to fetch rates.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique Identifier. |
| `vendor_id` | BIGINT FK | Vendor Reference. |
| `agreement_item_id` | BIGINT FK | Links to the specific contract line item (which contains the rate). |
| `usage_date` | DATE | The date service was provided. |
| `qty_used` | DECIMAL | The billable unit consumed (e.g., 50 (Km), 1 (Visit)). |
| `logged_by` | BIGINT FK | System User who verified the usage (NULL for auto-logs). |

---

### 6. `vnd_invoices`
**Purpose**: Stores the financial obligation (Bill) generated for the vendor.
**Key Relationships**: 
- Links to `vnd_vendors` and optionally `vnd_agreements`.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique Identifier. |
| `vendor_id` | BIGINT FK | Payee Vendor. |
| `invoice_number` | VARCHAR(50) | Vendor's physical invoice number. |
| `fixed_charge_amt` | DECIMAL | Calculated Fixed Component string. |
| `unit_charge_amt` | DECIMAL | Calculated Variable Component (Qty * Rate). |
| `qty_used` | DECIMAL | Total quantity billed. |
| `sub_total` | DECIMAL | Amount before tax/discount. |
| `net_payable` | DECIMAL | Final amount to pay. |
| `balance_due` | DECIMAL | `net_payable` - `amount_paid`. |
| `status` | BIGINT FK | Links to `sys_dropdown_table` (e.g., 'Approval Pending', 'Paid'). |

---

### 7. `vnd_payments`
**Purpose**: Tracks outflows of cash/bank transfers to vendors.
**Key Relationships**: 
- Links to `vnd_invoices`.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique Identifier. |
| `invoice_id` | BIGINT FK | The invoice being paid. |
| `amount` | DECIMAL | Amount paid in this transaction. |
| `payment_mode` | BIGINT FK | Links to `sys_dropdown_table` (Cheque, NEFT, etc.). |
| `reference_no` | VARCHAR | Transaction ID / UTR / Cheque Number. |
