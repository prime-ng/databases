# Settings (Module Configuration) — Business Requirements

## What This Screen Does

The Settings screen is where the admin defines the rules and limits for the entire Syllabus Books module. It controls what can be uploaded, who can upload, whether content is watermarked, and how notes are approved.

Think of this as the control room — every decision made here affects how teachers and students interact with books and notes across the school.

---

## When This Screen Is Used

- At the start of the academic year to configure module policies
- When the school decides to allow or restrict certain file formats
- When content protection needs to be enabled (e.g., watermarking)
- When upload limits need to be adjusted based on storage capacity
- When approval workflow rules change

---

## Configuration Sections

### 1. Book Settings

| Setting | Options | Description |
|---------|---------|-------------|
| Max File Size (MB) | Numeric value | Maximum allowed size for a single book file upload |
| Allowed Formats | PDF, EPUB, JPG, PNG (can select multiple) | Which file formats are accepted for book file uploads |
| Default Downloadable | On / Off | Whether new book files are downloadable by default |

### 2. Notes Settings

| Setting | Options | Description |
|---------|---------|-------------|
| Max File Size (MB) | Numeric value | Maximum allowed size for a single note file upload |
| Allowed Formats | PDF, DOCX, JPG, PNG (can select multiple) | Which file formats are accepted for note uploads |
| Default Downloadable | On / Off | Whether new notes are downloadable by default |

### 3. Student Uploads

| Setting | Options | Description |
|---------|---------|-------------|
| Allow Student Uploads | On / Off | Master switch to enable or disable all student note uploads |
| Require Approval | On / Off | Whether student uploads need teacher approval before becoming visible |
| Max Uploads Per Day | Numeric value | Limit on how many notes a student can upload in a single day |
| Max Per Subject | Numeric value | Limit on how many notes a student can upload for a single subject |

### 4. Teacher Upload Approval

| Setting | Options | Description |
|---------|---------|-------------|
| Require Approval | On / Off | Whether teacher uploads need admin approval or are auto-approved |

### 5. Content Protection

| Setting | Options | Description |
|---------|---------|-------------|
| Watermark | On / Off | Enable or disable watermark overlay on viewed content |
| Watermark Text | Free text | What text to display as the watermark (e.g., "School Name — Confidential") |
| Prevent PDF Print | On / Off | Block users from printing PDF files |
| Prevent PDF Copy | On / Off | Block users from copying text from PDF files |

### 6. Cross-Class Visibility

| Setting | Options | Description |
|---------|---------|-------------|
| Cross-Class Sharing | On / Off | Allow notes to be shared across different classes (useful for subjects like Maths that span multiple classes) |

---

## How Settings Affect Other Screens

| Setting | Affects |
|---------|---------|
| Book Max File Size + Allowed Formats | Book file upload — rejects files exceeding the size limit or of unlisted format |
| Notes Max File Size + Allowed Formats | Note file upload — rejects files exceeding the size limit or of unlisted format |
| Student Uploads (Require Approval) | Notes approval workflow — determines whether student notes go to Pending or get auto-approved |
| Teacher Upload Approval | Notes approval workflow — determines whether teacher notes are auto-approved or require admin review |
| Watermark Settings | Content display across the module — watermarks appear when viewing book/note content online |
| Cross-Class Sharing | Notes visibility — controls whether "Subject Wide" and "School Wide" visibility options are functional |

---

## Example Scenario

At the start of the session, the admin configures:
- Books: Max 50 MB, allow PDF and EPUB, downloadable by default
- Notes: Max 10 MB, allow PDF and DOCX, downloadable by default
- Student uploads: Enabled, require approval, max 5 per day, max 3 per subject
- Teacher uploads: Do not require approval
- Content protection: Watermark ON with "Springfield School — For Internal Use Only", prevent PDF print ON, prevent PDF copy ON
- Cross-class sharing: ON

This means:
- Teachers can upload PDF/EPUB books up to 50 MB without waiting for approval
- Students can upload up to 5 PDF/DOCX notes per day (max 3 per subject), but each note waits for teacher approval
- All content viewed online shows a watermark
- PDF printing and copying are blocked
- A note created for Class 10 Maths can also be seen by Class 11 students taking the same subject

---

## Related Screens

- **Book** — Upload limits and format restrictions apply when adding book files
- **Notes** — Approval workflow and upload limits apply when adding notes
- **Downloads** — Not directly affected by settings
