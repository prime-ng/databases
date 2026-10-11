# Vendor Management Module - Report Designs (Deliverable E)

**Document Version:** 1.0
**Context:** This document details the analytical reports required for the Vendor Management Module. These reports are designed to assist Administrators, Accountants, and Department Heads (e.g., Transport Manager) in tracking legal obligations, financial liabilities, and operational efficiency of external service providers.

---

## 1. Vendor Spend Analysis Report
**Purpose:** To analyze the total expenditure incurred on vendors over a specific period, categorized by service type (Transport, Infrastructure, etc.).

*   **Report Category:** Financial Analysis
*   **Primary Tables:** `vnd_vendors`, `vnd_invoices`, `sys_dropdown_table` (for Vendor Type)
*   **Key Filters:**
    *   Date Range (Invoice Date)
    *   Vendor Type (e.g., Transport, Canteen)
    *   Vendor Name (Multi-select)
    *   Payment Status (Paid / Partial / Pending)
*   **Output Columns:**
    *   Vendor Name
    *   Vendor Type
    *   Total Invoices Generated (Count)
    *   Total Billed Amount (₹)
    *   Total Tax Amount (₹)
    *   Total Paid Amount (₹)
    *   Outstanding Balance (₹)
*   **Frequency:** Monthly / Quarterly
*   **Intended User Roles:**
    1.  **Accountant**
        *   **Permissions:** View, Print, Export
    2.  **School Admin** / **Super Admin**
        *   **Permissions:** View, Print, Export
    3.  **Principal**
        *   **Permissions:** View, Print

---

## 2. Agreement Expiry & Renewal Tracker
**Purpose:** To proactively identify vendor contracts that are nearing expiration to initiate renewal or tendering processes.

*   **Report Category:** Compliance & Operations
*   **Primary Tables:** `vnd_vendors`, `vnd_agreements`
*   **Key Filters:**
    *   Expiry Date Range (e.g., Next 30 Days, Next 3 Months)
    *   Vendor Type
    *   Agreement Status (Active / Draft / Expired)
*   **Output Columns:**
    *   Agreement Ref No
    *   Vendor Name
    *   Service Category
    *   Start Date
    *   End Date
    *   Billing Cycle (Monthly/Fixed)
    *   Status (Active/Expired)
    *   Days to Expiry (Calculated)
*   **Frequency:** Weekly (Automated Email Alert)
*   **Intended User Roles:**
    1.  **School Admin**
        *   **Permissions:** View, Print, Export, Edit (Renew)
    2.  **Transport Head** (For Transport Vendors)
        *   **Permissions:** View, Export

---

## 3. Detailed Usage & Verification Log
**Purpose:** detailed audit trail of daily services consumed (e.g., Bus Km runs, Security Guards present) vs what was billed. Used to verify invoices before approval.

*   **Report Category:** Operational Functions
*   **Primary Tables:** `vnd_usage_logs`, `vnd_agreement_items_jnt`, `vnd_items`
*   **Key Filters:**
    *   Date Range
    *   Service Item (e.g., "40 Seater Bus")
    *   Linked Entity (e.g., specific Vehicle Number)
    *   Vendor Name
*   **Output Columns:**
    *   Date
    *   Vendor Name
    *   Item Name (Service)
    *   Linked Asset (Vehicle No / Building Block)
    *   Opening Reading / Count
    *   Closing Reading / Count
    *   **Qty Used (Billable)**
    *   Logged By (User)
    *   System Verified (Yes/No - if linked to Transport IoT)
*   **Frequency:** Daily / On-Demand (Pre-Invoice Checks)
*   **Intended User Roles:**
    1.  **Transport Head** / **Ops Manager**
        *   **Permissions:** View, Add, Edit, Print, Export
    2.  **School Admin**
        *   **Permissions:** View, Export

---

## 4. Accounts Payable Aging Report
**Purpose:** To track overdue payments and manage cash flow by categorizing unpaid invoices by their age.

*   **Report Category:** Financial Analysis
*   **Primary Tables:** `vnd_invoices`, `vnd_vendors`
*   **Key Filters:**
    *   As Of Date
    *   Vendor
    *   Minimum Overdue Days
*   **Output Columns:**
    *   Vendor Name
    *   Invoice Number
    *   Invoice Date
    *   Due Date
    *   Total Amount
    *   **0-30 Days Overdue** (Amount)
    *   **31-60 Days Overdue** (Amount)
    *   **61-90 Days Overdue** (Amount)
    *   **90+ Days Overdue** (Amount)
    *   Total Outstanding
*   **Frequency:** Weekly / Monthly
*   **Intended User Roles:**
    1.  **Accountant**
        *   **Permissions:** View, Print, Export
    2.  **School Admin**
        *   **Permissions:** View, Print

---

## 5. GST / Tax Input Credit Report
**Purpose:** Consolidates all taxes paid to vendors to assist in filing GST returns and claiming Input Tax Credit (ITC).

*   **Report Category:** Statutory / Tax
*   **Primary Tables:** `vnd_invoices`, `vnd_vendors`
*   **Key Filters:**
    *   Financial Year / Month
    *   Vendor GST Status (Registered/Unregistered)
*   **Output Columns:**
    *   Invoice Date
    *   Invoice No
    *   Vendor Name
    *   Vendor GSTIN
    *   Item Description (Summary)
    *   HSN/SAC Code
    *   Taxable Value
    *   CGST Amount
    *   SGST Amount
    *   IGST Amount
    *   Total Tax Paid
*   **Frequency:** Monthly
*   **Intended User Roles:**
    1.  **Accountant**
        *   **Permissions:** View, Print, Export
    2.  **Statutory Auditor** (External)
        *   **Permissions:** View, Export

---

## 6. Vendor Performance & Incident Report
**Purpose:** Evaluates vendors based on logged complaints and service interruptions. (Note: Relies on integration with Complaint Module).

*   **Report Category:** Quality Assurance
*   **Primary Tables:** `cmp_complaints` (Complaint Module), `vnd_vendors`
*   **Key Filters:**
    *   Date Range
    *   Vendor Name
    *   Severity (High/Medium/Low)
*   **Output Columns:**
    *   Vendor Name
    *   Total Complaints Received
    *   Resolved within SLA (Count)
    *   Breached SLA (Count)
    *   Avg Resolution Time
    *   Most Frequent Issue Category (e.g., "Bus Breakdown", "Poor Food Quality")
    *   Vendor Rating (Calculated)
*   **Frequency:** Quarterly / Annual Review
*   **Intended User Roles:**
    1.  **School Admin**
        *   **Permissions:** View, Print, Export
    2.  **Principal**
        *   **Permissions:** View
