# VND — Vendor Module | Requirement Conditions Catalog
**Date:** 2026-06-30 | **Agent:** Business Analyst
**Source:** `VND_FRD_Complete_2026-06-30.md` (Section 3.2) — canonical location for all condition detail

> This file is a pointer to the Complete Analysis Pack. The full Requirement Conditions Catalog for the Vendor module (20 conditions, BR-VND-001 through BR-VND-020) is defined in:
>
> `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/VND_FRD_Complete_2026-06-30.md`
> **Section 3.2 — Requirement Conditions Catalog**

## Summary Table

| Condition ID | Entity / Field | Type | Implementation |
|-------------|---------------|------|---------------|
| BR-VND-001-A | Vendor / GSTIN | Validation | Partial — format validated in VendorRequest; no DB UNIQUE KEY |
| BR-VND-001-B | Vendor / GSTIN | Validation | Not enforced at DB level |
| BR-VND-001-C | Vendor / PAN | Validation | Partial — format in VendorRequest; no uniqueness check |
| BR-VND-001-D | Vendor / PAN | Validation | Not enforced |
| BR-VND-002 | Invoice / Duplicate Period | Validation / Workflow | Yes — in code; needs service extraction |
| BR-VND-003 | Invoice / Agreement Status | Workflow | Not enforced |
| BR-VND-004 | Payment / Amount Ceiling | Validation | Not enforced — no VendorPaymentRequest |
| BR-VND-006-A | Agreement / End Date | Validation | Yes — in VendorAgreementRequest |
| BR-VND-007 | Agreement / Auto-Expiry | Workflow | Not implemented |
| BR-VND-008-A | Invoice / Monthly Frequency | Workflow | Partial — start/end date check only |
| BR-VND-008-B | Invoice / One-Time Frequency | Workflow | Partial |
| BR-VND-009-A | Payment / NEFT-RTGS-UPI Reference | Validation | Not enforced |
| BR-VND-009-B | Payment / Cheque Number | Validation | Not enforced |
| BR-VND-011 | Agreement / Activation Guard | Validation | Not enforced |
| BR-VND-012 | Vendor / Delete Dependency Warning | Validation | Not enforced |
| BR-VND-013 | Usage Log / Qty > 0 | Validation | Not enforced — no VndUsageLogRequest |
| BR-VND-014-A | Usage Log / Date Not Future | Validation | Not enforced |
| BR-VND-014-B | Usage Log / Date Within Period | Validation | Not enforced |
| BR-VND-016 | Payment / Delete Recalculation | Workflow | Not enforced |
| BR-VND-017 | Item / Deactivation Warning | Validation | Not enforced |
