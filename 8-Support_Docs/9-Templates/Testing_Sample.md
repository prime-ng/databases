# Vendor Management Module - Testing & QA Strategy (Deliverable F)

**Document Version:** 1.0
**Context:** This detailed guide provides the Testing & Quality Assurance protocols for the Vendor Management Module. It covers Developer Unit Testing checklists, QA Functional checklists, and specific Table-Driven Test Cases including edge scenarios.

---

## 1. Developer Test-Run Checklist (Per Screen)

### 1.1 Vendor Dashboard
- [ ] **Data Fetching**: Verify API returns correct JSON structure for "Total Payables", "Pending Invoices", and "Expiring Contracts".
- [ ] **Performance**: Dashboard loads within < 2 seconds. API queries use proper indexes (verify via `EXPLAIN`).
- [ ] **Empty States**: Verify behavior when no data exists (e.g., "No Pending Invoices" message instead of empty charts).
- [ ] **Charts**: Verify Pie and Bar charts render correctly with library (e.g., Chart.js/Recharts). Note: Handle cases with 0 values.
- [ ] **Links**: Ensure "View All" links navigate to the correct filtered lists.

### 1.2 Vendor Master (List & Add/Edit)
- [ ] **Validation (Client-side)**:
    - [ ] `Vendor Name` is required.
    - [ ] `Mobile Number` allows only 10 digits.
    - [ ] `Email` follows regex pattern.
- [ ] **Validation (Server-side)**:
    - [ ] Unique constraint check for `Vendor Name` (Handle HTTP 422 gracefully).
    - [ ] `vendor_type_id` exists in `sys_dropdown_table`.
- [ ] **Submission**:
    - [ ] POST request sends correct payload format.
    - [ ] On Success: Modal closes, toast appears, List auto-refreshes.
    - [ ] On Error: Inline error messages displayed below specific fields.

### 1.3 Agreement Studio
- [ ] **Date Logic**: Ensure `start_date` <= `end_date` in UI picker.
- [ ] **Dynamic Dropdowns**:
    - [ ] Selecting Item Type 'Transport' loads 'Vehicles' in the "Linked To" dropdown.
    - [ ] Selecting 'Canteen' hides the "Linked To" dropdown (if applicable).
- [ ] **Calculations**:
    - [ ] Verify `Hybrid` billing model calculation locally before submit: `Fixed + (Qty * Rate)`.
    - [ ] Verify `Tax` calculation updates immediately when `Tax %` changes.
- [ ] **File Upload**: Verify PDF payload is attached as `FormData` (not JSON) if using specialized upload endpoint.

### 1.4 Usage Log Entry
- [ ] **Batch Entry**: Verify grid handles 20+ rows without lag.
- [ ] **Input Constraints**: `Qty Used` accepts decimals but rejects negative numbers.
- [ ] **Auto-Save**: If implemented, verify debounced calls don't race.

### 1.5 Invoice Generation
- [ ] **Billing Engine**:
    - [ ] Verify background job correctly aggregates `vnd_usage_logs` for the selected month.
    - [ ] Check `Min Guarantee` logic: Use `gretest(actual_usage, min_guarantee)`.
- [ ] **State Transitions**:
    - [ ] "Approve" button only enabled for `Draft` status.
    - [ ] "Pay" button only enabled for `Approved` status.

---

## 2. QA Test-Run Checklist (Per Screen)

### 2.1 General UI/UX
- [ ] **Responsiveness**: Verify layout on Desktop (1920x1080), Laptop (1366x768), and Tablet (iPad Mode).
- [ ] **Consistency**: Check Fonts, Button Colors, and Padding match "Prime ERP" Design System.
- [ ] **Accessibility**: Tab navigation works flow-wise (Left-to-Right, Top-to-Bottom). All inputs have labels.

### 2.2 Functional Flows
- [ ] **Vendor Lifecycle**: Create Vendor -> Create Agreement -> Log Usage -> Generate Invoice -> Pay.
- [ ] **Filters**: Test combination of filters (e.g., Type="Transport" AND Status="Active").
- [ ] **Role Access**:
    - [ ] Log in as **Transport Manager**: Should NOT see "Pay" buttons.
    - [ ] Log in as **Accountant**: Should see "Pay" buttons but NOT "Delete User".

### 2.3 Dashboard & Reports
- [ ] **Data Accuracy**: Manually calculate "Total Payables" from the Invoice List and match with Dashboard Widget.
- [ ] **Export**: Click "Export Report" -> Download CSV -> Verify column headers and data types (Dates as YYYY-MM-DD).

---

## 3. Representative Test Cases

### 3.1 Scenario: Vendor Onboarding
| ID | Test Scenario | Pre-Condition | Action / Input Steps | Expected Result | Severity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-01** | Create Valid Vendor | Admin Logged In | 1. Open "Add Vendor" Modal.<br>2. Name: "Global Bus Co".<br>3. Type: "Transport".<br>4. Mobile: "9988776655".<br>5. Click Save. | Success Toast. Vendor appears in list. DB creates record. | High |
| **TC-02** | Duplicate Vendor Name | "Global Bus Co" Exists | 1. Open "Add Vendor" Modal.<br>2. Name: "Global Bus Co".<br>3. Click Save. | Error Message: "Vendor name already exists." Record NOT created. | Medium |
| **TC-03** | Invalid Mobile Format | Admin Logged In | 1. Enter Mobile: "123" or "ABC".<br>2. Click Save. | Validation Error: "Enter valid 10-digit mobile." | Low |

### 3.2 Scenario: Agreement Management
| ID | Test Scenario | Pre-Condition | Action / Input Steps | Expected Result | Severity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-04** | Invalid Date Range | Vendor Exists | 1. Open "New Agreement".<br>2. Start Date: "2025-12-01".<br>3. End Date: "2025-01-01".<br>4. Click Save. | Error Message: "End Date must be after Start Date." | High |
| **TC-05** | Hybrid Billing Setup | Agreement Open | 1. Add Item.<br>2. Model: "Hybrid".<br>3. Fixed: 5000.<br>4. Rate: 10.<br>5. Save. | Item saved. DB stores `billing_model='HYBRID'`, `fixed_charge=5000`, `unit_rate=10`. | High |

### 3.3 Scenario: Billing Logic (Edge Cases)
| ID | Test Scenario | Pre-Condition | Action / Input Steps | Expected Result | Severity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-06** | Min Guarantee Logic | Agr: Min 1000km.<br>Rate: ₹10/km. | 1. Log Usage: 800km (Total for month).<br>2. Generate Invoice. | System bills for 1000km.<br>Calculation: 1000 * 10 = ₹10,000.<br>(Not 800 * 10 = 8000). | Critical |
| **TC-07** | Zero Usage Invoice | Agr: Per Unit.<br>No Min Guarantee. | 1. Log Usage: 0.<br>2. Generate Invoice. | System generates Invoice of ₹0 (or warns "No Billable Amount"). | Medium |
| **TC-08** | Contract Expiry Usage | Contract Ends: Dec 31 | 1. Try to log usage for Date: "Jan 01". | Error/Warning: "Agreement Expired on selected date." | High |

### 3.4 Scenario: Invoice & Payments
| ID | Test Scenario | Pre-Condition | Action / Input Steps | Expected Result | Severity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-09** | Partial Payment | Invoice: ₹10,000.<br>Status: Approved. | 1. Click Pay.<br>2. Amount: ₹4,000.<br>3. Submit. | Invoice Status: "Partial".<br>Balance Due: ₹6,000.<br>Payment Record Created. | High |
| **TC-10** | Over-Payment Prevention | Invoice: ₹10,000.<br>Bal: ₹2,000. | 1. Click Pay.<br>2. Amount: ₹5,000. | Validation Error: "Amount exceeds Balance Due (₹2,000)." | Medium |

---

**End of Testing Strategy**
**Approved By:** QA Lead
**Last Updated:** Dec 25, 2025
