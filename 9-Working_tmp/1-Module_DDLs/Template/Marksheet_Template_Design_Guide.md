# 📄 Marksheet Template Design Guide
> **Module**: Template + MarksheetGeneration  
> **DDL Sources**: `tmp_Config_DDL_v5.sql` | `MSG_DDL_v1.sql`  
> **Version**: 1.0 — April 2026  
> **Purpose**: Complete reference for designing, building, and assigning marksheet templates in Prime-AI

---

## 1. HOW THE SYSTEM WORKS (Big Picture)

```
┌──────────────────────────────────────────────────────────────┐
│   TEMPLATE MODULE (Visual Layer)                             │
│                                                              │
│   tmp_templates     ←── canvas_json / html_content          │
│       ↑                                                      │
│   You design this!  Uses {{variable_name}} placeholders      │
│       ↓                                                      │
│   tmp_templates_variables_jnt  (which vars this template has)│
│       ↓                                                      │
│   tmp_template_assignments  (which class/session uses it)    │
└──────────────────────────────────────────────────────────────┘
                          ↓ at render time
┌──────────────────────────────────────────────────────────────┐
│   MARKSHEET MODULE (Data Layer)                              │
│                                                              │
│   msh_student_results         → overall %, grade, rank       │
│   msh_student_subject_results → per-subject marks, grade     │
│   std_students                → name, photo, DOB             │
│   sch_classes / sch_sections  → class name, section          │
└──────────────────────────────────────────────────────────────┘
                          ↓ TemplateService renders
┌──────────────────────────────────────────────────────────────┐
│   OUTPUT: Final HTML, ready to print as PDF                  │
└──────────────────────────────────────────────────────────────┘
```

**Two independent configurations are combined at render time:**

| Source | Module | Provides |
|--------|--------|----------|
| `msh_config_templates` (via `msh_class_config_jnt`) | MarksheetGeneration | Computation rules: weightages, grading, pass % |
| `tmp_template_assignments` | Template | Visual PDF layout with canvas/HTML |

---

## 2. AVAILABLE VARIABLES — MARKSHEET TYPE

These are the `{{variable_name}}` placeholders you can use in your template HTML.  
All belong to the `MARKSHEET` template type in `tmp_template_variables`.

### 2.1 Student Identity Variables

| Variable Name | Placeholder | Source Table | Source Field | Auto/Manual |
|---|---|---|---|---|
| Student Full Name | `{{student_name}}` | `std_students` | `full_name` | Auto |
| First Name | `{{first_name}}` | `std_students` | `first_name` | Auto |
| Last Name | `{{last_name}}` | `std_students` | `last_name` | Auto |
| Father Name | `{{father_name}}` | `std_students` | `father_name` | Auto |
| Mother Name | `{{mother_name}}` | `std_students` | `mother_name` | Auto |
| Date of Birth | `{{date_of_birth}}` | `std_students` | `date_of_birth` | Auto |
| Gender | `{{gender}}` | `std_students` | `gender` | Auto |
| Admission No | `{{admission_no}}` | `std_students` | `admission_no` | Auto |
| Roll Number | `{{roll_no}}` | `std_students` | `roll_no` | Auto |
| Student Code (QR) | `{{student_code}}` | `std_students` | `student_qr_code` | Auto |
| Student Photo | `{{student_photo}}` | `sys_media` | `photo_path` | Auto |
| Nationality | `{{nationality}}` | `std_student_details` | `nationality` | Auto |
| Blood Group | `{{blood_group}}` | `std_student_details` | `blood_group` | Auto |
| Category | `{{category}}` | `std_student_details` | `social_category` | Auto |

### 2.2 Class & Academic Variables

| Variable Name | Placeholder | Source Table | Source Field | Auto/Manual |
|---|---|---|---|---|
| Class Name | `{{class_name}}` | `sch_classes` | `name` | Auto |
| Section Name | `{{section_name}}` | `sch_sections` | `name` | Auto |
| Class & Section | `{{class_section}}` | computed | — | Manual |
| Academic Session | `{{academic_session}}` | `sch_org_academic_sessions_jnt` | `name` | Auto |
| Academic Year | `{{academic_year}}` | `sch_org_academic_sessions_jnt` | `short_name` | Auto |
| Exam Group / Term | `{{exam_group_name}}` | `msh_exam_groups` | `name` | Manual |

### 2.3 Result Summary Variables (passed by MSG module)

| Variable Name | Placeholder | Source Table | Source Field | Auto/Manual |
|---|---|---|---|---|
| Grand Total Marks | `{{grand_total}}` | `msh_student_results` | `grand_total` | Manual |
| Max Marks Total | `{{grand_max}}` | `msh_student_results` | `grand_max` | Manual |
| Overall Percentage | `{{overall_percentage}}` | `msh_student_results` | `overall_percentage` | Manual |
| Overall Grade | `{{overall_grade}}` | `msh_student_results` | `overall_grade` | Manual |
| Division | `{{division}}` | `msh_student_results` | `division` | Manual |
| Rank in Section | `{{rank_in_section}}` | `msh_student_results` | `rank_in_section` | Manual |
| Rank in Class | `{{rank_in_class}}` | `msh_student_results` | `rank_in_class` | Manual |
| Promotion Status | `{{promotion_status}}` | `msh_student_results` | `promotion_status` | Manual |
| Total Subjects | `{{total_subjects}}` | `msh_student_results` | `total_subjects` | Manual |
| Subjects Passed | `{{subjects_passed}}` | `msh_student_results` | `subjects_passed` | Manual |
| Result Status | `{{result_status}}` | `msh_student_results` | `result_status` | Manual |

### 2.4 Attendance Variables

| Variable Name | Placeholder | Source Table | Source Field | Auto/Manual |
|---|---|---|---|---|
| Total Working Days | `{{total_working_days}}` | `msh_student_attendance` | `total_working_days` | Manual |
| Days Present | `{{days_present}}` | `msh_student_attendance` | `days_present` | Manual |
| Days Absent | `{{days_absent}}` | computed | — | Manual |
| Attendance % | `{{attendance_percentage}}` | computed | — | Manual |

### 2.5 School / Institution Variables

| Variable Name | Placeholder | Source Table | Source Field | Auto/Manual |
|---|---|---|---|---|
| School Name | `{{school_name}}` | `sch_schools` | `name` | Auto |
| School Logo | `{{school_logo}}` | `sch_schools` | `logo_path` | Auto |
| School Address | `{{school_address}}` | `sch_schools` | `address` | Auto |
| School Phone | `{{school_phone}}` | `sch_schools` | `phone` | Auto |
| School Email | `{{school_email}}` | `sch_schools` | `email` | Auto |
| Board Name | `{{board_name}}` | `msh_config_templates` | `board_code` | Manual |
| Print Date | `{{print_date}}` | computed | now() | Manual |
| Academic Period | `{{academic_period}}` | computed | — | Manual |

### 2.6 Per-Subject Variables (Dynamic — rendered as table rows)

> ⚠️ These are NOT single-value variables — they render as a **loop table** in your HTML.  
> The render engine expands the `<!-- SUBJECT_TABLE_START -->` block for each subject.

| Placeholder | Field in `msh_student_subject_results` | Notes |
|---|---|---|
| `{{subject_name}}` | `sch_subjects.name` | Subject display name |
| `{{subject_code}}` | `sch_subjects.code` | e.g. ENG, MAT, SCI |
| `{{theory_marks}}` | `theory_marks` | NULL if no practical |
| `{{practical_marks}}` | `practical_marks` | NULL if no practical |
| `{{exam_weighted_total}}` | `exam_weighted_total` | After weightage |
| `{{ia_total}}` | `ia_total` | Internal assessment total |
| `{{homework_score}}` | `homework_score` | HW component |
| `{{quiz_score}}` | `quiz_score` | Quiz component |
| `{{subject_total}}` | `subject_total` | All components sum |
| `{{subject_max}}` | `subject_max` | Max possible |
| `{{subject_percentage}}` | `subject_percentage` | % |
| `{{subject_grade}}` | `subject_grade` | A1/A2/B1 etc |
| `{{is_passed}}` | `is_passed` | Pass/Fail flag |

### 2.7 Per-Exam-Type Columns (Dynamic — for UT-1, UT-2, HY etc.)

> These expand horizontally inside the subject table for each exam type in the group.

| Placeholder | Field | Notes |
|---|---|---|
| `{{exam_type_name}}` | `lms_exam_types.name` | e.g. UT-1, Half Yearly |
| `{{exam_marks_obtained}}` | `msh_student_subject_exam_marks.marks_obtained` | Can be "AB" if absent |
| `{{exam_max_marks}}` | `msh_student_subject_exam_marks.max_marks` | |
| `{{exam_result_status}}` | `msh_student_subject_exam_marks.result_status` | PASS/FAIL/ABSENT |

### 2.8 Co-Scholastic Variables (Dynamic — rendered as separate table)

| Placeholder | Field | Notes |
|---|---|---|
| `{{coscho_area_name}}` | `msh_template_coscholastic_components.name` | e.g. Work Education |
| `{{coscho_grade}}` | `msh_student_coscholastic_results.grade` | A/B/C |
| `{{coscho_remarks}}` | `msh_student_coscholastic_results.remarks` | Optional |

---

## 3. TEMPLATE DESIGNS

### Design 1: CBSE Term-1 Report Card (A4 Portrait)

**Code**: `CBSE_MARKSHEET_TERM1_V1`  
**Type**: Marksheet  
**Purpose**: `MARKSHEET_PRINT`  
**Scope**: CLASS_SCOPED (assign per class group — Primary, Middle, Secondary)  
**Paper**: A4 Portrait (210mm × 297mm)

```
┌─────────────────────────────────────────────────────────────────┐
│  🏫  {{school_logo}}                                            │
│      {{school_name}}                                            │
│      {{school_address}}                                         │
│      Ph: {{school_phone}} | {{school_email}}                    │
├─────────────────────────────────────────────────────────────────┤
│         REPORT CARD — {{exam_group_name}}                       │
│                 Academic Year: {{academic_year}}                 │
├─────────────────────────────────────────────────────────────────┤
│  📷 {{student_photo}} │ Name    : {{student_name}}              │
│                       │ Class   : {{class_name}}-{{section_name}}│
│                       │ Roll No : {{roll_no}}                   │
│                       │ Adm No  : {{admission_no}}              │
│                       │ DOB     : {{date_of_birth}}             │
│                       │ Father  : {{father_name}}               │
├─────────────────────────────────────────────────────────────────┤
│                    SCHOLASTIC REPORT                            │
├──────────┬─────────┬─────────┬──────┬──────┬──────┬─────┬──────┤
│ Subject  │  UT-1   │  UT-2   │  HY  │ Prac │  IA  │Total│Grade │
│          │ /10     │ /10     │ /80  │ /30  │ /10  │ /100│      │
├──────────┼─────────┼─────────┼──────┼──────┼──────┼─────┼──────┤
│ English  │  8      │  7      │  62  │  —   │  8   │  81 │  A2  │
│ Math     │  9      │  8      │  70  │  —   │  9   │  90 │  A1  │
│ Science  │  7      │  8      │  55  │  25  │  8   │  87 │  A1  │
│ ...      │  ...    │  ...    │  ...│  ... │  ... │ ... │  ... │
├──────────┴─────────┴─────────┴──────┴──────┴──────┴─────┴──────┤
│                   CO-SCHOLASTIC ACTIVITIES                      │
├──────────────────────────────────┬──────────────────────────────┤
│  Work Education                  │  Grade: A                    │
│  Art Education                   │  Grade: B                    │
│  Health & Physical Education     │  Grade: A                    │
│  Discipline                      │  Grade: A                    │
├──────────────────────────────────┴──────────────────────────────┤
│  ATTENDANCE: {{days_present}} / {{total_working_days}} days     │
├─────────────────────────────────────────────────────────────────┤
│  RESULT SUMMARY                                                 │
│  Total: {{grand_total}} / {{grand_max}}                         │
│  Percentage: {{overall_percentage}}%  │  Grade: {{overall_grade}}│
│  Division: {{division}}  │  Rank: {{rank_in_section}}           │
│  Status: {{promotion_status}}                                   │
├─────────────────────────────────────────────────────────────────┤
│  Class Teacher Sign       │  Principal Sign                     │
│  ___________________      │  ______________________             │
│                           │  Date: {{print_date}}               │
└─────────────────────────────────────────────────────────────────┘
```

**HTML Template Code:**

```html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'Times New Roman', serif; font-size: 11px; color: #000; }
  .page { width: 210mm; padding: 8mm; background: white; }
  .header { display: flex; align-items: center; border-bottom: 2px solid #000; padding-bottom: 6px; margin-bottom: 6px; }
  .header img.logo { width: 70px; height: 70px; object-fit: contain; margin-right: 12px; }
  .header .school-info { flex: 1; text-align: center; }
  .header .school-name { font-size: 16px; font-weight: bold; color: #1a3a5c; }
  .header .school-addr { font-size: 9px; color: #555; }
  .title-bar { text-align: center; background: #1a3a5c; color: white; padding: 5px; font-size: 13px; font-weight: bold; margin: 6px 0; }
  .sub-title { text-align: center; font-size: 11px; margin-bottom: 6px; }
  .student-info { display: flex; border: 1px solid #ccc; margin-bottom: 8px; }
  .student-photo { width: 90px; padding: 6px; border-right: 1px solid #ccc; }
  .student-photo img { width: 78px; height: 90px; object-fit: cover; border: 1px solid #999; }
  .student-details { flex: 1; padding: 6px; display: grid; grid-template-columns: 1fr 1fr; gap: 2px 12px; }
  .detail-row { font-size: 10px; }
  .detail-row span { font-weight: bold; }
  .section-title { background: #e8f0fe; border: 1px solid #1a3a5c; font-weight: bold; font-size: 11px; padding: 3px 6px; margin: 6px 0 0 0; }
  table.marks { width: 100%; border-collapse: collapse; font-size: 10px; }
  table.marks th { background: #1a3a5c; color: white; padding: 4px 3px; text-align: center; border: 1px solid #666; }
  table.marks td { padding: 3px; text-align: center; border: 1px solid #ccc; }
  table.marks tr:nth-child(even) { background: #f5f8ff; }
  table.marks tr.total-row { background: #fff3cd; font-weight: bold; }
  .coscho-table { width: 100%; border-collapse: collapse; font-size: 10px; margin-top: 4px; }
  .coscho-table th { background: #2d6a4f; color: white; padding: 3px 6px; border: 1px solid #666; }
  .coscho-table td { padding: 3px 6px; border: 1px solid #ccc; }
  .summary-box { border: 2px solid #1a3a5c; padding: 6px; margin-top: 6px; display: grid; grid-template-columns: 1fr 1fr; gap: 4px; }
  .summary-item { font-size: 11px; }
  .summary-item .label { font-weight: bold; color: #1a3a5c; }
  .result-badge { display: inline-block; padding: 2px 8px; border-radius: 3px; font-weight: bold; }
  .result-promoted { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
  .result-detained { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
  .sign-section { display: flex; justify-content: space-between; margin-top: 12px; border-top: 1px solid #ccc; padding-top: 8px; }
  .sign-box { text-align: center; width: 30%; }
  .sign-line { border-bottom: 1px solid #000; margin-bottom: 3px; height: 30px; }
  .pass { color: #155724; font-weight: bold; }
  .fail { color: #721c24; font-weight: bold; }
  .absent { color: #856404; }
</style>
</head>
<body>
<div class="page">

  <!-- HEADER -->
  <div class="header">
    <img class="logo" src="@{{school_logo}}" alt="School Logo">
    <div class="school-info">
      <div class="school-name">@{{school_name}}</div>
      <div class="school-addr">@{{school_address}}</div>
      <div class="school-addr">Ph: @{{school_phone}} | Email: @{{school_email}}</div>
    </div>
  </div>

  <!-- TITLE -->
  <div class="title-bar">REPORT CARD — @{{exam_group_name}}</div>
  <div class="sub-title">Academic Year: @{{academic_year}} | Board: @{{board_name}}</div>

  <!-- STUDENT INFO -->
  <div class="student-info">
    <div class="student-photo">
      <img src="@{{student_photo}}" alt="Student Photo">
    </div>
    <div class="student-details">
      <div class="detail-row"><span>Name:</span> @{{student_name}}</div>
      <div class="detail-row"><span>Admission No:</span> @{{admission_no}}</div>
      <div class="detail-row"><span>Class:</span> @{{class_name}} - @{{section_name}}</div>
      <div class="detail-row"><span>Roll No:</span> @{{roll_no}}</div>
      <div class="detail-row"><span>Father's Name:</span> @{{father_name}}</div>
      <div class="detail-row"><span>Mother's Name:</span> @{{mother_name}}</div>
      <div class="detail-row"><span>Date of Birth:</span> @{{date_of_birth}}</div>
      <div class="detail-row"><span>Category:</span> @{{category}}</div>
    </div>
  </div>

  <!-- SCHOLASTIC TABLE -->
  <div class="section-title">SCHOLASTIC PERFORMANCE</div>
  <table class="marks">
    <thead>
      <tr>
        <th rowspan="2" style="width:18%">Subject</th>
        <!-- EXAM_COLUMNS_START — engine injects one <th> per exam type -->
        <th>UT-1 (/10)</th>
        <th>UT-2 (/10)</th>
        <th>HY Exam (/80)</th>
        <!-- EXAM_COLUMNS_END -->
        <th>Theory</th>
        <th>Practical</th>
        <th>IA (/10)</th>
        <th>Total (/100)</th>
        <th>%</th>
        <th>Grade</th>
      </tr>
    </thead>
    <tbody>
      <!-- SUBJECT_TABLE_START — engine loops here per subject -->
      <tr>
        <td style="text-align:left; font-weight:bold">@{{subject_name}}</td>
        <!-- EXAM_MARKS_START — engine injects marks per exam type -->
        <td>@{{exam_marks_obtained}}</td>
        <!-- EXAM_MARKS_END -->
        <td>@{{theory_marks}}</td>
        <td>@{{practical_marks}}</td>
        <td>@{{ia_total}}</td>
        <td><strong>@{{subject_total}}</strong></td>
        <td>@{{subject_percentage}}%</td>
        <td style="font-weight:bold">@{{subject_grade}}</td>
      </tr>
      <!-- SUBJECT_TABLE_END -->
      <tr class="total-row">
        <td colspan="7" style="text-align:right">Grand Total</td>
        <td><strong>@{{grand_total}} / @{{grand_max}}</strong></td>
        <td>@{{overall_percentage}}%</td>
        <td>@{{overall_grade}}</td>
      </tr>
    </tbody>
  </table>

  <!-- CO-SCHOLASTIC -->
  <div class="section-title">CO-SCHOLASTIC ACTIVITIES &amp; ATTENDANCE</div>
  <table class="coscho-table">
    <thead>
      <tr>
        <th style="width:40%">Area</th>
        <th style="width:15%">Grade</th>
        <th style="width:45%">Remarks</th>
      </tr>
    </thead>
    <tbody>
      <!-- COSCHO_TABLE_START -->
      <tr>
        <td>@{{coscho_area_name}}</td>
        <td style="text-align:center;font-weight:bold">@{{coscho_grade}}</td>
        <td>@{{coscho_remarks}}</td>
      </tr>
      <!-- COSCHO_TABLE_END -->
      <tr style="background:#f0f8ff">
        <td><strong>Attendance</strong></td>
        <td colspan="2">@{{days_present}} / @{{total_working_days}} days (@{{attendance_percentage}}%)</td>
      </tr>
    </tbody>
  </table>

  <!-- RESULT SUMMARY -->
  <div class="summary-box">
    <div class="summary-item"><span class="label">Grand Total:</span> @{{grand_total}} / @{{grand_max}}</div>
    <div class="summary-item"><span class="label">Percentage:</span> @{{overall_percentage}}%</div>
    <div class="summary-item"><span class="label">Grade:</span> @{{overall_grade}}</div>
    <div class="summary-item"><span class="label">Division:</span> @{{division}}</div>
    <div class="summary-item"><span class="label">Rank (Section):</span> @{{rank_in_section}}</div>
    <div class="summary-item"><span class="label">Rank (Class):</span> @{{rank_in_class}}</div>
    <div class="summary-item">
      <span class="label">Result:</span>
      <span class="result-badge result-promoted">@{{promotion_status}}</span>
    </div>
    <div class="summary-item"><span class="label">Print Date:</span> @{{print_date}}</div>
  </div>

  <!-- SIGNATURES -->
  <div class="sign-section">
    <div class="sign-box">
      <div class="sign-line"></div>
      <div>Class Teacher</div>
    </div>
    <div class="sign-box">
      <div class="sign-line"></div>
      <div>Examination Controller</div>
    </div>
    <div class="sign-box">
      <div class="sign-line"></div>
      <div>Principal</div>
    </div>
  </div>

</div>
</body>
</html>
```

---

### Design 2: Simple Unit Test Marksheet (A4 Landscape)

**Code**: `UNIT_TEST_MARKSHEET_V1`  
**Type**: Marksheet  
**Purpose**: `MARKSHEET_PRINT`  
**Scope**: CLASS_SCOPED  
**Paper**: A4 Landscape (297mm × 210mm) — compact format

```
┌──────────────────────────────────────────────────────┐
│  {{school_logo}} | {{school_name}}                   │
│  UNIT TEST RESULT — {{exam_group_name}}              │
│  {{academic_year}} | Class: {{class_name}}-{{section}}│
├────────┬─────────────┬────────┬──────┬──────┬────────┤
│Name    │ Admission No│ Roll   │ Eng  │ Math │ Science│
│        │             │        │ /30  │ /30  │ /30   │
├────────┼─────────────┼────────┼──────┼──────┼────────┤
│ Rahul  │ ADM/2025/01 │  01   │  28  │  25  │  27   │
│...     │...          │ ...   │ ...  │ ...  │ ...   │
└────────┴─────────────┴────────┴──────┴──────┴────────┘
```

**HTML Template Code:**

```html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  body { font-family: Arial, sans-serif; font-size: 10px; }
  .page { width: 297mm; padding: 6mm; }
  .header { display: flex; align-items: center; gap: 12px; border-bottom: 2px solid #333; padding-bottom: 6px; margin-bottom: 8px; }
  .logo { width: 55px; height: 55px; object-fit: contain; }
  .school-name { font-size: 15px; font-weight: bold; }
  .report-title { font-size: 12px; font-weight: bold; background: #2c3e50; color: white; padding: 4px 10px; margin-bottom: 4px; }
  .meta { font-size: 10px; color: #444; margin-bottom: 8px; }
  table { width: 100%; border-collapse: collapse; font-size: 10px; }
  th { background: #2c3e50; color: white; padding: 5px; border: 1px solid #555; text-align: center; }
  td { padding: 4px; border: 1px solid #ccc; text-align: center; }
  tr:nth-child(even) { background: #f9f9f9; }
  .student-name-col { text-align: left !important; font-weight: bold; }
  .total-col { background: #fff9c4; font-weight: bold; }
  .grade-col { font-weight: bold; color: #1a3a5c; }
</style>
</head>
<body>
<div class="page">
  <div class="header">
    <img class="logo" src="@{{school_logo}}" alt="Logo">
    <div>
      <div class="school-name">@{{school_name}}</div>
      <div class="report-title">UNIT TEST RESULT — @{{exam_group_name}}</div>
      <div class="meta">
        Academic Year: @{{academic_year}} &nbsp;|&nbsp;
        Class: @{{class_name}} - @{{section_name}} &nbsp;|&nbsp;
        Print Date: @{{print_date}}
      </div>
    </div>
  </div>

  <!-- Single student card layout for individual print -->
  <table>
    <tr>
      <th style="width:5%">#</th>
      <th style="width:20%">Student Name</th>
      <th style="width:12%">Admission No</th>
      <th style="width:6%">Roll No</th>
      <!-- EXAM_COLUMNS_START -->
      <th>@{{exam_type_name}} (/@{{exam_max_marks}})</th>
      <!-- EXAM_COLUMNS_END -->
      <th class="total-col">Total (@{{grand_max}})</th>
      <th>%</th>
      <th>Grade</th>
      <th>Result</th>
    </tr>
    <!-- This template is for individual student view — use class list view for bulk -->
    <tr>
      <td>@{{roll_no}}</td>
      <td class="student-name-col">@{{student_name}}</td>
      <td>@{{admission_no}}</td>
      <td>@{{roll_no}}</td>
      <!-- SUBJECT_TOTAL_LOOP -->
      <td>@{{subject_total}}</td>
      <!-- SUBJECT_TOTAL_END -->
      <td class="total-col"><strong>@{{grand_total}}</strong></td>
      <td>@{{overall_percentage}}%</td>
      <td class="grade-col">@{{overall_grade}}</td>
      <td>@{{promotion_status}}</td>
    </tr>
  </table>
</div>
</body>
</html>
```

---

## 4. ASSIGNING A TEMPLATE TO A CLASS

### Step-by-Step Assignment Flow

```
Step 1: Create Template Type (if not seeded)
  → tmp_templates_type: MARKSHEET (already seeded)

Step 2: Define Variables (if not seeded)
  → tmp_template_variables: all variables above (run TemplateVariableSeeder)

Step 3: Design & Save Template
  → tmp_templates: create HTML design with @{{variable}} placeholders
  → tmp_templates_variables_jnt: link which variables this template uses

Step 4: Create Purpose (if not seeded)
  → tmp_template_purposes: MARKSHEET_PRINT (already seeded, CLASS_SCOPED)

Step 5: Assign Template to Class/Group
  → tmp_template_assignments:
      template_id  = your template's ID
      purpose_id   = ID of MARKSHEET_PRINT purpose
      session_id   = current academic session ID
      class_id     = specific class ID (optional)
      class_group_id = class group ID (optional)
      scope_hash   = auto-generated by MySQL
```

### Assignment Scope Rules

| Scenario | Set | Scope Hash Example |
|---|---|---|
| Assign to **Class X specifically** | `class_id = 10, class_group_id = NULL` | `1:3:C10` |
| Assign to **Primary group** (Class 1–5 all) | `class_id = NULL, class_group_id = 1` | `1:3:G1` |
| Assign as **school-wide fallback** | `class_id = NULL, class_group_id = NULL` | `1:3:SCHOOL` |

### Template Resolution Priority at Print Time

```
When student of Class 10-A presses "Print Marksheet":
  ↓
Step 1: Find assignment WHERE class_id = 10 AND purpose = MARKSHEET_PRINT AND session = current
        → If FOUND → use this template ✅

Step 2: Find assignment WHERE class_group has class 10 AND purpose = MARKSHEET_PRINT
        → If FOUND → use this template ✅

Step 3: Find assignment WHERE class_id IS NULL AND class_group_id IS NULL
        → School-wide fallback → If FOUND → use this template ✅

Step 4: No template found → Error: "No marksheet template configured for this class"
```

---

## 5. MARKSHEET MODULE SETUP CHECKLIST

Before a student can print a marksheet, ALL of these must be configured:

### A. MarksheetGeneration Module (Data/Computation Config)
- [ ] `msh_marksheet_types` — Create type: "Term-1 Report Card"
- [ ] `msh_class_groups` — Create groups: Primary (1-5), Middle (6-8), Secondary (9-10)
- [ ] `msh_class_group_items_jnt` — Map classes to groups
- [ ] `msh_exam_groups` — Create: "Term-1" with date range
- [ ] `msh_exam_group_items_jnt` — Link exam types: UT-1, UT-2, Half Yearly
- [ ] `msh_config_templates` — Create computation config: passing %, best-of-N, grading schema
- [ ] `msh_template_scholastic_components` — Set weightages (Exam 80%, IA 20%)
- [ ] `msh_template_exam_weightages` — Set per-exam weightage (UT-1=10, UT-2=10, HY=80)
- [ ] `msh_template_ia_components` — Define IA: Notebook=5, Enrichment=5
- [ ] `msh_template_coscholastic_components` — Define: Work Ed, Art, Health PE, Discipline
- [ ] `msh_class_config_jnt` — Assign config template to class/group
- [ ] `msh_marksheet_schedules` — Create schedule, add class-sections
- [ ] **Run ComputeMarksheetJob** — Populates result tables

### B. Template Module (Visual Layer)
- [ ] Run `TemplateTypeSeeder` — ensures MARKSHEET type exists
- [ ] Run `TemplateVariableSeeder` — seeds all variables
- [ ] **Design template HTML** using this guide
- [ ] Create `tmp_templates` record with html_content
- [ ] Link variables via `tmp_templates_variables_jnt`
- [ ] Create `tmp_template_purposes` — MARKSHEET_PRINT (seeded)
- [ ] **Assign template** via `tmp_template_assignments` for session + class/group

---

## 6. VARIABLE PLACEHOLDER SYNTAX

| Format | Used In | Description |
|---|---|---|
| `@{{variable_name}}` | HTML templates | Standard replacement — renders the value |
| `<!-- SUBJECT_TABLE_START -->` | HTML comment | Loop start marker for subject rows |
| `<!-- SUBJECT_TABLE_END -->` | HTML comment | Loop end marker for subject rows |
| `<!-- EXAM_COLUMNS_START -->` | HTML comment | Dynamic exam columns start |
| `<!-- EXAM_COLUMNS_END -->` | HTML comment | Dynamic exam columns end |
| `<!-- COSCHO_TABLE_START -->` | HTML comment | Co-Scholastic rows loop start |
| `<!-- COSCHO_TABLE_END -->` | HTML comment | Co-Scholastic rows loop end |

> **Important**: The `@{{...}}` prefix (with `@`) is intentional — it avoids conflicts with  
> Blade template syntax `{{...}}` when the HTML is stored in the database.

---

## 7. QUICK-START EXAMPLE (Term-1 CBSE Secondary)

```sql
-- Step 1: Find IDs needed
SELECT id FROM tmp_templates_type WHERE name = 'Marksheet';                  -- e.g. 1
SELECT id FROM tmp_template_purposes WHERE code = 'MARKSHEET_PRINT';        -- e.g. 1
SELECT id FROM sch_org_academic_sessions_jnt WHERE is_current = 1 LIMIT 1;  -- e.g. 3
SELECT id FROM msh_class_groups WHERE code = 'SECONDARY';                   -- e.g. 2

-- Step 2: Create the template (paste your HTML from Section 3)
INSERT INTO tmp_templates (code, name, type_id, html_content, is_active)
VALUES (
  'CBSE_TERM1_SEC_2025',
  'CBSE Secondary Term-1 Report Card 2025-26',
  1,       -- marksheet type_id
  '...your HTML from above...',
  1
);

-- Step 3: Link variables (loop for all variable IDs belonging to MARKSHEET type)
INSERT INTO tmp_templates_variables_jnt (template_id, variable_id, display_order)
SELECT LAST_INSERT_ID(), id, ROW_NUMBER() OVER (ORDER BY id)
FROM tmp_template_variables
WHERE template_type_id = 1 AND is_active = 1;

-- Step 4: Assign to Secondary class group for 2025-26
INSERT INTO tmp_template_assignments
  (template_id, purpose_id, academic_session_id, class_id, class_group_id)
VALUES
  (LAST_INSERT_ID(), 1, 3, NULL, 2);
-- scope_hash auto-generated by MySQL: '1:3:G2'
```

---

## 8. TIPS FOR TEMPLATE DESIGNERS

### Do's ✅
- Always include `{{school_logo}}` and `{{school_name}}` in the header
- Use `{{print_date}}` in the footer for audit trail
- Include `{{promotion_status}}` prominently — this is what parents look for
- Test your HTML in a browser first before saving to the DB
- Use print CSS: `@media print { .no-print { display: none; } }`
- Use `A4` paper size explicitly in CSS: `@page { size: A4 portrait; margin: 10mm; }`

### Don'ts ❌
- Do NOT use Blade syntax `{{ }}` — use `@{{ }}` instead (stored in DB, not compiled)
- Do NOT hardcode marks or grades — they must come from variables
- Do NOT use JavaScript in templates — they render as static HTML for PDF
- Do NOT make the template wider than `210mm` for portrait or `297mm` for landscape
- Do NOT use absolute image paths — use URL-based paths stored in media

### Print-Ready CSS Snippet
```css
@page {
  size: A4 portrait;
  margin: 10mm;
}
@media print {
  body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  .no-print { display: none !important; }
  .page-break { page-break-after: always; }
}
```

---

## 9. VARIABLE SEEDER REFERENCE

These variables must be in `TemplateVariableSeeder.php` under `template_type_id = (MARKSHEET type)`:

```
student_name, first_name, last_name, father_name, mother_name,
date_of_birth, gender, admission_no, roll_no, student_code,
student_photo, nationality, blood_group, category,
class_name, section_name, class_section, academic_session, academic_year,
exam_group_name, board_name, print_date, academic_period,
grand_total, grand_max, overall_percentage, overall_grade, division,
rank_in_section, rank_in_class, promotion_status, total_subjects,
subjects_passed, result_status,
total_working_days, days_present, days_absent, attendance_percentage,
school_name, school_logo, school_address, school_phone, school_email,
subject_name, subject_code, theory_marks, practical_marks,
exam_weighted_total, ia_total, homework_score, quiz_score,
subject_total, subject_max, subject_percentage, subject_grade, is_passed,
exam_type_name, exam_marks_obtained, exam_max_marks, exam_result_status,
coscho_area_name, coscho_grade, coscho_remarks
```

---

*End of Marksheet Template Design Guide v1.0 — Prime-AI MarksheetGeneration + Template Module*
