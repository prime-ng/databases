# HPC First Template — PDF Blade Page 2 Design (`first_pdf.blade.php`)

**Date:** 2026-03-17
**File:** `Modules/Hpc/resources/views/hpc_form/pdf/first_pdf.blade.php`
**Template:** First Template (Grades 3–5)
**Page:** 2 — "This Is Me"
**PDF Reference:** `11-HPC-Found_Form-page-2.pdf` (in this folder)

---

## Context

Page 2 of the first template is the **"This Is Me"** self-expression page. The shared PDF
(`11-HPC-Found_Form-page-2.pdf`) shows the exact layout. Replace (or implement if missing) the
`@if($part->page_no == 2)` block in `first_pdf.blade.php` to match the PDF exactly.

---

## Pre-Read (Mandatory)

1. `Modules/Hpc/resources/views/hpc_form/pdf/first_pdf.blade.php` — locate the `@if($part->page_no == 2)` block
2. `11-HPC-Found_Form-page-2.pdf` (in this folder) — page 2 design reference
3. `database/seeders/HPCTemplateSeeder.php` — `seedPage2()` method (lines ~569–623)

---

## Architecture Rules (Non-Negotiable)

| # | Rule |
|---|------|
| 1 | **NO** Blade components (`<x-*>`) |
| 2 | **NO** Bootstrap classes — inline styles ONLY |
| 3 | **NO** flexbox or CSS grid — use `<table>` for ALL layouts |
| 4 | **NO** JavaScript |
| 5 | Font: `DejaVu Sans` only |
| 6 | `page-break-after: always` on page 2 container `<div>` |
| 7 | All helpers in `@php` block at top |
| 8 | Do NOT use `str_pad()` with empty string — PHP 8 error |

---

## Seeder Data for Page 2 (First Template)

Method: `seedPage2(int $tId, int $pId)` — lines ~569–623

### Section 1 — THIS_IS_ME "This is me"
| Field `html_object_name` | Type | Label |
|--------------------------|------|-------|
| `p2_gender` | Descriptor | "I am" — options: 👧 Girl, 👦 Boy |
| `p2_age_years` | Descriptor | "Age (years)" — dropdown 3–18 years |
| `p2_birthday` | Text | "My birthday" |
| `p2_city` | Text | "I live in" |
| `p2_family_girl` | Boolean | 👧 Girl |
| `p2_family_boy` | Boolean | 👦 Boy |
| `p2_family_father` | Boolean | 👨 Father |
| `p2_family_mother` | Boolean | 👩 Mother |

### Section 2 — MY_FUTURE "My future"
| Field | Type | Label |
|-------|------|-------|
| `p2_dream_job` | Text | "I want to be a" |
| `p2_friends` | Text | "My friends" |

### Section 3 — MY_FAVORITES "My favorites"
| Field | Type | Label / Options |
|-------|------|-----------------|
| `p2_fav_colour` | Descriptor | Favourite Colour (emoji options) |
| `p2_fav_food` | Descriptor | Favourite Food (emoji options) |
| `p2_fav_animal` | Descriptor | Favourite Animal (emoji options) |
| `p2_fav_flower` | Descriptor | Favourite Flower (emoji options) |
| `p2_fav_sport` | Descriptor | Favourite Sport (emoji options) |
| `p2_fav_subject` | Descriptor | Favourite Subject (emoji options) |

---

## What to Identify in the PDF Image

Read `11-HPC-Found_Form-page-2.pdf` and identify:

1. **Page title / header** — Is there a coloured header bar or title strip at the top?
2. **"This Is Me" block layout** — Is gender shown as large emoji circles? Radio-style buttons?
3. **Age field** — Shown as a dropdown label or fill-in boxes?
4. **Birthday** — Date picker format or underline blanks?
5. **Family section** — Are family members shown as emoji tick-boxes or checkbox grid?
6. **"My Future" section** — Is "I want to be a" a large write-in area?
7. **"My Favorites" section** — Are favorites shown as icon-grid (emoji circles) or inline labels?
8. **Column layout** — Is page 2 a 2-column layout or full-width single column?
9. **Background colours** — Any section headers with coloured backgrounds?
10. **Decorative elements** — Any border frames, icons, or illustrations?

---

## Implementation Template

```blade
@elseif($part->page_no == 2)
@php
    $v = function($key) use ($savedValues, $student) {
        return $savedValues[$key] ?? $student->{$key} ?? '';
    };
    $chk = function($key) use ($savedValues) {
        return !empty($savedValues[$key]) ? '&#9746;' : '&#9744;';
    };
    // Helper: selected descriptor label from options
    $desc = function($key, $options, $labels) use ($savedValues) {
        $val = $savedValues[$key] ?? '';
        $idx = array_search($val, $options);
        return ($idx !== false) ? $labels[$idx] : ($val ?: '—');
    };
@endphp

<div style="page-break-after:always; font-family:'DejaVu Sans',sans-serif; font-size:11px; padding:8px;">

    {{-- Page title/header matching PDF --}}
    <div style="background:#[COLOR]; color:#fff; font-weight:bold; font-size:13px; padding:6px 10px; margin-bottom:8px;">
        This Is Me
    </div>

    {{-- THIS IS ME section --}}
    <table width="100%" cellpadding="4" cellspacing="0" style="border-collapse:collapse; margin-bottom:8px;">
        <tr>
            <td style="font-size:11px; border:1px solid #ddd; width:30%;">I am</td>
            <td style="font-size:11px; border:1px solid #ddd;">
                {!! $chk('p2_gender') !!} 👧 Girl &nbsp;&nbsp; {!! $chk('p2_gender') !!} 👦 Boy
            </td>
        </tr>
        <tr>
            <td style="font-size:11px; border:1px solid #ddd;">Age</td>
            <td style="font-size:11px; border:1px solid #ddd;">{{ $v('p2_age_years') }}</td>
        </tr>
        <tr>
            <td style="font-size:11px; border:1px solid #ddd;">My birthday</td>
            <td style="font-size:11px; border:1px solid #ddd;">{{ $v('p2_birthday') }}</td>
        </tr>
        <tr>
            <td style="font-size:11px; border:1px solid #ddd;">I live in</td>
            <td style="font-size:11px; border:1px solid #ddd;">{{ $v('p2_city') }}</td>
        </tr>
        <tr>
            <td style="font-size:11px; border:1px solid #ddd;">My family</td>
            <td style="font-size:11px; border:1px solid #ddd;">
                {!! $chk('p2_family_girl') !!} 👧 Girl &nbsp;
                {!! $chk('p2_family_boy') !!} 👦 Boy &nbsp;
                {!! $chk('p2_family_father') !!} 👨 Father &nbsp;
                {!! $chk('p2_family_mother') !!} 👩 Mother
            </td>
        </tr>
    </table>

    {{-- MY FUTURE section --}}
    {{-- MY FAVORITES section --}}
    {{-- Match exact layout from PDF --}}

</div>
```

> **Important:** Replace all `[COLOR]` values and layout details with what you see in the actual PDF.
> The above is only a skeleton — build the full layout from the PDF image.

---

## Descriptor Field Rendering (for Favourites)

Descriptor fields save a selected value. Render the saved label:

```php
// In @php block:
$genderOptions  = ['👧 Girl', '👦 Boy'];
$colourOptions  = ['🔴 Red','🔵 Blue','🟢 Green','🟡 Yellow','🟣 Purple','🟠 Orange','⚫ Black','⚪ White'];
$foodOptions    = ['🍕 Pizza','🍔 Burger','🍜 Pasta','🍣 Sushi','🍛 Curry','🥗 Salad','🍱 Bento','🌮 Taco'];
$animalOptions  = ['🦁 Lion','🐘 Elephant','🦒 Giraffe','🐼 Panda','🐬 Dolphin','🦅 Eagle','🐕 Dog','🐈 Cat'];
$flowerOptions  = ['🌹 Rose','🌻 Sunflower','🌸 Cherry Blossom','🌷 Tulip','💐 Bouquet','🌺 Hibiscus'];
$sportOptions   = ['⚽ Soccer','🏀 Basketball','🎾 Tennis','🏊 Swimming','🏏 Cricket','🏸 Badminton','🤸 Gymnastics'];
$subjectOptions = ['📖 Reading','🧮 Math','🔬 Science','🎨 Art','🌍 Social Studies','💻 Computer','🎵 Music'];
```

In blade, display the saved value directly:
```blade
{{ $savedValues['p2_fav_colour'] ?? '—' }}
```

---

## Verification

- [ ] Page 2 block starts with `@elseif($part->page_no == 2)`
- [ ] `page-break-after:always` on container
- [ ] THIS IS ME section matches PDF layout
- [ ] MY FUTURE section matches PDF layout
- [ ] MY FAVORITES section matches PDF layout (emoji options displayed)
- [ ] No Bootstrap classes
- [ ] No flexbox/grid
- [ ] No JavaScript
- [ ] No `str_pad()` with empty string
