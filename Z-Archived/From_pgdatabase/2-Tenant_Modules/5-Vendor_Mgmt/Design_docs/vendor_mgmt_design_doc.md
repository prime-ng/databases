# Vendor Management Module - Technical Design Document

## 1. Overview
The **Vendor Management Module** is a critical subsystem of the School ERP, designed to centralize the management of all external service providers (Transport, Canteen, Security, Maintenance, etc.). It moves beyond simple address books to handle complex **Contract Lifecycles**, **Automated Billing**, and **Performance Analytics**.

**Scope:**
- **Vendor Onboarding**: KYC, Categorization, and Bank Details.
- **Contract Management**: Flexible billing models (Fixed, Variable, Hybrid).
- **Service Logging**: Tracking actual usage (e.g., Km runs, Meals served) for billing.
- **Financials**: Invoice generation, approval workflows, and payment tracking.

**Cross-Module Interactions:**
- **Transport Module**: Feeds vehicle usage data (`km_run`) into `vnd_usage_logs` for billing driver/bus contractors.
- **Inventory Module**: `vnd_items` with `item_nature='CONSUMABLE'` will link to stock inward/outward flows.
- **Finance Module**: All approved `vnd_invoices` become "Accounts Payable" entries.
- **Complaint Module**: Vendor-related queries are handled via the central Complaint system.

---

## 2. Data Context
**Entities:** Vendor, Item (Service/Product), Agreement, Usage Log, Invoice, Payment.

**Cardinality Matrix:**
- **Vendor** (1) ---- (Many) **Agreements**
- **Agreement** (1) ---- (Many) **Agreement Items**
- **Agreement Item** (1) ---- (Many) **Usage Logs**
- **Vendor** (1) ---- (Many) **Invoices**
- **Invoice** (1) ---- (Many) **Payments**

**Sensitive Data (PII/Financial):**
- **Critical**: `vnd_vendors.bank_details` (Account No, IFSC), `vnd_vendors.pan_number`.
- **Handling**: Fields should be encrypted at rest if required by local compliance. Access restricted to 'Accountant' and 'Admin' roles.

**Retention Policy:**
- Financial Records (Invoices/Payments/Agreements): **7 Years** (Statutory requirement).
- Usage Logs: **3 Years** (for audit trails).

---

## 3. Screen Layouts
The UI follows the **Z-Screen-Sample** pattern: Clean, ASCII-art style wireframes for clarity.

**Priority Screens:**
1.  **Vendor Dashboard** (Analytics & Quick Actions).
2.  **Vendor Master List** (Filterable, Searchable).
3.  **Vendor Master Detail** (Profile + Tabs for Agreements, Invoices).
4.  **Agreement Studio** (Complex form for defining billing logic).
5.  **Usage Logger** (Grid input for daily data entry).
6.  **Invoice Manager** (List of Due/Paid bills).

---

## 4. Data Models (ER Diagram)

```ascii
      +-------------+        +----------------+       +-------------------------+
      | vnd_vendors |<-------| vnd_agreements |<------| vnd_agreement_items_jnt |
      +-------------+        +----------------+       +-------------------------+
             ^                        ^                            ^
             |                        |                            |
             |                        |                     +----------------+
             |                        +---------------------| vnd_usage_logs |
             |                                              +----------------+
      +--------------+
      | vnd_invoices |<-------------------------------+
      +--------------+                                |
             ^                                +--------------+
             |                                | vnd_payments |
             +--------------------------------+--------------+
```

---

## 5. User Workflows

### 5.1. Happy Path: Transport Vendor Billing
1.  **Setup**: Admin creates Vendor "ABC Travels" and Agreement "Annual Bus Contract".
2.  **Define Rates**: In Agreement, add Item "40-Seater Bus". Usage Type: "HYBRID" (Fixed ₹50,000 + ₹20/km).
3.  **Usage**: Transport Manager logs Daily Bus Readings in Transport Module -> System auto-syncs to `vnd_usage_logs`.
4.  **Billing**: End of Month -> Accountant clicks "Generate Invoice". System aggregates Logs + Fixed cost = Draft Invoice.
5.  **Approval**: Admin reviews Invoice -> Approves.
6.  **Payment**: Accountant records Partial Payment -> Status updates to 'Partial'.

### 5.2. Exception: Dispute Handling
1.  Vendor disputes "Total Km" on Invoice.
2.  Admin marks Invoice Status -> 'Disputed' (via Custom Status Dropdown).
3.  Admin navigates to `vnd_usage_logs`, corrects specific day entries.
4.  Admin "Regenerates" Invoice.

---

## 6. Visual Design & UI Components
**Style Guide (Z-Pattern):**
- **Header**: Standard breadcrumb (Home > Operations > Vendor). Action Buttons (Add, Export) on right.
- **Grids**: Zebra-striped rows. Actions column (Edit/Delete icons) on far right.
- **Forms**: Two-column layout for standard fields. Full-width for text areas. Group related fields (e.g., "Address Details", "Bank Info") in Fieldsets/Cards.
- **Status Badges**:
    - `Active` / `Paid`: Green Pill.
    - `Draft` / `Pending`: Yellow Pill.
    - `Overdue` / `Terminated`: Red Pill.

---

## 7. Accessibility (WCAG AA)
- **Keyboard Nav**: All interactive elements (Inputs, Buttons, Dropdowns) must be tab-accessible.
- **Focus Indicators**: High-contrast outline on focus.
- **ARIA Labels**:
    - Usage Logs Grid: `aria-label="Daily Usage Entry Row for Date 2024-01-01"`.
    - Icons: Tooltip texts must be screen-reader visible.
- **Color Contrast**: Text ratio > 4.5:1. Avoid relying solely on color (e.g., Overdue rows should have "Overdue" text, not just red background).

---

## 8. Testing Strategy
**Unit Tests:**
- **Billing Logic**: Test `Fixed`, `Per_Unit`, and `Hybrid` calculations. Boundary test: Usage = 0, Usage < Min_Guarantee.
- **Tax Calc**: Verify multi-tax logic (`tax1` + `tax2`...).

**Integration Tests:**
- **Transport Sync**: Verify that closing a "Trip" in Transport Module correctly inserts a row in `vnd_usage_logs`.

**E2E Tests:**
- Create Vendor -> Add Agreement -> Log Usage -> Generate Invoice -> Pay.

---

## 9. Deployment / Runbook
1.  **DB Migration**: Run `vendor_mgmt_v2.1.sql`.
2.  **Seeding**: Ensure `sys_dropdown_table` is populated with `vendor_type`, `unit`, `invoice_status`.
3.  **Config**: Set `sch_settings` variable `trip_usage_needs_to_be_updated_into_vendor_usage_log = TRUE` to enable Transport hook.

---

## 10. Future Enhancements
1.  **Vendor Portal** (High Complexity): Allow vendors to login, view POs, and upload own Invoices.
2.  **Auto-PO Generation** (Medium): Auto-generate Purchase Orders based on `reorder_level` in `vnd_items`.
3.  **Dispute Chat** (Low): Embedded chat on Invoice page between Admin and Vendor.
