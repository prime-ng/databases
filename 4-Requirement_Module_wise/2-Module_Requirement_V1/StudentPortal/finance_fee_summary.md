# Finance — Fee Summary Tab Requirements

## 1. Functional Overview
Displays tuition fees, active invoices, payment histories, and direct payment checkout redirect buttons.

---

## 2. Page Structure & Parameters

### A. Fee Structure Breakdown
- Table showing fee components:
  - **Head**: Admission Fee, Tuition Fee, Lab Fee, Sports Fee, Library Fee, etc.
  - **Due Amount**: Amount assigned for each head.
  - **Paid Amount**: Paid total.
  - **Remaining Balance**: Due minus paid.

### B. Invoices List Table
- Table showing generated invoices:
  - **Invoice ID**: Unique invoice identifier.
  - **Invoice Amount**: Total amount due.
  - **Paid Amount**: Amount paid.
  - **Balance**: Unpaid amount.
  - **Due Date**: Payment deadline.
  - **Status**: Paid, Unpaid, or Partially Paid.
  - **Actions**: "View Details" (printable invoice) and "Pay Now" buttons.

### C. Invoice Details Page
- Printable view showing school information, student information, invoice details, itemized fees, payment logs, and a signature box.

---

## 3. Database References
- **Models**:
  - `Modules\StudentFee\Models\FeeInvoice`
  - `Modules\StudentFee\Models\FeeAssignment`
- **Tables**:
  - `fee_invoices`
  - `fee_assignments`
