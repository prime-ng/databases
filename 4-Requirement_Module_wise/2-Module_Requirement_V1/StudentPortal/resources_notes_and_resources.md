# Resources — Notes & Resources Tab Requirements

## 1. Functional Overview
A repository of study notes, syllabus files, and guides uploaded by teachers, filtered by class and enrollment.

---

## 2. Directory Layout & Parameters

### A. Resource List Grid
- Displays study files grouped by note type:
  - **Details**: Title, Subject, Chapter, Author (Teacher Name).
  - **Rating**: Average rating stars and total reviews count.
  - **Actions**: "Download Notes" and "Rate Note" buttons.

### B. Secure File Downloads
- File downloads increment the download counter and log download details (Note ID, User ID, IP, User Agent).

### C. Rating & Review Modal
- **Form Inputs**:
  - Star Rating: 1-5 stars.
  - Review: Optional text input (Max 500 characters).
- Submitting a rating recomputes the average rating for the notes file.

---

## 3. Database References
- **Models**:
  - `Modules\SyllabusBooks\Models\SlbNote`
  - `Modules\SyllabusBooks\Models\SlbNotesRating`
  - `Modules\SyllabusBooks\Models\SlbNotesDownload`
- **Tables**:
  - `slb_notes`
  - `slb_notes_ratings`
  - `slb_notes_downloads`
