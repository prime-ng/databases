# Media Asset Viewer — Requirement Document

## 1. Overview

The Media Asset Viewer provides a **read-only, tabbed browser** of all media files stored via the Spatie Media Library package (`sys_media` table). It allows platform administrators to browse files by MIME type category, search by file metadata, and verify file integrity on disk. It includes aggregate statistics and a per-file integrity check endpoint.

| Attribute | Value |
|-----------|-------|
| **Module** | SystemConfig |
| **Controller** | `TenantMediaStoreController` |
| **Prefix** | `sys_` (`sys_media`) |
| **FRD IDs** | REQ-SYS-010 |
| **Permission** | `system-config.setting.viewAny` (reuses setting permission) |
| **Auth Pattern** | `Gate::authorize('system-config.setting.viewAny')` |
| **Routes** | `GET /system-config/media-store`, `GET /system-config/media-store/{id}/check` |
| **DB Source** | Tenant database — `sys_media` (spatie/media-library) |
| **Model** | `Modules\Prime\Models\Media` (extends `Spatie\MediaLibrary\MediaCollections\Models\Media`) |
| **CRUD?** | **No** — View Only. No upload/edit/delete routes. |

---

## 2. Actor / User Role

| Role | Access |
|------|--------|
| Super Admin | Full read access — all tabs, search, disk filter, file check |
| Platform Manager | Access via `system-config.setting.viewAny` (shared with Settings feature) |
| Platform Support | Access via same permission |
| School Admin | Access from tenant subdomain via same permission |

**Note:** Media Store reuses the `system-config.setting.*` permission, not a dedicated media permission. This means granting setting access also grants media access and vice versa.

---

## 3. Functional Requirements

| ID | Requirement | Status | Notes |
|----|-------------|--------|-------|
| FR-MS-01 | Dashboard stats: Total file count, total storage used, collection count, disk count | ✅ Implemented | 4 stat cards |
| FR-MS-02 | Disk breakdown: per-disk file count + total size | ✅ Implemented | Small cards below stats |
| FR-MS-03 | Tabbed media listing: All, Images, PDFs, Documents, Videos, Audio, Others | ✅ Implemented | MIME group definitions hardcoded in controller |
| FR-MS-04 | Search by `file_name`, `name`, `collection_name`, `model_type` | ✅ Implemented | LIKE %search% across all 4 fields |
| FR-MS-05 | Disk filter dropdown | ✅ Implemented | Select distinct disks |
| FR-MS-06 | File integrity check endpoint (per file) | ✅ Implemented | `checkFile()` — verifies `Storage::disk()->exists()` |
| FR-MS-07 | Display: thumbnail (images) or MIME type icon (other files) | ✅ Implemented | Thumbnail fallback with error handling |
| FR-MS-08 | Display: file name, MIME type, collection, model, disk, size, conversions, upload date | ✅ Implemented | Full row per file |
| FR-MS-09 | Open file in new tab | ✅ Implemented | External link button |
| FR-MS-10 | Visual feedback on file check (green row = OK, red = missing) | ✅ Implemented | Inline JS with row color flash |
| FR-MS-11 | CSV / bulk export | — | Not implemented |

---

## 4. MIME Group Definitions

The controller defines the following MIME groups as a `const` array:

| Group | MIME Types |
|-------|-----------|
| **Images** | `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `image/svg+xml`, `image/avif` |
| **PDFs** | `application/pdf` |
| **Documents** | `application/msword`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document`, `application/vnd.ms-excel`, `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`, `text/plain`, `text/csv` |
| **Videos** | `video/mp4`, `video/mpeg`, `video/quicktime`, `video/webm` |
| **Audio** | `audio/mpeg`, `audio/wav`, `audio/ogg`, `audio/mp4` |
| **Others** | Everything not in the above groups |

---

## 5. Business Rules

| Rule ID | Rule | Source | Status |
|---------|------|--------|--------|
| — | Tab counts are computed client-side from pre-loaded `$tabs` collection | Implementation | ✅ All MIME-group filtering done in-memory on the full result set |
| — | The "Others" tab includes `$knownMimes` exclusion (union of all group MIME types) | Implementation | ✅ Correctly uses `whereNotIn` |
| — | File check does NOT authenticate per-file; any user with `system-config.setting.viewAny` can check any file | Implementation | ✅ Single gate on the method |
| — | Only `Storage::disk()->exists()` check — no content verification (hash, checksum) | Implementation | ✅ Basic existence check only |

---

## 6. Data Dictionary — `sys_media`

Key columns from Spatie Media Library (`sys_media` in tenant DB):

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| `id` | BIGINT UNSIGNED (PK) | Yes | |
| `model_type` | VARCHAR | Yes | Morph map to owning model |
| `model_id` | BIGINT UNSIGNED | Yes | Morph map ID |
| `uuid` | CHAR(36) | Yes | |
| `collection_name` | VARCHAR | Yes | e.g. `book_covers`, `avatars`, `documents` |
| `name` | VARCHAR | Yes | Human-readable name |
| `file_name` | VARCHAR | Yes | Original filename with extension |
| `mime_type` | VARCHAR | Yes | e.g. `image/jpeg` |
| `disk` | VARCHAR | Yes | e.g. `public`, `s3`, `local` |
| `conversions_disk` | VARCHAR | No | Separate disk for conversions |
| `size` | BIGINT UNSIGNED | Yes | Bytes |
| `manipulations` | JSON | Yes | |
| `custom_properties` | JSON | Yes | |
| `generated_conversions` | JSON | Yes | |
| `responsive_images` | JSON | Yes | |
| `order_column` | INT UNSIGNED | Yes | |
| `created_at` | TIMESTAMP | Auto | |
| `updated_at` | TIMESTAMP | Auto | |

---

## 7. Routes

| Method | URI | Name | Description |
|--------|-----|------|-------------|
| GET | `/system-config/media-store` | `system-config.media-store.index` | Tabbed listing with stats, search, disk filter |
| GET | `/system-config/media-store/{id}/check` | `system-config.media-store.check` | JSON file integrity check |

*Registered in `routes/tenant.php` under middleware `['auth', 'verified']` and prefix `system-config`.*

---

## 8. Controller Logic (TenantMediaStoreController)

### `index(Request $request)`

1. **Authorization:** `Gate::authorize('system-config.setting.viewAny')`
2. **Input:** `$search` (string), `$disk` (string — disk name filter)
3. **Stats Query:**
   - `Media::count()` — total file count
   - `Media::sum('size')` — total bytes
   - `Media::distinct('collection_name')->count('collection_name')` — unique collections
   - `Media::selectRaw('disk, COUNT(*) as cnt, SUM(size) as total_size')->groupBy('disk')->get()` — per-disk breakdown
   - `Media::distinct('disk')->pluck('disk')` — distinct disk list for filter
4. **Base Query:** `$this->baseQuery($search, $disk)->get()` — eager-loads ALL matching records (not paginated)
5. **Known Mimes:** Merges all groups into a flat array
6. **Tab Collections:**
   - `all` → full result set
   - `images` → filter by `self::MIME_GROUPS['images']`
   - `pdfs` → filter by `self::MIME_GROUPS['pdfs']`
   - `documents` → filter by `self::MIME_GROUPS['documents']`
   - `videos` → filter by `self::MIME_GROUPS['videos']`
   - `audio` → filter by `self::MIME_GROUPS['audio']`
   - `others` → `whereNotIn(knownMimes)` — everything not in any group
7. **View:** `systemconfig::media-store.index` with all data

### `checkFile(int $id)`

1. **Authorization:** `Gate::authorize('system-config.setting.viewAny')`
2. Finds `Media` by ID or 404
3. Calls `Storage::disk($mediaItem->disk)->exists($mediaItem->getPathRelativeToRoot())`
4. Returns JSON: `{ id, exists: bool, url: string }`

### `baseQuery(?string $search, ?string $disk)`

- `Media::query()->orderByDesc('created_at')`
- If search: `where file_name LIKE %search% OR name LIKE %search% OR collection_name LIKE %search% OR model_type LIKE %search%`
- If disk: `where disk = $disk`

### View Logic (media-store/index.blade.php)

- **Stats Cards:** 4 cards in a row grid (Total Files, Total Storage, Collections, Storage Disks)
- **Disk Breakdown:** Inline mini-cards showing per-disk file count + size
- **Search:** Text input + disk select dropdown + submit button
- **Tab Navigation:** Bootstrap tabs with file count badges per tab
- **File Table:** Thumbnail/MIME icon, filename, collection badge, model class + ID, disk badge, size, conversions badge, upload date, action buttons (open + check)
- **Check File Button:** Inline JS that calls `checkFile` endpoint, updates button icon to green (exists) or red (missing), flashes row color
- **MIME Icon Mapping:** `image/` → image icon, `video/` → film icon, `audio/` → music icon, `word` → word icon, `excel/spreadsheet` → excel icon, PDF → PDF icon, default → file icon

---

## 9. Known Issues & Gaps

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | **No pagination** — `$allMedia = $this->baseQuery(...)->get()` loads ALL media rows into memory | **High** | With thousands of media files, this will cause OOM or slow page loads |
| 2 | No date range filter | Low | ⬜ Enhancement |
| 3 | No model type filter | Low | ⬜ Enhancement |
| 4 | No collection name filter distinct from search | Low | ⬜ Enhancement |
| 5 | No upload/delete capability — view-only (may be intentional) | Info | As designed |
| 6 | Reuses `system-config.setting.viewAny` permission instead of a dedicated media permission — may cause over-permissioning | Medium | ⬜ Review |
| 7 | File check endpoint does not verify file content integrity (hash/checksum) — only existence on disk | Low | ⬜ Enhancement |
| 8 | No feature tests exist for this controller | High | ⬜ Backlog |
| 9 | MIME group definitions are hardcoded in controller — not configurable or extendable without code change | Low | ⬜ Consider config |
| 10 | View uses inline PHP functions (`formatBytes`, `mimeIcon`, `conversionBadge`) defined in Blade template — should be moved to a helper or service | Low | ⬜ Refactor |

---

## 10. Dependencies

| Dependency | Type | Module | Details |
|------------|------|--------|---------|
| `Modules\Prime\Models\Media` | Model | Prime | Extends `Spatie\MediaLibrary\MediaCollections\Models\Media` |
| `sys_media` table | DB | — | Spatie Media Library — tenant database |
| `spatie/laravel-medialibrary` | Package | — | Media library package |
| Laravel `Storage` facade | Laravel | — | Disk existence checks |

---

## 11. Mock Data / Seed Requirements

- At least 50 media records across multiple collections (e.g. `book_covers`, `avatars`, `documents`, `assignments`)
- At least 5 different MIME types represented: JPEG, PNG, PDF, DOCX, MP4, MP3
- At least 3 different disks (e.g. `public`, `local`, `s3`)
- Some files with `generated_conversions` populated, some without
- At least 1 file where the underlying storage file is missing (for checkFile test)

---

## 12. Version History

| Version | Date | Author | Notes |
|---------|------|--------|-------|
| 1.0 | 2026-07-23 | OpenCode | Initial requirement document from controller analysis + FRD SYS_FRD_Complete_2026-06-30 |

---

## 13. Appendix — FRD Excerpts

**REQ-SYS-010:** Media Asset Viewer — Status: PARTIAL (60%) [inferred]. TenantMediaStoreController + index view exist; auth unknown.

---

## 14. Review Notes

- The controller is well-structured and clean, but **lacks pagination** which is a critical performance gap
- The `baseQuery` returns all matching records; tab filtering is done in-memory with Laravel Collection's `whereIn` / `whereNotIn` — efficient only for small datasets
- File check endpoint returns full URL via `$mediaItem->getUrl()` — this relies on Spatie's URL generation which may vary by disk driver
- The reuse of `system-config.setting.viewAny` is documented in the controller DocBlock comment but not in the actual code

---

## 15. Open Questions

| # | Question | Raised By | Status |
|---|----------|-----------|--------|
| 1 | Was the pagination omission intentional, or is it a known gap? The FRD notes 60% completion | — | ⬜ Open |
| 2 | Should a dedicated `system-config.media.viewAny` permission be created instead of reusing setting permission? | — | ⬜ Open |
| 3 | Should the MIME group definitions be moved to config for extensibility? | — | ⬜ Open |

---

## 16. Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Business Analyst | OpenCode AI | 2026-07-23 | — |
| Tech Lead | — | — | — |
| QA Lead | — | — | — |
