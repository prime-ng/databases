# MSG Screen Design Specification — Part 3: Review, Publication, PDF & Portal
**Screens:** SC-MSG-13 to SC-MSG-15 + Portal Views | **Date:** 2026-04-13

---

## SC-MSG-13: Individual Student Marksheet Preview

### Screen Identity
| Item | Value |
|---|---|
| Route | `marksheet-generation.schedules.student-preview` |
| Controller | `ResultReviewController@studentPreview` |
| Tables | All 6 result tables |
| Actors | Super Admin, Principal, Coordinator, Class Teacher, Subject Teacher |
| Permission | `msg.report.student` |

### Layout — Full Marksheet (matches PDF output)
```
┌─────────────────────────────────────────────────────────────────────────┐
│                     [School Logo]  ABC PUBLIC SCHOOL                    │
│                     Affiliated to CBSE (Aff. No: 2730XXX)               │
│                     REPORT CARD — Session 2025-26 (Term-1)              │
├─────────────────────────────────────────────────────────────────────────┤
│  Student Name: Aarav Sharma          Class: IX-A                        │
│  Roll No: 01                          DOB: 2011-05-15                   │
│  Admission No: ADM/2020/0042         Mother: Priya Sharma               │
│  Father: Rajesh Sharma                                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  PART A — SCHOLASTIC AREAS                                              │
│                                                                         │
│  ┌──────────────┬──────┬──────┬──────┬──────┬──────┬───────┬──────┐     │
│  │ Subject      │ UT-1 │ UT-2 │  HY  │  NB  │ Enr. │ Total │ Grd  │     │
│  │              │ (10) │ (10) │ (80) │ (5)  │ (5)  │ (100) │      │     │
│  ├──────────────┼──────┼──────┼──────┼──────┼──────┼───────┼──────┤     │
│  │ English      │   8  │   7  │  64  │   4  │   4  │   87  │  A2  │     │
│  │ Hindi        │   9  │   8  │  72  │   5  │   5  │   99  │  A1  │     │
│  │ Mathematics  │   7  │   6  │  58  │   4  │   3  │   78  │  B1  │     │
│  │ Science*     │   8  │   7  │52+25 │   3  │   4  │   99  │  A1  │     │
│  │  └ Theory    │      │      │  52  │      │      │   74  │      │     │
│  │  └ Practical │      │      │  25  │      │      │   25  │      │     │
│  │ Social Sci   │   6  │   7  │  60  │   4  │   4  │   81  │  A2  │     │
│  │ Computer*    │   9  │   9  │56+28 │   5  │   5  │  112  │  A1  │     │
│  │  └ Theory    │      │      │  56  │      │      │   84  │      │     │
│  │  └ Practical │      │      │  28  │      │      │   28  │      │     │
│  ├──────────────┼──────┼──────┼──────┼──────┼──────┼───────┼──────┤     │
│  │ Grand Total  │      │      │      │      │      │  556  │  A2  │     │
│  └──────────────┴──────┴──────┴──────┴──────┴──────┴───────┴──────┘     │
│  * Subjects with Theory + Practical split                               │
│                                                                         │
│  PART B — CO-SCHOLASTIC AREAS                                           │
│  ┌──────────────────────────────────┬───────┐                           │
│  │ Work Education                   │   A   │                           │
│  │ Art Education                    │   B   │                           │
│  │ Health & Physical Education      │   A   │                           │
│  └──────────────────────────────────┴───────┘                           │
│                                                                         │
│  PART C — DISCIPLINE                                                    │
│  ┌──────────────────────────────────┬───────┐                           │
│  │ Overall Discipline Grade         │   A   │  (from BehaviouralAssmt)  │
│  └──────────────────────────────────┴───────┘                           │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │ Attendance: 110 / 114 working days                               │   │
│  │ Overall Percentage: 92.67%    Overall Grade: A1                  │   │
│  │ Rank: 3 / 42     Division: First Division                        │   │
│  │ Result: PROMOTED to Class X                                      │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  Class Teacher: _______________   Principal: _______________            │
│  Date: 2025-11-30                                                       │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                    [Download PDF]  [Print]  [Back to Review Grid]       │
└─────────────────────────────────────────────────────────────────────────┘
```

### Data Sources
| Section | Tables |
|---|---|
| Student Header | `std_students` (name, admission_no, dob), parent info from guardian tables, `sch_class_section_jnt` (class, section) |
| Part A — Scholastic | `msh_student_subject_exam_marks` (per-exam marks), `msh_student_ia_marks` (IA marks), `msh_student_subject_results` (totals, grades), `msh_subject_practical_configs` (theory/practical flag) |
| Part B — Co-Scholastic | `msh_student_coscholastic_results` (grades per area) |
| Part C — Discipline | `msh_student_coscholastic_results` WHERE `is_ba_linked=1` |
| Footer | `msh_student_attendance` (working days, present), `msh_student_results` (percentage, grade, rank, division, promotion_status) |
| School Header | School name/logo from SchoolSetup config (`sch_organizations`), board affiliation |

### Behaviour
- Layout exactly matches the PDF output (WYSIWYG preview)
- [Download PDF] → generates DomPDF and serves download (signed URL)
- [Print] → browser print dialog (CSS `@media print` styles)
- Subjects with practical: show theory + practical sub-rows
- AB/WH cells show styled badges
- Navigation: [Previous Student] / [Next Student] arrows in header
- Class Teacher name from `sch_class_section_jnt.class_teacher_id` → `sch_employees.name`

---

## SC-MSG-14: Publication & Lock

### Screen Identity
| Item | Value |
|---|---|
| Route | `marksheet-generation.schedules.publish`, `.lock`, `.unlock` |
| Controller | `PublicationController` |
| Table | `msh_marksheet_schedules`, `msh_computation_logs` |
| Actors | Super Admin, Principal |
| Permission | `msg.publish.execute`, `msg.publish.lock`, `msg.publish.unlock` |

### Layout
```
┌─────────────────────────────────────────────────────────────────────────┐
│ Publication Control: Term-1 Report Card - Secondary 2025-26             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Current Status:  🔵 REVIEWED                                           │
│  Last Computed:   2025-11-25 14:32:05                                   │
│  Total Students:  200                                                   │
│  Computed By:     Admin (admin@school.com)                              │
│                                                                         │
│  ┌─ Summary ────────────────────────────────────────────────────────┐   │
│  │ Class-Sections: 9-A, 9-B, 10-A, 10-B, 11-A (5 sections)          │   │
│  │ Promoted: 185 | Compartment: 8 | Detained: 4 | Withheld: 3       │   │
│  │ IA Marks Entered: 200/200 ✅                                     │   │
│  │ Co-Scholastic Entered: 200/200 ✅                                │   │
│  │ Attendance Entered: 198/200 ⚠️ (2 missing)                       │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─ Actions ────────────────────────────────────────────────────────┐   │
│  │                                                                  │   │
│  │  [🟢 PUBLISH MARKSHEETS]                                         │   │
│  │  This will:                                                      │   │
│  │  • Make marksheets visible to students and parents               │   │
│  │  • Lock the config template (no changes allowed)                 │   │
│  │  • Send notification to 200 students + parents                   │   │
│  │  • This action can be reversed via Unlock (admin only)           │   │
│  │                                                                  │   │
│  │  ⚠️ 2 students have missing attendance. Continue anyway?         │   │
│  │                                                                  │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─ Audit Log ──────────────────────────────────────────────────────┐   │
│  │ Date                │ Action    │ By          │ Remarks          │   │
│  │ 2025-11-25 14:32   │ COMPUTE   │ Admin       │ 200 students      │   │
│  │ 2025-11-26 10:15   │ RECOMPUTE │ Admin       │ Marks fix         │   │
│  │ 2025-11-27 09:00   │ REVIEWED  │ Principal   │ Approved          │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Actions by Status
| Current Status | Available Actions | Button Style | Confirmation |
|---|---|---|---|
| COMPUTED | [Mark as Reviewed] | Blue | Simple confirm |
| REVIEWED | [Publish Marksheets] | Green | Modal: "This will notify X students + parents. Proceed?" |
| PUBLISHED | [Lock] | Dark Grey | Modal: "Lock permanently? Unlock will require admin approval." |
| PUBLISHED | [Unlock] (Admin only) | Red outline | Modal with mandatory reason textarea (min 10 chars) |
| LOCKED | [Unlock] (Admin only) | Red outline | Same modal as above |

### Unlock Modal
```
┌───────────────────────────────────────────────────┐
│ Unlock Published Marksheet                        │
│                                                   │
│ ⚠️ This will allow re-computation of results.     │
│                                                   │
│ Reason (required):                                │
│ ┌───────────────────────────────────────────────┐ │
│ │ Marks correction for Student Diya Gupta in    │ │
│ │ Mathematics UT-2. Teacher entered 8 instead   │ │
│ │ of 18.                                        │ │
│ └───────────────────────────────────────────────┘ │
│                                                   │
│ This action will be logged permanently.           │
│                                                   │
│                     [Cancel]  [Unlock & Revert]   │
└───────────────────────────────────────────────────┘
```

### Data Sources for Audit Log
| Column | Source |
|---|---|
| Date | `msh_computation_logs.started_at` |
| Action | `msh_computation_logs.action` |
| By | `msh_computation_logs.triggered_by` → `sys_users.name` |
| Remarks | `msh_computation_logs.remarks` |

---

## SC-MSG-15: Marksheet PDF Download

### Screen Identity
| Item | Value |
|---|---|
| Route | `marksheet-generation.schedules.pdf.student` / `.pdf.bulk` |
| Controller | `MarksheetPdfController` |
| Actors | All roles (with permission scoping) |
| Permission | `msg.report.download` |

### Layout: Download Options (within Schedule Dashboard or Review Grid)
```
┌─────────────────────────────────────────────────────────────────────────┐
│ Download Marksheets: Term-1 Report Card - Secondary 2025-26             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Individual Student:                                                    │
│  Class-Section: [9-A  ▼]     Student: [Aarav Sharma  ▼]                 │
│                                        [📥 Download PDF]                │
│                                                                         │
│  ─────────────────────── OR ────────────────────────                    │
│                                                                         │
│  Bulk Download (entire class-section):                                  │
│  Class-Section: [9-A  ▼]    (42 students)                               │
│                               [📥 Download ZIP (42 PDFs)]               │
│                                                                         │
│  ─────────────────────── OR ────────────────────────                    │
│                                                                         │
│  All Class-Sections in Schedule:                                        │
│  (200 students across 5 sections)                                       │
│                               [📥 Download All (200 PDFs)]              │
│                                                                         │
│  ⚠️ Large downloads are queued. You'll be notified when ready.          │
└─────────────────────────────────────────────────────────────────────────┘
```

### PDF Spec (DomPDF — follows D13 HPC pattern)
| Item | Spec |
|---|---|
| Engine | DomPDF (`barryvdh/laravel-dompdf`) |
| Template | `resources/views/pdf/marksheet_pdf.blade.php` |
| CSS | Inline styles only. `$css` array. No external stylesheets |
| Layout | `<table>` based. No flexbox/grid. No JavaScript |
| Page Size | A4 portrait |
| School Logo | Base64-encoded from school config |
| Fonts | Default DomPDF fonts (DejaVu Sans) |
| Filename | `Marksheet_{StudentName}_{Class}_{Schedule}.pdf` |

### URL Security
| Scenario | URL Type |
|---|---|
| Admin/Teacher download | Direct route with Gate::authorize |
| Student/Parent download | `URL::temporarySignedRoute()` — 24-hour expiry |

---

## Student Portal View: Marksheet List + Detail

### Screen Identity
| Item | Value |
|---|---|
| Route | `student-portal.marksheets.index` / `.show` |
| Controller | StudentPortal module — new controller method or existing portal controller |
| Permission | `msg.report.student` (scoped to own student_id) |

### Layout: Marksheet List (within Student Portal)
```
┌─────────────────────────────────────────────────────────────────────────┐
│ 📋 My Marksheets                                                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─ 2025-26 ─────────────────────────────────────────────────────────┐  │
│  │                                                                   │  │
│  │  📄 Term-1 Report Card                     Published: 2025-11-30  │  │
│  │     Class: IX-A | Grade: A2 | Rank: 3/42                          │  │
│  │     [View Marksheet]  [Download PDF]                              │  │
│  │                                                                   │  │
│  │  📄 UT-1 Result                            Published: 2025-09-15  │  │
│  │     Class: IX-A | Overall: 87%                                    │  │
│  │     [View Marksheet]  [Download PDF]                              │  │
│  │                                                                   │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌─ 2024-25 ─────────────────────────────────────────────────────────┐  │
│  │  📄 Annual Report Card                     Published: 2025-04-10  │  │
│  │     Class: VIII-A | Grade: A2 | Rank: 5/40                        │  │
│  │     [View Marksheet]  [Download PDF]                              │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

### Data Source
```sql
SELECT ms.id, ms.name, ms.schedule_date, sr.overall_percentage,
       sr.overall_grade, sr.rank_in_section, sr.promotion_status
FROM msh_marksheet_schedules ms
JOIN msh_student_results sr ON sr.schedule_id = ms.id
JOIN sys_dropdown_table sdt ON ms.status_id = sdt.id
WHERE sr.student_id = {current_student_id}
  AND sdt.value = 'PUBLISHED'
  AND ms.is_active = 1
ORDER BY ms.academic_session_id DESC, ms.schedule_date DESC
```

### Security
- Query ALWAYS filtered by `student_id = Auth::user()->student->id`
- No student_id parameter in URL — derived from session
- [Download PDF] generates signed URL: `URL::temporarySignedRoute('marksheet-generation.schedules.pdf.student', now()->addHours(24), [schedule, student])`

---

## Parent Portal View: Child's Marksheets

### Screen Identity
| Item | Value |
|---|---|
| Route | `parent-portal.marksheets.index` / `.show` |
| Controller | ParentPortal module — new controller method |
| Permission | `msg.report.student` (scoped to linked children) |

### Layout: Same as Student Portal but with Child Selector
```
┌─────────────────────────────────────────────────────────────────────────┐
│ 📋 Marksheets                                                           │
│                                                                         │
│  Child: [Aarav Sharma (IX-A)  ▼]   ← only shows linked children         │
│         [Ananya Sharma (VI-B) ]                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  (Same marksheet list layout as Student Portal, filtered by selected    │
│   child's student_id)                                                   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Security
- Child selector populated from parent's linked children (guardian ↔ student relationship)
- `ParentChildPolicy` verifies parent can only access their own children's data
- URL parameter = child's student_id, validated against parent's linked children
- PDF download uses same signed URL mechanism
