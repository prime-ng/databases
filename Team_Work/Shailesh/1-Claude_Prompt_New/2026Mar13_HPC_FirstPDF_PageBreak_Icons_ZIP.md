# HPC: Fix first_pdf.blade.php — Page Breaks, Icons, Teacher Feedback + ZIP Download

**Date:** 2026-03-13
**Type:** Bug Fix + Enhancement
**Module:** HPC (Holistic Progress Card)
**Severity:** High — PDF renders incorrectly; icons invisible; sections split mid-page
**Files to modify:**
- `Modules/Hpc/resources/views/hpc_form/pdf/first_pdf.blade.php`
- `Modules/Hpc/app/Http/Controllers/HpcController.php`
- `Modules/Hpc/resources/views/student-list/index.blade.php`

---

## Pre-Read (mandatory before coding)

Read these files **in full** before making any changes:

1. `Modules/Hpc/resources/views/hpc_form/pdf/first_pdf.blade.php` — Full file (1,067 lines). Focus on:
   - `$css` array (lines 27–134): `section_container`, `page`, `icon_normal`, `icon_selected`, `circle_container`, `assess_section`, `comments_sec`
   - Teacher Feedback block (lines 639–865): `$resourceEmojis`, `$selfAcItems`, `$peerAcItems`, icon `asset()` calls
   - Page-break logic at bottom of `@foreach($sortedParts)` (lines 1044–1063)
   - Circle diagram block (lines 738–753, 907–963): uses `position:absolute` children

2. `Modules/Hpc/app/Http/Controllers/HpcController.php` — Read:
   - `generateReportPdf()` method (~line 1208–1557): current PDF save + JSON response
   - `buildPdf()` and `minifyHtml()` helper methods
   - `generateSingleStudentPdf()` method (~line 1847–2163)
   - How `tenant_asset()` and `Storage::disk('public')` are used

3. `Modules/Hpc/resources/views/student-list/index.blade.php` — Read the JavaScript section. Find the `#generate-report` click handler and the AJAX success callback that currently opens `pdf_url` in a new tab.

---

## Problems Found

### Problem 1 — Emoji / Icon images are invisible in the generated PDF

**Root cause:** The Teacher Feedback block (lines 668–716) builds `$resourceEmojis` and `$selfAcItems` / `$peerAcItems` using `asset('hpc/icons/...')` and `asset('emoji/...')`:

```php
// WRONG — DomPDF cannot load HTTP URLs
'books' => '<img src="'.asset('hpc/icons/res_books.png').'"...',
'yes'   => ['icon'=>'<img src="'.asset('emoji/happy.png').'"...'],
```

DomPDF renders HTML from a PHP string — it does not have HTTP access. It can only load images from the **filesystem** using `file://` paths or **base64 data URIs**.

The circle images at the top of the file already do this correctly (lines 18–25):
```php
$circleOuterPath = public_path('hpc/images/circle_outer.jpg');
$circleOuterSrc  = file_exists($circleOuterPath)
    ? 'data:image/jpeg;base64,'.base64_encode(file_get_contents($circleOuterPath))
    : asset('hpc/images/circle_outer.jpg');
```

Apply **exactly the same pattern** to every icon and emoji in the feedback section.

---

### Problem 2 — Sections split / cut across pages

**Root cause A:** The `section_container` CSS (line 31) has no `page-break-inside:avoid`:
```php
'section_container' => 'margin-bottom:14px;padding:12px;border:2px solid #e36c0a;border-radius:15px;background:white;',
```

Add `page-break-inside:avoid;` to this style so DomPDF will not split a section box across pages.

**Root cause B:** The Teacher Feedback `<div style="{{ $css['section_container'] }}">` wrapper (line 727) is large and contains nested tables. It needs `page-break-inside:avoid` AND a `page-break-before:auto` so DomPDF can push it to the next page when there is not enough space.

**Root cause C:** `assess_section` and `comments_sec` styles already have `page-break-inside:avoid` (lines 125–127) but they are **inside** a parent that does not — so DomPDF ignores the inner `avoid` when the parent forces a break.

**Root cause D:** The `circle_container` (line 79) uses `position:relative` with absolutely-positioned children. DomPDF supports `position:relative/absolute` only within a single block that has explicit dimensions. When the parent has no fixed height, children overflow invisibly.

---

### Problem 3 — Teacher Feedback circle diagram alignment broken

**Root cause:** The circle diagram in the feedback section (lines 738–753) uses:
```php
'circle_container' => 'position:relative;width:230px;height:230px;...',
```
with children using `position:absolute`. DomPDF handles this only when the container has **both explicit width and height set in px**, and all child elements also have explicit px dimensions. The letter badges (line 750–752) use `position:absolute` with `top/left` percentage — DomPDF does not support `%` in positioned children.

Replace `%` values in `$letterPos` with **px values** calculated from the 230px container.

---

### Problem 4 — `generateReportPdf` returns individual URLs, not a ZIP

**Current behaviour** (lines 1551–1557):
```php
return response()->json([
    'success'  => true,
    'pdf_url'  => $generatedPdfs[0]['url'],
    'pdf_urls' => $generatedPdfs,
    ...
]);
```

Each student PDF is saved individually. There is no ZIP file created.

**Required behaviour:**
After all student PDFs are generated, create a single ZIP file containing all of them, save it to tenant storage, return the ZIP URL instead of individual PDF URLs.

---

### Problem 5 — Frontend opens PDF URL in new tab instead of downloading ZIP

The current AJAX success handler in `student-list/index.blade.php` opens `response.pdf_url` in a new tab. After the fix to Problem 4, the response will return `zip_url`. The frontend must trigger an automatic browser download of the ZIP file.

---

## Fixes — Detailed Instructions

### Fix 1 — Convert all emoji/icon `asset()` calls to base64 data URIs in first_pdf.blade.php

**File:** `Modules/Hpc/resources/views/hpc_form/pdf/first_pdf.blade.php`
**Where:** Inside the `@php` block at the top of the Teacher Feedback section (after line 647, before line 665)

Replace the `$resourceEmojis` array and the icon references inside `$selfAcItems` and `$peerAcItems` with a helper closure that converts local paths to base64 URIs:

```php
$pdfImg = function(string $relativePath, string $alt = '', string $size = '24px') {
    $path = public_path($relativePath);
    if (file_exists($path)) {
        $ext  = strtolower(pathinfo($path, PATHINFO_EXTENSION));
        $mime = $ext === 'png' ? 'image/png' : ($ext === 'jpg' || $ext === 'jpeg' ? 'image/jpeg' : 'image/png');
        $src  = 'data:'.$mime.';base64,'.base64_encode(file_get_contents($path));
    } else {
        $src = asset($relativePath); // fallback
    }
    return '<img src="'.$src.'" alt="'.$alt.'" style="width:'.$size.';height:'.$size.';display:block;margin:0 auto;">';
};
```

Then rebuild `$resourceEmojis`, `$selfAcItems`, and `$peerAcItems` using `$pdfImg(...)` instead of `asset(...)`. Example:

```php
$resourceEmojis = [
    'books'    => $pdfImg('hpc/icons/res_books.png',    'Books',    '24px'),
    'news'     => $pdfImg('hpc/icons/res_news.png',     'News',     '24px'),
    'toys'     => $pdfImg('hpc/icons/res_toys.png',     'Toys',     '24px'),
    'phone'    => $pdfImg('hpc/icons/res_phone.png',    'Phone',    '24px'),
    'internet' => $pdfImg('hpc/icons/res_internet.png', 'Internet', '24px'),
    'tv'       => $pdfImg('hpc/icons/res_tv.png',       'TV',       '24px'),
    'cwsn'     => $pdfImg('hpc/icons/res_cwsn.png',     'CWSN',     '24px'),
];
```

Apply same pattern for `emoji/happy.png`, `emoji/no.png`, `emoji/not_sure.png`, `hpc/icons/icon_friend.png`, `icon_teacher.png`, `icon_books.png`, `icon_pc.png`, `icon_none.png`, and `hpc/icons/res_other.png` (the one already using `$isPdf` check at line 849 — unify it with the same helper).

---

### Fix 2 — Add page-break-inside:avoid to section_container

**File:** `Modules/Hpc/resources/views/hpc_form/pdf/first_pdf.blade.php`
**Where:** `$css` array, line ~31

Change:
```php
'section_container' => 'margin-bottom:14px;padding:12px;border:2px solid #e36c0a;border-radius:15px;background:white;',
```
To:
```php
'section_container' => 'margin-bottom:14px;padding:12px;border:2px solid #e36c0a;border-radius:15px;background:white;page-break-inside:avoid;',
```

Also add `page-break-inside:avoid;` to these CSS keys:
- `assess_section` (line ~125) — already has it, verify it's present
- `comments_sec` (line ~127) — already has it, verify it's present
- `paper` (line ~76) — add it
- `goals_box` (line ~68) — add it

---

### Fix 3 — Fix circle diagram letter badge positions

**File:** `Modules/Hpc/resources/views/hpc_form/pdf/first_pdf.blade.php`
**Where:** `$letterPos` array (lines 136–147)

The container is 230×230px. Replace `%` values with `px` equivalents:

```php
$letterPos = [
    'feedback' => [
        'Stream'   => 'top:156px;left:78px;',   // 70% of 230, 34% of 230
        'Mountain' => 'top:92px;left:78px;',    // 40% of 230, 34% of 230
        'Sky'      => 'top:23px;left:78px;',    // 10% of 230, 34% of 230
    ],
    'summary' => [
        'Stream'   => 'top:136px;left:51px;',   // 59% of 230, 22% of 230
        'Mountain' => 'top:78px;left:90px;',    // 34% of 230, 39% of 230
        'Sky'      => 'top:21px;left:129px;',   // 9% of 230, 56% of 230
    ],
];
```

Also ensure `letter_badge` in `$css` (line ~89) has explicit `width` and `height` in px (not just line-height) so DomPDF renders it as a visible circle:

```php
'letter_badge' => 'position:absolute;width:26px;height:26px;color:white;border-radius:50%;text-align:center;line-height:26px;font-weight:bold;font-size:14px;z-index:10;background:#e36c0a;',
```

---

### Fix 4 — Fix `generateReportPdf` to create a ZIP file

**File:** `Modules/Hpc/app/Http/Controllers/HpcController.php`
**Where:** End of `generateReportPdf()` method, after the `foreach ($studentIds as $studentId)` loop (after line 1540)

**Step 1 — Keep existing per-student PDF generation unchanged.** The loop that generates and saves individual PDFs stays as-is.

**Step 2 — After the loop, create a ZIP file:**

```php
// After foreach loop ends and $generatedPdfs is populated:

$zipFilename  = 'HPC_Reports_' . now()->format('Ymd_His') . '.zip';
$zipDir       = storage_path('app/public/hpc-reports/zip');
$zipFullPath  = $zipDir . '/' . $zipFilename;

if (!is_dir($zipDir)) {
    mkdir($zipDir, 0775, true);
}

$zip = new \ZipArchive();
if ($zip->open($zipFullPath, \ZipArchive::CREATE | \ZipArchive::OVERWRITE) !== true) {
    return response()->json([
        'success' => false,
        'message' => 'Failed to create ZIP archive.',
    ], 500);
}

foreach ($generatedPdfs as $entry) {
    // Reconstruct filesystem path from the stored filename
    // $entry['filename'] must be stored in the loop (see Step 3 below)
    $pdfPath = storage_path('app/public/hpc-reports/pdf/' . $entry['filename']);
    if (file_exists($pdfPath)) {
        $zip->addFile($pdfPath, $entry['filename']);
    }
}
$zip->close();

$zipUrl = tenant_asset('storage/hpc-reports/zip/' . $zipFilename);
```

**Step 3 — Also store `filename` in `$generatedPdfs` array inside the loop** (after line 1522):

```php
$generatedPdfs[] = [
    'student_id' => $studentId,
    'filename'   => $filename,          // ADD THIS
    'url'        => $pdfUrl,
];
```

**Step 4 — Update the JSON response** to return `zip_url`:

```php
return response()->json([
    'success'   => true,
    'zip_url'   => $zipUrl,
    'pdf_urls'  => $generatedPdfs,
    'message'   => count($generatedPdfs) . ' report(s) generated. Download ZIP below.',
    'warnings'  => $errors,
]);
```

---

### Fix 5 — Frontend: download ZIP automatically on AJAX success

**File:** `Modules/Hpc/resources/views/student-list/index.blade.php`
**Where:** The `#generate-report` click handler AJAX success callback

Find the current success handler that does something like:
```js
window.open(response.pdf_url, '_blank');
// or
window.location.href = response.pdf_url;
```

Replace it with:
```js
if (response.success && response.zip_url) {
    // Trigger automatic ZIP download
    var link = document.createElement('a');
    link.href = response.zip_url;
    link.download = '';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}
```

Do NOT remove the existing error handling or loading state logic — only replace the success branch that handles the URL.

---

## Rules

1. Do NOT rewrite or restructure `first_pdf.blade.php` from scratch. Make targeted edits only.
2. Do NOT change the `$css` key names — other parts of the template reference them.
3. Do NOT change the `generateSingleStudentPdf()` method — it is separate and working.
4. Do NOT use `ZipArchive` without checking `extension_loaded('zip')` — if not available, return a helpful error.
5. Do NOT use `Storage::disk('public')->put()` for the ZIP — use direct filesystem (`mkdir` + `ZipArchive::addFile`) so `addFile()` can access real paths.
6. Tenancy path: always use `tenant_asset('storage/...')` for public URLs, `storage_path('app/public/...')` for filesystem paths.
7. Do NOT add `page-break-before:always` to `section_container` — that would force every section to a new page. Use only `page-break-inside:avoid`.
8. Do NOT touch any of the `generateReportPdf` logic before line 1519 (`$pdf = $this->buildPdf(...)`).

---

## Verification

After all fixes:

### Icons & Emojis
- Generate a PDF for a student with Teacher Feedback data saved.
- The happy/no/not_sure emoji images must be visible in the PDF (not blank squares).
- The resource icons (books, news, toys, etc.) must appear in the Home Resources row.

### Page Breaks
- Sections must not split mid-box. If a `section_container` does not fit on the current page, DomPDF must move the entire box to the next page.
- The Teacher Feedback page (pages 4, 6, 8, 10, 12, 14) must render as one unbroken block per page.

### Circle Diagram
- The letter badges (A, S, C) must appear inside the circle at their correct positions.
- The three concentric circle images must render with correct overlap.

### ZIP Download (multiple students)
- Select 2+ students on the student list, click Generate PDF.
- The AJAX response must contain `zip_url`.
- Browser must automatically start downloading the ZIP file.
- ZIP must contain one PDF per student, named `HPC_student_{id}_{timestamp}.pdf`.

### Single Student PDF
- `generateSingleStudentPdf()` must be unaffected — still downloads a single PDF directly.

---

## Summary of Changes

| # | File | Change | Location |
|---|------|--------|----------|
| 1 | `first_pdf.blade.php` | Add `$pdfImg` helper closure; replace all `asset()` icon/emoji calls with base64 data URIs | Teacher Feedback `@php` block (~line 648) |
| 2 | `first_pdf.blade.php` | Add `page-break-inside:avoid` to `section_container`, `paper`, `goals_box` CSS keys | `$css` array (~lines 31, 68, 76) |
| 3 | `first_pdf.blade.php` | Replace `%` with `px` in `$letterPos`; fix `letter_badge` to have explicit background color | `$letterPos` array (lines 136–147) + `$css['letter_badge']` (~line 89) |
| 4 | `HpcController.php` | Add `filename` key to `$generatedPdfs` entries; add ZIP creation after loop; update JSON response to return `zip_url` | `generateReportPdf()` method (~lines 1522, 1540–1557) |
| 5 | `index.blade.php` | Replace `window.open(pdf_url)` with `<a download>` trigger using `zip_url` | AJAX success callback in `#generate-report` handler |