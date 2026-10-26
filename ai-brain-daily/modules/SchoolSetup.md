# Module: SchoolSetup

Append-only rollup. Newest entries at the bottom.

## 2026-10-20 — Role dashboard + login redirect merged

- **Commit:** `25b7d5121` (merge; authored on `development`)
- **Files:** `RoleDashboard` model, `sys_role_dashboards` migration, `RoleDashboardSeeder`, `RoleDashboardController`/`Request`, `LoginRedirectResolver`, role/dashboard tab view, `UserRolePrmController`, `Role`, routes, permission sync.
- **What:** Per-role dashboard configuration and login redirect resolution.
- **Why:** Branch sync with `development`.
- **Status:** Merged
- **Report:** `ai-brain-daily/daily/2026-10-20.md` (Appendix B)

## 2026-10-21 — Model/service fixes; role dashboards moved to Dashboard

- **Commit:** `2bbab7987` (Tarun) + moves in `7cc9ac488`
- **Files:** 9 unique (plus 3-4 paths moved from SchoolSetup to Dashboard)
- **What:** SchoolSetup model/service fixes; role-dashboard code consolidated under Dashboard.
- **Status:** Done
- **Report:** `ai-brain-daily/daily/2026-10-21.md`

## 2026-10-23 — Room/RoomType active checks, inactive section deactivation cascade & Subject Study Format modal layout/auto-fill

- **Commits:** `f57974331`, `4a6f35905`, `d5efbe3bc`, `3184a8d8a`
- **Files:** `Modules/SchoolSetup/app/Http/Controllers/SectionController.php`, `Modules/SchoolSetup/app/Http/Controllers/SubjectClassMappingController.php`, `Modules/SchoolSetup/app/Http/Controllers/SubjectGroupController.php`, `Modules/SchoolSetup/app/Http/Controllers/SubjectStudyFormatController.php`, `Modules/SchoolSetup/app/Http/Requests/SchoolClassRequest.php`, `Modules/SchoolSetup/app/Models/Room.php`, `Modules/SchoolSetup/app/Models/SubjectGroup.php`, `Modules/SchoolSetup/app/Models/SubjectStudyFormat.php`, `Modules/SchoolSetup/resources/views/school-class/partials/section/_scripts.blade.php`, `Modules/SchoolSetup/resources/views/school-class/partials/subject-study-format/create.blade.php`, `Modules/SchoolSetup/resources/views/school-class/partials/subject-study-format/edit.blade.php`, `public/backend/js/subject-study-format.js`
- **What:**
  - **Room & RoomType Active Scoping:** Added `scopeActive()` to `Room.php` and enforced active room validation across `SchoolClassRequest`, `SubjectClassMappingController`, and `RequirementConsolidationController`.
  - **Inactive Section Cascading:** Deactivating a section now immediately cascades deactivation to `ClassSection`, filters out inactive sections from Stream and Subject Group dropdowns, and dynamically hides deactivated sections from the modal DOM without page refresh.
  - **Subject Study Format Modal:** Widened modal to `modal-xl`, positioned Subject (Optional/Both) as column 1, and automated derivation of Option Code, Option Short Name, and Option Name on subject selection.
- **Verified:** `php -l` passed (0 syntax errors); frontend modal interactions and dynamic AJAX dropdowns verified.
- **Status:** Done
- **Report:** [daily/2026-10-23.md](../daily/2026-10-23.md)

## 2026-10-24 — SectionController & SchoolClassController Audit Remediation & Comprehensive Audit Reports
- **Agents:** antigravity
- **Work done:**
  - Audited and generated complete reports and fix plans for 36 controllers in `final-audit-reports/shailesh/SchoolSetup/` (25,813 lines).
  - Refactored `SectionController.php` (commit `afb0c16f3`): Wrapped database mutating operations in `DB::transaction()`, eliminated raw exception message leakage to clients, enforced Gate permissions checks outside `try` blocks, removed debug statements.
  - Refactored `SchoolClassController.php` (commit `f8c675a3c`): Enforced `DB::transaction()` across all mutating methods (`store`, `update`, `sectionWithClassUpdate`, `destroy`, `toggleStatus`, `updateStudentCounts`, `restore`, `forceDelete`), moved `Gate::authorize()` and `Gate::any()` outside try blocks, sanitized error messages, added strict PHP return types.
- **Files changed:**
  - `Modules/SchoolSetup/app/Http/Controllers/SchoolClassController.php` (M)
  - `Modules/SchoolSetup/app/Http/Controllers/SectionController.php` (M)
  - `final-audit-reports/shailesh/SchoolSetup/*` (73 files) (A)
- **Commits:** `3ccb91fd1`, `afb0c16f3`, `f8c675a3c`
- **Status:** Done
- **Open items:** Continue refactoring remaining controllers following their audit fix plans.
- **Evidence:** [daily/2026-10-24.md](../daily/2026-10-24.md)
