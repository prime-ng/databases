# PROMPT: Update AI Brain from HPC Gap Analysis (2026-03-16)

## Mode
Standard mode. This is a FILE UPDATE task — read source, update targets. **No code changes.**

---

## CONFIGURATION
```
AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
DB_REPO        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
SOURCE_FILE    = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning/2-Gap_Analysis/HPC_Gap_Analysis_Complete.md
DATE           = 2026-03-16
```

---

## TASK

Read the HPC Complete Gap Analysis file (`{SOURCE_FILE}`) and update the following AI Brain files to reflect the findings. **Do NOT create new files** — only update existing ones.

---

## PRE-READ (Mandatory)

1. `{SOURCE_FILE}` — The complete gap analysis (761 lines). Read ALL of it first.
2. `{AI_BRAIN}/memory/MEMORY.md` — Index file (update timestamps + add gap analysis reference)
3. `{AI_BRAIN}/memory/modules-map.md` — HPC row needs major update
4. `{AI_BRAIN}/memory/progress.md` — HPC progress tracker
5. `{AI_BRAIN}/memory/decisions.md` — Check if new decisions need recording
6. `{AI_BRAIN}/memory/known-bugs-and-roadmap.md` — Add HPC roadmap items
7. `{AI_BRAIN}/lessons/known-issues.md` — Verify/add HPC issues (SEC-HPC-*, BUG-HPC-*, PERF-HPC-*)
8. `{AI_BRAIN}/claude-config/rules/hpc.md` — Update HPC-specific rules
9. `{AI_BRAIN}/memory/project-context.md` — Update HPC statistics if needed
10. `{AI_BRAIN}/memory/db-schema.md` — Add Schema-2 migration gap note

---

## FILE-BY-FILE UPDATE INSTRUCTIONS

### 1. `modules-map.md` — HPC Row Update

Find the HPC row in the Tenant-Scoped Modules table and the "Module Completion Detail" section. Replace/update with data from the gap analysis:

**HPC row in main table — update to:**
```
| **Hpc** | 15 | 26 | 2 | 14 | 89 | **~40%** | HpcController ~2297 lines. 4 PDF templates (138 pages total) + ZIP + queued email. 10 CRUD resource controllers. Template structure 95%, web form 90%, PDF gen 90%. **BUT:** 4/20 blueprint screens done (20%); student/parent/peer portals 0%; 13/15 main controller methods zero auth; 20 known issues ALL OPEN; 15/26 tables missing migrations |
```

**HPC completion detail — update to:**
```
| Hpc (~40%) | 15 controllers, 26 models, 2 services (HpcReportService, HpcPdfDataService), 14 FormRequests, 138 web form blade partials, 4 PDF blades, 1 Job (SendHpcReportEmail), 1 Mailable (HpcReportMail). Template structure: 100% (all 138 pages seeded). Web form: 90%. PDF generation: 90%. CRUD admin: 85%. Email/ZIP: 95%. | **SEC-HPC-001 (CRITICAL):** 13/15 HpcController methods zero auth. **SEC-HPC-002:** 7/14 FormRequests return `true`. **SEC-HPC-003:** No EnsureTenantHasModule. **BUG-HPC-001:** 4 template controller imports missing → 500s. **BUG-HPC-003:** Garbled permission string in show(). **BUG-HPC-009:** Trash routes shadowed. **15/26 tables missing migration files.** Student portal: 0%. Parent mechanism: 0%. Peer workflow: 0%. LMS integration: 0%. Approval workflow: 5%. Credit calculator: 0%. Tests: 0%. Blueprint: 4/20 screens done. **Actual completion ~40%** (was listed as 73%, reduced by counting multi-actor gaps + blueprint coverage). See `3-Project_Planning/2-Gap_Analysis/HPC_Gap_Analysis_Complete.md` for full 8-dimension analysis. |
```

### 2. `progress.md` — HPC Progress Update

Find and update the HPC entry. Key changes:
- Change completion from whatever it says to **~40%** with explanation
- Add sub-breakdown: Template 95%, Form 90%, PDF 90%, CRUD 85%, Security 15%, Multi-Actor 0%, Blueprint 20%
- Add note: "Revised down from 73% after comprehensive gap analysis (2026-03-16) counting blueprint coverage and multi-actor data collection"
- Add reference to gap analysis file

### 3. `decisions.md` — Add New Decision

Add a new decision entry:

```markdown
### D20: HPC Gap Analysis Findings — Revised Completion Model (2026-03-16)
- **Why:** Previous estimates (73%) only counted template structure + CRUD completion. Comprehensive gap analysis against official NEP 2020 PDFs (138 pages, 4 templates) and implementation blueprint (20 screens) revealed that multi-actor data collection (student/parent/peer), approval workflows, and 12 of 20 screens are NOT STARTED.
- **Finding:** Template structure is 100% complete (all 138 pages seeded with correct html_object_names). Web form and PDF generation are 90%. But data can only be entered by teachers — 64 of 138 pages (46%) should be filled by students, parents, or peers.
- **Revised estimate:** ~40% overall. Need ~13 developer-weeks to reach full implementation.
- **Reference:** `databases/3-Project_Planning/2-Gap_Analysis/HPC_Gap_Analysis_Complete.md`
```

### 4. `known-bugs-and-roadmap.md` — Add HPC Section

Add an HPC-specific section (or update if one exists) with:
- **4 security issues:** SEC-HPC-001 (CRITICAL, 13/15 methods zero auth), SEC-HPC-002 (HIGH, 7 FRs return true), SEC-HPC-003 (HIGH, no EnsureTenantHasModule), SEC-HPC-004 (HIGH, module routes bypass tenancy)
- **14 bugs:** BUG-HPC-001 through BUG-HPC-014 (list each with severity + one-line description from the gap analysis)
- **2 performance issues:** PERF-HPC-001 (N+1 in PDF gen), PERF-HPC-002 (15× duplicated index query)
- **Roadmap:** 4-sprint plan (Sprint 1: P0+P1 security/bugs 2 days; Sprint 2: P2 workflows 3 weeks; Sprint 3: P3 multi-actor 3 weeks; Sprint 4: P3 screens+integration 3 weeks)

### 5. `known-issues.md` — Verify/Update HPC Entries

Read the existing HPC entries in `lessons/known-issues.md`. The gap analysis found **20 issues total (4 SEC + 14 BUG + 2 PERF)**. Cross-reference:
- If an issue already exists, verify its severity and description match the gap analysis. Update if needed.
- If an issue is missing, ADD it using the standard format from that file.
- Specifically ensure these NEW issues from the gap analysis are present:
  - BUG-HPC-009 (trash routes shadowed)
  - BUG-HPC-010 (duplicate table prefix)
  - BUG-HPC-011 (18/26 models missing created_by)
  - BUG-HPC-012 (cross-layer Dropdown import)
  - BUG-HPC-013 (ZIP files never cleaned)
  - BUG-HPC-014 (tenant_asset URL issue)
  - PERF-HPC-001 (N+1 in PDF generation)
  - PERF-HPC-002 (15× duplicated index query)
  - Permission typo: `topic-equivalency-snapsho.viewAny`

### 6. `claude-config/rules/hpc.md` — Update HPC Rules

Read the existing file and update/add these rules:

```markdown
## Key Facts (updated 2026-03-16 from comprehensive gap analysis)

### Module Stats
- Controllers: 15 (HpcController ~2297 lines — god controller)
- Models: 26 (all use SoftDeletes)
- Services: 2 (HpcReportService 788 lines, HpcPdfDataService 165 lines)
- FormRequests: 14 (7 return true in authorize())
- Jobs: 1 (SendHpcReportEmail)
- Mailables: 1 (HpcReportMail)
- Blade views: ~232 (138 form partials + 4 PDF templates + CRUD views)
- Routes: 89 references in tenant.php
- Migrations: 11 (Schema-1 only; 15 Schema-2 tables MISSING migrations)
- Tests: 0
- Seeders: 0

### Template Coverage
- T1 Foundation: 18 pages (BV1-BV3, Gr 1-2) → first_pdf.blade.php
- T2 Preparatory: 30 pages (Gr 3-5) → second_pdf.blade.php
- T3 Middle: 46 pages (Gr 6-8) → third_pdf.blade.php
- T4 Secondary: 44 pages (Gr 9-12) → fourth_pdf.blade.php
- Total: 138 pages, ~1,695 fields, all seeded and renderable

### Blueprint Screens (4/20 done)
- DONE: SC-02 (Circular Goals), SC-03 (Learning Outcomes), SC-06 (Part-A Entry), SC-19 (Bulk Generator)
- PARTIAL: SC-01 (Template Builder — missing imports), SC-05 (Dashboard — basic), SC-08 (Evaluation — basic CRUD), SC-18 (Report Preview)
- NOT STARTED: SC-04, SC-07, SC-09-SC-17, SC-20 (12 screens)

### Data Provider Reality
- TEACHER + SYSTEM sections: Working (74 pages, 54%)
- STUDENT sections: 35 sections across all templates — 0% have student input mechanism
- PARENT sections: 9 sections — 0% have parent input mechanism
- PEER sections: 14 sections — 0% have peer input mechanism

### Open Gaps (from 2026-03-14, ALL still open as of 2026-03-16)
- GAP-1: No Student Self-Service Portal (0%)
- GAP-2: No Parent Data Collection (0%)
- GAP-3: No Peer Assessment Workflow (0%)
- GAP-4: No Role-Based Section Locking (0%)
- GAP-5: No Approval Workflow (5%)
- GAP-6: No LMS/Exam Auto-Feed (0%)
- GAP-7: No Eval-to-Report Auto-Feed (0%)
- GAP-8: Attendance Data Partial (~30%)

## Before Working on HPC
1. Read `3-Project_Planning/2-Gap_Analysis/HPC_Gap_Analysis_Complete.md`
2. Check P0 items — if security fixes are not done, do those FIRST
3. Never add features before fixing SEC-HPC-001 (auth) and BUG-HPC-001 (imports)
```

### 7. `project-context.md` — Minor Update

In the Key Statistics table or the HPC workflow entry, update:
- HPC note: "~40% complete (revised 2026-03-16 via comprehensive gap analysis)"
- If there's a mention of "~73%" for HPC anywhere, change it to "~40%"

### 8. `MEMORY.md` — Update Index

- Change `Last Updated: 2026-03-15` to `Last Updated: 2026-03-16`
- In the "Quick Reference: Active Critical Bugs" section, ensure HPC bugs are represented
- Add under "Project Planning Documents" or "Gap Analysis" section:
  ```
  | `2-Gap_Analysis/HPC_Gap_Analysis_Complete.md` | Complete 8-dimension HPC gap analysis (2026-03-16): 138-page PDF fidelity, data provider mapping, blueprint vs code, schema alignment, security audit, route health, data flow, multi-actor status. **20 issues found, all OPEN.** |
  ```

### 9. `db-schema.md` — Add Migration Gap Note

Add a note in the HPC section (or create one if none exists):
```
### HPC Schema Gap (identified 2026-03-16)
- Schema-1 (Template + Report): 11 tables — all have migrations ✅
- Schema-2 (NEP 2020 / PARAKH): 15 tables — models exist but NO migration files
  - Missing: hpc_circular_goals, hpc_circular_goal_competency_jnt, hpc_learning_outcomes,
    hpc_outcome_entity_jnt, hpc_outcome_question_jnt, hpc_knowledge_graph_validation,
    hpc_topic_equivalency, hpc_syllabus_coverage_snapshot, hpc_ability_parameters,
    hpc_performance_descriptors, hpc_student_evaluation, hpc_learning_activities,
    hpc_learning_activity_type, hpc_student_hpc_snapshot, hpc_hpc_levels
- These tables likely exist in the DB (created via raw SQL or seeder) but lack versioned migrations
- **Action needed:** Create 15 additive migration files before next deployment
```

---

## RULES

1. **Read each target file COMPLETELY before editing** — do not guess current content
2. **Preserve existing content** — only update/add sections, never delete unrelated content
3. **Use exact numbers from the gap analysis** — 15 controllers, 26 models, 138 pages, 20 issues, ~40%, etc.
4. **Cross-reference** — if two files mention HPC completion %, make them consistent (~40%)
5. **Add timestamps** — every updated section should note "(updated 2026-03-16)"
6. **Do NOT create new files** — only edit the 9 files listed above
7. **Keep MEMORY.md under 200 lines** — if adding rows, remove stale/redundant ones
8. **Reference the gap analysis file** — always point to `3-Project_Planning/2-Gap_Analysis/HPC_Gap_Analysis_Complete.md` as the authoritative source
9. **Preserve formatting** — match the existing markdown style of each file
10. **Verify before writing** — after editing each file, confirm the edit is consistent with the gap analysis numbers
