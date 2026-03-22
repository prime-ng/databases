# HPC Fourth Template — PDF Blade Page 2 Design (`fourth_pdf.blade.php`)

**Date:** 2026-03-17
**File:** `Modules/Hpc/resources/views/hpc_form/pdf/fourth_pdf.blade.php`
**Template:** Fourth Template (Grades 9–12)
**Page:** 2 — "Self-Evaluation & Goals"
**PDF Reference:** `14-HPC-Second_Form-page-2.pdf` (in this folder)

---

## Context

Page 2 of the fourth template is the **Self-Evaluation, Career Aspirations, Goals, and Support Grid** page.
The shared PDF (`14-HPC-Second_Form-page-2.pdf`) shows the exact layout. Replace (or implement
if missing) the `@if($part->page_no == 2)` block in `fourth_pdf.blade.php` to match the PDF exactly.

---

## Pre-Read (Mandatory)

1. `Modules/Hpc/resources/views/hpc_form/pdf/fourth_pdf.blade.php` — locate the `@if($part->page_no == 2)` block
2. `14-HPC-Second_Form-page-2.pdf` (in this folder) — page 2 design reference
3. `database/seeders/HPCTemplateSeeder.php` — `seedPage2Fourth()` method (lines ~2509–2591)

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

## Seeder Data for Page 2 (Fourth Template)

Method: `seedPage2Fourth(int $tId, int $pId)` — lines ~2509–2591

### Section 1 — SELF_EVAL "Self-Evaluation – Part A(2)"
*Note: "Circle the most appropriate option."*
| Field `html_object_name` | Type | Label |
|--------------------------|------|-------|
| `p2_perf_last_year` | Text | "Last year, my performance at school was…" |
| `p2_teacher_feedback` | Text | "My teachers thought my efforts last year were…" |
| `p2_proud_achievement` | Text | "I am most proud of…" |
| `p2_improve_this_year` | Text | "This year, I would like to improve…" |
| `p2_school_goal_status` | Descriptor | "My school goal status" — options: Accomplished / Still working / Not started |

### Section 2 — CAREER_ASPIRATIONS "Career Aspirations"
| Field | Type | Label |
|-------|------|-------|
| `p2_career_1` | Text | Career aspiration 1 |
| `p2_career_2` | Text | Career aspiration 2 |
| `p2_career_3` | Text | Career aspiration 3 |
| `p2_career_4` | Text | Career aspiration 4 |
| `p2_fulfill_1` | Text | "To fulfill my aspirations, I need to" — item 1 |
| `p2_fulfill_2` | Text | Fulfillment step 2 |
| `p2_fulfill_3` | Text | Fulfillment step 3 |
| `p2_fulfill_4` | Text | Fulfillment step 4 |

### Section 3 — GOALS_LEFT "Goals!"
| Field | Type | Label |
|-------|------|-------|
| `p2_goal_last_school` | Text | "My goal in school last year was…" |
| `p2_goal_why` | Text | "Why was the goal important to you?" |
| `p2_specific_goal` | Text | "One specific goal I would like to achieve this year:" |
| `p2_goal_measure` | Text | "How will I know I have achieved this goal?" |

### Section 4 — ACTION_TIMELINE "To achieve this goal, things I need to do:"
| Field | Type | Label |
|-------|------|-------|
| `p2_action_week` | Text | "A week from now:" |
| `p2_action_6weeks` | Text | "6 weeks from now:" |
| `p2_action_6months` | Text | "6 months from now:" |

### Section 5 — SUPPORT_GRID "Support Grid"
| Field | Type | Label |
|-------|------|-------|
| `p2_strength_1` | Text | Strength 1 |
| `p2_strength_2` | Text | Strength 2 |
| `p2_strength_3` | Text | Strength 3 |
| `p2_home_support_1` | Text | Home support 1 |
| `p2_home_support_2` | Text | Home support 2 |
| `p2_home_support_3` | Text | Home support 3 |
| `p2_school_support_1` | Text | School support 1 |
| `p2_school_support_2` | Text | School support 2 |
| `p2_school_support_3` | Text | School support 3 |

---

## What to Identify in the PDF Image

Read `14-HPC-Second_Form-page-2.pdf` and identify:

1. **Page header** — Colour, title text ("Self-Evaluation" or "Part A(2)")?
2. **SELF-EVAL section** — 4 fill-in lines + goal status. Are they stacked or in a 2-column layout?
3. **Goal status field** — How is "Accomplished / Still working / Not started" shown? (Circled options? Radio boxes? Underline?)
4. **CAREER ASPIRATIONS section** — 4 career items listed. 4 fulfilment items. Are they in 2 separate columns or stacked?
5. **GOALS section** — 4 fill-in questions. Single column? Boxed area?
6. **ACTION TIMELINE section** — 3 time-boxes (1 week / 6 weeks / 6 months). Are they side-by-side in a 3-column table? Or stacked vertically?
7. **SUPPORT GRID section** — 3 columns (Strengths / Home Support / School Support) × 3 rows. Shown as a 3-column table?
8. **Section header styles** — Colours, bold labels, border styles?
9. **Overall page** — Is this one dense page or does it flow across pages? (If content exceeds one page, use `page-break-inside:avoid` on heavy sections.)

---

## Implementation Template

```blade
@elseif($part->page_no == 2)
@php
    $v = function($key) use ($savedValues, $student) {
        return $savedValues[$key] ?? $student->{$key} ?? '';
    };
    $goalStatusMap = [
        'accomplished'  => 'Accomplished',
        'still_working' => 'Still working',
        'not_started'   => 'Not started',
    ];
    $goalStatusLabel = $goalStatusMap[$savedValues['p2_school_goal_status'] ?? ''] ?? '—';
    // Helper: render fill-in row
    $row = function($label, $key) use ($v) {
        return '<tr>'
             . '<td style="border:1px solid #ddd; font-size:10px; width:50%; padding:3px;">' . $label . '</td>'
             . '<td style="border:1px solid #ddd; font-size:10px; padding:3px;">' . htmlspecialchars((string)$v($key), ENT_QUOTES) . '</td>'
             . '</tr>';
    };
@endphp

<div style="page-break-after:always; font-family:'DejaVu Sans',sans-serif; font-size:11px; padding:8px;">

    {{-- Page header --}}
    <div style="background:#[COLOR]; color:#fff; font-weight:bold; font-size:12px; padding:5px 8px; margin-bottom:6px;">
        Self-Evaluation – Part A(2)
    </div>

    {{-- SELF-EVALUATION section --}}
    <div style="font-weight:bold; font-size:11px; background:#[SECTION_BG]; padding:3px 6px; margin-bottom:3px;">Self-Evaluation</div>
    <table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse; margin-bottom:6px;">
        {!! $row('Last year, my performance at school was…', 'p2_perf_last_year') !!}
        {!! $row('My teachers thought my efforts last year were…', 'p2_teacher_feedback') !!}
        {!! $row('I am most proud of…', 'p2_proud_achievement') !!}
        {!! $row('This year, I would like to improve…', 'p2_improve_this_year') !!}
        <tr>
            <td style="border:1px solid #ddd; font-size:10px; padding:3px;">My school goal status</td>
            <td style="border:1px solid #ddd; font-size:10px; padding:3px;">{{ $goalStatusLabel }}</td>
        </tr>
    </table>

    {{-- CAREER ASPIRATIONS section --}}
    <div style="font-weight:bold; font-size:11px; background:#[SECTION_BG]; padding:3px 6px; margin-bottom:3px;">Career Aspirations</div>
    <table width="100%" cellpadding="3" cellspacing="0" style="border-collapse:collapse; margin-bottom:6px;">
        <tr>
            <td style="border:1px solid #ddd; width:50%; font-size:10px;">
                <div style="font-weight:bold; margin-bottom:2px;">My career aspirations is/are:</div>
                @for($i=1;$i<=4;$i++)
                <div>{{ $i }}. {{ $v('p2_career_'.$i) }}</div>
                @endfor
            </td>
            <td style="border:1px solid #ddd; width:50%; font-size:10px; vertical-align:top;">
                <div style="font-weight:bold; margin-bottom:2px;">To fulfill my aspirations, I need to:</div>
                @for($i=1;$i<=4;$i++)
                <div>{{ $i }}. {{ $v('p2_fulfill_'.$i) }}</div>
                @endfor
            </td>
        </tr>
    </table>

    {{-- GOALS section --}}
    <div style="font-weight:bold; font-size:11px; background:#[SECTION_BG]; padding:3px 6px; margin-bottom:3px;">Goals!</div>
    <table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse; margin-bottom:6px;">
        {!! $row('My goal in school last year was…', 'p2_goal_last_school') !!}
        {!! $row('Why was the goal important to you?', 'p2_goal_why') !!}
        {!! $row('One specific goal I would like to achieve this year:', 'p2_specific_goal') !!}
        {!! $row('How will I know I have achieved this goal?', 'p2_goal_measure') !!}
    </table>

    {{-- ACTION TIMELINE section (3-column) --}}
    <div style="font-weight:bold; font-size:11px; background:#[SECTION_BG]; padding:3px 6px; margin-bottom:3px;">
        To achieve this goal, things I need to do:
    </div>
    <table width="100%" cellpadding="3" cellspacing="0" style="border-collapse:collapse; margin-bottom:6px;">
        <tr>
            <th style="border:1px solid #ddd; font-size:10px; background:#f0f0f0; width:33%;">A week from now</th>
            <th style="border:1px solid #ddd; font-size:10px; background:#f0f0f0; width:33%;">6 weeks from now</th>
            <th style="border:1px solid #ddd; font-size:10px; background:#f0f0f0; width:33%;">6 months from now</th>
        </tr>
        <tr>
            <td style="border:1px solid #ddd; font-size:10px; height:30px;">{{ $v('p2_action_week') }}</td>
            <td style="border:1px solid #ddd; font-size:10px;">{{ $v('p2_action_6weeks') }}</td>
            <td style="border:1px solid #ddd; font-size:10px;">{{ $v('p2_action_6months') }}</td>
        </tr>
    </table>

    {{-- SUPPORT GRID section (3-column × 3 rows) --}}
    <div style="font-weight:bold; font-size:11px; background:#[SECTION_BG]; padding:3px 6px; margin-bottom:3px;">Support Grid</div>
    <table width="100%" cellpadding="3" cellspacing="0" style="border-collapse:collapse; margin-bottom:6px;">
        <tr>
            <th style="border:1px solid #ddd; font-size:10px; background:#f0f0f0; width:33%;">My strengths / abilities</th>
            <th style="border:1px solid #ddd; font-size:10px; background:#f0f0f0; width:33%;">Support at home / community</th>
            <th style="border:1px solid #ddd; font-size:10px; background:#f0f0f0; width:33%;">Support at school</th>
        </tr>
        @for($i=1;$i<=3;$i++)
        <tr>
            <td style="border:1px solid #ddd; font-size:10px; height:22px;">{{ $v('p2_strength_'.$i) }}</td>
            <td style="border:1px solid #ddd; font-size:10px;">{{ $v('p2_home_support_'.$i) }}</td>
            <td style="border:1px solid #ddd; font-size:10px;">{{ $v('p2_school_support_'.$i) }}</td>
        </tr>
        @endfor
    </table>

</div>
```

> **Important:** Replace all `[COLOR]` / `[SECTION_BG]` values and adjust layout to exactly match
> the PDF. The template above is a skeleton — build from the PDF image.

---

## Verification

- [ ] Page 2 block exists in `fourth_pdf.blade.php`
- [ ] `page-break-after:always` on container
- [ ] SELF-EVAL — 4 text fields + goal status shown correctly
- [ ] CAREER ASPIRATIONS — 4 career items + 4 fulfillment items match PDF layout
- [ ] GOALS — 4 fill-in questions match PDF
- [ ] ACTION TIMELINE — 3-column table (1 week / 6 weeks / 6 months) matches PDF
- [ ] SUPPORT GRID — 3-column × 3-row table matches PDF
- [ ] Section header colours match PDF exactly
- [ ] No Bootstrap classes
- [ ] No flexbox/grid
- [ ] No JavaScript
- [ ] No `str_pad()` with empty string
