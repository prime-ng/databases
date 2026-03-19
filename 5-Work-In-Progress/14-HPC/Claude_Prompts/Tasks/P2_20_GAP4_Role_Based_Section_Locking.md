# PROMPT: Implement Role-Based Section Locking — HPC Module
**Task ID:** P2_20
**Issue IDs:** GAP-4
**Priority:** P2-Medium
**Estimated Effort:** 3 days
**Prerequisites:** All P0 and P1 tasks must be complete

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
```

---

## CONTEXT

Currently `formStore()` accepts ALL form fields from ANY authenticated user via `$request->all()`. The HPC report has sections intended for different actors: teacher (74 pages), student (35 sections), parent (9 sections), peer (14 sections). There is no mechanism to lock sections by role — a student should only edit student sections, a teacher only teacher sections, etc. The `hpc_template_rubric_items` table needs an `owner_role` ENUM column, and `formStore()` needs to filter fields by the current user's role.

---

## DESIGN

1. **Schema Change:** Add `owner_role` ENUM('teacher','student','parent','peer','system') column to `hpc_template_section_items` or `hpc_template_rubric_items` table
2. **Seeder Update:** Tag each existing template item with its intended `owner_role` based on the data provider mapping (74 teacher pages, 35 student sections, etc.)
3. **Controller Logic:** `formStore()` filters incoming fields — only accepts fields where the item's `owner_role` matches the current user's role
4. **UI Indication:** Read-only visual styling for sections the user cannot edit (greyed out, lock icon)

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Http/Controllers/HpcController.php` — `formStore()` method
2. `{MODULE_PATH}/app/Models/HpcTemplateSectionItems.php` — current schema
3. `{MODULE_PATH}/app/Models/HpcTemplateRubricItems.php` — current schema
4. Existing HPC migration files for table structure reference

---

## STEPS

1. Create migration to add `owner_role` ENUM column to the appropriate items table
2. Update the model's `$fillable` to include `owner_role`
3. Create a seeder or migration that tags existing items with correct roles based on the gap analysis data provider mapping
4. Modify `formStore()` to:
   a. Determine current user's role (teacher/student/parent/peer)
   b. Load allowed field names for that role from the template items
   c. Filter `$request` to only include allowed fields
   d. Return 403 if user tries to submit fields outside their role
5. Update form blade partials to add `disabled` attribute on inputs where `owner_role != current_user_role`

---

## ACCEPTANCE CRITERIA

- Each template item has an `owner_role` tag
- `formStore()` rejects fields that don't match the user's role
- Teacher can only fill teacher sections (74 pages)
- Student sections appear read-only to teachers (visual indication)
- Migration is additive (no data loss)

---

## DO NOT

- Do NOT implement the student/parent/peer portals (those are P3 tasks)
- Do NOT change the form layout or page structure
- Do NOT modify PDF generation
