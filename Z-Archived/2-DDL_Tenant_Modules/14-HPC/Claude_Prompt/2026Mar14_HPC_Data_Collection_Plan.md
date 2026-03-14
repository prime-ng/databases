# HPC Module — Multi-Actor Data Collection Implementation Plan
**Date:** 2026-03-14
**Module:** Hpc (Holistic Progress Card)
**Prerequisite:** Read `2026Mar14_HPC_Gap_Analysis.md` first
**Estimated Total Effort:** ~8-10 developer-weeks across 5 phases

---

## Goal

Enable Students, Teachers, and Parents to independently fill their respective sections of the HPC Report Card through role-specific interfaces, reducing teacher data entry burden by ~60% and improving data quality through direct input from each stakeholder.

---

## Phase 0: Foundation Fixes (Week 1)
> **Priority: CRITICAL — Must do before any new feature work**

### 0.1 Security Fixes
| Task | File | Effort |
|------|------|--------|
| Add `Gate::authorize()` to all 12 HpcController public methods | `HpcController.php` | 1h |
| Fix 7 FormRequests with hardcoded `return true` in `authorize()` | 7 Request files | 1h |
| Add `EnsureTenantHasModule::class.':HPC'` to HPC route group | `routes/tenant.php` L2498 | 5min |
| Empty `Modules/Hpc/routes/web.php` and `api.php` scaffold routes | 2 files | 5min |
| Fix garbled permission string in `HpcTemplatesController::show()` | `HpcTemplatesController.php` L97 | 2min |

### 0.2 Routing Fixes
| Task | File | Effort |
|------|------|--------|
| Add 4 missing `use` imports (HpcTemplates*, Parts*, Sections*, Rubrics*) | `routes/tenant.php` | 5min |
| Remove/fix 3 routes to non-existent methods (hpcSecondForm, hpcThredForm, hpcFourthForm) | `routes/tenant.php` | 15min |
| Reorder all `trash/view` routes BEFORE `Route::resource()` | `routes/tenant.php` | 30min |
| Remove orphan import `LearningActivityController` (singular) | `routes/tenant.php` L19 | 2min |

### 0.3 Model Fixes
| Task | File | Effort |
|------|------|--------|
| Fix uppercase class refs in HpcTemplates model (HPCTemplateSections → HpcTemplateSections) | `HpcTemplates.php` | 10min |
| Fix wrong Student import in StudentHpcSnapshot (SchoolSetup → StudentProfile) | `StudentHpcSnapshot.php` | 5min |
| Add `created_by` to $fillable in 18 models | 18 model files | 30min |

**Phase 0 Total: ~1 day**

---

## Phase 1: Role-Based Section Ownership (Week 2)
> **Goal: Tag every rubric item with WHO should fill it, enforce write permissions**

### 1.1 Schema Change — Add `owner_role` to Template Rubric Items

```sql
-- Migration: add_owner_role_to_hpc_template_rubric_items
ALTER TABLE hpc_template_rubric_items
  ADD COLUMN `owner_role` ENUM('TEACHER','STUDENT','PARENT','PEER','SYSTEM')
  NOT NULL DEFAULT 'TEACHER' AFTER `description`;
```

**Why:** Each rubric item (form field) gets tagged with who owns it. This is the foundation for all subsequent phases. The `SYSTEM` role covers auto-populated fields (attendance, student master data).

### 1.2 Seed Owner Roles

Create a seeder that tags existing rubric items based on their section codes:

| Section Pattern | Owner Role | Example Pages (T4) |
|----------------|------------|---------------------|
| `*_SELF_EVAL*`, `*_GOALS*`, `*_TIME*`, `*_FUTURE*`, `*_ACCOMPLISH*` | STUDENT | 2-12 |
| `*_LEARNER_REFLECT*`, `*_INQUIRY*` | STUDENT | 19-20, 22, 24, 26 |
| `*_TEACHER_ASSESS*`, `*_STAGE_DESC*`, `*_CLASSROOM*`, `*_CREDITS*` | TEACHER | 13-15, 21, 23, 25, 29-32, 38-42 |
| `*_PEER_ASSESS*`, `*_PEER_FB*` | PEER | 16 (right), 17/27/33 (peer section) |
| `*_PARENT_OBS*`, `*_PARENT_FB*`, `*_HOME_RES*` | PARENT | T1-T3 parent sections |
| `*_ATTENDANCE*`, `*_BASIC_INFO*` | SYSTEM | Page 1 |

### 1.3 Enforce Write Permissions in formStore()

Modify `HpcController::formStore()` to check `owner_role` before saving:

```php
// In formStore(), after loading report and template:
$userRole = $this->resolveHpcRole($request->user()); // TEACHER, STUDENT, PARENT, PEER

// When iterating form fields:
foreach ($fields as $fieldId => $value) {
    $rubricItem = $rubricItemMap[$fieldId] ?? null;
    if ($rubricItem && $rubricItem->owner_role !== $userRole && $userRole !== 'TEACHER') {
        continue; // Skip fields that don't belong to this role
        // Exception: Teachers can fill any section (backup entry)
    }
    // ... save as normal
}
```

**Teachers retain ability to fill ANY section** (they're the fallback for absent stakeholders).

### 1.4 Visual Section Locking in Form UI

In the web form view, add visual indicators:
- Green border: "Your section — please fill"
- Grey background + lock icon: "Filled by [Teacher/Student/Parent]"
- Fields owned by other roles become `readonly` for non-teachers

**Phase 1 Total: ~3 days**

---

## Phase 2: Student Self-Service (Weeks 3-4)
> **Goal: Students fill their own self-reflection, goals, and project planning sections**

### 2.1 Student HPC Route Group

Add to `routes/tenant.php`:

```php
// Student-facing HPC routes (inside StudentPortal middleware group)
Route::middleware(['auth', 'verified', 'role:student'])
    ->prefix('student-portal/hpc')
    ->name('student-portal.hpc.')
    ->group(function () {
        Route::get('/', [StudentHpcFormController::class, 'index']);           // List my reports
        Route::get('/{report}/fill', [StudentHpcFormController::class, 'fill']);  // Fill my sections
        Route::post('/{report}/save', [StudentHpcFormController::class, 'save']); // Save my sections
    });
```

### 2.2 New Controller: StudentHpcFormController

```
Modules/Hpc/app/Http/Controllers/StudentHpcFormController.php
```

| Method | Purpose |
|--------|---------|
| `index()` | Show list of HPC reports assigned to this student (where status = 'Draft' and student's sections not yet complete) |
| `fill($report)` | Render the form showing ONLY sections where `owner_role = 'STUDENT'` as editable. Teacher/parent sections shown read-only. |
| `save($report)` | Save only fields where `owner_role = 'STUDENT'`. Validates student owns this report (`$report->student_id === auth()->user()->student_id`). |

### 2.3 Student Form View

Create `Modules/Hpc/resources/views/student-form/fill.blade.php`:
- Reuses the same per-page Blade partials as the teacher form
- But wraps non-student sections in `<fieldset disabled>` with a lock overlay
- Shows a progress indicator: "You've completed 8/20 sections"
- Submit button saves ONLY student-owned fields

### 2.4 Teacher Dashboard Integration

On the teacher's student list view, add status badges per student:

| Badge | Meaning |
|-------|---------|
| "Student: Pending" (yellow) | Student hasn't started self-reflection |
| "Student: In Progress" (blue) | Student partially complete |
| "Student: Done" (green) | Student completed all their sections |

Query: Count `hpc_report_items` where `rubric_item.owner_role = 'STUDENT'` and `assessed_by = student_user_id`.

### 2.5 Notification Trigger

When teacher creates/opens a report for a student:
1. Auto-create the `hpc_reports` record (status = 'Draft')
2. Send notification to the student: "Your HPC self-reflection is ready to fill. Please complete by [date]."
3. Use existing Notification module (`Modules/Notification/`) channels

**Phase 2 Total: ~5 days**

---

## Phase 3: Parent Data Collection (Weeks 4-5)
> **Goal: Parents provide home observations and feedback via shared link**

### 3.1 Approach: Token-Based Shared Links (No Parent Login Required)

Parents in Indian K-12 schools often don't have individual login credentials. Instead of building a full parent portal, use **time-limited signed URLs**:

```php
// Generate parent link
$url = URL::temporarySignedRoute(
    'hpc.parent-form',
    now()->addDays(14),  // 2-week expiry
    ['report' => $report->id, 'token' => $parentToken]
);
// Example: https://school.prime-ai.com/hpc/parent/fill?report=42&token=abc123&signature=xyz
```

### 3.2 Schema Addition — Parent Token

```sql
-- Migration: add_parent_token_to_hpc_reports
ALTER TABLE hpc_reports
  ADD COLUMN `parent_token` VARCHAR(64) NULL AFTER `status`,
  ADD COLUMN `parent_completed_at` TIMESTAMP NULL AFTER `parent_token`,
  ADD INDEX `idx_reports_parent_token` (`parent_token`);
```

### 3.3 Parent Form Controller

```
Modules/Hpc/app/Http/Controllers/ParentHpcFormController.php
```

| Method | Purpose |
|--------|---------|
| `fill($report)` | Validate signed URL + token. Render ONLY `owner_role = 'PARENT'` sections. No auth required. |
| `save($report)` | Save only parent-owned fields. Set `parent_completed_at`. Mark `assessed_by = NULL` (no user ID for parents). |

### 3.4 Parent Form View

Create `Modules/Hpc/resources/views/parent-form/fill.blade.php`:
- Standalone page (no admin layout, no sidebar)
- School branding header (logo, name)
- Student name displayed (not editable)
- Only parent sections shown:
  - **T1:** Parent Observation checklist + Comments
  - **T2:** Home Resources checkboxes + 10 Feedback Questions + Support Plan
  - **T3:** Home Resources + Parent Self-Evaluation + Feedback Suggestions
  - **T4:** No parent sections (skip entirely)
- "Thank you" confirmation page after submit
- Mobile-responsive (parents use phones)

### 3.5 Teacher Triggers Parent Link

On the teacher's student list, add a "Send to Parent" button per student:
1. Generates signed URL with parent_token
2. Sends via SMS/WhatsApp to guardian's phone (from `std_student_details.mobile`)
3. Also sends via email if guardian email exists
4. Shows "Link sent" badge on student row

### 3.6 Parent Status Tracking

| Badge | Meaning |
|-------|---------|
| "Parent: Not Sent" (grey) | Link not yet generated |
| "Parent: Pending" (yellow) | Link sent, no response yet |
| "Parent: Done" (green) | `parent_completed_at` is set |
| "Parent: Expired" (red) | Link expired without response |

**Phase 3 Total: ~4 days**

---

## Phase 4: Auto-Feed from System Data (Weeks 5-6)
> **Goal: Reduce manual entry by pulling data from other modules**

### 4.1 Attendance Auto-Population

**Currently:** Teacher manually enters attendance in the HPC form.
**Fix:** Auto-populate from `std_student_attendance` when report is created/opened.

```php
// In HpcController::hpc_form() or HpcReportService
$attendance = StudentAttendance::where('student_id', $studentId)
    ->whereBetween('attendance_date', [$sessionStart, $sessionEnd])
    ->selectRaw("
        MONTH(attendance_date) as month,
        COUNT(*) as working_days,
        SUM(CASE WHEN status = 'PRESENT' THEN 1 ELSE 0 END) as days_present
    ")
    ->groupBy('month')
    ->get();
// Auto-fill attendance fields in hpc_report_items
```

### 4.2 Student Master Data Auto-Population

**Currently:** Some fields auto-populate (name, DOB), but address, guardian details, religion, etc. require manual entry for some templates.
**Fix:** On report creation, auto-copy ALL relevant student fields:
- From `std_students`: name, gender, DOB, aadhar, apaar
- From `std_student_details`: father/mother name, occupation, education, mobile, siblings
- From `std_student_profiles`: mother_tongue, medium_of_instruction
- From `std_student_academic_sessions`: roll_no, house
- From `sch_organizations`: school_name, UDISE, address

### 4.3 hpc_student_evaluation → Report Auto-Feed

**Currently:** Teachers enter Awareness/Sensitivity/Creativity ratings in `hpc_student_evaluation` via a dedicated CRUD screen AND separately re-enter the same data in the HPC form.
**Fix:** When opening the HPC form, pre-populate pages 29-30, 36-37 from `hpc_student_evaluation`:

```php
$evaluations = StudentHpcEvaluation::where('student_id', $studentId)
    ->where('academic_session_id', $sessionId)
    ->with(['abilityParameter', 'performanceDescriptor', 'subject'])
    ->get();
// Map to rubric items for pages P29_AWARENESS, P29_SENSITIVITY, P30_CREATIVITY
```

### 4.4 Future: LMS Integration (Post-MVP)

When LMS modules mature, auto-feed:
| Source | Target HPC Section | Mapping |
|--------|-------------------|---------|
| `lms_exam` scores | Teacher Assessment (p13-15, 21, 23, 25) | Subject score → competency descriptor |
| `lms_quiz` results | Stage Assessment | Quiz performance → skill level |
| `lms_homework` completion | Activity Tracking (p39) | Completion rate → hours logged |
| `std_student_attendance` | Page 1 attendance table | Already possible (4.1 above) |

**Phase 4 Total: ~4 days**

---

## Phase 5: Workflow & Notifications (Weeks 6-7)
> **Goal: Enforce Draft → Review → Published lifecycle**

### 5.1 Workflow State Machine

```
                    Teacher opens
                         │
                         ▼
                    ┌─────────┐
                    │  Draft   │◄───── Student/Parent can edit
                    └────┬────┘
                         │ Teacher clicks "Submit for Review"
                         ▼
                   ┌──────────┐
                   │ Submitted │──── Notification → Principal
                   └────┬─────┘
                        │ Principal approves
                        ▼
                   ┌──────────┐
                   │  Final   │──── Locked. No more edits.
                   └────┬─────┘
                        │ Admin publishes
                        ▼
                   ┌──────────┐
                   │ Published │──── Visible to student/parent
                   └──────────┘
```

### 5.2 Schema Addition

```sql
ALTER TABLE hpc_reports
  ADD COLUMN `submitted_at` TIMESTAMP NULL AFTER `status`,
  ADD COLUMN `submitted_by` INT UNSIGNED NULL AFTER `submitted_at`,
  ADD COLUMN `reviewed_at` TIMESTAMP NULL AFTER `submitted_by`,
  ADD COLUMN `reviewed_by` INT UNSIGNED NULL AFTER `reviewed_at`,
  ADD COLUMN `published_at` TIMESTAMP NULL AFTER `reviewed_by`,
  ADD COLUMN `published_by` INT UNSIGNED NULL AFTER `published_at`;
```

### 5.3 Notifications

| Event | Recipient | Channel |
|-------|-----------|---------|
| Report created | Student | In-app + email |
| Parent link generated | Parent | SMS + WhatsApp |
| Student completes sections | Teacher | In-app |
| Parent completes sections | Teacher | In-app |
| Teacher submits for review | Principal | In-app + email |
| Principal approves | Teacher | In-app |
| Report published | Student + Parent | In-app + email + SMS |

### 5.4 Completion Dashboard

Create `Modules/Hpc/resources/views/dashboard/completion.blade.php`:

```
Class 10-A (Term 1, 2026-27)
┌──────────┬──────────┬──────────┬──────────┬──────────┐
│ Student  │ Student  │ Parent   │ Teacher  │ Status   │
│ Name     │ Sections │ Sections │ Sections │          │
├──────────┼──────────┼──────────┼──────────┼──────────┤
│ Aarav S. │ ██████░░ │ N/A      │ ████░░░░ │ Draft    │
│ Priya M. │ ████████ │ N/A      │ ████████ │ Final    │
│ Rahul K. │ ░░░░░░░░ │ N/A      │ ██░░░░░░ │ Draft    │
└──────────┴──────────┴──────────┴──────────┴──────────┘
         ■ Complete  ░ Pending
```

**Phase 5 Total: ~4 days**

---

## Implementation Timeline

```
Week 1:  Phase 0 — Foundation Fixes (security, routing, models)
Week 2:  Phase 1 — Role-Based Section Ownership (schema + enforcement)
Week 3:  Phase 2 — Student Self-Service (controller + views + notifications)
Week 4:  Phase 2 (cont.) + Phase 3 start — Parent Token Links
Week 5:  Phase 3 (cont.) + Phase 4 — Auto-Feed from System Data
Week 6:  Phase 5 — Workflow + Dashboard
Week 7:  Testing + Polish + Documentation
```

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Students don't complete sections | Teacher retains ability to fill all sections; deadline reminders via Notification module |
| Parents don't click link | SMS reminder after 5 days; teacher can enter on behalf; link re-generation |
| Peer assessment bias/bullying | Teacher reviews all peer input before finalizing; optional anonymization |
| Migration breaks existing data | All schema changes are additive (new columns with defaults); no drops or renames |
| Student portal not ready | Student HPC form can work standalone with `role:student` middleware, independent of StudentPortal module completion |

---

## Success Metrics

| Metric | Before | After (Target) |
|--------|--------|----------------|
| Teacher time per student per term (T4) | ~60 min | ~25 min |
| Student sections filled by student directly | 0% | 80%+ |
| Parent response rate | 0% (teacher guesses) | 50%+ |
| Reports published on time | Unknown | 90%+ |
| Data accuracy (self-reflection) | Low (teacher proxy) | High (direct input) |

---

## Files to Create/Modify

### New Files
| File | Phase |
|------|-------|
| `database/migrations/tenant/2026_03_15_add_owner_role_to_hpc_template_rubric_items.php` | 1 |
| `database/migrations/tenant/2026_03_15_add_parent_token_to_hpc_reports.php` | 3 |
| `database/migrations/tenant/2026_03_15_add_workflow_columns_to_hpc_reports.php` | 5 |
| `Modules/Hpc/app/Http/Controllers/StudentHpcFormController.php` | 2 |
| `Modules/Hpc/app/Http/Controllers/ParentHpcFormController.php` | 3 |
| `Modules/Hpc/resources/views/student-form/fill.blade.php` | 2 |
| `Modules/Hpc/resources/views/parent-form/fill.blade.php` | 3 |
| `Modules/Hpc/resources/views/dashboard/completion.blade.php` | 5 |
| `Modules/Hpc/app/Services/HpcWorkflowService.php` | 5 |
| `Modules/Hpc/app/Services/HpcAutoFeedService.php` | 4 |

### Modified Files
| File | Phase | Changes |
|------|-------|---------|
| `HpcController.php` | 0, 4 | Add Gate::authorize; auto-feed attendance/student data |
| `HpcReportService.php` | 1, 4 | Add role-check on save; add auto-feed methods |
| `routes/tenant.php` | 0, 2, 3 | Fix imports/routes; add student/parent route groups |
| `HpcTemplates.php` (model) | 0 | Fix uppercase class refs |
| 7 FormRequest files | 0 | Fix hardcoded `return true` |
| `student-list/index.blade.php` | 2, 3 | Add completion badges, parent link button |
| `HpcReport.php` (model) | 3, 5 | Add parent_token, workflow columns to $fillable |
| `HpcTemplateRubricItems.php` (model) | 1 | Add owner_role to $fillable |
