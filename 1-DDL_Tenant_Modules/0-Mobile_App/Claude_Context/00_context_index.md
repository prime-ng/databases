# Mobile App — Working Notes & Context Index

> **Purpose:** Track exactly which AI_Brain / project-planning artifacts have been
> consumed for the Prime-AI Mobile App requirements work, what was extracted from
> each, and any files still pending. Append-only log per phase.
>
> **Prompt being executed:** `{OLD_REPO}/1-DDL_Tenant_Modules/0-Mobile_App/Claude_Prompt/PrimeAi_MobileApp_prompt_v2.md`
> **Current phase:** Phase 1 — Feature List
> **Owner:** Business Analyst + Mobile Application Architect (Claude)

---

## Phase 1 — Files Consumed

### §1.1 Project foundation

| File | Last Updated | What I took from it |
|------|--------------|---------------------|
| `{AI_BRAIN}/README.md` | n/a (stable) | Confirms folder layout; lists "Mobile App" already in client layer of architecture diagram |
| `{AI_BRAIN}/memory/MEMORY.md` | 2026-03-21 | Index of memory files; quick-ref to active critical bugs (SEC-PLATFORM-004, SEC-PAY-001, SEC-HPC-001, SEC-004, SEC-NTF-006, BUG-VND-001, BUG-CMP-001, SEC-009) |
| `{AI_BRAIN}/memory/project-context.md` | n/a (continuously updated) | Stack: Laravel 11→12, MySQL, stancl/tenancy v3.9, UUIDs, Sanctum. Roles: Tenant — SuperAdmin, Principal, VicePrincipal, Teacher, Staff, Accountant, Librarian, Parent, Student. Authorization pattern `module.feature.action`. 6 key business workflows (onboarding, FET timetable, admission, fee+Razorpay, complaint AI, notification dispatch). |
| `{AI_BRAIN}/memory/modules-map.md` | 2026-04-09 audit | **37 modules (5 central + 32 tenant)**. Full table of FULL/RBS_ONLY status per module. Route prefixes (e.g. `/student-portal/*`, `/student-fee/*`). Planned modules with Hostel, Cafeteria, Certificate, ParentPortal, VisitorSecurity, Maintenance, FrontOffice, Inventory, HrStaff (with `_2step_Prompt1.md` artifacts ready). |
| `{AI_BRAIN}/memory/architecture.md` | 2026-03-12 | Request flow incl. Mobile clients already named in client layer. Auth middleware stack: `auth` / `auth:sanctum` → `InitializeTenancyByDomain` → `EnsureTenantIsActive` → `EnsureTenantHasModule`. Maturity matrix: Caching 0/5, API design 2/5, Security 2/5 — mobile must work *around* these gaps. Known critical bugs: BUG-004 tenant migration commented, SEC-004 webhook auth. |
| `{AI_BRAIN}/memory/conventions.md` | n/a | Table prefixes (sch_, std_, tt_, slb_, qns_, tpt_, ntf_, fin_, pmt_, hpc_, lms_, lib_, hst_, ppt_, etc.). Standard CRUD pattern + soft deletes + is_active on every table. JSON response envelope `{ success, data, message, meta }` already used. |
| `{AI_BRAIN}/memory/db-schema.md` | 2026-03-12 | 370 tenant tables. Authoritative DDL paths (`{TENANT_DDL}` etc.). Full table list per module prefix — used to populate "Source Tables" field per feature. v2 still has known errors (Vendor/Complaint/Timetable/HPC/LmsExam/Library/Accounting). |
| `{AI_BRAIN}/memory/tenancy-map.md` | n/a | Bootstrappers: Database/Cache/Filesystem/Queue. Tenant onboarding broken (BUG-004 migration pipeline commented). Webhook routes must stay outside auth (SEC-004). env() in routes breaks after config:cache (SEC-PLATFORM-002). Storage path `storage/tenant_{uuid}/`. |

### §1.2 Module-specific deep dives

| File | Last Updated | What I took from it |
|------|--------------|---------------------|
| `{AI_BRAIN}/memory/student-parent-portal.md` | 2026-04-02 | **Student Portal — 35 screens (S1–S35), ~55% complete.** Complete table of every screen with route + status (✅/🟡/❌). 7 controllers, 55+ named routes, 57 blade views. **Parent Portal — 23 screens (P1–P23), ~5% complete** — almost entirely Missing. Custom middleware: `EnsureStudentAccess`, `EnsureParentAccess`. Multi-Child Context (parent_selected_student_id session). 5-Layer security stack. **16 new tables required** for Parent Portal feature parity (sch_school_events, sch_event_rsvp, sch_ptm_*, msg_threads/messages, std_medical_details, std_certificates, etc.). LMS integration points (Quiz/Homework/Exam/Gradebook/Self-Practice). **Known critical issues:** SR-AUTH-001 (fee IDOR), SEC-004 (Razorpay webhook), SR-AUTH-003/004, QB-SEC-001, BUG-007. |
| `{AI_BRAIN}/memory/lms-modules.md` | 2026-03-21 | (Read inferred via MEMORY index — full read deferred to Phase 2 SRS where field-level detail matters.) |
| `{AI_BRAIN}/memory/known-bugs-and-roadmap.md` | 2026-03-26 | All P0 SEC-* IDs that the Mobile API must call out as blockers when present. SEC-NEW-001 (hardcoded API keys), SEC-NEW-002 (Student IDOR proceedPayment), BUG-NEW-001 (PAY 3 broken prefixes, no DDL — blocks any payment endpoint), BUG-NEW-002 (NTF routes commented out — blocks all notification surfaces), BUG-NEW-004 (lms_homework_assignment missing — blocks homework publish), BUG-NEW-006 (TTS conflict check), BUG-001 (missing model imports → fatal Gate calls), BUG-002 (duplicate policy registrations silently overwriting), BUG-004 (tenant onboarding broken), BUG-007 (Student null pointer on session). Full mass-assignment risks via `$request->all()` — D25/D30. |

### §1.3 Decisions, rules, conventions

| File | Last Updated | What I took from it |
|------|--------------|---------------------|
| `{AI_BRAIN}/state/decisions.md` | n/a (running log) | D1 (db-per-tenant), D2 (nwidart modules), D3 (3-layer DB), D4 (Spatie RBAC), D5 (UUIDs), D6 (domain routing), D7 (prefix convention), D8 (soft deletes everywhere), D9 (DomPDF), D10 (Razorpay), D29 (no ENUM — use sys_dropdown_table), D32 (MarksheetGeneration), D33 (Employee DDL v4), D34 (Hostel DDL v3). All ground-truth rules in Phase-1 §2 of feature list trace to these. |
| `{AI_BRAIN}/state/progress.md` | 2026-04-09 | Per-module completion %. **StudentPortal 50% (down from 68%)** — IDORs in proceedPayment + Exam attempt confirmed unpatched. **StudentProfile 20%** — Leave subsystem confirmed dead code. **Transport 40%** — Aadhaar/PAN plaintext (IT Act violation). **Notification 35%** — all routes commented + prime.* prefix mismatch. **Payment 45%** — webhook behind auth. Used to mark backend dependency status per feature. |
| `{AI_BRAIN}/rules/{tenancy,security,module,school}-rules.md` | various | Scanned via README — full read deferred to Phase 2 SRS section §9 (Permissions & Security). Confirmed mobile auth must reuse Sanctum + EnsureTenantHasModule middleware where applicable. |

### §1.4 Project planning

| File | Status |
|------|--------|
| `{RBS_MAPPING}` (`{RBS_DIR}/PrimeAI_RBS_Menu_Mapping_v2.0.md`) | **NOT YET FULLY PARSED** — RBS Functionality / Task / Sub-task IDs left as placeholders in feature catalogue (`RBS Mapping = TBD`); to be filled in Phase 2 once each feature has been mapped to specific RBS sub-tasks. Flagged as Open Question Q-3. |
| `{GAP_ANALYSIS_PROJECT_FILE}` (`PrimeAI_Gap_Analysis_v1.0.md`) | **Not read line-by-line in Phase 1** — gap signals already captured via `progress.md` and `known-bugs-and-roadmap.md`. Will cross-link in Phase 3 backend-gap-analysis deliverable. |
| `{PROJECT_DOCS}/01-project-overview.md` | Not read in Phase 1 — substantive contents already covered by `project-context.md` + `db-schema.md`. |
| `{PROJECT_DOCS}/11-all-modules-controllers-models.md` | Not read in Phase 1 — `modules-map.md` row-per-module table is a sufficient substitute for the inclusion-criteria pass. Will read for Phase 2 SRS API-contract section. |
| `{PROJECT_DOCS}/10-new-feature-checklist.md` | Not read in Phase 1 — needed for backend gap workitem authoring (Phase 3 / new mobile API endpoints). |
| `{LIFECYCLE_BLUEPRINT}` | Not read in Phase 1 — referenced for Phase 2 MVP sequencing alignment in `01_mobile_feature_list_v1.md` Section 5; will be read for Phase 3 dev-pipeline deliverable. |

### §1.5 Canonical schema

| File | Status |
|------|--------|
| `{TENANT_DDL}`, `{PRIME_DDL}`, `{GLOBAL_DDL}` | **Tables referenced via `db-schema.md` summaries.** Direct DDL only consulted on ad-hoc basis for column-level validation — not opened end-to-end in Phase 1. Will cite specific table column lists in Phase 2 (API request/response schemas) and Phase 3 (gap analysis DDL changes). |

### §1.6 Output folder

| Path | Status |
|------|--------|
| `{OLD_REPO}/1-DDL_Tenant_Modules/0-Mobile_App/Claude_Prompt/` | Exists; v1 + v2 prompts present. |
| `{OLD_REPO}/1-DDL_Tenant_Modules/0-Mobile_App/Claude_Context/` | Exists (empty). This file is the first artifact. |
| `{OLD_REPO}/1-DDL_Tenant_Modules/0-Mobile_App/Requirement/` | Exists (empty). Phase 1 deliverable `01_mobile_feature_list_v1.md` written here. |
| `{OLD_REPO}/1-DDL_Tenant_Modules/0-Mobile_App/Design/` | Exists (empty). Reserved for Phase 3. |

---

## Phase 1 — Open Questions Logged for User

1. **Stack:** Flutter recommended (see feature list §1). Confirm or override.
2. **Tenant resolution at app launch:** subdomain entry vs. tenant code/QR vs. unique deep-link install — needs decision before Phase 2 auth flow detail.
3. **RBS mapping:** Do you want each feature back-mapped to specific Functionality/Task/Sub-task IDs from `PrimeAI_RBS_Menu_Mapping_v2.0.md` in Phase 2, or keep mobile-feature IDs as the canonical identifier with a separate cross-reference table?
4. **iOS deployment ownership:** Per-tenant Apple Developer accounts (white-label) vs. one Prime-AI master account hosting all schools (skin via tenant config).
5. **Branding/white-label:** App icon + name + splash colour per tenant (build-time vs run-time).
6. **Localization scope:** Hindi + English only, or also regional languages (Marathi, Gujarati, Tamil, Telugu, Bengali) at MVP?
7. **Push providers:** FCM + APNs only, or also include MSG91/Twilio for SMS fallback (DLT-compliant SMS exists in planned `Communication` module).
8. **Online exam mobile policy:** Allow online exam-taking on mobile (camera, fullscreen, DevTools detection are weaker on mobile than browser); or restrict mobile to viewing schedule + results only and require web for the actual attempt?
9. **Transport staff app:** One unified app with role-gated UI, or a separate stripped-down "Driver/Conductor" app to minimize PII exposure on shared devices?
10. **Backend ownership of new `/api/mobile/v1/*` namespace:** Each existing module gets a `MobileController.php` (Modules/<Name>/app/Http/Controllers/Api/Mobile/), or one consolidated `Modules/MobileApi/` — note: Rule §2.7 of v2 prompt forbids a generic Mobile module for *business* logic, but a thin API namespace re-exposing existing services is consistent with that rule. Awaiting your call.

---

## Phase 1 — Status

- ✅ Folder structure verified
- ✅ Critical AI_Brain files loaded
- ✅ Stack recommendation made (Flutter)
- ✅ `01_mobile_feature_list_v1.md` produced
- 🛑 **STOP — awaiting "approved — proceed to Phase 2"**

---

## Phase 2 — Pending (do not execute until approved)

- Read `{RBS_MAPPING}` end-to-end
- Read `{LIFECYCLE_BLUEPRINT}` for MVP sequencing
- Read `{PROJECT_DOCS}/11-all-modules-controllers-models.md` for endpoint mapping
- Spot-read `{TENANT_DDL}` for column-level schema where needed per feature
- Produce `02_mobile_srs_index.md` + `02_mobile_srs_batch_NN.md`

## Phase 3 — Pending

- Cross-link to `{GAP_ANALYSIS_PROJECT_FILE}` from backend gap doc
- Map mobile build phases to `{LIFECYCLE_BLUEPRINT}` 9-phase pipeline
- Produce 9 design files in `Design/`
