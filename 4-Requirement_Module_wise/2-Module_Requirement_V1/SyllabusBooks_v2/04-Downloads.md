# Downloads (Download Audit) — Business Requirements

## What This Screen Does

The Downloads screen is a read-only audit log that shows who downloaded which book files and study notes, when they downloaded them, and from where. It helps the school monitor content usage, track popular resources, and investigate any unusual download activity.

This is not a place to take action — it is purely for monitoring and reporting.

---

## When This Screen Is Used

- Admin wants to see which books are most downloaded
- A teacher wants to check if students are accessing their notes
- Investigation of suspicious download activity
- End-of-term content usage reporting
- Audit compliance — tracking who accessed what and when

---

## Two Sections

### 1. Notes Download Log

This section lists every time a note file was downloaded.

| Information Captured | Description |
|---------------------|-------------|
| Note Title | Which note was downloaded |
| Downloader Name | Name of the person who downloaded |
| IP Address | Network address of the downloader |
| User Agent | Browser/device information |
| Downloaded At | Date and time of download |

### 2. Book File Download Log

This section lists every time a book file was downloaded.

| Information Captured | Description |
|---------------------|-------------|
| Book Title | Which book the file belongs to |
| File Label | Which file was downloaded (e.g., "Chapter 1 PDF") |
| File Format | Format of the downloaded file (PDF, EPUB, etc.) |
| Downloader Name | Name of the person who downloaded |
| IP Address | Network address of the downloader |
| User Agent | Browser/device information |
| Downloaded At | Date and time of download |

---

## Filtering

Users can filter the download logs to narrow down results:

| Filter | Description |
|--------|-------------|
| By Note | Select a specific note to see its download history |
| By Book | Select a specific book to see its file download history |
| By Date Range | View downloads within a specific period |

---

## Business Rules

**Read-Only**
No one can create, edit, or delete download records manually. Records are created automatically when a user downloads a book file or a note file.

**Automatic Logging**
Every download triggers an automatic log entry. The system captures:
- Who downloaded (the logged-in user)
- What was downloaded (note/book file reference)
- When it happened (server timestamp)
- From where (IP address)
- Using what (browser/device user agent string)

**Permanent Record**
Download records are not deleted (no soft delete, no hard delete). They remain as permanent audit trail entries.

---

## What This Screen Is NOT For

- This is NOT where you upload or manage content
- This is NOT where you approve or reject notes
- This is NOT where you configure settings

Everything here is read-only — a window into how your content is being used.

---

## Example Scenarios

**Monitoring Exam Season Usage:**
In the week before exams, admin notices that "Science for Class 10" has 500 downloads in one day. They filter by book to see which specific files are most popular — Chapter 3 PDF has 200 downloads alone. This tells admin that Chapter 3 content is heavily accessed, which may prompt teachers to focus revision sessions on that chapter.

**Investigating Unusual Activity:**
A note that is normally downloaded 5 times a month suddenly has 100 downloads in one day. Admin filters by that note, sees multiple downloads from the same IP address within minutes. This could indicate a bot or scripted download. Admin can investigate further.

---

## Related Screens

- **Book** — The files being downloaded originate from the Book screen
- **Notes** — The notes being downloaded originate from the Notes screen
