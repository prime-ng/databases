# HPC Fourth Template — PDF Blade Page 1 Design (`fourth_pdf.blade.php`)

**Date:** 2026-03-17
**File:** `Modules/Hpc/resources/views/hpc_form/pdf/fourth_pdf.blade.php`
**Template:** Fourth Template (Grades 9–12)
**Priority:** High

---

## Context

The user will share the **fourth template PDF image** (page 1). Your job is to:
1. Read the shared PDF page 1 image carefully.
2. Replace the existing `@if($part->page_no == 1)` block in `fourth_pdf.blade.php` with a DomPDF-compatible HTML layout that **exactly matches the PDF design**.

---

## Pre-Read (Mandatory)

Read these files before making any changes:

1. `Modules/Hpc/resources/views/hpc_form/pdf/fourth_pdf.blade.php` — full file
2. `Modules/Hpc/resources/views/hpc_form/pdf/first_pdf.blade.php` — reference implementation (page 1 block, lines ~344–580)
3. The shared **fourth template PDF page 1 image** — study it carefully before writing any code

---

## Architecture Rules (Non-Negotiable)

| # | Rule |
|---|------|
| 1 | **NO** Blade components (`<x-*>`) inside PDF templates |
| 2 | **NO** Bootstrap classes — inline styles ONLY |
| 3 | **NO** flexbox or CSS grid — use `<table>` for ALL layouts |
| 4 | **NO** JavaScript |
| 5 | Font family: `DejaVu Sans` — the only font guaranteed in DomPDF |
| 6 | `page-break-after: always` on the page 1 container `<div>` |
| 7 | All helper closures must be defined inside `@php` at top of the block |
| 8 | Do NOT use `str_pad()` with an empty pad string — PHP 8 throws `ValueError` |

---

## Helper Closures Required

Define these inside `@php` at the start of the page 1 block. Copy the pattern from `first_pdf.blade.php`:

```php
// Safe character-box renderer (NO str_pad — PHP 8 safe)
$boxes = function($value, $count) {
    $str  = (string)$value;
    $html = '';
    for ($i = 0; $i < $count; $i++) {
        $char = $i < strlen($str) ? $str[$i] : '';
        $html .= '<span style="display:inline-block;width:16px;height:16px;'
               . 'border:1px solid #333;text-align:center;font-size:10px;'
               . 'line-height:16px;margin:0 1px;">'
               . htmlspecialchars($char, ENT_QUOTES)
               . '</span>';
    }
    return $html;
};

// Get saved student value by html_object_name
$v = function($key) use ($savedValues, $student) {
    return $savedValues[$key] ?? $student->{$key} ?? '';
};

// Single-line field with label
$line = function($label, $value, $width = '100%') {
    return '<div style="margin-bottom:4px;font-size:11px;">'
         . '<span style="font-weight:bold;">' . $label . ':</span> '
         . '<span style="border-bottom:1px solid #333;display:inline-block;'
         . 'min-width:120px;">' . htmlspecialchars((string)$value, ENT_QUOTES) . '</span>'
         . '</div>';
};

// Checkbox helper
$chk = function($checked) {
    return $checked ? '&#9746;' : '&#9744;';
};

// Checkbox with label
$cb = function($label, $checked) use ($chk) {
    return '<span style="font-size:11px;margin-right:8px;">'
         . ($checked ? '&#9746;' : '&#9744;') . ' ' . $label
         . '</span>';
};

// Integer value helper
$int = function($key) use ($savedValues) {
    return isset($savedValues[$key]) ? (int)$savedValues[$key] : '';
};
```

---

## What to Identify in the PDF Image

When reading the fourth template PDF page 1, identify and implement:

### 1. Header / School Information Block
- What fields appear? (School name, village, BRC/CRC, state, pin code, UDISE code, teacher code, APAAR ID)
- Are UDISE and Teacher Code on the **same line** or different lines?
- Is there a school logo or header branding different from first/second templates?

### 2. General Information Section
- Does it have: Student Name, Roll No, Registration No?
- Are Roll No and Registration No on the **same line** or separate lines?
- Grade selection checkboxes — **Grade 9, 10, 11, 12** (fourth template)
- Photograph box position (right column?)
- Note: In `seedPage1Fourth()`, current order is: GRADE(2), SECTION_DOB_AGE(3), PHOTOGRAPH(4) — verify against PDF whether PHOTOGRAPH comes before or after SECTION_DOB_AGE
- Section, DOB, Age fields
- Address and Phone
- Mother's Name alone or grouped?
- Mother's Education + Occupation — same line?
- Father's Name alone or grouped?
- Father's Education + Occupation — same line?
- Siblings count and age
- Mother Tongue + Medium of Instruction — same line?
- Rural/Urban — separate line?
- Health/Illness info

### 3. Attendance Section
- Column headers: MONTHS | APR | MAY | JUN | JUL | AUG | SEP | OCT | NOV | DEC | JAN | FEB | MAR
- Row labels: Working Days | Present | Reason (or similar)
- Header background color (confirm from PDF — orange `#FF6B35` or different for Grade 9-12?)

### 4. Additional Sections (Fourth Template Specific)
- Does page 1 have a **Self-Evaluation** section? (Page 2 starts with SELF_EVAL in current seeder)
- Are there any sections unique to Grades 9-12 not present in first template?
- **Interests section** — present or not on page 1?

---

## Implementation Pattern

Follow the **exact same approach** as `first_pdf.blade.php` page 1 block:

```blade
@if($part->page_no == 1)
@php
    // ... all helper closures ...
    // Attendance data builder
    $months = ['apr','may','jun','jul','aug','sep','oct','nov','dec','jan','feb','mar'];
    $workingDays = []; $present = []; $reasons = [];
    foreach ($months as $m) {
        $workingDays[] = $int('attendance_working_'.$m);
        $present[]     = $int('attendance_present_'.$m);
        $reasons[]     = $v('attendance_reason_'.$m);
    }
    // Photograph URL
    $p1PhotoUrl = '';
    if (!empty($savedValues['student_photo'])) {
        $p1PhotoUrl = Storage::disk('public')->exists($savedValues['student_photo'])
            ? Storage::disk('public')->path($savedValues['student_photo']) : '';
    }
@endphp

<div style="page-break-after:always; font-family:'DejaVu Sans',sans-serif; font-size:11px; padding:8px;">

    {{-- PART-A(1) school info block --}}
    <table width="100%" cellpadding="3" cellspacing="0" style="border-collapse:collapse; margin-bottom:6px;">
        {{-- rows matching PDF exactly --}}
    </table>

    {{-- GENERAL INFORMATION block --}}
    <table width="100%" cellpadding="3" cellspacing="0" style="border-collapse:collapse; margin-bottom:6px;">
        {{-- rows matching PDF exactly --}}
    </table>

    {{-- ATTENDANCE table --}}
    <table width="100%" cellpadding="3" cellspacing="0" style="border-collapse:collapse; margin-bottom:6px;">
        <tr>
            <th style="background:#FF6B35; color:#fff; font-size:10px; border:1px solid #ccc;">MONTHS</th>
            @foreach(['APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC','JAN','FEB','MAR'] as $mh)
            <th style="background:#FF6B35; color:#fff; font-size:10px; border:1px solid #ccc;">{{ $mh }}</th>
            @endforeach
        </tr>
        {{-- Working Days, Present, Reason rows --}}
    </table>

    {{-- Only if shown on page 1 of fourth template PDF --}}
    {{-- INTERESTS or SELF-EVALUATION section if present --}}

</div>
@endif
```

---

## Grade Checkboxes for Fourth Template

Fourth template covers **Grades 9, 10, 11, 12**. Use these `html_object_name` keys:
- `grade_grade9`  → "Grade 9"
- `grade_grade10` → "Grade 10"
- `grade_grade11` → "Grade 11"
- `grade_grade12` → "Grade 12"

---

## Key Differences from First Template

| Feature | First Template | Fourth Template |
|---------|---------------|-----------------|
| Grades | 3, 4, 5 | 9, 10, 11, 12 |
| Pages | ~30 | Different count |
| Page 2 start | Subject evaluations | Self-Evaluation (SELF_EVAL) |
| Interests section | Present on page 1 | Verify from PDF |
| Header color | Confirm from PDF | Confirm from PDF |

---

## Key Data Variables Available

| Variable | Type | Purpose |
|----------|------|---------|
| `$savedValues` | array | All saved field values keyed by `html_object_name` |
| `$student` | Model | Student record (name, roll_no, dob, etc.) |
| `$organization` | Model | School/org data (name, address, udise_code, etc.) |
| `$savedTableData` | array | Saved table/attendance data |
| `$part` | object | Current page part (`page_no`, `title`, etc.) |

---

## Verification After Implementation

Run:
```bash
php artisan db:seed --class=HPCTemplateSeeder
```

Then generate a PDF for a fourth-template student and visually compare page 1 against the shared PDF:

- [ ] School info block matches PDF layout
- [ ] UDISE + Teacher Code on same line (if PDF shows them together)
- [ ] Grade checkboxes show Grade 9, 10, 11, 12
- [ ] Photograph box is in correct position
- [ ] General info rows match PDF order exactly
- [ ] Attendance table has correct header color and 12 month columns
- [ ] Any fourth-template-specific sections present (Self-Evaluation if on page 1)
- [ ] No Bootstrap classes anywhere
- [ ] No flexbox/grid CSS
- [ ] No JavaScript
- [ ] No empty `str_pad()` calls
- [ ] `page-break-after:always` on page 1 container
