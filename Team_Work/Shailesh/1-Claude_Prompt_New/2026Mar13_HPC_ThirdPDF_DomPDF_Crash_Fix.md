# HPC: Fix third_pdf.blade.php — DomPDF Crash + Layout Issues

**Date:** 2026-03-13
**Type:** Bug Fix
**Module:** HPC (Holistic Progress Card)
**Severity:** Critical — PDF crashes on generation; layout broken throughout
**File to modify:** `Modules/Hpc/resources/views/hpc_form/pdf/third_pdf.blade.php`

---

## Task

Fix all bugs in `third_pdf.blade.php` so that:
1. The DomPDF crash is resolved and PDF generates successfully
2. The generated PDF design matches the Blade file browser view
3. No page-break cutting issues
4. No alignment issues
5. Emoji images display correctly

---

## Pre-Read (mandatory before coding)

Read these files **in full** before making any changes:

1. `Modules/Hpc/resources/views/hpc_form/pdf/third_pdf.blade.php` — Full file (2,105 lines).
   Focus on:
   - `$css` array (lines 16–69): `section_container` (line 20), note it is missing `page-break-inside:avoid`
   - Emoji URL arrays using `asset()`: lines 560–564, 1015, 1220
   - All `display:flex` usages: lines 595, 669, 702, 707, 843, 846, 866, 869, 889, 892, 901, 914, 916, 926, 1585, 1615
   - Activity + Assessment side-by-side div (line 914): `display:flex; gap:15px` containing two `flex:1` children
   - Table inside flex child (line 942): `<table width="100%">` inside a `flex:1` div — this is the **crash location**
   - HOME_RESOURCES flex grid (line 595): `flex:1 1 calc(50% - 10px)`
   - SUPPORT_WITH flex grid (line 702): `display:flex; flex-wrap:wrap; gap:10px`
   - CURRICULAR GOALS flex grid (line 843): `display:flex; flex-wrap:wrap; gap:15px`
   - COMPETENCIES flex grid (line 866): `display:flex; flex-wrap:wrap; gap:15px`
   - APPROACH flex grid (line 889): `display:flex; flex-wrap:wrap; gap:15px`

2. `Modules/Hpc/resources/views/hpc_form/pdf/first_pdf.blade.php` — Read lines 18–30 only.
   This shows the correct `public_path()` + `base64_encode()` image loading pattern for DomPDF.

---

## Root Causes Found

### Bug 1 — CRASH: "Min/max width is undefined for table rows"

**Error:**
```
[2026-03-13 17:13:41] local.ERROR: HPC generateSingleStudentPdf error:
Min/max width is undefined for table rows
```

**Root cause:** On pages 5, 9, 13, 17, 21, 25, 29, 33, 37, 41 (Activity Tab pages), the HTML structure is:

```html
<!-- Line 914: flex container — DomPDF DOES NOT SUPPORT display:flex -->
<div style="margin-bottom:20px; display:flex; gap:15px;">
    <div style="flex:1; border:1px solid #e36c0a; ...">     <!-- flex:1 child — width UNKNOWN to DomPDF -->
        <div style="padding:12px; min-height:120px;">
            {{ $savedValues[$actItem['field_id']] }}
        </div>
    </div>
    <div style="flex:1; border:1px solid #e36c0a; ...">     <!-- flex:1 child — width UNKNOWN to DomPDF -->
        ...
    </div>
</div>

<!-- Line 942: table with width="100%" inside the flex child above -->
<table width="100%" style="border-collapse:collapse; border:2px solid #e36c0a;">
```

DomPDF does not implement `display:flex`. It treats flex containers as regular blocks but **cannot resolve the width of `flex:1` children**. When a `<table width="100%">` appears inside a `flex:1` child whose width is undefined, DomPDF crashes with `Min/max width is undefined for table rows`.

This is the **primary crash**. Every Activity Tab page (10 pages) triggers this crash.

---

### Bug 2 — `display:flex` used extensively — DomPDF does not support it

`display:flex` appears **15 times** in the file. DomPDF completely ignores flex layout:

| Line | Location | Used for |
|---|---|---|
| 595 | HOME_RESOURCES | Resource checkbox grid (2-per-row) |
| 669 | SELF_EVAL emoji circle | Centering emoji image |
| 702 | SUPPORT_WITH | Checkbox items grid (2-per-row) |
| 707 | SUPPORT_WITH item | Icon + label side-by-side |
| 843 | CURRICULAR GOALS | Checkbox items wrap |
| 846 | CURRICULAR GOALS label | Checkbox + text side-by-side |
| 866 | COMPETENCIES | Checkbox items wrap |
| 869 | COMPETENCIES label | Checkbox + text side-by-side |
| 889 | APPROACH | Checkbox items wrap |
| 892 | APPROACH label | Checkbox + text side-by-side |
| 901 | APPROACH other text | Icon + input side-by-side |
| 914 | Activity + Assessment | Two boxes side-by-side — **CRASH source** |
| 916 | Activity box | `flex:1` child |
| 926 | Assessment box | `flex:1` child |
| 1585, 1615 | Reflection pages | Items with icon + text |

All of these must be converted to `<table>`-based layouts.

---

### Bug 3 — `gap`, `flex-wrap`, `align-items`, `calc()` — all unsupported

These CSS properties are used alongside `display:flex` and are also not supported by DomPDF:

- `gap:10px`, `gap:15px`, `gap:8px` — DomPDF ignores this; elements bunch together or collapse
- `flex-wrap:wrap` — ignored by DomPDF; items overflow
- `flex:1 1 calc(50% - 10px)` — `calc()` is not supported; `flex` is not supported
- `align-items:center` — not supported
- `min-width:150px` on flex children — ignored when flex is not applied

---

### Bug 4 — Emoji images use `asset()` HTTP URLs → invisible in DomPDF

DomPDF cannot make HTTP requests to load images.

Three locations:

**Location A — Pages 5,9,13,… (Activity Tab — SELF_EVAL section) (~line 560):**
```php
$emojiUrls = [
    'yes'       => asset('emoji/happy.png'),       // WRONG
    'sometimes' => asset('emoji/sometimes.png'),   // WRONG
    'no'        => asset('emoji/no.png'),           // WRONG
    'not_sure'  => asset('emoji/not_sure.png'),     // WRONG
    'unsure'    => asset('emoji/not_sure.png'),     // WRONG
];
```

**Location B — Self-Reflection pages (pages 6,10,14,…) (~line 1015):**
```php
$srEmojiUrls = ['yes'=>asset('emoji/happy.png'),'sometimes'=>asset('emoji/sometimes.png'),...];
```

**Location C — Peer Feedback pages (pages 7,11,15,…) (~line 1220):**
```php
$pfEmojiUrls = ['yes'=>asset('emoji/happy.png'),'sometimes'=>asset('emoji/sometimes.png'),...];
```

---

### Bug 5 — `opacity` and `object-fit` not fully supported

Line 669: `opacity:0.7` inside a div containing emoji — DomPDF has limited opacity support.
Line 670: `object-fit:cover` on emoji `<img>` — DomPDF ignores `object-fit`.
Line 1102, 1353: `opacity:0.7` on `<img>` elements for non-selected emoji.

---

### Bug 6 — `section_container` missing `page-break-inside:avoid`

```php
// Line 20 — missing page-break-inside:avoid
'section_container' => 'margin-bottom:14px;padding:12px;border:2px solid #e36c0a;border-radius:15px;background:white;',
```

Without this, DomPDF splits every section box mid-page.

---

### Bug 7 — `box-shadow` and `line-height:1.5` — limited/no support

Line 491: `box-shadow:0 4px 8px rgba(227,108,10,0.1)` — DomPDF ignores this.
Lines 920, 930, etc.: `line-height:1.5` — DomPDF may not handle unitless line-height correctly.

---

## Fixes — Detailed Instructions

### Fix 1 — Add `$pdfImg` helper + `$emojiImgMap` to top-level `@php` block

**Where:** Inside the top-level `@php` block, immediately after the `$css` array definition (after line 69)

Add **once**:

```php
/* DomPDF image helper: converts public/ path to inline base64 data URI */
$pdfImg = function(string $relativePath, string $alt = '', string $w = '42px', string $h = '42px') {
    $path = public_path($relativePath);
    if (file_exists($path)) {
        $ext  = strtolower(pathinfo($path, PATHINFO_EXTENSION));
        $mime = match($ext) { 'jpg','jpeg' => 'image/jpeg', 'gif' => 'image/gif', default => 'image/png' };
        $src  = 'data:' . $mime . ';base64,' . base64_encode(file_get_contents($path));
    } else {
        $src = asset($relativePath);
    }
    return '<img src="' . $src . '" alt="' . htmlspecialchars($alt) . '" style="width:' . $w . ';height:' . $h . ';display:block;margin:0 auto;" />';
};

/* Pre-built base64 emoji HTML — reused across all pages */
$emojiImgMap = [
    'yes'       => $pdfImg('emoji/happy.png',     'Yes',      '40px', '40px'),
    'sometimes' => $pdfImg('emoji/sometimes.png', 'Sometimes','40px', '40px'),
    'no'        => $pdfImg('emoji/no.png',        'No',       '40px', '40px'),
    'not_sure'  => $pdfImg('emoji/not_sure.png',  'Not sure', '40px', '40px'),
    'unsure'    => $pdfImg('emoji/not_sure.png',  'Not sure', '40px', '40px'),
];
```

---

### Fix 2 — Remove all three per-page `asset()` emoji arrays

In each page block that defines `$emojiUrls`, `$srEmojiUrls`, `$pfEmojiUrls`:

**Remove** the entire array definition.

Replace every HTML reference like:
```php
// OLD
$eUrl4 = $emojiUrls[$optVal4] ?? $emojiUrls['not_sure'];
// in HTML:
<img src="{{ $eUrl4 }}" style="width:45px;height:45px;object-fit:cover;" alt="{{ $optVal4 }}">
```

With:
```php
// NEW — use pre-built base64 HTML
{!! $emojiImgMap[$optVal4] ?? $emojiImgMap['not_sure'] !!}
```

Apply to all three locations (lines 560–564, 1015, 1220) and all downstream HTML references.
Always use `{!! !!}` not `{{ }}` since values are HTML strings.

---

### Fix 3 — CRITICAL: Replace Activity + Assessment `display:flex` with `<table>` (fixes the crash)

**Where:** Line 914 — the Activity/Assessment side-by-side block

**Current (causes DomPDF crash):**
```html
<div style="margin-bottom:20px; display:flex; gap:15px;">
    <div style="flex:1; border:1px solid #e36c0a; border-radius:10px; overflow:hidden;">
        <div style="background:#e36c0a; color:white; padding:8px 12px; font-weight:bold; font-size:14px;">
            {{ $actItem['label'] ?? 'Activity' }}
        </div>
        <div style="padding:12px; background:white; min-height:120px; font-size:13px; line-height:1.5;">
            {{ $savedValues[$actItem['field_id'] ?? ''] ?? '---' }}
        </div>
    </div>
    <div style="flex:1; border:1px solid #e36c0a; border-radius:10px; overflow:hidden;">
        <div style="background:#e36c0a; color:white; padding:8px 12px; font-weight:bold; font-size:14px;">
            {{ $assessItem['label'] ?? 'Assessment Question' }}
        </div>
        <div style="padding:12px; background:white; min-height:120px; font-size:13px; line-height:1.5;">
            {{ $savedValues[$assessItem['field_id'] ?? ''] ?? '---' }}
        </div>
    </div>
</div>
```

**Replace with (DomPDF-safe table layout):**
```html
<table width="100%" cellspacing="8" cellpadding="0" style="margin-bottom:20px;border-collapse:separate;">
    <tr>
        <td width="50%" style="vertical-align:top;border:1px solid #e36c0a;border-radius:10px;overflow:hidden;padding:0;">
            <div style="background:#e36c0a;color:white;padding:8px 12px;font-weight:bold;font-size:14px;">
                {{ $actItem['label'] ?? 'Activity' }}
            </div>
            <div style="padding:12px;background:white;font-size:13px;">
                {{ $savedValues[$actItem['field_id'] ?? ''] ?? '---' }}
            </div>
        </td>
        <td width="50%" style="vertical-align:top;border:1px solid #e36c0a;border-radius:10px;overflow:hidden;padding:0;">
            <div style="background:#e36c0a;color:white;padding:8px 12px;font-weight:bold;font-size:14px;">
                {{ $assessItem['label'] ?? 'Assessment Question' }}
            </div>
            <div style="padding:12px;background:white;font-size:13px;">
                {{ $savedValues[$assessItem['field_id'] ?? ''] ?? '---' }}
            </div>
        </td>
    </tr>
</table>
```

This removes all flex/flex:1/gap and replaces with a standard two-column table that DomPDF can render. The Assessment Rubric table that follows (line 942) will now have a known container width and will not crash.

---

### Fix 4 — Replace HOME_RESOURCES `display:flex` grid with `<table>`

**Where:** Line 595 — HOME_RESOURCES section `display:flex; flex-wrap:wrap; gap:10px`

**Replace:**
```html
<div style="display:flex; flex-wrap:wrap; gap:10px; margin-bottom:15px;">
    @foreach($boolItems4 as $item)
        <div style="flex:1 1 calc(50% - 10px); min-width:150px; ...">
            ...
        </div>
    @endforeach
</div>
```

**With a table-based 2-column grid:**
```html
<table width="100%" cellspacing="6" cellpadding="0" style="margin-bottom:15px;">
    @foreach($boolItems4->chunk(2) as $rowChunk)
    <tr>
        @foreach($rowChunk as $item)
            @php
                $sv4r = $savedValues[$item['field_id']]??null;
                $is4r = !empty($sv4r) && in_array(strtolower(trim((string)$sv4r)),['1','on','yes','true','y'],true);
            @endphp
            <td width="50%" style="vertical-align:top;padding:4px;">
                <div style="border:2px solid {{ $is4r?'#e36c0a':'#e6a15c' }};border-radius:10px;padding:12px;background:{{ $is4r?'#fff3e6':'#fff8f0' }};text-align:center;">
                    <div style="width:24px;height:24px;border:2px solid {{ $is4r?'#e36c0a':'#ccc' }};border-radius:4px;margin:0 auto 8px;text-align:center;line-height:20px;font-size:14px;font-weight:bold;background:{{ $is4r?'#fff3e6':'white' }};color:{{ $is4r?'#e36c0a':'transparent' }};">&#10003;</div>
                    <div style="font-size:12px;color:#333;font-weight:{{ $is4r?'600':'normal' }};">{{ $item['label'] }}</div>
                    <div style="font-size:10px;color:{{ $is4r?'#e36c0a':'#999' }};margin-top:5px;">{{ $is4r?'Available':'Not Available' }}</div>
                </div>
            </td>
        @endforeach
        {{-- Fill empty cell if odd number of items --}}
        @if($rowChunk->count() < 2)<td width="50%"></td>@endif
    </tr>
    @endforeach
</table>
```

Note: `$boolItems4` must be a Laravel Collection for `->chunk(2)` to work. If it's a plain array, use `array_chunk($boolItems4, 2)` and adapt the foreach accordingly.

---

### Fix 5 — Replace SUPPORT_WITH `display:flex` grid with `<table>`

**Where:** Line 702 — SUPPORT_WITH section

**Replace** the outer `display:flex; flex-wrap:wrap; gap:10px` div with a 2-column table identical in structure to Fix 4. Each item's inner layout (checkbox icon + label side-by-side) should use a small inline table:

```html
<table width="100%" cellspacing="6" cellpadding="0">
    @foreach(array_chunk($boolItems4, 2) as $rowChunk)
    <tr>
        @foreach($rowChunk as $si)
            @php $sch4 = !empty($savedValues[$si['field_id']]) && in_array(strtolower(trim((string)$savedValues[$si['field_id']])),['1','on','yes','true'],true); @endphp
            <td width="50%" style="vertical-align:top;padding:4px;">
                <div style="border:2px solid {{ $sch4?'#e36c0a':'#ccc' }};border-radius:8px;padding:10px;background:{{ $sch4?'#fff3e6':'white' }};">
                    <table cellspacing="0" cellpadding="0"><tr>
                        <td style="vertical-align:middle;padding-right:8px;">
                            <span style="display:inline-block;width:20px;height:20px;border:2px solid {{ $sch4?'#e36c0a':'#ccc' }};border-radius:4px;text-align:center;line-height:16px;font-size:12px;background:{{ $sch4?'#e36c0a':'white' }};color:white;">{{ $sch4?'&#10003;':'' }}</span>
                        </td>
                        <td style="vertical-align:middle;font-size:12px;color:#333;font-weight:{{ $sch4?'600':'normal' }};">{{ $si['label'] }}</td>
                    </tr></table>
                </div>
            </td>
        @endforeach
        @if(count($rowChunk) < 2)<td width="50%"></td>@endif
    </tr>
    @endforeach
</table>
```

---

### Fix 6 — Replace CURRICULAR GOALS, COMPETENCIES, APPROACH `display:flex` with `<table>`

**Where:** Lines 843, 866, 889 — three separate sections all using `display:flex; flex-wrap:wrap; gap:15px` with `<label style="display:flex; align-items:center; ...">` children.

These sections show checkbox items (boolean). Replace the flex wrapper div with a table where each row has 3 items:

```html
<table width="100%" cellspacing="4" cellpadding="0">
    @foreach(array_chunk($goalItems, 3) as $rowChunk)
    <tr>
        @foreach($rowChunk as $item)
            @php $checked = $isChecked($item['field_id']); @endphp
            <td width="33%" style="vertical-align:middle;padding:5px;">
                <table cellspacing="0" cellpadding="0"><tr>
                    <td style="vertical-align:middle;padding-right:6px;">
                        <span style="display:inline-block;width:18px;height:18px;border:2px solid {{ $checked?'#e36c0a':'#ccc' }};border-radius:4px;background:{{ $checked?'#e36c0a':'white' }};text-align:center;line-height:14px;font-size:12px;color:white;">{{ $checked?'&#10003;':'' }}</span>
                    </td>
                    <td style="vertical-align:middle;font-size:13px;color:#333;">{{ $item['label'] }}</td>
                </tr></table>
            </td>
        @endforeach
        @for($i = count($rowChunk); $i < 3; $i++)<td width="33%"></td>@endfor
    </tr>
    @endforeach
</table>
```

Apply the same table pattern for `$compItems` (COMPETENCIES) and `$approachBools` (APPROACH). For the APPROACH "Other:" text field at line 901, replace the flex row with a simple inline table.

---

### Fix 7 — Fix SELF_EVAL emoji circle: replace `display:flex` inside emoji cell

**Where:** Line 667–680 — inside the SELF_EVAL question table, each `<td>` contains:
```html
<div style="display:inline-block; text-align:center;">
    <div style="... display:flex; align-items:center; justify-content:center;">
        <img src="{{ $eUrl4 }}" style="width:45px;height:45px;object-fit:cover;">
    </div>
```

**Replace** the flex div with a simple centered div:
```html
<div style="text-align:center;">
    <div style="width:55px;height:55px;margin:0 auto 5px;border:{{ $isSel4?'3':'2' }}px solid {{ $isSel4?'#e36c0a':'#ccc' }};border-radius:50%;overflow:hidden;background:{{ $isSel4?'#fff3e6':'#f9f9f9' }};">
        {!! $emojiImgMap[$optVal4] ?? $emojiImgMap['not_sure'] !!}
    </div>
    <div style="font-size:11px;color:{{ $isSel4?'#e36c0a':'#666' }};font-weight:{{ $isSel4?'bold':'normal' }};margin-top:3px;">
        {{ $optLbl4 }}{{ $isSel4?' &#10003;':'' }}
    </div>
</div>
```

Remove `opacity:0.7` from the non-selected div. Remove `object-fit:cover` from all `<img>` tags.

---

### Fix 8 — Fix Self-Reflection and Peer Feedback emoji references (lines 1102, 1353)

**Where:** Lines ~1102 and ~1353 — emoji images inside Self-Reflection and Peer Feedback pages

These lines use `$em['url']` and inline `opacity:0.7`:
```html
<img src="{{ $em['url'] }}" style="width:35px;height:35px;{{ $isSelected?'border:2px solid #e36c0a;border-radius:18px;':'opacity:0.7;' }}" alt="{{ $optStr }}">
```

The `$em['url']` is derived from `$srEmojiUrls` / `$pfEmojiUrls` — both already removed in Fix 2.

After Fix 2, `$em['url']` will not exist. Instead, find where `$em` is built and change to use `$emojiImgMap`:

Find the loop that builds the `$em` array on Self-Reflection and Peer Feedback pages. Change the img output to:
```php
// If $em is an array with 'value' key matching emoji keys:
{!! $emojiImgMap[$em['value']] ?? $emojiImgMap['not_sure'] !!}
```

Remove the `opacity:0.7` border style on non-selected items (border color already differentiates state).

---

### Fix 9 — Add `page-break-inside:avoid` to `section_container` CSS

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

### Fix 10 — Remove remaining unsupported CSS throughout the file

| Search for | Action |
|---|---|
| `display:flex` | Replace with table layout (already done in Fixes 3–7) — search for any remaining occurrences |
| `flex:1` | Remove after replacing with table `<td>` |
| `flex-wrap:wrap` | Remove |
| `gap:` | Remove — use `cellspacing` on tables instead |
| `align-items:center` | Remove |
| `justify-content:center` | Remove |
| `calc(` | Remove — replace with fixed `%` or `px` values |
| `object-fit:cover` | Remove from all `<img>` style attributes |
| `object-fit:contain` | Remove from all `<img>` style attributes |
| `box-shadow:` | Remove wherever found |
| `opacity:0.7` / `opacity:0.6` | Remove |
| `line-height:1.5` | Replace with `line-height:20px` (explicit px) |
| `cursor:default` | Remove |

---

## Rules

1. Do NOT rewrite the file from scratch. Make targeted fixes only.
2. Do NOT change `$css` key names — they are referenced throughout all 46 pages.
3. The `$pdfImg` helper and `$emojiImgMap` must be defined **once** at the top-level `@php` block — never repeated per page.
4. After replacing emoji references, always use `{!! !!}` not `{{ }}` for HTML image output.
5. When converting flex grids to table grids — use `array_chunk()` for plain PHP arrays or `->chunk()` for Laravel Collections.
6. After Fix 3 (Activity/Assessment table), the Assessment Rubric table at line 942 must remain unchanged — it already uses `width="100%"` which is correct inside a `<td>`.
7. Total page count must remain 46 — no pages added or removed.
8. Do NOT modify `generateReportPdf()` or `generateSingleStudentPdf()` in the controller.
9. Do NOT add `page-break-before:always` to sections — only `page-break-inside:avoid`.

---

## Verification

**Test 1 — PDF generates without error**
Generate PDF for a student assigned Template 3 (Grades 6–8).
No exception should be thrown. The log must NOT contain `Min/max width is undefined for table rows`.

**Test 2 — All 46 pages render**
Open the generated PDF. Count pages. Must equal the number of active `hpc_template_parts` for Template 3 (should be 46). No blank pages.

**Test 3 — Emoji images visible**
Pages with SELF_EVAL, Self-Reflection, and Peer Feedback sections must show emoji face images. Not blank/broken image placeholders.

**Test 4 — Activity Tab pages (5,9,13,17,21,25,29,33,37,41)**
Each Activity Tab page must show:
- Activity box and Assessment Question box side-by-side in two columns
- Assessment Rubric table below with correct column widths
- Curricular Goals, Competencies, Approach items in clean rows — no collapsed/overflowed layout

**Test 5 — No section cut mid-page**
Each orange-bordered section box must appear complete on one page. DomPDF must push any section that does not fit to the next page.

---

## Summary of Changes

| # | Location | Change |
|---|---|---|
| 1 | Top-level `@php` (after `$css`) | Add `$pdfImg` helper + `$emojiImgMap` base64 image strings |
| 2 | Lines 560–564, 1015, 1220 | Remove `asset()` emoji URL arrays; replace `<img src="{{ $eUrl }}">` with `{!! $emojiImgMap[$key] !!}` |
| 3 | Line 914 — Activity+Assessment | Replace `display:flex; gap:15px` with `<table width="100%">` two-column layout — **fixes crash** |
| 4 | Line 595 — HOME_RESOURCES | Replace `display:flex; flex-wrap:wrap` grid with 2-column `<table>` |
| 5 | Line 702 — SUPPORT_WITH | Replace `display:flex; flex-wrap:wrap` grid with 2-column `<table>` |
| 6 | Lines 843, 866, 889 — GOALS/COMP/APPROACH | Replace `display:flex` checkbox grids with 3-column `<table>` |
| 7 | Line 667–680 — SELF_EVAL emoji cell | Remove `display:flex` inside emoji circle div; use `$emojiImgMap` |
| 8 | Lines 1102, 1353 — SR/PF emoji | Update to use `$emojiImgMap`; remove `opacity` |
| 9 | `$css` array line 20 | Add `page-break-inside:avoid` to `section_container` |
| 10 | Entire file | Remove all `display:flex`, `gap`, `flex-wrap`, `calc()`, `object-fit`, `box-shadow`, `opacity`, `align-items`, `cursor:default` |