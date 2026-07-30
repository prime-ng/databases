# Question Media Store — Business Requirements

## What This Screen Does

The Question Media Store screen is where teachers manage media files (images, audio clips, videos, and PDFs) that can be attached to questions, answer options, and teacher explanations. Think of it as a media library that stores files and lets teachers reuse them across multiple questions.

Each media file is stored with metadata: file name, file path, MIME type, storage disk, file size, checksum, owner type (QUESTION, OPTION, EXPLANATION, or RECOMMENDATION), and optional curriculum tagging (class, subject, lesson, topic) for easier filtering.

Each media file is linked to a single owner through a polymorphic `morphTo` relationship on the `qns_media_store` table itself. The `owner_type` column stores the owner category (QUESTION, OPTION, EXPLANATION, RECOMMENDATION); `owner_id` stores the foreign key. A media file belongs to exactly one owner — sharing across multiple owners is not supported. Note: `owner_id` is NOT in the model's `$fillable` and is NOT passed by the controller, so the relationship is effectively non-functional.

---

## When This Screen Is Used

- **Uploading Media** — When a teacher wants to add an image, audio clip, video, or PDF to the media library
- **Attaching Media to Questions** — Media is linked to an owner (question/option/explanation) during media creation via the `owner_type` field (no UI modal exists for attaching during question editing)
- **Browsing Available Media** — To find and reuse existing media files across different questions
- **Reordering Media** — To change the display order of media attached to a question or option
- **Soft-Deleting and Restoring** — To temporarily remove a media file or bring it back

---

## Who Can Access This Screen

- **Teacher** — Can upload and manage media for their questions
- **Head of Department** — Full access
- **School Admin** — Full access

All access is controlled by permissions like `tenant.question-media-store.viewAny`, `tenant.question-media-store.view`, `tenant.question-media-store.create`, `tenant.question-media-store.update`, `tenant.question-media-store.delete`, `tenant.question-media-store.restore`, `tenant.question-media-store.forceDelete`, `tenant.question-media-store.status`.

---

## How This Screen Works — Logic Flow (Non-Technical)

### The Media List

When a teacher opens the Question Media tab, the system shows a paginated list of all media files. Each row shows the file name, media type badge (IMAGE, AUDIO, VIDEO, PDF), file size, owner type, and Action buttons (View, Edit, Delete).

### Uploading Media

When the teacher clicks "Add Media," a form opens with:
- **Owner Type** — Required: QUESTION, OPTION, EXPLANATION, or RECOMMENDATION
- **Class, Subject, Lesson, Topic** — Optional curriculum tagging for easier filtering
- **Media Type** — Required: IMAGE, AUDIO, VIDEO, PDF
- **Ordinal** — Display order position
- **Placed At** — Optional location reference (in `$fillable` and validated by Request, but NOT passed to `create()` or `update()` by the controller — field is never persisted)
- **Disk** — Required: local or public
- **Media File** — The actual file to upload (validated by type)

The file is validated based on its media type: images must be valid image formats, audio must be valid audio formats, etc. Images may be automatically compressed to reduce file size.

### Editing Media

When editing, metadata (owner type, curriculum tags, ordinal, disk) can be updated. The media file itself can be replaced. Note: `placed_at` is NOT persisted by the controller despite being in `$fillable` and validated.

### Viewing Media Details

The detail view shows all file metadata including UUID, file name, media type, file path, MIME type, formatted size, URL, disk, active status, and related curriculum names (class, subject, lesson, topic).

### Reordering Media (Note: `$ownerId` is accepted but ignored)

Teachers can change the display order of media files filtered by `owner_type` using the reorder function. The `$ownerId` parameter is accepted by the route signature but ignored in the query — only `owner_type` is used for filtering.

### Browsing by Owner (Note: `$ownerId` is accepted but ignored)

Teachers can view media files filtered by `owner_type` using the `getByOwner` endpoint. The `$ownerId` parameter is accepted by the route signature but ignored in the query — only `owner_type` is used for filtering.

### Soft-Deleting and Restoring

Media files can be soft-deleted. Force-deleting permanently removes the file from storage and the database record (no junction table exists).

---

## Validate Before Save

| Field | Rule |
|-------|------|
| owner_type | Required, must be one of: QUESTION, OPTION, EXPLANATION, RECOMMENDATION |
| class_id | Optional, must exist in classes table |
| subject_id | Optional, must exist in subjects table |
| lesson_id | Optional, must exist in lessons table |
| topic_id | Optional, must exist in topics table |
| media_type | Required, must be one of: IMAGE, AUDIO, VIDEO, PDF |
| ordinal | Optional, whole number, minimum 1 |
| placed_at | Optional, text, max 255 characters |
| disk | Required, must be one of: local, public |
| media_file | Required on create (with MIME validation per media_type); optional on update |

---

## Business Rules and Conditions

### Rule 1: File Type Validation per Media Type
Each media type has specific file format requirements:
- IMAGE: jpg, jpeg, png, gif, webp
- AUDIO: mp3, wav, ogg
- VIDEO: mp4, avi, mov
- PDF: pdf

### Rule 2: Image Compression
Uploaded images may be automatically compressed to reduce storage size while maintaining quality.

### Rule 3: Polymorphic Ownership
Media files are linked to a single owner via a polymorphic `morphTo` relationship on `qns_media_store`. Each media file belongs to exactly one owner (QUESTION, OPTION, EXPLANATION, or RECOMMENDATION). Sharing across multiple owners is not supported.

### Rule 4: Cascade on Owner Delete (Not Implemented)
The code does not define any cascade behavior when an owner (question/option) is deleted. Media records with orphaned `owner_id` values are not automatically cleaned up.

### Rule 5: UUID Generation
Each media file is assigned a UUID on creation for unique identification across the system.

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| File Type Validation | Each media type only accepts specific file formats |
| Image Compression | Uploaded images are compressed automatically |
| Polymorphic Ownership | Media linked to a single owner via morphTo relationship on qns_media_store |
| No Cascade on Delete | No cascade behavior defined for owner deletion (orphaned records) |
| UUID | Each media file gets a unique UUID |

---

## Validate Before Save — Error Messages

| Scenario | Error Message |
|----------|--------------|
| Invalid owner type | "The selected owner type is invalid." |
| Invalid media type | "The selected media type is invalid." |
| File not provided on create | "The media file field is required." |
| Invalid disk | "The selected disk is invalid." |
| File type mismatch | Validation message based on media type |

---

## Success Scenarios

- A teacher uploads an image diagram of the human heart for a Biology question. The file is stored, compressed, and assigned UUID, linked to the question via the `owner_type` field.

---

## Example Scenario

Ms. Sharma is creating a Biology question about the human heart. She first opens the Question Media tab and uploads a diagram of the heart (heart_diagram.png, 2.5 MB, IMAGE type, tagged to Class 10 Biology Lesson "Circulatory System"). The system compresses the image to 800 KB.

Later, the diagram is retrievable via the `getByOwner` endpoint filtered by `owner_type` = QUESTION. (No Media Attachment modal exists in the current codebase.)

---

## Related Screens

- **Question Bank** — Where media is attached to questions and options during creation/editing
- **Question Review** — Where review decisions are documented

---

## Dependencies module and tables

| Module | Tables |
|--------|--------|
| QuestionBank Core | `qns_media_store` (primary table — no junction table exists) |
| Syllabus | `slb_lessons`, `slb_topics` (curriculum tagging) |
| School Setup | `sch_classes`, `sch_subjects` (curriculum tagging) |
