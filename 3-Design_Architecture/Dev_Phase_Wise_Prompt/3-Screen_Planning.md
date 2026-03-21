# Phase 3 — Screen Planning (YOU Decide)
========================================



## CONFIGURATION
----------------
MODULE_CODE       = ACC                    # Used in: issue codes (BUG-HPC-001), section headers, AI Brain lookups
MODULE            = Accounting             # Used in: issue codes (BUG-HPC-001), section headers, AI Brain lookups
MODULE_DIR        = Modules/Accounting/    # Used in: file paths (Modules/Hpc/), git commands
BRANCH            = Brijesh_Accounting     # Used in: context for the prompt
DEVELOPER         = Brijesh                 # Used in: context for the prompt
RBS_MODULE_CODE   = K
DB_TABLE_PREFIX   = acc_
DATABASE_NAME     = tenant_db
DATE              = 20th Mar 2026         # Used in: git --since filter (Tier 3)


### This is the NEW phase that replaces wireframes

After reviewing the DDL, you now know exactly what tables and columns exist. NOW you tell Claude how to organize them into screens.

### What YOU Provide

Fill in this template and give it to Claude:

```markdown
# [MODULE_NAME] — Screen Planning

## I have reviewed the DDL. Here is how I want the screens organized:

### Master Index Page (Tab-Based)
Tab 1: [Entity1 Name] — show columns: [col1, col2, col3]
Tab 2: [Entity2 Name] — show columns: [col1, col2, col3]
Tab 3: [Entity3 Name] — show columns: [col1, col2, col3]
(OR: No master page — each entity gets its own page)

### Screen Combinations
- [Entity1] and [Entity2] should be on the SAME create form (two sections)
- [Entity3] gets its own separate create/edit form
- [Entity4] is a child of [Entity3] — show as a tab on Entity3's show page

### Form Layouts
- [Entity1] create form: Two-column layout
- [Entity2] create form: Single column with tabs (Tab 1: Basic Info, Tab 2: Details)
- [Entity3] create form: Simple single column

### Special Screens
- Dashboard with: [chart type] showing [what data]
- Report page with: [filters] and [export options]
- (OR: No special screens for now — just CRUD)

### Notes
- [Entity5] is a lookup table — only needs a simple CRUD, no fancy UI
- [Entity6] is read-only — no create/edit, just index + show
```

### Prompt 3A — Claude Confirms Screen Plan

```
## Confirm Screen Plan

I have provided my screen planning decisions above.

Based on my decisions and the DDL from Phase 2, confirm:
1. How many Blade view files will be created?
2. How many controllers are needed?
3. Which entities share a controller vs have their own?
4. Which views are tab-based vs standalone?

List every file that will be created in Phase 5 (Frontend) so I can approve before proceeding.
```

### Quality Gate 3
- [ ] You've decided: which tables = which screens
- [ ] You've decided: tabs vs separate pages
- [ ] You've decided: form layout (columns, tabs, sections)
- [ ] Claude has confirmed the file list and you've approved it


