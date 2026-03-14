# HPC: Fix fourth_pdf.blade.php — DomPDF Layout, Grid/Flex, Clock, Emoji

**Date:** 2026-03-13
**Type:** Bug Fix
**Module:** HPC (Holistic Progress Card)
**Severity:** Critical — Generated PDF is completely broken; layout collapses, all multi-column sections render as single column, clock is invisible, emoji show as blank boxes
**Files to modify:**
- `Modules/Hpc/resources/views/hpc_form/pdf/fourth_pdf.blade.php`

---

## Pre-Read (mandatory before coding)

Read the **full file** before making any changes:

1. `Modules/Hpc/resources/views/hpc_form/pdf/fourth_pdf.blade.php` — Full file. Focus on:
   - CSS `<style>` block (lines 216–324): `.grid-2`, `.grid-3`, `.grid-4` class definitions using `display:grid`
   - `$css` PHP array (lines 16–66): note `photo_img` key has `object-fit:cover`
   - Page 1 (line ~391): `<div class="grid-3">` — 3-column layout
   - Page 2 (line ~450): `display:flex;gap:8px;` rubric pairs, flex layouts throughout
   - Page 3 (lines ~654–744): `<div class="grid-2">`, `<div class="grid-3">` section layouts
   - Page 4 (line ~943): `<div class="grid-4">` 4-column time habits cards
   - Page 5 (lines ~1104–1178): analog clock faces using `position:absolute`, `%` values, `transform:rotate()`, `transform:translateX/translateY(-50%)`
   - Page 6 (lines ~1245, 1283, 1396, 1405): `display:flex;flex-wrap:wrap`, `class="grid-2"`, nested grid-2
   - Page 7 (lines ~1436, 1461, 1481, 1495): `class="grid-2"` x3, `display:flex;justify-content:space-between`
   - Page 10 (line ~1884): `style="display:grid;grid-template-columns:repeat(4,1fr);gap:10px;"` inline grid, emoji glyph switch block (lines 1890–1900)
   - Page 11 (lines ~2023, 2064, 2086): `class="grid-3"`, `class="grid-2"` x2
   - Page 12 (lines ~2160, 2171, 2190, 2230): `display:flex;flex-wrap:wrap`, `class="grid-3"` x2
   - Page 13 (lines ~2325, 2337): `display:flex;justify-content:space-between`, `display:flex;align-items:center`
   - Unicode emoji glyphs in text (lines ~939, 1240, 1289, 1345, 1393, 1433, 1453, 1878, 1890–1900)
   - `box-shadow` in inline styles: 51 occurrences

---

## Problems Found

### Problem 1 — `display:grid` classes collapse entire multi-column layout (CRITICAL)

**Root cause:** The `<style>` block defines `.grid-2`, `.grid-3`, `.grid-4` using `display:grid; grid-template-columns:...`:

```css
/* WRONG — DomPDF ignores CSS Grid */
.grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.grid-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 12px; }
.grid-4 { display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 12px; }
```

These classes are used **15 times** via `class="grid-2"`, `class="grid-3"`, `class="grid-4"`. When DomPDF renders the PDF, CSS Grid is ignored and all child `<div>` elements stack vertically in a single column, completely breaking every section layout in pages 1, 3, 4, 6, 7, 11, 12.

There is also an **inline `display:grid`** on page 10 (line ~1884):
```html
<div style="display:grid;grid-template-columns:repeat(4,1fr);gap:10px;">
```

DomPDF does NOT support `display:grid` at all.

---

### Problem 2 — `display:flex` everywhere collapses all flex layouts (CRITICAL)

**Root cause:** There are **85 occurrences** of `display:flex` as inline styles throughout the file. DomPDF ignores flexbox layout. Every `flex:1` child, every `flex-wrap:wrap` container, and every `gap:Npx` spacer produces zero-width or stacked results.

Key locations causing visible breakage:
- Page 2: `display:flex;gap:8px;` around rubric pairs (lines ~450, 472, 505)
- Page 2: `display:flex;flex-direction:column;gap:4px;` around radio options (line ~550)
- Page 2: `display:flex;...` support section header + content (lines ~579, 586)
- Page 3: Multiple `display:flex;flex-wrap:wrap;gap:8px;` for radio option buttons (line ~680)
- Page 6: `display:flex;flex-wrap:wrap;gap:10px;` for Next Big Step options (line ~1245)
- Page 6: `display:flex;flex-wrap:wrap;gap:8px;` for course type radios (line ~1318)
- Page 7: `display:flex;justify-content:space-between;` for range slider labels (line ~1481)
- Page 12: `display:flex;flex-wrap:wrap;align-items:center;gap:12px;` schedule section (line ~2160)
- Page 12: `display:flex;flex-wrap:wrap;gap:6px;` schedule item inputs (line ~2171)
- Page 13: `display:flex;justify-content:space-between;align-items:center;` rubric header row (line ~2325)

---

### Problem 3 — Analog clock faces (Page 5) are completely broken

**Root cause A:** The clock number markers use `transform:translateX(-50%)` and `transform:translateY(-50%)`:
```html
<div style="position:absolute;top:8%;left:50%;transform:translateX(-50%);">12</div>
<div style="position:absolute;top:50%;right:8%;transform:translateY(-50%);">3</div>
```
DomPDF does NOT support `transform`. The numbers will appear at `left:50%` or `top:50%` without centering.

**Root cause B:** The clock hands use `transform:rotate(Ndeg) translateX(-50%)`:
```html
<div style="position:absolute;bottom:50%;left:50%;...transform:rotate({{ $amHourRotate }}deg) translateX(-50%);">
```
DomPDF ignores `transform:rotate()` — clock hands won't rotate or position correctly.

**Root cause C:** The clock container uses `box-shadow:0 5px 10px rgba(0,0,0,0.1)` — ignored by DomPDF.

---

### Problem 4 — Unicode emoji glyphs render as blank boxes

**Root cause:** The DejaVu Sans font bundled with DomPDF does NOT include Unicode emoji codepoints. Every emoji used as a text character in a heading or label will render as a blank rectangle.

Affected locations (16 total occurrences):
- Line ~939: `📅 My Time Habits` in `<h5>` heading
- Line ~1240: `🚀 {{ $fpRubric['description'] }}` in div
- Line ~1289: `🎓 {{ $collegePlan['title'] }}` in div
- Line ~1345: `💼 {{ $careerPlan['title'] }}` in div
- Line ~1393: `💬 {{ $discussion['title'] }}` in div
- Line ~1433: `📅 {{ $futureSelf['title'] }}` in div
- Line ~1453: `🌟 {{ $feelFuture['title'] }}` in div
- Line ~1878: `⚠️ {{ $note }}` in inline-block badge
- Lines ~1890–1900: `@switch($index % 8)` block with `🎤 ✍️ ❤️ ⚧️ 🌍 🏛️ ⚖️ 🧠` — all inside a flex `<div>` that is itself a grid cell

---

### Problem 5 — `box-shadow` on 51 elements is silently ignored

**Root cause:** DomPDF ignores the `box-shadow` CSS property. Every card/panel that uses `box-shadow:0 1px 3px rgba(0,0,0,0.1)` will render without shadow — these do not cause a crash but make the PDF look different from the Blade view (no card depth). The borders should be made explicit.

---

### Problem 6 — `object-fit:cover` on student photo image

**Root cause:** `$css['photo_img']` (line ~28) contains `object-fit:cover` — not supported by DomPDF.
```php
'photo_img' => 'width:90px;height:90px;object-fit:cover;',
```
Remove `object-fit:cover`.

---

### Problem 7 — `accent-color` on checkboxes/radio buttons

**Root cause:** `accent-color:#e36c0a` in the `<style>` block (line ~270) and inline on checkbox in page 13 (`accent-color:#e67e22`) — not supported by DomPDF, silently ignored.

---

### Problem 8 — `overflow-x:auto` on table wrappers

**Root cause:** Two `<div style="overflow-x:auto;">` wrappers around tables (pages 3 and 8). DomPDF ignores this, but it can cause the table to overflow the page without scrolling. Remove the wrapper `<div>` and let the table render full-width directly.

---

### Problem 9 — `input[type="range"]` slider (Page 7) invisible in PDF

**Root cause:** Page 7 Feel About Future section uses `<input type="range" ...>` slider (line ~1474). DomPDF cannot render HTML range inputs. The slider shows as blank.

Replace the range input with a static visual rating bar made of table cells showing the saved rating value.

---

## Fixes — Detailed Instructions

### Fix 1 — Remove CSS Grid classes from `<style>` block; replace all `class="grid-N"` usages with `<table>` layouts

**File:** `fourth_pdf.blade.php`
**Where:** `<style>` block (lines ~293–307) and every `class="grid-2"`, `class="grid-3"`, `class="grid-4"` occurrence

**Step 1 — Remove or empty the grid class definitions in the `<style>` block:**
```css
/* REMOVE these three blocks entirely */
.grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.grid-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 12px; }
.grid-4 { display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 12px; }
```

**Step 2 — Replace every `<div class="grid-2">` with a `<table>` pattern:**
```html
<!-- BEFORE (broken) -->
<div class="grid-2">
    <div>...content A...</div>
    <div>...content B...</div>
</div>

<!-- AFTER (DomPDF compatible) -->
<table width="100%" cellspacing="8" cellpadding="0" style="border-collapse:separate;">
    <tr>
        <td width="50%" style="vertical-align:top;">...content A...</td>
        <td width="50%" style="vertical-align:top;">...content B...</td>
    </tr>
</table>
```

**Step 3 — Replace every `<div class="grid-3">` with a 3-column table:**
```html
<table width="100%" cellspacing="8" cellpadding="0" style="border-collapse:separate;">
    <tr>
        <td width="33%" style="vertical-align:top;">...col 1...</td>
        <td width="34%" style="vertical-align:top;">...col 2...</td>
        <td width="33%" style="vertical-align:top;">...col 3...</td>
    </tr>
</table>
```

**Step 4 — Replace every `<div class="grid-4">` with a 4-column table:**
```html
<table width="100%" cellspacing="8" cellpadding="0" style="border-collapse:separate;">
    <tr>
        <td width="25%" style="vertical-align:top;">...col 1...</td>
        <td width="25%" style="vertical-align:top;">...col 2...</td>
        <td width="25%" style="vertical-align:top;">...col 3...</td>
        <td width="25%" style="vertical-align:top;">...col 4...</td>
    </tr>
</table>
```

**Step 5 — Replace the inline grid on page 10 (course cards, line ~1884):**
```html
<!-- BEFORE -->
<div style="display:grid;grid-template-columns:repeat(4,1fr);gap:10px;">
    @foreach($courseAreas as $index => $area)
    <div>...</div>
    @endforeach
</div>

<!-- AFTER — chunk the array into rows of 4 -->
@php $courseChunks = array_chunk($courseAreas, 4); @endphp
@foreach($courseChunks as $chunk)
<table width="100%" cellspacing="8" cellpadding="0" style="border-collapse:separate;margin-bottom:8px;">
    <tr>
        @foreach($chunk as $index => $area)
        @php $color = $colors[$index % count($colors)]; @endphp
        <td width="25%" style="vertical-align:top;">
            <div style="background:white;border-radius:10px;padding:10px;text-align:center;border-top:3px solid {{ $color }};">
                <h6 style="font-weight:600;margin:0;font-size:11px;">{{ $area }}</h6>
            </div>
        </td>
        @endforeach
        @for($i = count($chunk); $i < 4; $i++)
        <td width="25%"></td>
        @endfor
    </tr>
</table>
@endforeach
```

Note: also remove the emoji glyph from the course card icon `<div>` when doing this (see Fix 4).

---

### Fix 2 — Replace all `display:flex` inline layouts with `<table>` layouts

**File:** `fourth_pdf.blade.php`

There are 85 occurrences of `display:flex`. Go through each page and replace with table-based equivalents. Key patterns:

**Pattern A — Two-column flex row (`flex:1` siblings):**
```html
<!-- BEFORE -->
<div style="display:flex;gap:8px;">
    <div style="flex:1;border-right:1px solid #dee2e6;padding-right:8px;">...left...</div>
    <div style="flex:1;padding-left:8px;">...right...</div>
</div>

<!-- AFTER -->
<table width="100%" cellspacing="0" cellpadding="0">
    <tr>
        <td width="50%" style="vertical-align:top;padding-right:6px;border-right:1px solid #dee2e6;">...left...</td>
        <td width="50%" style="vertical-align:top;padding-left:6px;">...right...</td>
    </tr>
</table>
```

**Pattern B — Flex header row with equal-width items:**
```html
<!-- BEFORE -->
<div style="display:flex;text-align:center;font-weight:bold;border-bottom:1px solid #dee2e6;padding-bottom:4px;">
    @foreach($rubrics as $rubric)
    <div style="flex:1;font-size:11px;">{{ $rubric['description'] }}</div>
    @endforeach
</div>

<!-- AFTER — use table header row directly (merge with content table) -->
```

**Pattern C — `display:flex;flex-wrap:wrap;gap:Npx;` for radio/checkbox option pills:**
```html
<!-- BEFORE -->
<div style="display:flex;flex-wrap:wrap;gap:8px;">
    @foreach($opts as $optIdx => $optVal)
    <div style="display:flex;align-items:center;">
        <input type="radio"...> <label>...</label>
    </div>
    @endforeach
</div>

<!-- AFTER -->
<table cellspacing="0" cellpadding="0"><tr>
    @foreach($opts as $optIdx => $optVal)
    <td style="padding-right:10px;white-space:nowrap;">
        <input type="radio"...>&nbsp;<label style="font-size:11px;">{{ $lbls[$optIdx] ?? $optVal }}</label>
    </td>
    @endforeach
</tr></table>
```

**Pattern D — `display:flex;justify-content:space-between;align-items:center;`:**
```html
<!-- BEFORE -->
<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;">
    <h6 style="font-weight:bold;margin:0;">{{ $rubric['description'] }}</h6>
    <div style="width:30px;height:30px;border:2px solid #e67e22;border-radius:50%;"></div>
</div>

<!-- AFTER -->
<table width="100%" cellspacing="0" cellpadding="0" style="margin-bottom:10px;">
    <tr>
        <td style="vertical-align:middle;"><h6 style="font-weight:bold;margin:0;font-size:13px;">{{ $rubric['description'] }}</h6></td>
        <td width="30" style="text-align:right;vertical-align:middle;"><div style="width:30px;height:30px;border:2px solid #e67e22;border-radius:50%;display:inline-block;"></div></td>
    </tr>
</table>
```

**Pattern E — `display:flex;flex-direction:column;gap:4px;` for stacked radio options:**
```html
<!-- BEFORE -->
<div style="display:flex;flex-direction:column;gap:4px;">
    @foreach($opts as $optIdx => $optVal)
    <div style="display:flex;align-items:center;">
        <input type="radio"...> <label>...</label>
    </div>
    @endforeach
</div>

<!-- AFTER -->
@foreach($opts as $optIdx => $optVal)
<div style="margin-bottom:4px;">
    <input type="radio"...>&nbsp;<label style="font-size:11px;">{{ $lbls[$optIdx] ?? $optVal }}</label>
</div>
@endforeach
```

**Pattern F — Page 12 schedule section flex layout:**
```html
<!-- BEFORE -->
<div style="display:flex;flex-wrap:wrap;align-items:center;gap:12px;">
    <div style="flex:0 0 150px;">...title block...</div>
    <div style="flex:1;">
        <div style="display:flex;flex-wrap:wrap;gap:6px;">
            @foreach($scheduleItems as $item)
            <div style="flex:1;min-width:80px;">...input...</div>
            @endforeach
        </div>
    </div>
</div>

<!-- AFTER -->
<table width="100%" cellspacing="0" cellpadding="0">
    <tr>
        <td width="150" style="vertical-align:middle;padding-right:12px;">...title block...</td>
        <td style="vertical-align:top;">
            <table width="100%" cellspacing="4" cellpadding="0"><tr>
                @foreach($scheduleItems as $item)
                <td style="vertical-align:top;"><input type="text" style="width:100%;padding:4px;" name="{{ $item['field_id'] }}" value="{{ $item['saved_value'] }}"></td>
                @endforeach
            </tr></table>
        </td>
    </tr>
</table>
```

---

### Fix 3 — Fix analog clock faces (Page 5)

**File:** `fourth_pdf.blade.php`
**Where:** Lines ~1111–1131 (AM clock), lines ~1147–1167 (PM clock)

**Root cause:** The analog clock uses `transform:rotate()` and `transform:translateX/translateY(-50%)` which DomPDF does NOT support. Replace the complex SVG-style clock with a simple **static table-based clock display** showing the saved time value in a text format.

**Replace the entire AM and PM clock face blocks** with a simple visual representation:

```html
<!-- REPLACE AM clock face (lines ~1111-1131) -->
<div style="width:140px;height:140px;border-radius:50%;background:#fff;margin:0 auto 12px;border:4px solid #ffc107;text-align:center;vertical-align:middle;display:table-cell;">
    <div style="display:block;padding-top:45px;">
        <div style="font-size:22px;font-weight:bold;color:#ffc107;">{{ $amItem['saved_value'] ?: '09:00' }}</div>
        <div style="font-size:10px;color:#999;margin-top:4px;">AM</div>
    </div>
</div>
```

Since DomPDF cannot render SVG/canvas clocks or rotated elements, show the time value numerically in a styled circle using `display:table-cell` (which DomPDF supports for vertical centering).

Apply the same replacement for the PM clock.

---

### Fix 4 — Remove Unicode emoji glyphs; replace with text labels or remove

**File:** `fourth_pdf.blade.php`
**Where:** All 16 occurrences of emoji glyphs in text

Remove or replace each emoji glyph with a plain-text alternative or a styled bracket indicator:

| Location | Original | Replace with |
|---|---|---|
| Line ~939 | `📅 My Time Habits` | `My Time Habits` |
| Line ~1240 | `🚀 {{ $fpRubric['description'] }}` | `{{ $fpRubric['description'] ?: 'Next Big Step' }}` |
| Line ~1289 | `🎓 {{ $collegePlan['title'] }}` | `{{ $collegePlan['title'] ?: 'College Plan' }}` |
| Line ~1345 | `💼 {{ $careerPlan['title'] }}` | `{{ $careerPlan['title'] ?: 'Career Plan' }}` |
| Line ~1393 | `💬 {{ $discussion['title'] }}` | `{{ $discussion['title'] ?: 'Discussion' }}` |
| Line ~1433 | `📅 {{ $futureSelf['title'] }}` | `{{ $futureSelf['title'] ?: 'Future Self' }}` |
| Line ~1453 | `🌟 {{ $feelFuture['title'] }}` | `{{ $feelFuture['title'] ?: 'Feel About Future' }}` |
| Line ~1878 | `⚠️ {{ $note }}` | `[Note] {{ $note }}` |
| Lines ~1890–1900 | `@switch` emoji block | Remove the entire icon `<div>` (just keep `<h6>` with course name) |

For the course cards (page 10) `@switch` block that renders one emoji per card — **remove the entire icon div** (the 36×36px colored circle containing the emoji). Keep only the `<h6>` text label:
```php
// REMOVE this entire block from each course card:
<div style="width:36px;height:36px;...display:flex;align-items:center;justify-content:center;...">
    @switch($index % 8) ... @endswitch
</div>
```

---

### Fix 5 — Replace `input[type="range"]` slider (Page 7) with static rating bar

**File:** `fourth_pdf.blade.php`
**Where:** Lines ~1474–1484 (Feel About Future range slider)

Replace the range input with a static table-based rating bar:

```html
<!-- BEFORE -->
<input type="range" style="width:100%;height:6px;border-radius:3px;" name="{{ $item['field_id'] }}" min="1" max="5" value="{{ $sliderValue }}" step="1">
<div style="display:flex;justify-content:space-between;margin-top:4px;">
    <span style="font-size:9px;color:#6c757d;">Low</span>
    <span style="font-size:9px;color:#6c757d;">High</span>
</div>

<!-- AFTER -->
@php $ratingColors = ['#dc3545','#fd7e14','#ffc107','#0d6efd','#198754']; @endphp
<table cellspacing="2" cellpadding="0" style="margin-top:4px;">
    <tr>
        @for($r = 1; $r <= 5; $r++)
        <td><div style="width:22px;height:22px;border-radius:50%;background:{{ $r <= $sliderValue ? $ratingColors[$r-1] : '#e9ecef' }};border:2px solid {{ $r <= $sliderValue ? $ratingColors[$r-1] : '#dee2e6' }};text-align:center;line-height:18px;font-size:10px;font-weight:bold;color:white;">{{ $r }}</div></td>
        @endfor
        <td style="padding-left:6px;font-size:10px;color:#6c757d;vertical-align:middle;">/ 5</td>
    </tr>
</table>
<input type="hidden" name="{{ $item['field_id'] }}" value="{{ $sliderValue }}">
```

---

### Fix 6 — Remove `box-shadow` from all inline styles

**File:** `fourth_pdf.blade.php`

There are **51 occurrences** of `box-shadow:0 1px 3px rgba(0,0,0,0.1)` (and variations). DomPDF silently ignores them but they add CSS parsing overhead and create visual discrepancy. Replace card containers that rely on `box-shadow` for visual separation with an explicit `border`:

Replace:
```html
style="background:white;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,0.1);"
```
With:
```html
style="background:white;border-radius:8px;border:1px solid #e0e0e0;"
```

---

### Fix 7 — Remove unsupported CSS properties from `$css` array and `<style>` block

**File:** `fourth_pdf.blade.php`

**In `$css` PHP array:**
- `photo_img` (line ~28): remove `object-fit:cover;`
  ```php
  'photo_img' => 'width:90px;height:90px;',
  ```

**In `<style>` block:**
- Remove `accent-color: #e36c0a;` from `input[type="radio"], input[type="checkbox"]` rule (line ~270)
- Remove `.grid-2`, `.grid-3`, `.grid-4` CSS classes entirely (see Fix 1)
- Remove `display: grid; grid-template-columns:...` from those classes (see Fix 1)
- Remove `gap: 12px;` from those classes (see Fix 1)
- The `@media print { .grid-2, .grid-3, .grid-4 { page-break-inside: avoid; } }` block can be removed too

**Inline `accent-color` on page 13** (line ~2340):
```html
<!-- BEFORE -->
style="width:16px;height:16px;margin-right:6px;accent-color:#e67e22;"
<!-- AFTER -->
style="width:16px;height:16px;margin-right:6px;"
```

**`cursor:pointer`** in label styles — remove all occurrences (they are harmless but DomPDF ignores them).

---

### Fix 8 — Add `page-break-inside:avoid` to page wrapper, remove `overflow-x:auto`

**File:** `fourth_pdf.blade.php`

**`overflow-x:auto` wrappers** (lines ~750, ~1638): Remove the `<div style="overflow-x:auto;">` wrapper div entirely. The table should be rendered directly without the overflow container — DomPDF ignores it and the extra div can confuse table width calculation.

**Page container** already has `page-break-inside:avoid` in the `.page-container` class. Verify `.section-block` also has it (line ~281 — it does: `page-break-inside: avoid;`).

---

## Rules

1. Do NOT rewrite the entire file from scratch. Make targeted edits per page.
2. Do NOT change the `$css` PHP array key names — other parts of the template reference them.
3. Do NOT use `display:flex`, `display:grid`, `gap:`, `align-items:`, `justify-content:`, `flex:1` anywhere in the file — DomPDF ignores all of these.
4. Do NOT use `transform:rotate()`, `transform:translate()`, or any CSS transform property.
5. Do NOT use `box-shadow` — use explicit `border:1px solid #e0e0e0` instead.
6. Do NOT use Unicode emoji codepoints (📚🎤🚀 etc.) in text — they render as blank boxes in DejaVu Sans.
7. Do NOT use `object-fit`, `accent-color`, `cursor:pointer`, `overflow-x`, `min-width` on flex children, or CSS `gap`.
8. When replacing `class="grid-N"` with tables, preserve the page-break logic: add `style="page-break-inside:avoid;"` to the wrapping `<table>`.
9. Do NOT touch any PHP data-loading logic (`$buildSectionData`, `$renderItem`, etc.) — only change the HTML/CSS rendering.
10. Do NOT modify `HpcController.php` or `student-list/index.blade.php`.

---

## Verification

After all fixes, regenerate the PDF for a Grade 9–12 student with all pages populated:

### Layout
- Page 1 (Basic Information): 3-column rubric layout must show 3 actual columns, not all stacked vertically
- Page 2 (Self-Evaluation): Rubric pairs must appear side-by-side; goals section must have 2 columns (left: textarea, right: radio buttons)
- Page 3 (Goals Continuation): grid-2 header cards must be side-by-side; grid-3 cards must be in 3 columns
- Page 4 (Time Management): 4 habit cards must appear in a row, not stacked
- Page 6 (Future Plan): Next Big Step option cards must be horizontal; grid-2 College/Career cards must be side-by-side
- Page 7 (Future Self): All grid-2 sections must be two columns
- Page 10 (Online Courses): 4-per-row course card grid must render; no emoji blank boxes
- Page 11 (Project Work): 3-column PEDAGOGIES section must be 3 columns; grid-2 must be 2 columns
- Page 12 (Schedule): Schedule header + inputs must be in the same row; 3-column planning must be 3 columns
- Page 13 (Stage Assessment): Rubric title row (description + circle) must be on same line

### Clock (Page 5)
- AM and PM time values must be visible as numeric text inside the circle — no blank clock face

### Emoji
- No blank boxes in any heading or section title
- Course card icons (page 10) show only the text label, not broken emoji boxes

### Page Breaks
- No section must split mid-content across pages
- Each page's `.page-container` must cause a page break after it

### Student Photo (Page 1)
- Student photo renders without `object-fit` distortion (fill the box)

---

## Summary of Changes

| # | Location | Problem | Fix |
|---|---|---|---|
| 1 | `<style>` block (lines ~293–307) | `.grid-2/.grid-3/.grid-4` use `display:grid` — not supported | Remove CSS Grid class definitions; they are replaced with `<table>` layouts |
| 2 | Every `class="grid-2"` (15 occurrences) | CSS Grid collapses to single column in DomPDF | Replace each with `<table width="100%" cellspacing="8">` 2/3/4-column table |
| 3 | Page 10 line ~1884 | `style="display:grid;grid-template-columns:repeat(4,1fr);"` inline | Replace with `array_chunk` + `<table>` row-of-4 |
| 4 | 85 occurrences of `display:flex` | Flex layout ignored — all children stack vertically | Replace all flex containers with `<table>` layouts using patterns A–F |
| 5 | Page 5 lines ~1111–1167 | Clock hands/numbers use `transform:rotate/translate` — not supported | Replace with numeric time display in a styled circle |
| 6 | 16 emoji text occurrences | DejaVu Sans has no emoji glyphs | Remove emoji glyphs; use plain text labels |
| 7 | 51 occurrences of `box-shadow` | Ignored by DomPDF; cards look flat | Replace with `border:1px solid #e0e0e0` |
| 8 | `$css['photo_img']` line ~28 | `object-fit:cover` not supported | Remove `object-fit:cover` |
| 9 | `<style>` block line ~270 + page 13 | `accent-color` not supported | Remove from style block and inline |
| 10 | Pages 3, 8 lines ~750, ~1638 | `overflow-x:auto` ignored, wraps table | Remove `<div style="overflow-x:auto;">` wrapper |
| 11 | Page 7 lines ~1474–1484 | `<input type="range">` invisible in PDF | Replace with static 5-dot rating bar table |