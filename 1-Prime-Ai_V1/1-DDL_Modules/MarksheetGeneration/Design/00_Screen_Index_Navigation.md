# MSG — Screen Design Master Index & Navigation Flow
**Module:** MarksheetGeneration | **Date:** 2026-04-13 | **Total Screens:** 19

---

## Screen Index

| Screen ID | Screen Name | File | Actor(s) | Route |
|---|---|---|---|---|
| **MASTERS & CONFIGURATION** | | `01_Masters_Configuration_Screens.md` | | |
| SC-MSG-01 | Marksheet Type Master | Part 1 | Admin, Principal | `marksheet-types.*` |
| SC-MSG-07a | Class Group Management | Part 1 | Admin, Principal | `class-groups.*` |
| SC-MSG-02 | Exam Group Setup | Part 1 | Admin, Principal, Coordinator | `exam-groups.*` |
| SC-MSG-03 | Config Template Builder (5 tabs) | Part 1 | Admin, Principal | `config-templates.create/edit` |
| SC-MSG-04 | Exam Weightage Setup (Tab 3 of Template) | Part 1 | Admin, Principal | (within template) |
| SC-MSG-05 | IA Component Setup (Tab 4 of Template) | Part 1 | Admin, Principal, Coordinator | (within template) |
| SC-MSG-06 | Co-Scholastic Area Setup (Tab 5 of Template) | Part 1 | Admin, Principal, Coordinator | (within template) |
| SC-MSG-07 | Class/Group Template Assignment | Part 1 | Admin, Principal | `config-templates.assign` |
| SC-MSG-08 | Practical Configuration | Part 1 | Admin, Principal, Coordinator | `practical-configs.*` |
| **SCHEDULE & COMPUTATION** | | `02_Schedule_Entry_Screens.md` | | |
| SC-MSG-09 | Marksheet Schedule Dashboard | Part 2 | All config roles | `schedules.index` |
| SC-MSG-10 | Marksheet Schedule Setup | Part 2 | Admin, Principal | `schedules.create/edit` |
| SC-MSG-11 | Computation Progress (Livewire) | Part 2 | All config roles | `schedules.progress` |
| SC-MSG-12a | IA Marks Entry Grid | Part 2 | Teacher, Coordinator | `schedules.ia-marks` |
| SC-MSG-06a | Co-Scholastic Entry Grid | Part 2 | Class Teacher, Coordinator | `schedules.coscholastic` |
| SC-MSG-09a | Attendance Entry | Part 2 | Class Teacher, Coordinator | `schedules.attendance` |
| SC-MSG-12 | Result Review Grid (Livewire) | Part 2 | Principal, Teacher | `schedules.review` |
| **REVIEW, PUBLICATION & PDF** | | `03_Review_Publication_Portal_Screens.md` | | |
| SC-MSG-13 | Individual Student Marksheet Preview | Part 3 | All config roles | `schedules.student-preview` |
| SC-MSG-14 | Publication & Lock | Part 3 | Admin, Principal | `schedules.publish/lock/unlock` |
| SC-MSG-15 | PDF Download | Part 3 | All roles (scoped) | `schedules.pdf.student/bulk` |
| Portal-S | Student Portal — Marksheet List & View | Part 3 | Student | `student-portal.marksheets.*` |
| Portal-P | Parent Portal — Marksheet List & View | Part 3 | Parent | `parent-portal.marksheets.*` |

---

## Screen Navigation Flow

```
                        ┌─────────────────┐
                        │   SIDE MENU      │
                        │  "Marksheet      │
                        │   Generation"    │
                        └────────┬─────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              ▼                  ▼                  ▼
     ┌────────────────┐ ┌──────────────┐  ┌──────────────────┐
     │ SC-MSG-01      │ │ SC-MSG-07a   │  │ SC-MSG-09        │
     │ Marksheet      │ │ Class Group  │  │ Schedule         │
     │ Types          │ │ Management   │  │ Dashboard        │
     └────────────────┘ └──────────────┘  └────────┬─────────┘
              │                                     │
              ▼                            ┌────────┼───────────────┐
     ┌────────────────┐                   ▼        ▼               ▼
     │ SC-MSG-02      │          ┌─────────────┐ ┌──────────┐ ┌────────────┐
     │ Exam Group     │          │ SC-MSG-10   │ │ [Action  │ │ SC-MSG-15  │
     │ Setup          │          │ Schedule    │ │  Dropdown│ │ PDF        │
     └────────────────┘          │ Setup       │ │  per row]│ │ Download   │
              │                  └─────────────┘ └────┬─────┘ └────────────┘
              ▼                                       │
     ┌────────────────┐              ┌────────────────┼───────────────────┐
     │ SC-MSG-03      │              ▼                ▼                   ▼
     │ Config         │     ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
     │ Template       │     │ SC-MSG-11    │  │ SC-MSG-12a   │  │ SC-MSG-14    │
     │ Builder        │     │ Computation  │  │ IA Marks     │  │ Publication  │
     │ ┌────────────┐ │     │ Progress     │  │ Entry        │  │ & Lock       │
     │ │Tab1: Basic │ │     │ (Livewire)   │  ├──────────────┤  └──────┬───────┘
     │ │Tab2: Comp. │ │     └──────┬───────┘  │ SC-MSG-06a   │         │
     │ │Tab3: ExWt  │ │            │          │ Co-Scholastic│         ▼
     │ │Tab4: IA    │ │            ▼          │ Entry        │  ┌──────────────┐
     │ │Tab5: CoSch │ │     ┌──────────────┐  ├──────────────┤  │ Notifications│
     │ └────────────┘ │     │ SC-MSG-12    │  │ SC-MSG-09a   │  │ → Students   │
     └────────┬───────┘     │ Result       │  │ Attendance   │  │ → Parents    │
              │             │ Review Grid  │  │ Entry        │  │ → Teachers   │
              ▼             │ (Livewire)   │  └──────────────┘  └──────────────┘
     ┌────────────────┐     └──────┬───────┘
     │ SC-MSG-07      │            │
     │ Class/Group    │            ▼
     │ Assignment     │     ┌──────────────┐
     └────────────────┘     │ SC-MSG-13    │
              │             │ Student      │
              ▼             │ Marksheet    │──── [Download PDF] ──→ SC-MSG-15
     ┌────────────────┐     │ Preview      │
     │ SC-MSG-08      │     └──────────────┘
     │ Practical      │
     │ Config         │
     └────────────────┘


PORTAL FLOWS (separate entry points):

     ┌──────────────────┐          ┌──────────────────┐
     │ Student Portal   │          │ Parent Portal    │
     │ Dashboard        │          │ Dashboard        │
     └────────┬─────────┘          └────────┬─────────┘
              │                             │
              ▼                             ▼
     ┌──────────────────┐          ┌──────────────────┐
     │ Portal-S         │          │ Portal-P         │
     │ My Marksheets    │          │ Child Marksheets │
     │ (list)           │          │ (child selector) │
     └────────┬─────────┘          └────────┬─────────┘
              │                             │
              ▼                             ▼
     ┌──────────────────┐          ┌──────────────────┐
     │ Marksheet Detail │          │ Marksheet Detail │
     │ (same as MSG-13) │          │ (same as MSG-13) │
     │ [Download PDF]   │          │ [Download PDF]   │
     └──────────────────┘          └──────────────────┘
```

---

## User Journey: Configuration Workflow (one-time setup)

```
1. Admin creates Marksheet Types (SC-MSG-01)
   → "Unit Test", "Term-1 Report Card", "Annual Report Card"

2. Admin creates Class Groups (SC-MSG-07a)
   → PRIMARY (1-5), MIDDLE (6-8), SECONDARY (9-12)

3. Admin creates Exam Groups (SC-MSG-02)
   → TERM1 = [UT-1, UT-2, HY-EXAM]
   → TERM2 = [UT-3, UT-4, ANNUAL-EXAM]
   → ANNUAL = [ALL exam types]

4. Admin creates Config Template (SC-MSG-03)
   → Tab 1: Basic info (type=Term-1, group=TERM1, grading=CBSE)
   → Tab 2: Components (Exam=80%, HW=5%, Quiz=5%, Quest=10%)
   → Tab 3: Exam Weightage (UT-1=10%, UT-2=10%, HY=80%)
   → Tab 4: IA Components (Notebook=5, Enrichment=5)
   → Tab 5: Co-Scholastic (Work Ed, Art, Health & PE, Discipline→BA)

5. Admin assigns template to Class Group (SC-MSG-07)
   → "CBSE Secondary Term-1" → SECONDARY group

6. Coordinator configures Practical split (SC-MSG-08)
   → Science (Theory=70, Practical=30)
   → Computer Science (Theory=50, Practical=50)
```

## User Journey: Result Generation Workflow (per term)

```
1. Admin creates Schedule (SC-MSG-10)
   → "Term-1 Report Card - Secondary 2025-26"
   → Selects class-sections: 9-A, 9-B, 10-A, 10-B, 11-A

2. Teachers enter IA marks (SC-MSG-12a)
   → Each subject teacher enters Notebook + Enrichment per student

3. Class teachers enter Co-Scholastic grades (SC-MSG-06a)
   → Work Ed, Art, Health & PE = A/B/C per student
   → Discipline auto-populated from BA module

4. Class teachers enter Attendance (SC-MSG-09a)
   → Working days + Days present per student

5. Admin triggers Computation (SC-MSG-09 → SC-MSG-11)
   → System computes: exam marks → component aggregation → subject totals
     → grades → ranks → division → promotion status

6. Principal reviews results (SC-MSG-12)
   → Matrix grid: Student × Subject × Exam
   → Flags anomalies (AB, WH, very low scores)
   → [Mark as Reviewed]

7. Admin publishes (SC-MSG-14)
   → Status → PUBLISHED
   → Template locked
   → Notifications sent to students + parents

8. Students/Parents view on portal (Portal-S / Portal-P)
   → See marksheet, download PDF
```

---

## Livewire Components Summary

| Component | Screen | Purpose |
|---|---|---|
| `ComputationProgressComponent` | SC-MSG-11 | Real-time job progress with 2s polling. Per-class-section bars. Error log. |
| `ResultReviewGridComponent` | SC-MSG-12 | Dynamic column generation per template config. Sortable. Sticky columns. Inline statistics. |

---

## Component Technology Map

| Screen | Primary Tech | Alpine.js | Livewire | Notes |
|---|---|---|---|---|
| SC-MSG-01 | Blade + CRUD | Toggle, delete confirm modal | No | Simple CRUD |
| SC-MSG-07a | Blade + chips | Add/remove class chips | No | Tag-style UI |
| SC-MSG-02 | Blade + checkboxes | Drag reorder | No | Checkbox list |
| SC-MSG-03 | Blade + tabs | Tab switching, real-time sum validation, conditional show | No | 5-tab form |
| SC-MSG-07 | Blade + split panel | Template selection, assignment actions | No | Split layout |
| SC-MSG-08 | Blade + grid | Checkbox toggle, conditional fields | No | Class-Subject grid |
| SC-MSG-09 | Blade + table | Status badges, action dropdown | No | Dashboard list |
| SC-MSG-10 | Blade + form | Template-dependent class filtering | No | Create form |
| SC-MSG-11 | **Livewire** | — | **Yes** (2s poll) | Progress bars |
| SC-MSG-12a | Blade + grid | Tab navigation between cells | No | Data entry grid |
| SC-MSG-06a | Blade + grid | Dropdown per cell | No | Grade entry grid |
| SC-MSG-09a | Blade + grid | Apply-to-all helper | No | Attendance grid |
| SC-MSG-12 | **Livewire** | — | **Yes** | Dynamic columns, sort |
| SC-MSG-13 | Blade (read-only) | Print button | No | Matches PDF layout |
| SC-MSG-14 | Blade + modals | Unlock reason modal | No | Publication actions |
| SC-MSG-15 | Blade | Download buttons | No | PDF download |
| Portal-S | Blade (read-only) | — | No | Signed URL downloads |
| Portal-P | Blade (read-only) | Child selector dropdown | No | Signed URL downloads |
