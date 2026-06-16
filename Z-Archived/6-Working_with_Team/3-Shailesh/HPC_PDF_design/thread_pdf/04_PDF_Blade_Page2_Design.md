# HPC Third Template — PDF Blade Page 2 Design (`third_pdf.blade.php`)

**Date:** 2026-03-17
**File:** `Modules/Hpc/resources/views/hpc_form/pdf/third_pdf.blade.php`
**Template:** Third Template (Grades 6–8, 46 pages)
**Page:** 2 — "All About Me"
**PDF Reference:** `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/9-Clude_Work_Log/3-Shailesh/HPC_PDF_design/thread_pdf/13-HPC-Middle_Form-page-2.pdf` (in this folder)

---

## Context

Page 2 of the third template is the **"All About Me"** self-expression page. The shared PDF
(`13-HPC-Middle_Form-page-2.pdf`) shows the exact layout. Replace (or implement if missing)
the `@if($part->page_no == 2)` block in `third_pdf.blade.php` to match the PDF exactly.

---

## Pre-Read (Mandatory)

1. `Modules/Hpc/resources/views/hpc_form/pdf/third_pdf.blade.php` — locate the `@if($part->page_no == 2)` block
2. `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/9-Clude_Work_Log/3-Shailesh/HPC_PDF_design/thread_pdf/13-HPC-Middle_Form-page-2.pdf` — page 2 design reference
3. `database/seeders/HPCTemplateSeeder.php` — `seedPage2Third()` method (lines ~1705–1738)

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

## Seeder Data for Page 2 (Third Template)

Method: `seedPage2Third(int $tId, int $pId)` — lines ~1705–1738

### Section 1 — ALL_ABOUT_ME "All About Me"
| Field `html_object_name` | Type | Label |
|--------------------------|------|-------|
| `part_a2_name` | Text | "My Name" |
| `live_with` | Text | "I live with my" |
| `live_place` | Text | "We stay at" |
| `siblings_no` | Text | "I have __ siblings" |
| `languages` | Text | "Languages I speak" |
| `after_school` | Text | "After school I like to" |
| `special_skills` | Text | "I have special skills in" |
| `proud_of` | Text | "I am proud of" |
| `help_others` | Text | "I can help others by" |

### Section 2 — MY_GOALS "My Goals"
| Field | Type | Label |
|-------|------|-------|
| `goal_school` | Text | "My goal at school this year is" |
| `goal_outside` | Text | "My goal outside of school is" |
| `how_achieve` | Text | "I will achieve my goals by" |

### Section 3 — MY_LEARNINGS "My Learnings"
| Field | Type | Label |
|-------|------|-------|
| `best_learning` | Text | "The best thing I learnt this year is" |
| `apply_learning` | Text | "I will use this learning by" |
| `improve_next_year` | Text | "Next year I want to improve on" |

---

## What to Identify in the PDF Image

Read `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/9-Clude_Work_Log/3-Shailesh/HPC_PDF_design/thread_pdf/13-HPC-Middle_Form-page-2.pdf` and identify:

1. **Page title / header** — Colour and title text for "All About Me" header?
2. **ALL ABOUT ME section layout** — Are these 9 fields stacked as fill-in lines? 2-column grid?
3. **"I live with my" field** — Single line or multi-line write area?
4. **Skills and proud-of fields** — Are they grouped in a box or open lines?
5. **MY GOALS section** — 3 separate fill-in boxes? Numbered list?
6. **MY LEARNINGS section** — 3 rows with underline blanks? Bordered box?
7. **Section header styling** — Background colour, font size, border style?
8. **Overall page structure** — Single full-width column? Left/right split?
9. **Any decorative elements** — Stars, icons, colour strips between sections?

---

## Implementation Template

```blade
@elseif($part->page_no == 2)
@php
    $v = function($key) use ($savedValues, $student) {
        return $savedValues[$key] ?? $student->{$key} ?? '';
    };
    // Helper: render a fill-in row
    $row = function($label, $key) use ($v) {
        return '<tr>'
             . '<td style="border:1px solid #ddd; font-size:11px; width:45%; padding:4px;">' . $label . '</td>'
             . '<td style="border:1px solid #ddd; font-size:11px; padding:4px;">' . htmlspecialchars((string)$v($key), ENT_QUOTES) . '</td>'
             . '</tr>';
    };
@endphp

<div style="page-break-after:always; font-family:'DejaVu Sans',sans-serif; font-size:11px; padding:8px;">

    {{-- Page header -- match PDF colour and title --}}
    <div style="background:#[COLOR]; color:#fff; font-weight:bold; font-size:13px; padding:6px 10px; margin-bottom:8px;">
        All About Me
    </div>

    {{-- ALL ABOUT ME section --}}
    <div style="font-weight:bold; background:#[SECTION_COLOR]; padding:4px 6px; margin-bottom:4px; font-size:11px;">All About Me</div>
    <table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse; margin-bottom:8px;">
        {!! $row('My Name', 'part_a2_name') !!}
        {!! $row('I live with my', 'live_with') !!}
        {!! $row('We stay at', 'live_place') !!}
        {!! $row('I have __ siblings', 'siblings_no') !!}
        {!! $row('Languages I speak', 'languages') !!}
        {!! $row('After school I like to', 'after_school') !!}
        {!! $row('I have special skills in', 'special_skills') !!}
        {!! $row('I am proud of', 'proud_of') !!}
        {!! $row('I can help others by', 'help_others') !!}
    </table>

    {{-- MY GOALS section --}}
    <div style="font-weight:bold; background:#[SECTION_COLOR]; padding:4px 6px; margin-bottom:4px; font-size:11px;">My Goals</div>
    <table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse; margin-bottom:8px;">
        {!! $row('My goal at school this year is', 'goal_school') !!}
        {!! $row('My goal outside of school is', 'goal_outside') !!}
        {!! $row('I will achieve my goals by', 'how_achieve') !!}
    </table>

    {{-- MY LEARNINGS section --}}
    <div style="font-weight:bold; background:#[SECTION_COLOR]; padding:4px 6px; margin-bottom:4px; font-size:11px;">My Learnings</div>
    <table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse; margin-bottom:8px;">
        {!! $row('The best thing I learnt this year is', 'best_learning') !!}
        {!! $row('I will use this learning by', 'apply_learning') !!}
        {!! $row('Next year I want to improve on', 'improve_next_year') !!}
    </table>

</div>
```

> **Important:** Replace all `[COLOR]` / `[SECTION_COLOR]` values and layout details with what
> you see in the actual PDF. The template above is a skeleton only.

---

## Verification

- [ ] Page 2 block exists in `third_pdf.blade.php`
- [ ] `page-break-after:always` on container
- [ ] ALL ABOUT ME — all 9 fields match PDF layout
- [ ] MY GOALS — 3 fields match PDF layout
- [ ] MY LEARNINGS — 3 fields match PDF layout
- [ ] Section header colours match PDF
- [ ] No Bootstrap classes
- [ ] No flexbox/grid
- [ ] No JavaScript
- [ ] No `str_pad()` with empty string
