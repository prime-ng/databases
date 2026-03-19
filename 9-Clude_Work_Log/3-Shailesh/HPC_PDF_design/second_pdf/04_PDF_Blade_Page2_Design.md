# HPC Second Template — PDF Blade Page 2 Design (`second_pdf.blade.php`)

**Date:** 2026-03-17
**File:** `Modules/Hpc/resources/views/hpc_form/pdf/second_pdf.blade.php`
**Template:** Second Template (Grades 3–5)
**Page:** 2 — "About Me"
**PDF Reference:** `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/9-Clude_Work_Log/3-Shailesh/HPC_PDF_design/second_pdf/12-HPC-Prep_Form-page-2.pdf`

---

## Context

Page 2 of the second template is the **"About Me"** self-expression page. The shared PDF
(`12-HPC-Prep_Form-page-2.pdf`) shows the exact layout. Replace (or implement if missing)
the `@if($part->page_no == 2)` block in `second_pdf.blade.php` to match the PDF exactly.

---

## Pre-Read (Mandatory)

1. `Modules/Hpc/resources/views/hpc_form/pdf/second_pdf.blade.php` — locate the `@if($part->page_no == 2)` block
2. `12-HPC-Prep_Form-page-2.pdf` (in this folder) — page 2 design reference
3. `database/seeders/HPCTemplateSeeder.php` — `seedPage2Second()` method (lines ~1162–1193)

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

## Seeder Data for Page 2 (Second Template)

Method: `seedPage2Second(int $tId, int $pId)` — lines ~1162–1193

### Section 1 — ABOUT_ME "About Me"
| Field `html_object_name` | Type | Label |
|--------------------------|------|-------|
| `p2_name` | Text | "My name is" |
| `p2_age` | Text | "I am ___ years old" |

### Section 2 — MY_FAMILY "My Family"
| Field | Type | Label |
|-------|------|-------|
| `p2_family_photo` | Image | "Family Photo Upload" |

### Section 3 — THINGS_ABOUT_ME "Things About Me"
| Field | Type | Label |
|-------|------|-------|
| `p2_good_at` | Text | "I am good at" |
| `p2_improve` | Text | "I want to improve" |
| `p2_like` | Text | "I like to" |
| `p2_dislike` | Text | "I don't like to" |

### Section 4 — FAVORITE_THINGS "Favorite Things"
| Field | Type | Label |
|-------|------|-------|
| `p2_fav_food` | Text | "Favorite food" |
| `p2_fav_game` | Text | "Favorite game" |
| `p2_fav_festival` | Text | "Favorite festival" |

### Section 5 — WHEN_GROW_UP "When I Grow Up"
| Field | Type | Label |
|-------|------|-------|
| `p2_career` | Text | "I want to become" |

### Section 6 — WANT_TO_LEARN "Three Things I Want to Learn"
| Field | Type | Label |
|-------|------|-------|
| `p2_learnings` | Text | "Three things I want to learn" |

---

## What to Identify in the PDF Image

Read `12-HPC-Prep_Form-page-2.pdf` and identify:

1. **Page title / header** — Colour strip? Title text? (e.g., "About Me" with a coloured background)
2. **Name and Age layout** — On same line or separate rows? Large write-in area?
3. **Family Photo box** — Where is it? Full width or right column? Box size?
4. **"Things About Me" block** — 4 fill-in lines, stacked vertically or in a 2-column grid?
5. **"Favorite Things" section** — 3 items in a row or stacked?
6. **"When I Grow Up" section** — Large write-in box or small line?
7. **"Three Things I Want to Learn" section** — Numbered list? Blank lines?
8. **Section header styles** — Coloured backgrounds, icons, border styles?
9. **Overall page structure** — Single column, two columns, or mixed?
10. **Decorative elements** — Any illustrations, star bullets, colour strips?

---

## Implementation Template

```blade
@elseif($part->page_no == 2)
@php
    $v = function($key) use ($savedValues, $student) {
        return $savedValues[$key] ?? $student->{$key} ?? '';
    };
    // Family photo URL
    $famPhotoUrl = '';
    if (!empty($savedValues['p2_family_photo'])) {
        $famPhotoUrl = \Storage::disk('public')->exists($savedValues['p2_family_photo'])
            ? \Storage::disk('public')->path($savedValues['p2_family_photo']) : '';
    }
@endphp

<div style="page-break-after:always; font-family:'DejaVu Sans',sans-serif; font-size:11px; padding:8px;">

    {{-- Page header -- match PDF colour and title exactly --}}
    <div style="background:#[COLOR]; color:#fff; font-weight:bold; font-size:13px; padding:6px 10px; margin-bottom:8px;">
        About Me
    </div>

    {{-- ABOUT ME: Name + Age --}}
    <table width="100%" cellpadding="4" cellspacing="0" style="border-collapse:collapse; margin-bottom:6px;">
        <tr>
            <td style="border:1px solid #ddd; font-size:11px;">My name is</td>
            <td style="border:1px solid #ddd; font-size:11px;">{{ $v('p2_name') }}</td>
        </tr>
        <tr>
            <td style="border:1px solid #ddd; font-size:11px;">I am ___ years old</td>
            <td style="border:1px solid #ddd; font-size:11px;">{{ $v('p2_age') }}</td>
        </tr>
    </table>

    {{-- MY FAMILY: Family Photo --}}
    <table width="100%" cellpadding="4" cellspacing="0" style="border-collapse:collapse; margin-bottom:6px;">
        <tr>
            <td style="border:1px solid #ddd; font-size:11px; font-weight:bold; background:#f5f5f5;">My Family</td>
        </tr>
        <tr>
            <td style="border:1px solid #ddd; text-align:center; height:80px;">
                @if($famPhotoUrl)
                    <img src="{{ $famPhotoUrl }}" style="max-height:75px; max-width:120px;" />
                @else
                    <span style="color:#aaa; font-size:10px;">[Family Photo]</span>
                @endif
            </td>
        </tr>
    </table>

    {{-- THINGS ABOUT ME --}}
    {{-- FAVORITE THINGS --}}
    {{-- WHEN I GROW UP --}}
    {{-- THREE THINGS TO LEARN --}}
    {{-- Build each section table to match PDF exactly --}}

</div>
```

> **Important:** Replace `[COLOR]` and all layout details with what you see in the actual PDF.

---

## Verification

- [ ] Page 2 block exists in `second_pdf.blade.php`
- [ ] `page-break-after:always` on container
- [ ] ABOUT ME (name + age) section matches PDF
- [ ] MY FAMILY photo box matches PDF position and size
- [ ] THINGS ABOUT ME (4 lines) matches PDF
- [ ] FAVORITE THINGS (3 items) matches PDF
- [ ] WHEN I GROW UP section matches PDF
- [ ] THREE THINGS TO LEARN section matches PDF
- [ ] No Bootstrap classes
- [ ] No flexbox/grid
- [ ] No JavaScript
