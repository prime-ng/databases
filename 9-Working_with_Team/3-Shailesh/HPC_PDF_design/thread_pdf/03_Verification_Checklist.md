# HPC Third Template — Verification Checklist

**Date:** 2026-03-17
**Template:** Third Template (Grades 6–8, 46 pages)
**Seeder Method:** `seedPage1Third(int $tId, int $pId)`
**Blade File:** `Modules/Hpc/resources/views/hpc_form/pdf/third_pdf.blade.php`
**PDF Reference:** `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/9-Clude_Work_Log/3-Shailesh/HPC_PDF_design/thread_pdf/13-HPC-Middle_Form-page-1.pdf`

---

## Step 1 — Run the Seeder

```bash
php artisan db:seed --class=HPCTemplateSeeder
```

Check for no PHP errors. If seeder fails, fix before proceeding.

---

## Step 2 — Seeder Data Verification

Open a DB client (TablePlus / MySQL Workbench) and run:

```sql
-- Get template ID for third template
SELECT id, name FROM hpc_templates WHERE slug = 'third' OR name LIKE '%third%' OR name LIKE '%middle%';

-- Get all page 1 rubrics (replace {tId} with actual template ID)
SELECT r.display_order, r.slug, r.label, ri.html_object_name, ri.display_order AS field_order
FROM hpc_template_rubrics r
JOIN hpc_template_rubric_items ri ON ri.rubric_id = r.id
JOIN hpc_template_section_table s ON r.section_id = s.id
WHERE r.template_id = {tId}
  AND s.page_id = (SELECT id FROM hpc_template_pages WHERE template_id = {tId} AND page_no = 1)
ORDER BY s.display_order, r.display_order, ri.display_order;
```

### Seeder Checklist — PART-A(1)

| # | Check | Expected |
|---|-------|----------|
| 1 | SCHOOL_NAME ordinal | 1 |
| 2 | VILLAGE_BRC_CRC ordinal | 2 |
| 3 | STATE_PINCODE ordinal | 3 |
| 4 | UDISE_TEACHER ordinal | 4 — **both** `udise_code` AND `teacher_code` in same rubric |
| 5 | APAAR_ID ordinal | 5 |
| 6 | No separate UDISE_CODE rubric | Must NOT exist as a standalone rubric |
| 7 | No separate TEACHER_CODE rubric | Must NOT exist as a standalone rubric |

### Seeder Checklist — GENERAL INFORMATION

| Ordinal | Slug | Fields | Check |
|---------|------|--------|-------|
| 1 | `STUDENT_NAME` | `student_name` only | [ ] |
| 2 | `ROLL_REGISTRATION` | `roll_no`, `registration_no` | [ ] |
| 3 | `GRADE_SELECTION` | `grade_grade6`, `grade_grade7`, `grade_grade8` | [ ] |
| 4 | `SECTION_DOB_AGE` | `section`, `dob`, `age` | [ ] |
| 5 | `PHOTOGRAPH` | `student_photo` | [ ] |
| 6 | `ADDRESS_PHONE` | `address`, `phone` | [ ] |
| 7 | `MOTHER_NAME` | `mother_name` only | [ ] |
| 8 | `MOTHER_EDU_OCC` | `mother_education`, `mother_occupation` | [ ] |
| 9 | `FATHER_NAME` | `father_name` only | [ ] |
| 10 | `FATHER_EDU_OCC` | `father_education`, `father_occupation` | [ ] |
| 11 | `SIBLINGS` | `siblings_count`, `siblings_age` | [ ] |
| 12 | `LANGUAGE_INSTRUCTION` | `mother_tongue`, `medium_of_instruction` | [ ] |
| 13 | `RURAL_URBAN` | `rural_urban` only | [ ] |
| 14 | `HEALTH_INFO` | `illness_count` | [ ] |

### Seeder Checklist — Critical Checks

- [ ] No ordinal gaps (1, 2, 3 … sequential with no skips)
- [ ] No duplicate ordinals within the same section
- [ ] `STUDENT_BASIC` rubric does NOT exist (was the old wrong grouping)
- [ ] `MOTHER_GUARDIAN` rubric does NOT exist (was the old wrong grouping)
- [ ] `FATHER_GUARDIAN` rubric does NOT exist (was the old wrong grouping)
- [ ] `LANGUAGE_DEMO` rubric does NOT exist (was the old wrong grouping)
- [ ] `RURAL_URBAN` is a separate rubric, NOT a field inside LANGUAGE_INSTRUCTION

---

## Step 3 — Grade Key Verification

Verify grade checkbox `html_object_name` values in DB:

```sql
SELECT html_object_name, label, display_order
FROM hpc_template_rubric_items
WHERE rubric_id = (
    SELECT id FROM hpc_template_rubrics
    WHERE template_id = {tId} AND slug = 'GRADE_SELECTION'
    AND section_id IN (SELECT id FROM hpc_template_section_table WHERE page_id = (
        SELECT id FROM hpc_template_pages WHERE template_id = {tId} AND page_no = 1
    ))
);
```

Expected results:
- `grade_grade6` | Grade 6 | 1
- `grade_grade7` | Grade 7 | 2
- `grade_grade8` | Grade 8 | 3

If wrong, fix by replacing the grade loop with explicit `ri()` calls.

---

## Step 4 — PDF Generation Verification

1. Log in as a tenant school admin
2. Navigate to HPC → select a student assigned to the **third template** (middle school, Grades 6-8)
3. Generate the PDF
4. **Compare page 1 against `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/9-Clude_Work_Log/3-Shailesh/HPC_PDF_design/thread_pdf/13-HPC-Middle_Form-page-1.pdf`**

### PDF Layout Checklist — Page 1

#### School Information Block
- [ ] School name displays correctly
- [ ] Village / BRC / CRC on one row
- [ ] State and pin code present
- [ ] UDISE Code (11 boxes) and Teacher Code on the **same line**
- [ ] APAAR ID on its own line below UDISE/Teacher

#### General Information Block
- [ ] Student Name on its own row
- [ ] Roll No and Registration No on the same row
- [ ] Grade checkboxes show: Grade 6 ☐, Grade 7 ☐, Grade 8 ☐
- [ ] Photograph box visible in correct position
- [ ] Section, DOB, Age on same row
- [ ] Address and Phone on same row
- [ ] Mother Name on its own row
- [ ] Mother Education + Occupation on same row
- [ ] Father Name on its own row
- [ ] Father Education + Occupation on same row
- [ ] Siblings count and age on same row
- [ ] Mother Tongue + Medium of Instruction on same row
- [ ] Rural/Urban on its own separate row
- [ ] Health/Illness info visible

#### Attendance Table
- [ ] Header row: MONTHS | APR | MAY | JUN | JUL | AUG | SEP | OCT | NOV | DEC | JAN | FEB | MAR
- [ ] Header background color matches PDF
- [ ] Working Days row present
- [ ] Present/Attendance row present
- [ ] Reason row present (if shown in PDF)

#### Page Boundary
- [ ] Page 1 ends cleanly — `page-break-after:always` applied
- [ ] Page 2 starts with **ALL ABOUT ME** section (not mixed into page 1)

#### General Layout
- [ ] No Bootstrap classes visible
- [ ] No flexbox/grid layout issues
- [ ] All text uses DejaVu Sans font
- [ ] No PHP errors or blade errors in logs

---

## Step 5 — Common Issues to Check

| Issue | How to Check | Fix |
|-------|-------------|-----|
| `str_pad()` ValueError | PHP error log | Replace with for-loop character access |
| Missing `$v` closure | PHP error: undefined variable | Add `$v` inside `@php` block |
| Wrong grade checkboxes | Grade 3/4/5 shown instead of 6/7/8 | Fix grade keys in seeder |
| Photo not showing | Empty box in PDF | Check `Storage::disk('public')->exists()` path |
| Ordinal gaps in seeder | DB query shows gap | Re-number all ordinals sequentially |
| Grade loop generates wrong keys | DB shows wrong html_object_name | Replace loop with explicit `ri()` calls |
| ALL ABOUT ME on page 1 | Content bleeds across page break | Ensure `page-break-after:always` on page 1 div |

---

## Architecture Reference

### File Locations
```
database/seeders/HPCTemplateSeeder.php        ← Seeder
Modules/Hpc/resources/views/hpc_form/pdf/     ← PDF blade templates
  ├── first_pdf.blade.php   (Template 1, reference implementation)
  ├── second_pdf.blade.php  (Template 2)
  ├── third_pdf.blade.php   (Template 3, Grades 6-8 — this template)
  └── fourth_pdf.blade.php  (Template 4, Grades 9-12)
```

### Third Template Page 2 Context
Page 2 seeder (`seedPage2Third`) creates:
- `ALL_ABOUT_ME` section → live_with, live_place, siblings_no, languages
- `MY_GOALS` section → goal_school, goal_outside, how_achieve
- `MY_LEARNINGS` section → best_learning, apply_learning, improve_next_year

These are Grade 6-8 specific sections that come **after** page 1.

### Key Tables
```
hpc_templates                  — Template definitions
hpc_template_pages             — Pages per template
hpc_template_section_table     — Sections per page
hpc_template_rubrics           — One row per rubric (= one form row)
hpc_template_rubric_items      — Fields within a rubric (side-by-side)
```

---

## Sign-Off

After all checks pass, mark the task complete:

```
✅ seedPage1Third() — Seeder fixed and verified
✅ third_pdf.blade.php page 1 — PDF design matches 13-HPC-Middle_Form (1)-1.pdf
✅ No PHP errors
✅ No ordinal gaps
✅ Grade checkboxes: Grade 6, 7, 8
✅ Grade html_object_name keys correct (grade_grade6, etc.)
✅ Page 2 ALL ABOUT ME starts on separate page
```
