# Support — Complaints: New Complaint Tab Requirements

## 1. Functional Overview
Enables students to submit complaints, automatically assigns severity and priority score, and generates a unique ticket number.

---

## 2. Page Structure & Parameters

### A. Complaint Form Inputs
- **Category**: Dropdown list of parent categories.
- **Subcategory**: Dropdown populated dynamically via AJAX based on selected category.
- **Severity Level & Priority**: Fetched automatically based on selected category.
- **Title**: Required text input (Max 200 characters).
- **Description**: Detailed description.
- **Location details**: Optional text input (Max 255 characters).
- **Incident Date**: Optional date selector.
- **Attachment**: Optional image/file upload.

### B. Submission Logic
- Generates a unique ticket number: `CMP-` + current year + 6-digit serial (e.g. `CMP-2026-000001`).
- Sets default status to Open.
- Attaches uploaded files to the database record.

---

## 3. Database References
- **Models**:
  - `Modules\Complaint\Models\Complaint`
  - `Modules\Complaint\Models\ComplaintCategory`
- **Tables**:
  - `cmp_complaints`
  - `cmp_complaint_categories`
