# HPC: Fix second_pdf.blade.php — DomPDF Rendering Issues

**Date:** 2026-03-13
**Type:** Bug Fix
**Module:** HPC (Holistic Progress Card)
**Severity:** High — PDF output broken; blank pages; emojis invisible; sections cut mid-page
**File to modify:** `Modules/Hpc/resources/views/hpc_form/pdf/second_pdf.blade.php`

---

## Task

Fix all DomPDF rendering issues in `second_pdf.blade.php` so the generated PDF matches the browser view.

The file renders correctly in the browser and via browser Print → Save as PDF. But when the HPC controller's `generateReportPdf()` or `generateSingleStudentPdf()` functions use DomPDF to generate the PDF, the output is broken.

---

## Pre-Read (mandatory before coding)

Read these files **in full** before making any changes:

1. `Modules/Hpc/resources/views/hpc_form/pdf/second_pdf.blade.php` — Full file (2,858 lines).
   Focus on:
   - `$css` array (lines 16–69): `section_container` (line 20), `page` (line 19)
   - Page wrapper div (line 245): `<div style="min-height:267mm;display:block;">`
   - Page 2 `@php` block (~line 382): `$emojiUrls` — uses `asset('emoji/...')`
   - Page 3 `@php` block (~line 587): `$p3EmojiUrls` — uses `asset('emoji/...')`
   - Page 4 `@php` block (~line 664): `$p4EmojiUrls` — uses `asset('emoji/...')`
   - Page 5 `@php` block (~line 768): `$p5EmojiUrls` — uses `asset('emoji/...')`
   - Page 6 `@php` block (~line 876): `$p6EmojiUrls` + `$resourceIcons6` (Unicode emoji chars `📚📰`)
   - Wavy box decorations (~lines 693, 703, 797, 807): `position:absolute`, `calc()`, `z-index:-1`
   - Selected emoji checkmark overlay (~lines 624–636, 730–741, 834–845): `position:relative/absolute`
   - Page break closing logic (lines 2847–2852)

2. `Modules/Hpc/resources/views/hpc_form/pdf/first_pdf.blade.php` — Read lines 1–30 only.
   Note how circle images are loaded using `public_path()` + `base64_encode()` (lines 18–25).
   This is the **correct DomPDF image pattern** — apply the same to second_pdf.

---

## Root Causes Found

### Bug 1 — All emoji images use `asset()` HTTP URLs → invisible in DomPDF

DomPDF renders HTML server-side. It **cannot make HTTP requests** to load images. Every `asset('emoji/...')` call produces a URL like `https://school.test/emoji/happy.png` which DomPDF cannot fetch.

Affected arrays (all using `asset()`):
- `$emojiUrls` on page 2 (~line 382–393)
- `$p3EmojiUrls` on page 3 (~line 587–591)
- `$p4EmojiUrls` on page 4 (~line 664–669)
- `$p5EmojiUrls` on page 5 (~line 768–773)
- `$p6EmojiUrls` on page 6 (~line 876–881)
- Any similar arrays on pages 7–30

**Result:** All emoji images render as blank/broken in the generated PDF.

---

### Bug 2 — Unicode emoji characters are invisible (DejaVu Sans can't render them)

On page 6, resource icons use Unicode emoji chars directly in PHP:

```php
$resourceIcons6 = [
    'resources_books'     => '📚',   // DejaVu Sans → empty box
    'resources_newspaper' => '📰',   // DejaVu Sans → empty box
    'resources_toys'      => '🧩',   // DejaVu Sans → empty box
    ...
];
```

DomPDF uses **DejaVu Sans** font. This font does not contain emoji Unicode codepoints. These characters render as empty rectangles.

---

### Bug 3 — `min-height:267mm` wrapper causes blank pages

Every `$part` iteration is wrapped in (line 245):

```html
<div style="min-height:267mm;display:block;">
```

In a browser, `min-height` expands the div if content is taller, or pads it to 267mm if shorter.

In DomPDF, this forces every page wrapper to take up 267mm of vertical space **even if the content is 80mm**. The remaining 187mm of padding overflows into the next physical page, producing a **blank page** between every content section.

---

### Bug 4 — `position:absolute` + `calc()` + `z-index:-1` in wavy box decoration

Pages 4 and 5 name fields use an absolutely-positioned decorative wave:

```html
<div style="position:absolute; left:-3px; bottom:-15px;
            width:calc(100% + 6px); height:25px;
            z-index:-1; border-radius:0 0 50% 50% / 0 0 100% 100%;">
</div>
```

DomPDF does not support `calc()`, negative `z-index`, or the double-slash `border-radius` shorthand. This element renders as a misplaced block that breaks surrounding layout.

---

### Bug 5 — `position:absolute` checkmark overlay misaligned

Pages 3–6+ use an absolutely-positioned ✓ badge over the selected emoji:

```html
<div style="position:relative; display:inline-block;">
    <div style="width:50px;height:50px;..."><img ...></div>
    <div style="position:absolute; top:-5px; right:-5px; ...">✓</div>
</div>
```

DomPDF only supports `position:absolute` inside containers with **explicit px dimensions**. `display:inline-block` without explicit `width/height` causes the child to be misplaced or invisible.

---

### Bug 6 — `section_container` missing `page-break-inside:avoid`

```php
// Line 20 — missing page-break-inside:avoid
'section_container' => 'margin-bottom:14px;padding:12px;border:2px solid #e36c0a;border-radius:15px;background:white;',
```

Without this, DomPDF splits section boxes across pages — half the section on one page, half on the next.

---

### Bug 7 — Unsupported CSS properties used throughout

| CSS property | Used where | DomPDF behaviour |
|---|---|---|
| `object-fit:contain` | All emoji `<img>` tags | Ignored — image uses width/height only |
| `box-shadow:...` | Name field containers pages 4–5 | Ignored |
| `transition:all 0.3s ease` | Resource checkbox page 6 | Ignored |
| `opacity:0.6` | Non-selected emoji divs | Limited — may not render |
| `calc(100% + 6px)` | Wavy decoration pages 4–5 | Not supported — layout broken |
| `border-radius:0 0 50% 50% / 0 0 100% 100%` | Wavy decoration | Complex shorthand not supported |

---

## Fixes — Detailed Instructions

### Fix 1 — Add `$pdfImg` helper + `$emojiImgMap` to top-level `@php` block

**Where:** Inside the top-level `@php` block, immediately after the `$css` array definition (after line 69)

Add this **once**:

```php
/* DomPDF image helper: converts a public/ path to inline base64 data URI */
$pdfImg = function(string $relativePath, string $alt = '', string $w = '42px', string $h = '42px') {
    $path = public_path($relativePath);
    if (file_exists($path)) {
        $ext  = strtolower(pathinfo($path, PATHINFO_EXTENSION));
        $mime = match($ext) { 'jpg','jpeg' => 'image/jpeg', 'gif' => 'image/gif', default => 'image/png' };
        $src  = 'data:' . $mime . ';base64,' . base64_encode(file_get_contents($path));
    } else {
        $src = asset($relativePath); // fallback for non-PDF context
    }
    return '<img src="' . $src . '" alt="' . htmlspecialchars($alt) . '" style="width:' . $w . ';height:' . $h . ';display:block;margin:0 auto;" />';
};

/* Pre-built emoji image HTML — reused on all pages, base64 encoded once */
$emojiImgMap = [
    'yes'       => $pdfImg('emoji/happy.png',     'Yes',       '42px', '42px'),
    'sometimes' => $pdfImg('emoji/sometimes.png', 'Sometimes', '42px', '42px'),
    'no'        => $pdfImg('emoji/no.png',        'No',        '42px', '42px'),
    'unsure'    => $pdfImg('emoji/not_sure.png',  'Not sure',  '42px', '42px'),
];
```

---

### Fix 2 — Remove all per-page `asset()` emoji URL arrays

In every page `@php` block that defines `$emojiUrls`, `$p3EmojiUrls`, `$p4EmojiUrls`, `$p5EmojiUrls`, `$p6EmojiUrls` (and any similar on pages 7–30):

**Remove** the entire array definition. Replace any HTML references like:

```php
// OLD — remove these
$emojiUrl = $p3EmojiUrls[$optVal] ?? $p3EmojiUrls['unsure'];
// and in HTML:
<img src="{{ $emojiUrl }}" alt="{{ $optLabel }}" style="width:100%;height:100%;object-fit:contain;">
```

With:

```php
// NEW — use pre-built base64 HTML from top-level $emojiImgMap
{!! $emojiImgMap[$optVal] ?? $emojiImgMap['unsure'] !!}
```

Note: change `{{ }}` to `{!! !!}` because `$emojiImgMap` values are HTML strings.

Apply to every page with emoji option selectors. Search the file for `asset('emoji/` to find all occurrences.

---

### Fix 3 — Replace Unicode emoji resource icons with image-based HTML

**Where:** Page 6 `@php` block, `$resourceIcons6` array (~line 884)

Replace:
```php
$resourceIcons6 = [
    'resources_books'     => '📚',
    'resources_newspaper' => '📰',
    'resources_toys'      => '🧩',
    'resources_computer'  => '💻',
    'resources_internet'  => '🌐',
    'resources_broadcast' => '📻',
    'resources_worksheet' => '📝',
];
```

With:
```php
$resourceIcons6 = [
    'resources_books'     => $pdfImg('hpc/icons/res_books.png',    'Books',     '28px', '28px'),
    'resources_newspaper' => $pdfImg('hpc/icons/res_news.png',     'News',      '28px', '28px'),
    'resources_toys'      => $pdfImg('hpc/icons/res_toys.png',     'Toys',      '28px', '28px'),
    'resources_computer'  => $pdfImg('hpc/icons/res_pc.png',       'Computer',  '28px', '28px'),
    'resources_internet'  => $pdfImg('hpc/icons/res_internet.png', 'Internet',  '28px', '28px'),
    'resources_broadcast' => $pdfImg('hpc/icons/res_radio.png',    'Radio',     '28px', '28px'),
    'resources_worksheet' => $pdfImg('hpc/icons/res_books.png',    'Worksheet', '28px', '28px'),
];
```

In the HTML that renders `$resIcon`, change `{{ $resIcon }}` to `{!! $resIcon !!}`.

---

### Fix 4 — Remove `min-height:267mm` from the page wrapper

**Where:** Line 245

Change:
```html
<div style="min-height:267mm;display:block;">
```
To:
```html
<div style="display:block;">
```

Update the closing comment on line 2847:
```html
</div>{{-- end page wrapper --}}
```

---

### Fix 5 — Remove wavy box `position:absolute` decoration (pages 4 and 5)

**Where:** Name field containers on pages 4 and 5 (~lines 693, 703, 797, 807)

Each name box has this inner decorative div — **delete it entirely**:
```html
<!-- DELETE this entire div on each name box -->
<div style="position: absolute; left: -3px; bottom: -15px; width: calc(100% + 6px); height: 25px; background: #d9d2e9; border: 3px solid #3f375b; border-top: none; border-radius: 0 0 50% 50% / 0 0 100% 100%; z-index: -1;"></div>
```

Also on the outer container div, remove `position: relative` and `box-shadow`:

Change:
```html
<div style="background: #d9d2e9; border: 3px solid #3f375b; border-radius: 12px; padding: 20px; position: relative; box-shadow: 0 4px 10px rgba(0,0,0,0.05);">
```
To:
```html
<div style="background: #d9d2e9; border: 3px solid #3f375b; border-radius: 12px; padding: 20px;">
```

Apply the same to both name boxes on page 4 (purple and green) and page 5.

---

### Fix 6 — Replace `position:absolute` checkmark overlay with inline table layout

**Where:** Pages 3, 4, 5, 6, and all subsequent pages that use the emoji option selector

**Current broken pattern:**
```html
<td style="text-align:center; vertical-align:middle; width:{{ (100/$optionCount) }}%;">
    <div style="position:relative; display:inline-block;">
        @if($isSelected)
            <div style="width:50px;height:50px;border:3px solid #e36c0a;border-radius:50%;overflow:hidden;background:#fff3e6;box-shadow:0 2px 5px rgba(227,108,10,0.3);">
                <img src="{{ $emojiUrl }}" alt="{{ $optLabel }}" style="width:100%;height:100%;object-fit:contain;">
            </div>
            <div style="position:absolute;top:-5px;right:-5px;width:20px;height:20px;background:#e36c0a;border-radius:50%;text-align:center;line-height:18px;color:white;font-size:12px;font-weight:bold;border:2px solid white;">✓</div>
        @else
            <div style="width:50px;height:50px;border:2px solid #ccc;border-radius:50%;overflow:hidden;background:#f9f9f9;opacity:0.6;">
                <img src="{{ $emojiUrl }}" alt="{{ $optLabel }}" style="width:100%;height:100%;object-fit:contain;">
            </div>
        @endif
    </div>
    <div style="font-size:10px;color:#666;margin-top:5px;font-weight:{{ $isSelected?'bold':'normal' }};">{{ $optLabel }}</div>
</td>
```

**Replace with DomPDF-safe version:**
```html
<td style="text-align:center;vertical-align:middle;width:{{ (100/$optionCount) }}%;padding:4px;">
    <div style="width:52px;height:52px;border:{{ $isSelected?'3px solid #e36c0a':'2px solid #ccc' }};border-radius:50%;overflow:hidden;background:{{ $isSelected?'#fff3e6':'#f9f9f9' }};margin:0 auto;">
        {!! $emojiImgMap[$optVal] ?? $emojiImgMap['unsure'] !!}
    </div>
    <div style="font-size:10px;color:{{ $isSelected?'#e36c0a':'#666' }};margin-top:3px;font-weight:{{ $isSelected?'bold':'normal' }};text-align:center;">
        {{ $optLabel }}{{ $isSelected?' ✓':'' }}
    </div>
</td>
```

The ✓ is now inline after the label text — no absolute positioning needed.

---

### Fix 7 — Add `page-break-inside:avoid` to `section_container` CSS

**Where:** `$css` array line 20

Change:
```php
'section_container' => 'margin-bottom:14px;padding:12px;border:2px solid #e36c0a;border-radius:15px;background:white;',
```
To:
```php
'section_container' => 'margin-bottom:14px;padding:12px;border:2px solid #e36c0a;border-radius:15px;background:white;page-break-inside:avoid;',
```

---

### Fix 8 — Remove unsupported CSS properties throughout entire file

Do a search-and-remove pass on the full file:

| Search for | Action |
|---|---|
| `object-fit: contain` | Remove this property from all `<img>` style attributes |
| `box-shadow:` | Remove the entire `box-shadow` property wherever found |
| `transition:` | Remove the entire `transition` property wherever found |
| `opacity: 0.6` | Remove — the border color difference already shows selection state |
| `letter-spacing:` | Remove |
| `calc(100% + 6px)` | Already removed in Fix 5, verify none remain |

---

## Rules

1. Do NOT rewrite the file from scratch. Make targeted edits only.
2. Do NOT change the `$css` key names — they are referenced throughout all 30 pages.
3. The `$pdfImg` helper and `$emojiImgMap` must be defined **once** in the top-level `@php` block — not repeated per page.
4. After replacing emoji image references, always use `{!! !!}` not `{{ }}` for the image HTML output.
5. Do NOT touch any other controller files or migration files.
6. Do NOT touch `generateReportPdf()` or `generateSingleStudentPdf()` in the controller.
7. Total page count must remain 30 after fixes — no pages added or removed.
8. Do NOT add `page-break-before:always` to individual sections — only `page-break-inside:avoid`.

---

## Verification

After all fixes:

**Test 1 — No blank pages**
Generate PDF for any student with Template 2. Count pages in generated PDF. Must equal the number of active `hpc_template_parts` for Template 2. No blank pages between content pages.

**Test 2 — Emoji images visible**
Generate PDF for a student with saved answers on pages 3–6. All emoji face images (happy, no, sometimes, not_sure) must be visible in the PDF — not blank boxes.

**Test 3 — Sections not split mid-page**
Each orange-bordered section box must appear complete on one page. If a box does not fit on the current page, DomPDF must push the entire box to the next page.

**Test 4 — Name boxes on pages 4 and 5 render correctly**
The purple and green name field containers must display cleanly. No broken/misplaced decorative elements below them.

**Test 5 — Selected option highlighted correctly**
For a student with saved answers, the selected emoji option must have orange border and ✓ in label. Non-selected options have grey border.

---

## Summary of Changes

| # | Location | Change |
|---|---|---|
| 1 | Top-level `@php` (after `$css`) | Add `$pdfImg` helper closure and `$emojiImgMap` pre-built base64 image strings |
| 2 | Pages 2–30 all `$emojiUrls` / `$pNEmojiUrls` arrays | Remove all `asset('emoji/...')` arrays; replace `<img src="{{ $emojiUrl }}">` with `{!! $emojiImgMap[$optVal] !!}` |
| 3 | Page 6 `$resourceIcons6` | Replace Unicode emoji chars with `$pdfImg()` image HTML |
| 4 | Page 6 resource icon render | Change `{{ $resIcon }}` to `{!! $resIcon !!}` |
| 5 | Line 245 | Remove `min-height:267mm` from page wrapper div |
| 6 | Pages 4 and 5 name boxes | Delete inner wavy `position:absolute` decoration divs; remove `position:relative` and `box-shadow` from outer containers |
| 7 | Pages 3–6+ emoji option selectors | Replace `position:relative/absolute` checkmark overlay with inline border + label ✓ indicator |
| 8 | `$css` array line 20 | Add `page-break-inside:avoid` to `section_container` |
| 9 | Entire file | Remove `object-fit:contain`, `box-shadow`, `transition`, `opacity:0.6`, `letter-spacing` |