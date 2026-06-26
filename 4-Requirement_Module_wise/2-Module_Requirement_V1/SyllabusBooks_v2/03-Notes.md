# Notes — Business Requirements

## What This Screen Does

The Notes screen allows teachers and students to upload study notes — revision summaries, practice questions, formula sheets, mind maps, and more. Notes can be linked to specific books and chapters, or they can be standalone resources.

This is the school's collaborative study material repository. Instead of printing and distributing paper notes, everything is uploaded once and made available digitally.

---

## When This Screen Is Used

- A teacher creates a revision summary for an upcoming exam
- A student submits a well-prepared notes for teacher approval
- Teachers want to share subject-wide study guides
- Admin wants to review and approve pending notes

---

## Key Fields at a Glance

**Title**
A short, descriptive name for the note. Example: "Polynomials Quick Revision", "Periodic Table Mnemonics".

**Description (Optional)**
A longer explanation of what the note covers.

**Notes Type**
What kind of note is this? Options include:

| Type | Description |
|------|-------------|
| Revision Notes | Exam-focused summary |
| Practice Questions | Sample problems with answers |
| Formula Sheet | Key formulas for quick reference |
| Mind Map | Visual concept mapping |
| Flow Chart | Step-by-step process diagram |
| Cheat Sheet | Compact reference card |
| Summary | Chapter synopsis |
| Worksheet | Printable exercise sheet |
| Other | Anything else |

**Class, Subject, Academic Session**
Which class and subject this note is meant for. Every note must be assigned to a specific class-subject combination.

**Book (Optional)**
If this note is based on a particular textbook, link it to the book.

**Chapter (Optional)**
If the note is for a specific chapter of the linked book, select the chapter.

**Visibility**
Who can see this note?

| Option | Description |
|--------|-------------|
| Class Only | Only students in the same class can see it |
| Subject Wide | All students taking this subject across classes can see it |
| School Wide | Everyone in the school can see it |

**Downloadable Toggle**
Whether students are allowed to download the note file or can only view it online.

**Note File**
The actual study material file (PDF, DOCX, JPG, PNG, or other allowed format).

---

## Approval Workflow

Notes go through a status workflow. This ensures content quality before students access it.

```
DRAFT ──→ PENDING APPROVAL ──→ APPROVED
                               └──→ REJECTED (with reason)
DRAFT ──→ ARCHIVED
```

| Status | What It Means |
|--------|---------------|
| Draft | Work in progress. Only the uploader can see it. |
| Pending Approval | Submitted for review. Teachers/Admins see it in the approval queue. |
| Approved | Published. Visible to students based on the visibility setting. |
| Rejected | Didn't meet quality standards. The uploader is told the reason. |
| Archived | No longer relevant. Hidden from all users. |

### Approval Configuration (from Settings)

- **Student uploads** — Can require teacher approval before notes go live
- **Teacher uploads** — Can be auto-approved or require admin approval
- **Daily limit** — Students may be limited to a maximum number of uploads per day

---

## How the Approval Flow Works in Practice

**For a Student:**
1. Student uploads a note → it starts as "Pending Approval"
2. Teacher receives a notification
3. Teacher reviews the content
4. Teacher Approves (note becomes visible) or Rejects (student sees the rejection reason)

**For a Teacher:**
1. Teacher uploads a note → it is auto-approved (if settings allow) or goes to Pending Approval
2. Admin may review and approve/reject

---

## Note Ratings

Students can rate approved notes (1 to 5 stars). This helps the community identify high-quality notes. Ratings are anonymous and each student can only rate a note once.

---

## List View Features

| Feature | Description |
|---------|-------------|
| Search | By title, description |
| Filter | By class, subject, status, notes type, uploader role |
| Status Badge | Colour-coded status indicator |
| Rating Stars | Average rating displayed in the list |
| Download Count | How many times the note has been downloaded |

---

## Business Rules

**Book-Chapter Relationship**
If a note is linked to a book, the chapter selection shows only chapters belonging to that book. This ensures accurate linking.

**Unique Rating**
Each user can rate a specific note only once. If they try again, their previous rating is updated.

**Soft Delete**
Notes can be soft-deleted (moved to trash) and restored later. Permanent deletion removes the note file permanently.

**File Upload Rules**
- Allowed formats and maximum file size are controlled from Settings
- Each note can have one primary file plus optional additional files

---

## Example Scenarios

**Teacher Creates Revision Notes:**
Mrs. Sharma, Class 10 Maths teacher, creates "Quadratic Equations: Quick Revision" — selects Class 10, Subject Maths, links it to the NCERT Maths textbook, Chapter 4. Sets visibility to "Subject Wide" so all Class 10 sections benefit. The note is auto-approved. Students across all Class 10 sections can now download it.

**Student Submits Practice Questions:**
Rahul, a Class 12 Physics student, creates "Electrostatics Practice Problems" with 20 solved questions. His upload goes to Pending Approval. His teacher reviews it, finds it excellent, and approves it. Now all Class 12 Physics students can access Rahul's work.

---

## Related Screens

- **Book** — Notes can reference books and chapters
- **Downloads** — Note downloads are tracked in the audit log
- **Settings** — Upload limits, approval requirements, and format controls are configured from Settings
