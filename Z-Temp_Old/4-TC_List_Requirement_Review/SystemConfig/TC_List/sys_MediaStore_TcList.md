# Media Asset Viewer — Test Case List

## 1. Module Overview

| Attribute | Value |
|-----------|-------|
| **Module** | SystemConfig |
| **Feature** | Media Asset Viewer (REQ-SYS-010) |
| **Controller** | `TenantMediaStoreController` |
| **Routes** | `GET /system-config/media-store`, `GET /system-config/media-store/{id}/check` |
| **Permission** | `system-config.setting.viewAny` (reuses setting permission) |
| **Auth Pattern** | `Gate::authorize('system-config.setting.viewAny')` |
| **DB Table** | `sys_media` (Spatie Media Library) |
| **Model** | `Modules\Prime\Models\Media` |
| **Pagination** | **None** — all records loaded in-memory (Known Issue) |

---

## 2. Test Environment

- PHP 8.2+, Laravel 12
- spatie/laravel-medialibrary installed and configured
- `sys_media` table populated with ≥ 50 records across various MIME types
- At least 3 different disks configured (e.g. `public`, `local`, `s3`)
- File URLs must be resolvable via `$mediaItem->getUrl()`
- At least one file should be missing from disk for integrity check testing

---

## 3. Test Case Matrix

### 3.1 Authentication & Authorization

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-MS-01 | Unauthenticated user redirected to login | User not logged in | 1. Access `GET /system-config/media-store` | Redirected to login | — | — | ⬜ | ◌ |
| TC-MS-02 | Authenticated user without permission receives 403 | User lacks `system-config.setting.viewAny` | 1. Log in as user without permission<br>2. Access route | 403 Forbidden | — | — | ⬜ | ◌ |
| TC-MS-03 | User with `system-config.setting.viewAny` can view | User has permission | 1. Log in with correct permission<br>2. Access route | 200 OK, view rendered | — | — | ⬜ | ◌ |
| TC-MS-04 | Check file endpoint requires auth | Unauthenticated | 1. Access `GET /system-config/media-store/{id}/check` | Redirected to login | — | — | ⬜ | ◌ |
| TC-MS-05 | Check file endpoint 403 without permission | No permission | 1. Access as user without permission | 403 Forbidden | — | — | ⬜ | ◌ |

### 3.2 Dashboard Stats

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-MS-06 | Total file count stat displayed | 100 files in DB | 1. View media store | "Total Files" card shows "100" | — | — | ⬜ | ◌ |
| TC-MS-07 | Total storage used stat displayed | Files with known sizes | 1. View media store | "Total Storage Used" shows correct formatted size (e.g. "15.50 MB") | — | — | ⬜ | ◌ |
| TC-MS-08 | Collection count stat displayed | 5 distinct collections | 1. View media store | "Collections" card shows "5" | — | — | ⬜ | ◌ |
| TC-MS-09 | Storage disks count stat displayed | 3 distinct disks | 1. View media store | "Storage Disks" card shows "3" | — | — | ⬜ | ◌ |
| TC-MS-10 | Stats correct with zero media files | Empty `sys_media` table | 1. View media store | Total Files: 0, Total Storage: 0 B, Collections: 0, Disks: 0 | — | — | ⬜ | ◌ |

### 3.3 Disk Breakdown

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-MS-11 | Disk breakdown cards shown | Multiple disks with files | 1. View media store | Mini-cards show disk name, file count, total size per disk | — | — | ⬜ | ◌ |
| TC-MS-12 | Disk breakdown not shown when no disks | No media files | 1. View media store | Disk breakdown section hidden | — | — | ⬜ | ◌ |

### 3.4 Tab Navigation

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-MS-13 | All tab shows all media files | Mixed files | 1. View media store | "All" tab active by default; all files shown | — | — | ⬜ | ◌ |
| TC-MS-14 | Images tab shows only image MIME types | Images exist | 1. Click Images tab | Only files with MIME in images group shown | — | — | ⬜ | ◌ |
| TC-MS-15 | PDFs tab shows only PDF files | PDFs exist | 1. Click PDFs tab | Only `application/pdf` files shown | — | — | ⬜ | ◌ |
| TC-MS-16 | Documents tab shows Word/Excel/CSV/TXT | Documents exist | 1. Click Documents tab | Only document MIME types shown | — | — | ⬜ | ◌ |
| TC-MS-17 | Videos tab shows video MIME types | Videos exist | 1. Click Videos tab | Only video MIME types shown | — | — | ⬜ | ◌ |
| TC-MS-18 | Audio tab shows audio MIME types | Audio files exist | 1. Click Audio tab | Only audio MIME types shown | — | — | ⬜ | ◌ |
| TC-MS-19 | Others tab shows files not in any defined group | Files with unknown MIME types | 1. Click Others tab | Only files with MIME types not in any group shown | — | — | ⬜ | ◌ |
| TC-MS-20 | Tab badge shows correct count per tab | Files in each category | 1. View tabs | Each tab's badge displays accurate file count for that category | — | — | ⬜ | ◌ |
| TC-MS-21 | Tab with 0 files is hidden (except All) | No PDFs in DB | 1. View media store | PDFs tab hidden when count is 0 | — | — | ⬜ | ◌ |

### 3.5 Search & Filter

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-MS-22 | Search by file_name | File with known name | 1. Search for partial filename | Results filtered | — | — | ⬜ | ◌ |
| TC-MS-23 | Search by name (human-readable) | File with known name | 1. Search for name text | Results filtered | — | — | ⬜ | ◌ |
| TC-MS-24 | Search by collection_name | Files in known collection | 1. Search for collection name | Results filtered | — | — | ⬜ | ◌ |
| TC-MS-25 | Search by model_type | Files for known model | 1. Search for "Book" | Results filtered | — | — | ⬜ | ◌ |
| TC-MS-26 | Disk filter dropdown | Multiple disks exist | 1. Select specific disk | Only files on that disk shown | — | — | ⬜ | ◌ |
| TC-MS-27 | Search + Disk combined filter | Both params | 1. Search + select disk | Both filters applied (AND) | — | — | ⬜ | ◌ |
| TC-MS-28 | Search with no results | Unique search term | 1. Enter non-matching search | "No media files found." empty state | — | — | ⬜ | ◌ |
| TC-MS-29 | Clear search resets results | Search active | 1. Clear search field, re-submit | All files shown | — | — | ⬜ | ◌ |

### 3.6 File Display

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-MS-30 | Image file shows thumbnail | JPEG/PNG file | 1. View Images tab | Thumbnail image displayed (38x38, object-fit:cover) | — | — | ⬜ | ◌ |
| TC-MS-31 | Image thumbnail fallback on error | Broken image file | 1. View corrupted image | Fallback icon shown | — | — | ⬜ | ◌ |
| TC-MS-32 | Non-image file shows MIME icon | PDF file | 1. View PDFs tab | PDF icon shown | — | — | ⬜ | ◌ |
| TC-MS-33 | File name displayed with tooltip | Long filename | 1. Hover over filename | Full filename in tooltip; truncated display | — | — | ⬜ | ◌ |
| TC-MS-34 | MIME type displayed below filename | Any file | 1. View file row | MIME string shown in small text | — | — | ⬜ | ◌ |
| TC-MS-35 | Collection name shown as badge | File has collection | 1. View file row | Collection name in info-colored badge | — | — | ⬜ | ◌ |
| TC-MS-36 | Model type + ID displayed | Any media | 1. View file row | Model class_basename + "#{ID}" shown | — | — | ⬜ | ◌ |
| TC-MS-37 | Disk name displayed as badge | File on disk | 1. View file row | Disk name in badge; conversions_disk shown if different | — | — | ⬜ | ◌ |
| TC-MS-38 | File size formatted correctly | Various sizes | 1. View file row | Size in human-readable format (B/KB/MB/GB) | — | — | ⬜ | ◌ |
| TC-MS-39 | Conversions badge shows progress | File with conversions | 1. View file row | "N/M done" badge; green if all done, warning if partial | — | — | ⬜ | ◌ |
| TC-MS-40 | No conversions = "None" badge | File without conversions | 1. View file row | "None" badge in secondary color | — | — | ⬜ | ◌ |
| TC-MS-41 | Upload date displayed | Any file | 1. View file row | Date in "d M Y" format | — | — | ⬜ | ◌ |
| TC-MS-42 | Open file button links to file URL | Any file | 1. Click arrow-up button | File opens in new tab | — | — | ⬜ | ◌ |

### 3.7 File Integrity Check

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-MS-43 | Check file button returns JSON with correct structure | File exists on disk | 1. Click check button on existing file | Button shows green check; row flashes green; JSON: `{id, exists: true, url}` | — | — | ⬜ | ◌ |
| TC-MS-44 | Check file — file missing on disk | File record exists but file deleted | 1. Click check button on missing file | Button shows warning icon; row flashes red; `exists: false` | — | — | ⬜ | ◌ |
| TC-MS-45 | Check file — non-existent media ID | Invalid ID | 1. Call `GET /media-store/9999/check` | 404 Not Found | — | — | ⬜ | ◌ |
| TC-MS-46 | Check file — loading state during request | Any file | 1. Click check button while request pending | Button shows spinner icon, disabled | — | — | ⬜ | ◌ |
| TC-MS-47 | Check file — network error handling | Server unreachable | 1. Trigger error | Warning icon shown | — | — | ⬜ | ◌ |
| TC-MS-48 | Check file — row flash clears after 4 seconds | File checked | 1. Check file, wait 4 seconds | Row color class removed | — | — | ⬜ | ◌ |

### 3.8 No Upload/Delete

| TC# | Test Case | Precondition | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-MS-49 | No upload button on page | Any state | 1. Inspect page | No upload control present | — | — | ✅ | ◌ |
| TC-MS-50 | No delete button on any row | Any file | 1. Inspect page | No delete control present | — | — | ✅ | ◌ |
| TC-MS-51 | No edit controls on any row | Any file | 1. Inspect page | No edit control present | — | — | ✅ | ◌ |

---

## 4. Boundary & Edge Cases

| TC# | Test Case | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------|-----------------|----|----|--------|----|
| TC-MS-52 | Empty media library (0 files) | 1. View with empty table | Stats show 0s; All tab shows "No media files found." | — | — | ⬜ | ◌ |
| TC-MS-53 | Very large file (> 2GB) | 1. Create 2GB+ media record | Size formatted correctly in GB | — | — | ⬜ | ◌ |
| TC-MS-54 | File with very long filename (255 chars) | 1. Create file with 255-char name | Name truncated with tooltip; table layout intact | — | — | ⬜ | ◌ |
| TC-MS-55 | Thousands of media files (> 5000) | 1. Populate 5000+ records | Page loads (may be slow due to no pagination) | — | — | ⬜ | ◌ |
| TC-MS-56 | Search with special SQL characters | 1. Search for `%` or `_` | LIKE treats as literal (test MySQL behavior) | — | — | ⬜ | ◌ |
| TC-MS-57 | Unknown MIME type | 1. Create record with MIME `application/octet-stream` | Appears in "Others" tab | — | — | ⬜ | ◌ |
| TC-MS-58 | Disk filter with no files on selected disk | 1. Select disk with 0 files | Tab shows "No media files found." | — | — | ⬜ | ◌ |
| TC-MS-59 | File with null mime_type | 1. Create media with null mime_type | Appears in "Others" tab (not in any group) | — | — | ⬜ | ◌ |

---

## 5. Test Data Requirements

| Data Type | Quantity | Details |
|-----------|----------|---------|
| Image files (JPEG, PNG, GIF, WebP, SVG) | ≥ 10 | Mixed MIME types |
| PDF files | ≥ 5 | `application/pdf` |
| Document files (DOCX, XLSX, CSV, TXT) | ≥ 5 | Mixed document MIME types |
| Video files (MP4, WebM) | ≥ 3 | |
| Audio files (MP3, WAV, OGG) | ≥ 3 | |
| Unknown MIME files | ≥ 3 | e.g. `application/octet-stream` |
| Files across multiple disks | ≥ 3 disks | e.g. `public`, `local`, `s3` |
| Files with generated_conversions | ≥ 3 | Some complete, some partial |
| Files without conversions | ≥ 3 | |
| File missing from disk | ≥ 1 | Record exists but file deleted |
| Distinct collection names | ≥ 5 | e.g. `book_covers`, `avatars`, `documents` |
| Distinct model_types | ≥ 3 | e.g. `Book`, `User`, `Assignment` |

---

## 6. Test Execution Checklist

| Check | Description | Done? |
|-------|-------------|-------|
| Authentication tests pass (TC-MS-01 to TC-MS-05) | | ⬜ |
| Stats display correctly (TC-MS-06 to TC-MS-10) | | ⬜ |
| Disk breakdown displays (TC-MS-11, TC-MS-12) | | ⬜ |
| Tab navigation works for all 7 tabs (TC-MS-13 to TC-MS-21) | | ⬜ |
| Search + filter functions (TC-MS-22 to TC-MS-29) | | ⬜ |
| File display renders correctly (TC-MS-30 to TC-MS-42) | | ⬜ |
| File integrity check works (TC-MS-43 to TC-MS-48) | | ⬜ |
| View-only constraint verified (TC-MS-49 to TC-MS-51) | | ⬜ |
| Edge cases tested (TC-MS-52 to TC-MS-59) | | ⬜ |

---

## 7. Automation Notes

- Use `Pest` with `get()` for page loads
- File check endpoint tests should use `getJson()`
- Media records can be created via `Media` factory or using Spatie's `addMedia()` on a model
- For testing "missing file" scenario: create media record, then delete physical file from disk
- Performance test with 5000+ records is important due to no pagination
- Verify that `$mediaItem->getUrl()` returns a URL without throwing (may require storage link or S3 mock)

---

## 8. Known Issues

| # | Issue | Impact | Status |
|---|-------|--------|--------|
| 1 | **No pagination** — all media loaded into memory via `->get()` | Critical performance issue with large datasets; risk of OOM | ⬜ High Priority |
| 2 | Reuses `system-config.setting.viewAny` permission — no dedicated media permission | Over-permissioning risk | ⬜ Medium |
| 3 | MIME groups hardcoded in controller — not configurable | Adding new MIME types requires code change | ⬜ Low |
| 4 | View uses inline PHP functions (`formatBytes`, `mimeIcon`, `conversionBadge`) | Code duplication; hard to test | ⬜ Low |
| 5 | No feature tests exist — this list is forward-looking | All TCs unexecuted | ⬜ Backlog |

---

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/system-config/media-store` | `system-config.media-store.index` | `TenantMediaStoreController@index` |
| GET | `/system-config/media-store/{id}/check` | `system-config.media-store.check` | `TenantMediaStoreController@checkFile` |

---

## 10. Execution Status

| Total TCs | Pass | Fail | Blocked | Not Run | Coverage |
|-----------|------|------|---------|---------|----------|
| 59 | 0 | 0 | 0 | 59 | 0% |

**Last Executed:** —
**Executed By:** —
**Environment:** —
**Remarks:** Initial test case list created from code analysis. Pagination gap (Known Issue #1) should be addressed before full test execution.

---

## Document History

| Version | Date | Author | Notes |
|---------|------|--------|-------|
| 1.0 | 2026-07-23 | OpenCode AI | Initial TC list from controller + FRD analysis |
