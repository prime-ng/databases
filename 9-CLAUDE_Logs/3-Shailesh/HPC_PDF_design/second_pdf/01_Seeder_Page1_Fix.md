# HPC Second Template — Seeder Page 1 Fix (`seedPage1Second`)

**Date:** 2026-03-17
**File:** `database/seeders/HPCTemplateSeeder.php`
**Method:** `seedPage1Second(int $tId, int $pId)`
**Template:** Second Template (Grades 3–5, 30 pages)
**Priority:** High

---

## Context

The second template PDF first page has been shared. The `seedPage1Second()` method currently has
incorrect rubric groupings — fields that should be on separate rows are grouped together, and
fields that should be on the same row are separate. Fix them to exactly match the PDF page 
layout `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/9-Clude_Work_Log/3-Shailesh/HPC_PDF_design/second_pdf/12-HPC-Prep_Form-page-1.pdf`.

---

## Architecture Rules (Non-Negotiable)

| # | Rule |
|---|------|
| 1 | One **rubric = one row** in the PDF form |
| 2 | Multiple `ri()` calls on the same rubric = fields displayed **side-by-side on that row** |
| 3 | Each rubric has a unique `SLUG` (UPPER_SNAKE_CASE) and a human-readable label |
| 4 | `display_order` ordinal must match the **top-to-bottom reading order** in the PDF |
| 5 | Do **NOT** change field `html_object_name` keys — they are used in blade + saved values |

---

## Pre-Read (Mandatory)

Read these before making any change:
1. `database/seeders/HPCTemplateSeeder.php` — full `seedPage1Second()` method (lines ~1101–1160)
2. The shared **second template PDF page 1** — identify exact row order and field groupings

---

## Known Issues in Current `seedPage1Second()`

### PART-A(1) — Section 1 (`$s1`)

**Issue 1 — UDISE and Teacher Code are SEPARATE rubrics (ordinals 4 & 5):**
```
Current (WRONG):
$r = $this->insertRubric(..., 'UDISE_CODE',    'UDISE Code',    4, 1);
  $this->ri($r, 'udise_code', 1, ...);
$r = $this->insertRubric(..., 'TEACHER_CODE',  'Teacher Code',  5, 1);
  $this->ri($r, 'teacher_code', 1, ...);

Fix (CORRECT — same row per PDF):
$r = $this->insertRubric($tId, $pId, $s1, 'UDISE_TEACHER', 'UDISE Code and Teacher Code', 4, 1);
  $this->ri($r, 'udise_code',   1, 'Text', 'UDISE Code',   'UDISE Code',   1, '11-digit UDISE code');
  $this->ri($r, 'teacher_code', 2, 'Text', 'Teacher Code', 'Teacher Code', 1, 'Teacher identification code');
```

**Issue 2 — APAAR ID ordinal must become 5 after combining UDISE+Teacher:**
```
Current: ordinal 6
Fix:     ordinal 5
```

### GENERAL INFORMATION — Section 2 (`$s2`)

**Issue 3 — STUDENT_BASIC groups student_name + roll_no + registration_no together:**
```
Current (WRONG):
$r = $this->insertRubric(..., 'STUDENT_BASIC', ..., 1, 1);
  $this->ri($r, 'student_name',    1, ...);
  $this->ri($r, 'roll_no',         2, ...);
  $this->ri($r, 'registration_no', 3, ...);

Fix (CORRECT — each on its own row):
// Row 1 — Student Name alone
$r = $this->insertRubric($tId, $pId, $s2, 'STUDENT_NAME', 'Student Name', 1, 1);
  $this->ri($r, 'student_name', 1, 'Text', 'Student Name', 'Student Name', 1, 'Full name of the student');

// Row 2 — Roll No + Registration No (same row)
$r = $this->insertRubric($tId, $pId, $s2, 'ROLL_REGISTRATION', 'Roll No and Registration No', 2, 1);
  $this->ri($r, 'roll_no',         1, 'Text', 'Roll No.',         'Roll No',         1, 'Student roll number');
  $this->ri($r, 'registration_no', 2, 'Text', 'Registration No.', 'Registration No', 1, 'Student registration number');
```
Update all subsequent rubric ordinals accordingly (GRADE_SELECTION moves to 3, SECTION_DOB_AGE to 4, PHOTOGRAPH to 5, ADDRESS_PHONE to 6).

**Issue 4 — MOTHER_GUARDIAN groups name + education + occupation in same rubric:**
```
Current (WRONG):
$r = $this->insertRubric(..., 'MOTHER_GUARDIAN', ..., 6, 1);
  $this->ri($r, 'mother_name',       1, ...);
  $this->ri($r, 'mother_education',  2, ...);
  $this->ri($r, 'mother_occupation', 3, ...);

Fix (CORRECT — name alone, edu+occ together):
// Mother Name alone
$r = $this->insertRubric($tId, $pId, $s2, 'MOTHER_NAME', 'Mother/Guardian Name', {N}, 1);
  $this->ri($r, 'mother_name', 1, 'Text', 'Mother/Guardian Name', 'Mother/Guardian Name', 1, 'Name of mother or guardian');

// Mother Education + Occupation (same row)
$r = $this->insertRubric($tId, $pId, $s2, 'MOTHER_EDU_OCC', 'Mother/Guardian Education and Occupation', {N+1}, 1);
  $this->ri($r, 'mother_education',  1, 'Text', 'Mother/Guardian Education',  'Mother/Guardian Education',  1, '...');
  $this->ri($r, 'mother_occupation', 2, 'Text', 'Mother/Guardian Occupation', 'Mother/Guardian Occupation', 1, '...');
```
Replace `{N}` with the correct ordinal from the PDF row order.

**Issue 5 — FATHER_GUARDIAN same as Issue 4:**
```
Fix: Split into FATHER_NAME (alone) and FATHER_EDU_OCC (education + occupation same row)
```

**Issue 6 — LANGUAGE_DEMO groups mother_tongue + medium + rural_urban together:**
```
Current (WRONG):
$r = $this->insertRubric(..., 'LANGUAGE_DEMO', ..., 9, 1);
  $this->ri($r, 'mother_tongue',         1, ...);
  $this->ri($r, 'medium_of_instruction', 2, ...);
  $this->ri($r, 'rural_urban',           3, ...);

Fix (CORRECT — rural_urban on its own row):
// Mother Tongue + Medium of Instruction (same row)
$r = $this->insertRubric($tId, $pId, $s2, 'LANGUAGE_INSTRUCTION', 'Mother Tongue and Medium of Instruction', {N}, 1);
  $this->ri($r, 'mother_tongue',         1, 'Text', 'Mother Tongue',         'Mother Tongue',         1, '...');
  $this->ri($r, 'medium_of_instruction', 2, 'Text', 'Medium of Instruction', 'Medium of Instruction', 1, '...');

// Rural/Urban alone
$r = $this->insertRubric($tId, $pId, $s2, 'RURAL_URBAN', 'Rural/Urban', {N+1}, 1);
  $this->ri($r, 'rural_urban', 1, 'Text', 'Rural/Urban', 'Rural/Urban', 1, 'Area classification: Rural or Urban');
```

---

## Additional: Verify PDF-Specific Sections

After fixing the above, cross-check the PDF page 1 for:
- **Grades shown** — second template = Grade 3, Grade 4, Grade 5 (verify checkboxes in seeder)
- **ATTENDANCE section title** — confirm label matches PDF exactly
- **Any section present in PDF but missing in seeder** — add it

---

## Correct Ordinal Sequence (after all fixes)

Update ordinals to match the reading order in the PDF. The expected final sequence for `$s2`:

| Ordinal | Rubric Slug | Fields (same row) |
|---------|-------------|-------------------|
| 1 | `STUDENT_NAME` | student_name |
| 2 | `ROLL_REGISTRATION` | roll_no, registration_no |
| 3 | `GRADE_SELECTION` | grade_grade3, grade_grade4, grade_grade5 |
| 4 | `PHOTOGRAPH` | student_photo |
| 5 | `SECTION_DOB_AGE` | section, dob, age |
| 6 | `ADDRESS_PHONE` | address, phone |
| 7 | `MOTHER_NAME` | mother_name |
| 8 | `MOTHER_EDU_OCC` | mother_education, mother_occupation |
| 9 | `FATHER_NAME` | father_name |
| 10 | `FATHER_EDU_OCC` | father_education, father_occupation |
| 11 | `SIBLINGS` | siblings_count, siblings_age |
| 12 | `LANGUAGE_INSTRUCTION` | mother_tongue, medium_of_instruction |
| 13 | `RURAL_URBAN` | rural_urban |
| 14 | `HEALTH_INFO` | illness_count |

> **Adjust if the shared PDF shows a different order.**

---

## Verification

After changes, run:
```bash
php artisan db:seed --class=HPCTemplateSeeder
```

Check:
- [ ] `seedPage1Second()` has NO grouped rubrics that should be separate rows
- [ ] UDISE + Teacher Code are on same rubric (ordinal 4)
- [ ] APAAR ID is ordinal 5
- [ ] Student Name is its own rubric (ordinal 1 in GENERAL_INFO)
- [ ] Roll No + Registration No are on same rubric (ordinal 2)
- [ ] Mother/Father names are alone on their rows
- [ ] Rural/Urban is its own separate rubric
- [ ] All ordinals are sequential with no gaps
