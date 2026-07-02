# Prime School Management — UI/UX Audit, Review & Enhancement Prompt (V2)

> **Version:** 2.0 · **Adapted for:** Bharadwaj's local machine (macOS / Laravel Herd)
> **Supersedes:** `PRIME_UI_UX_CLAUDE_PROMPT.md` (V1, Tarun's original)
> **What changed in V2:**
> 1. All `{PROJECT_ROOT}` placeholders replaced with **real, verified absolute paths** on this machine.
> 2. **Every generated artifact is written into a single output folder** (see §0.2), never scattered across the app repos.
> 3. Audit coverage expanded from ~10 categories to a **full 25-dimension UI/UX audit taxonomy** (§2) with a formal scoring rubric.
> 4. Added a **structured Enhancement-Suggestion Engine** (§8) — prioritized, scored (Impact/Effort/RICE), and grouped into quick-wins vs. strategic bets.
> 5. Added **competitive benchmarking**, **cross-app consistency audit**, **design-token drift detection**, **component-inventory / duplication analysis**, and an **automated + manual accessibility protocol**.
>
> **Golden rule:** **Do not assume anything.** If a path is missing, a folder is empty, a module looks different than described, or a design decision is ambiguous, **stop and ask** before proceeding. Report what you actually found, not what you expected to find.

---

## ⛔ ABSOLUTE READ-ONLY MANDATE (Highest Priority — Overrides Everything Below)

**This task produces REPORTS AND REFERENCE DOCUMENTS ONLY. It must not change anything, anywhere.**

**You are STRICTLY FORBIDDEN from:**
- Editing, creating, deleting, moving, or renaming **any file** inside the application repos — `/Users/bkwork/Herd/prime_ai`, `/Users/bkwork/Herd/mobile_school`, `/Users/bkwork/Herd/mobile_student` — or anywhere else on the machine **except** the single output folder (§0.2).
- Modifying **any code** (Blade, PHP, CSS, JS, TypeScript, `.tsx`, config, `.env`, package files, etc.).
- Touching **databases in any way** — no schema/DDL changes, no migrations, no seeders, no `ALTER`/`CREATE`/`DROP`/`INSERT`/`UPDATE`/`DELETE`, no `php artisan migrate`, no writes of any kind. Database access, if any, is **read-only inspection only**.
- Running any command that **builds, installs, compiles, deploys, or mutates state** (`npm install`, `composer`, `artisan` mutating commands, `git commit/push`, formatters, linters that auto-fix, etc.).
- Applying, "just this once" fixing, or "quickly patching" anything you find during the audit — **you only document it as a recommendation.**

**You are ALLOWED to:**
- **Read** any file in the three app repos and the screenshot/context folders (read-only inspection).
- **Create new report and reference files ONLY inside** the output folder:
  `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/9-Working_with_Team/2-Tarun/Prompt_Output/`
  This includes the audit reports, the enhancement backlog, and the self-contained design-system reference folder (§9) — all of which are **new deliverables written under `OUTPUT`, never applied to the live apps.**
- Run **read-only** shell commands (`ls`, `cat`, `grep`, `find`, `git status`/`git log` — never mutating git commands).

**If completing any instruction in this prompt would require modifying anything outside `OUTPUT`, STOP and ask the user instead of proceeding.** Every design-system CSS/JS/HTML/markdown artifact is a *reference specification* placed under `OUTPUT` for humans and other AI agents to implement later — it is **never** written into `prime_ai`, `mobile_school`, or `mobile_student` as part of this task.

---

## 0. Project Setup (Run This First)

### 0.1 The Three Applications (verified paths)

This is a **multi-platform school-management ecosystem**. All three apps live under `/Users/bkwork/Herd/`:

```
/Users/bkwork/Herd/
├── prime_ai/          # Laravel 12 backend + student/parent web portals
├── mobile_school/     # React Native admin app  (Expo)  — package name: "primeadmin"
└── mobile_student/    # React Native student/parent/teacher app (Expo) — package name: "primeapp"
```

> ⚠️ **Naming note:** The original V1 prompt called the mobile apps `primeadmin` and `primeapp`. On **this** machine the folders are named `mobile_school` (= primeadmin) and `mobile_student` (= primeapp). Use the folder paths above; the package names inside `package.json` still read `primeadmin` / `primeapp`.

**Path variables used throughout this prompt** (treat as constants):

| Variable | Absolute path |
|----------|---------------|
| `BACKEND` | `/Users/bkwork/Herd/prime_ai` |
| `ADMIN_APP` | `/Users/bkwork/Herd/mobile_school` |
| `STUDENT_APP` | `/Users/bkwork/Herd/mobile_student` |
| `OUTPUT` | `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/9-Working_with_Team/2-Tarun/Prompt_Output` |

### 0.2 Output Contract (IMPORTANT — read carefully)

**Every file you produce goes under `OUTPUT`.** Do **not** write reports, mockups, or the design-system folder into the app repos. The app repos are **read-only reference** for this task.

Create this structure under `OUTPUT` and place all deliverables inside it:

```
Prompt_Output/
├── 00_RUN_SUMMARY.md                    # Final summary + index of everything produced (write LAST)
├── 01_AUDIT/
│   ├── PRIME_UI_UX_AUDIT_REPORT.md      # Master audit report (score + justification + roadmap)
│   ├── SCORECARD.md                      # 25-dimension scorecard with per-dimension scores
│   ├── EVIDENCE_LOG.md                   # Every file/screenshot inspected + what was observed
│   ├── CROSS_APP_CONSISTENCY.md          # Web vs. admin-app vs. student-app drift analysis
│   ├── ACCESSIBILITY_AUDIT.md            # WCAG 2.2 AA findings (automated + manual)
│   ├── COMPONENT_INVENTORY.md            # Catalog of existing components + duplication map
│   ├── DESIGN_TOKEN_DRIFT.md             # Token divergence across the 3 apps
│   └── COMPETITIVE_BENCHMARK.md          # Prime vs. international school-SaaS peers
├── 02_ENHANCEMENTS/
│   ├── ENHANCEMENT_BACKLOG.md            # All suggestions, scored (Impact/Effort/RICE), prioritized
│   ├── QUICK_WINS.md                     # ≤1-day, high-impact fixes
│   ├── STRATEGIC_BETS.md                 # Larger investments (redesigns, systems)
│   └── ROADMAP_TO_10.md                  # Phased plan to reach a 10/10 experience
├── 03_DESIGN_SYSTEM/
│   └── prime-design-system/             # Full component library (see §9)
└── 04_ASSETS/
    └── (any screenshots you reference, before/after clippings, diagrams)
```

If `OUTPUT` or any subfolder does not exist, create it. Confirm the folder is writable before starting heavy work.

### 0.3 Where to Find Existing Evidence

| Evidence type | Location(s) |
|---------------|-------------|
| Backend browser screenshots | `/Users/bkwork/Herd/prime_ai/tests/Browser/screenshots` |
| Curated product screenshots | `/Users/bkwork/Herd/Back_Prime_context_Tarun/Screenshots`, `/Users/bkwork/Herd/Back_Prime_context_Tarun/quiz-reports-screenshots` |
| Additional context screenshots | `/Users/bkwork/Herd/tarun_prime_context/tarun_prime_context/Screenshots` |
| Backend theme / color source | `/Users/bkwork/Herd/prime_ai/public/backend/css/adminlte-custom.css` |
| Backend base theme | `/Users/bkwork/Herd/prime_ai/public/backend/css/adminlte.css` |
| Mobile design tokens | `/Users/bkwork/Herd/mobile_school/constants/theme.ts`, `/Users/bkwork/Herd/mobile_student/constants/theme.ts` |

If a screenshot folder is empty or missing, **note it in `EVIDENCE_LOG.md` and ask** whether to proceed on code-only evidence.

---

## 1. Role & Mindset

You are a **senior product designer + full-stack UI engineer with 10+ years** building premium, international-grade UI/UX for enterprise and education software. You combine three lenses:

- **The senior designer** — visual craft, hierarchy, brand, emotional tone, "does this feel premium or generic?"
- **The UX researcher** — heuristics, cognitive load, task flows, error recovery, accessibility, inclusivity.
- **The pragmatic engineer** — what is actually shippable on AdminLTE v4 + Bootstrap 5.3 + jQuery on the web, and Expo + React Native + TypeScript on mobile, **without introducing new frameworks**.

You are **not re-skinning** — you are **rethinking the experience** while preserving the existing brand identity. You are honest and critical, but every criticism comes paired with a concrete, buildable fix.

---

## 2. Phase 1 — Full UI/UX Audit (Do This First)

> **Reminder:** Do not assume. Log every file you actually open in `01_AUDIT/EVIDENCE_LOG.md`. If you rate a dimension, you must cite the evidence behind the rating.

Before designing anything, audit the **current state** across all three apps and give an honest, senior-level assessment.

### Step 1 — Gather Evidence

Scan the following. For each, record in `EVIDENCE_LOG.md`: path, what it is, and 2–3 observations.

**Backend (Laravel / AdminLTE) — `BACKEND`:**
- `Modules/Payment/resources/views`
- `Modules/LmsQuests/resources/views`
- `Modules/TimetableFoundation/resources/views`
- `Modules/StudentPortal` (student web portal — Smart University theme)
- `Modules/ParentPortal` (parent web portal)
- Shared layout & components:
  - `resources/views/backend/v1/layouts/app.blade.php`
  - `resources/views/components/backend/*` (breadcrum, tabs, tables, forms, status-switch, etc.)
- Theme/color: `public/backend/css/adminlte-custom.css`, `public/backend/css/adminlte.css`
- **Also sample 3–4 additional modules** at random from `BACKEND/Modules/` (e.g. StudentFee, Hostel, LmsExam, MarksheetGeneration, BehaviouralAssessment) to test whether patterns are consistent platform-wide — do not audit only the "showcase" modules.

**Admin mobile app — `ADMIN_APP`:**
- `app/` (expo-router screens)
- `components/ui/` (primitives: button, input, card, badge, chip…)
- `components/navigation/`, `components/layout/`
- `constants/theme.ts`

**Student/parent/teacher mobile app — `STUDENT_APP`:**
- `app/`
- `components/ui/`
- `components/navigation/`, `components/layout/`
- `constants/theme.ts`

**Screenshots:** all folders listed in §0.3.

### Step 2 — Score Across the 25-Dimension Audit Taxonomy

Rate **each dimension 0–10** (0 = broken/absent, 5 = functional but generic, 8 = polished, 10 = best-in-class international SaaS). Record scores in `01_AUDIT/SCORECARD.md` with a one-line justification + evidence citation per dimension. Then compute a weighted overall score (weights below; if you deviate, state why).

| # | Dimension | What to evaluate | Weight |
|---|-----------|------------------|:---:|
| **A. Visual & Brand** | | | |
| 1 | Visual design & modernness | Does it look current (2025+) or dated? Depth, gradients, imagery quality | 5% |
| 2 | Brand personality | Distinctive vs. generic school ERP; memorability; emotional tone | 3% |
| 3 | Color system usage | Correct semantic use; over-saturation; tint/shade discipline; contrast | 4% |
| 4 | Typography | Scale, hierarchy, line-length, weight usage, readability, web-font loading | 4% |
| 5 | Iconography consistency | One icon family per platform; consistent size/stroke/metaphor | 3% |
| 6 | Imagery, illustration & empty-state art | Quality, relevance, cultural neutrality | 2% |
| **B. Layout & IA** | | | |
| 7 | Layout & whitespace | 8px grid discipline, density, alignment, breathing room | 4% |
| 8 | Information hierarchy | Clear primary/secondary/tertiary; scannability; F/Z-pattern respect | 5% |
| 9 | Navigation & wayfinding | Sidebar/menu clarity, breadcrumbs, active states, depth, search | 4% |
| 10 | Dashboard design | Greeting/personalization, priority stats, quick actions, "alive" feel | 4% |
| 11 | Data density & tables | Scannability, sticky headers, sort/filter, bulk actions, row affordances | 4% |
| **C. Interaction & UX** | | | |
| 12 | Nielsen heuristics compliance | Run all 10 heuristics; flag violations with examples | 6% |
| 13 | Forms & input UX | Grouping, inline validation, smart defaults, steppers, error prevention | 5% |
| 14 | Feedback & system status | Loading, skeletons, toasts, progress, optimistic UI, latency masking | 4% |
| 15 | Error handling & recovery | Friendly errors (no stack traces), undo, confirm-destructive, 404/403/500 | 4% |
| 16 | Empty / first-run / onboarding | No-data, no-results, permission-denied, first-use guidance | 3% |
| 17 | Motion & micro-interactions | Purposeful transitions, hover/press feedback, reduced-motion support | 2% |
| 18 | Cognitive load & progressive disclosure | Hiding advanced options, chunking, defaults, decision fatigue | 4% |
| **D. Quality, Reach & Trust** | | | |
| 19 | Accessibility (WCAG 2.2 AA) | Contrast, focus visibility, keyboard nav, targets ≥44px, semantics, SR labels | 7% |
| 20 | Responsive / mobile-web behavior | Breakpoints, table→card stacking, no horizontal scroll, touch targets | 4% |
| 21 | Mobile-app nativeness | Feels app-native vs. wrapped web; safe-area; gestures; platform idioms | 4% |
| 22 | Dark-mode parity & theming | Every component themed; no contrast breakage; token-driven | 3% |
| 23 | Internationalization & RTL | RTL-aware, flexible text length, locale currency/date, neutral copy | 3% |
| 24 | Microcopy & content design | Labels, button verbs, tone, helpfulness, consistency, jargon | 3% |
| 25 | Performance perception & trust cues | Perceived speed, asset weight, security/privacy signals, polish that builds trust | 2% |

**Scoring rubric anchors (apply consistently):**
- **9–10** — International best-in-class; you'd showcase it. No notable flaws.
- **7–8** — Polished and professional; minor gaps.
- **5–6** — Functional but generic; "typical school ERP."
- **3–4** — Noticeable problems that hurt usability or credibility.
- **0–2** — Broken, absent, or actively harmful.

### Step 3 — Cross-App Consistency Audit → `CROSS_APP_CONSISTENCY.md`

Compare the **same concept** across web / admin-app / student-app (e.g. a primary button, a status badge, a card, a stat tile, an empty state). Document: where they diverge, which is the best reference, and what a unified spec should be. Flag any concept that has **3 different visual treatments** across the 3 apps.

### Step 4 — Design-Token Drift → `DESIGN_TOKEN_DRIFT.md`

Extract the color/spacing/radius/typography tokens from all three sources (`adminlte-custom.css`, both `theme.ts`). Build a side-by-side table. Flag: colors that mean the same thing but differ in hex; missing tokens in one app; hard-coded values that bypass tokens.

### Step 5 — Component Inventory & Duplication → `COMPONENT_INVENTORY.md`

Catalog reusable components found (web Blade `x-backend.*` + both mobile `components/ui/*`). For each: name, location, variants, and any **duplicates / near-duplicates** that should be consolidated. This becomes the backbone of the design system in §9.

### Step 6 — Accessibility Audit → `ACCESSIBILITY_AUDIT.md`

Run a **WCAG 2.2 AA** pass. Where you cannot execute tooling, reason from the code/markup and note it as "static analysis."
- **Color contrast matrix** — check the palette (§5) text/background pairs against 4.5:1 (normal) and 3:1 (large). List every failing pair.
- **Focus indicators** — are visible focus states defined? Any `outline:none` without replacement?
- **Keyboard navigation** — tab order, skip-links, focus traps in modals, escape-to-close.
- **Touch targets** — flag interactive elements < 44×44px on mobile.
- **Semantics** — heading order, landmark regions, form labels, alt text, ARIA misuse.
- **Screen-reader labels** — icon-only buttons, status conveyed by color alone.
- **Reduced motion** — is `prefers-reduced-motion` respected?

### Step 7 — Competitive Benchmark → `COMPETITIVE_BENCHMARK.md`

Position Prime against **international school-management SaaS** (e.g. PowerSchool, Toddle, Teachmint, Classe365, Gradelink, Schoolbox, Skolaro, plus general premium-SaaS bars like Linear/Notion/Stripe for interaction polish). For 6–8 dimensions, rate Prime as **Behind / At-par / Ahead**, and note the single most impactful thing each peer does better. Keep it evidence-grounded — describe patterns, not brand-copying.

### Step 8 — Score Justification (in the master report)

In `PRIME_UI_UX_AUDIT_REPORT.md` write:
- **The overall weighted score /10** and the full per-dimension scorecard.
- **What's working well** (be specific, cite files/screens).
- **The biggest visual & UX problems** (top 10, ranked).
- **Why it does/does not look international-grade.**
- **What makes it feel like a generic school ERP vs. a premium SaaS product.**
- **Cross-app consistency verdict** and **accessibility verdict.**

### Step 9 — Roadmap to 10/10 → also written to `02_ENHANCEMENTS/ROADMAP_TO_10.md`

A phased plan (Phase 0 quick wins → Phase 1 foundations/tokens → Phase 2 component unification → Phase 3 flagship screens → Phase 4 polish/motion/i18n), with the key design principles and immediate next steps.

**Only after the audit reports exist should you proceed to §8 (enhancements) and §9 (design system).**

---

## 3. Project Context

| App | Path | Stack | Audience |
|-----|------|-------|----------|
| **Prime AI (Backend)** | `BACKEND` = `/Users/bkwork/Herd/prime_ai` | Laravel 12, `nwidart/laravel-modules`, **AdminLTE v4.0.0-beta3 (Bootstrap 5.3)** + jQuery 3.6, Blade | Admins, accountants, teachers, back-office |
| **Prime Admin (Mobile)** | `ADMIN_APP` = `/Users/bkwork/Herd/mobile_school` | Expo SDK 54, RN 0.81, TypeScript, `expo-router` | School admin/staff on mobile |
| **Prime App (Mobile)** | `STUDENT_APP` = `/Users/bkwork/Herd/mobile_student` | Expo SDK 54, RN 0.81, TypeScript, `expo-router` | Students, parents, teachers |

### 3.1 Backend UI Architecture
- Layout: `<x-backend.layouts.app>` → `resources/views/backend/v1/layouts/app.blade.php`
- Partials: `<x-backend.partials.* />` (head/sidebar/navbar/footer)
- Reusable components: `resources/views/components/backend/*`
  - `x-backend.components.breadcrum`
  - `x-backend.tab.search-bar`, `x-backend.tab.nav-tab`
  - `x-backend.table.action`, `x-backend.table.status-switch`
  - `x-backend.form.input-text`, `x-backend.form.input-textarea`, etc.
- Student web portal: `<x-frontend.layout.app>` (Smart University theme)
- Parent web portal: `@extends('parentportal::layouts.app')`

### 3.2 React Native UI Architecture (both mobile apps)
- Design tokens: `constants/theme.ts`
- UI primitives: `components/ui/button.tsx`, `input.tsx`, `card.tsx`, `badge.tsx`, `chip.tsx`, etc.
- Navigation: `components/navigation/app-header.tsx`, `drawer-content.tsx`, `screen-header.tsx`
- Layout helpers: `components/layout/screen-wrapper.tsx`, `screen-header.tsx`

---

## 4. Hard Constraints (Do Not Violate)

1. **Preserve the current color palette** (§5). Brand colors remain the foundation.
2. **Backend builds on AdminLTE v4.0.0-beta3 (Bootstrap 5.3) + jQuery 3.6** — as a **layer on top**, not a replacement. **No new frameworks** (no Livewire, Vue, React-in-Blade, new build tools). Do **not** use the legacy Bootstrap 4 files under `public/backend/plugins/bootstrap/`.
3. **Custom CSS overrides only**, in a separate well-organized layer that works **with** AdminLTE v4 classes.
4. **Keep the existing React Native stack** (Expo, RN, TypeScript, custom primitives). No new UI libraries.
5. **No changes to existing app code in this task.** This is **design-system + audit reference only**. All output goes to `OUTPUT` (§0.2), never into the app repos.
6. **STRICT READ-ONLY (see the Absolute Read-Only Mandate at the top).** This task **only creates reports and reference documents under `OUTPUT`**. Zero changes to code, DDL/database, config, dependencies, or any file outside `OUTPUT`. No migrations, no seeders, no builds, no auto-fixers, no mutating git commands. Findings are **documented as recommendations only** — never applied.

---

## 5. Color Scheme to Preserve

Source: `/Users/bkwork/Herd/prime_ai/public/backend/css/adminlte-custom.css`

| Token | Value | Usage |
|-------|-------|-------|
| `--primary` | `#6673fc` | Primary buttons, links, active states, brand accents |
| `--secondary` | `#64748b` | Secondary actions, muted emphasis |
| `--success` | `#3fcc7e` | Success, approved, paid, present |
| `--info` | `#4abad2` | Information highlights |
| `--warning` | `#facc15` | Warnings, pending |
| `--danger` | `#e44f56` | Errors, deletions, absent, overdue |
| `--light` | `#f4f6f9` | Light backgrounds |
| `--dark` | `#222c3c` | Dark elements, high-emphasis text |
| `--surface-bg` | `#ffffff` | Cards, panels, content surfaces |
| `--surface-secondary` | `#f8fafc` | Page backgrounds, alternating rows |
| `--surface-hover` | `#f1f5f9` | Hover states |
| `--surface-active` / `--surface-border` | `#e2e8f0` | Borders, dividers |
| `--text-primary` | `#1e293b` | Primary text |
| `--text-secondary` | `#475569` | Secondary text |
| `--text-muted` | `#94a3b8` | Placeholders, disabled, hints |
| `--text-link` | `#3b82f6` | Inline links |

**Dark mode:** surfaces flip to `#1e1e2d`, `#252536`, `#2a2a3d`; text flips to `#e2e8f0`.

You may use **tints, shades, and opacity variations**, but the core palette must stay recognizable. **Verify the actual values in the CSS file before quoting them** — if they differ from this table, trust the file and note the discrepancy.

---

## 6. Design Direction

Create UI/UX that **stands out from common school-management systems**. Avoid cluttered admin panels.

### 6.1 Visual Language
- Clean, spacious layouts on a consistent **8px grid**.
- Soft modern cards: subtle shadows, consistent radius, clear hierarchy.
- Friendly-but-professional typography with readable sizes.
- **Status = color + icon + label** (never color alone).
- Consistent iconography (Font Awesome / Bootstrap Icons for web; MaterialIcons for mobile).
- Full **light + dark** coverage for every component.

### 6.2 UX Principles
- **Reduce cognitive load** — group actions, progressive disclosure, hide advanced options.
- **Clear primary action** — one obvious next step per screen.
- **Forgiving interfaces** — confirm destructive actions, inline validation, helpful empty states, undo where possible.
- **Accessibility** — visible focus, sufficient contrast, ≥44px touch targets, semantic HTML.
- **International readiness** — RTL-aware, flexible text length, locale number/date formatting.

### 6.3 Differentiators
- Dashboards feel **alive and personal** (greeting, summary, quick actions).
- Tables feel **scannable & actionable** (sticky headers, hover rows, bulk actions).
- Forms feel **short and guided** (step indicators, inline help, smart defaults).
- Mobile apps feel **app-native**, not wrapped web pages.

---

## 7. Audit-Driven Design Priorities (Must Address)

From the Phase 1 audit, the design system + templates must fix:

1. **Reduce saturated backgrounds** — stat cards use white/very-light surfaces with colored **accents** (left/top border, icon, subtle gradient), not full-color fills.
2. **Unify component styles** — one design language for cards, tables, buttons, badges, tabs across backend + both portals + both mobile apps.
3. **Improve hierarchy** — dashboards lead with greeting + key actions, then 3–4 priority stats, then secondary widgets. No stacks of equal-weight cards.
4. **Modernize legacy elements** — replace heavy shadows, inconsistent radius, dated footers.
5. **Mobile-first responsiveness** — every table has a card-stacked variant; touch targets ≥44px.
6. **Accessibility** — WCAG 2.2 AA contrast, visible focus, friendly error pages (no stack traces).
7. **International readiness** — RTL-aware layouts, locale currency/date placeholders, neutral copy.
8. **Standardize iconography** — one icon family per platform.

---

## 8. Enhancement-Suggestion Engine (V2 — NEW)

> This is where V2 goes beyond V1: don't just report problems — produce a **prioritized, scored, buildable backlog**.

### 8.1 Produce the Backlog → `02_ENHANCEMENTS/ENHANCEMENT_BACKLOG.md`

For **every** issue found in the audit, emit a suggestion row. Each suggestion must have:

| Field | Description |
|-------|-------------|
| ID | `ENH-001`, `ENH-002`, … |
| Title | Short, action-oriented ("Replace full-color stat cards with accent-bordered cards") |
| Category | Which of the 25 audit dimensions it addresses |
| Apps affected | Backend / Admin-app / Student-app (one or more) |
| Problem | What's wrong today + evidence citation |
| Recommendation | Concrete, buildable fix (respecting §4 constraints) |
| Impact | 1–5 (user/business value) |
| Effort | 1–5 (1 = hours, 5 = multi-week) |
| Reach | Rough % of screens/users touched |
| **RICE / ICE score** | `(Reach × Impact) / Effort` (or ICE if reach is unknown) — used to rank |
| Priority | **P0** (critical/broken), **P1** (high), **P2** (medium), **P3** (nice-to-have) |
| Type | Quick win / Standard / Strategic bet |
| Depends on | Any prerequisite ENH IDs (e.g. tokens before components) |

Rank the whole backlog by RICE descending. Include a **summary table at the top**: count by priority, count by app, count of quick wins.

### 8.2 Split Views
- `QUICK_WINS.md` — everything that is **Effort ≤ 2 and Impact ≥ 3** (ship-this-week list).
- `STRATEGIC_BETS.md` — the **Effort ≥ 4** investments (redesigns, new systems, motion language, i18n rollout) with a short rationale + rough sequencing.

### 8.3 Enhancement Idea Sources (be exhaustive)
Generate suggestions across **all** of these lenses, not just the obvious visual ones:
- Visual polish & brand · Layout/whitespace/grid · Hierarchy & dashboards · Navigation & search
- Table/data-density UX · Form UX & validation · Empty/loading/error states · Onboarding & first-run
- Micro-interactions & motion · Dark-mode parity · **Accessibility (WCAG 2.2 AA→AAA where cheap)**
- **Internationalization & RTL** · Microcopy & tone · Iconography · Notifications & feedback
- **Performance perception** (skeletons, lazy loads, asset weight) · Trust & security cues
- **Cross-app consistency / shared design language** · Component consolidation / de-duplication
- **Personalization** (greetings, role-aware dashboards, saved views/filters) · Keyboard power-user features
- Data-viz & charts quality · Print/PDF styles (report cards, fee receipts) · Offline/low-bandwidth resilience (mobile)

For each lens, if there is genuinely nothing to improve, say so explicitly — don't pad.

---

## 9. Deliverable: Standalone Design-System Folder

> **Reminder:** Do not assume. If a component pattern conflicts with AdminLTE v4 / Bootstrap 5.3 conventions, ask before proceeding.

Create the design system at:

```
/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/9-Working_with_Team/2-Tarun/Prompt_Output/03_DESIGN_SYSTEM/prime-design-system/
```

A **complete, self-contained HTML/CSS/JS component library** that sits **on top of AdminLTE v4.0.0-beta3** and that the team + other AI models can reference and implement from.

### 9.1 Required Folder Structure

```
prime-design-system/
├── index.html                          # Design-system homepage / overview
├── README.md                           # How to use this folder
├── AI_IMPLEMENTATION_GUIDE.md          # How other AI models should implement these components
├── DESIGN_TOKENS.md                    # Colors, typography, spacing, shadows, radius
├── ACCESSIBILITY_STANDARDS.md          # Contrast, focus, touch targets, RTL notes
├── WEB_COMPONENTS/
│   ├── css/
│   │   ├── tokens.css                  # CSS custom properties (colors, spacing, radius, shadows)
│   │   ├── base.css                    # Reset, typography, global utilities
│   │   ├── components/
│   │   │   ├── buttons.css   forms.css   tables.css   cards.css
│   │   │   ├── navigation.css sidebar.css tabs.css     modals.css
│   │   │   ├── dropdowns.css  badges.css  alerts.css   pagination.css
│   │   │   ├── empty-state.css loaders.css toasts.css
│   │   └── dark-mode.css               # Dark mode overrides
│   ├── js/
│   │   ├── main.js  utils.js
│   │   └── components/ (dropdown, modal, tabs, sidebar, toast, table-actions, status-switch).js
│   └── html/
│       ├── 01-buttons.html … 14-toasts.html          # component galleries
│       ├── 15-dashboard-admin.html
│       ├── 16-dashboard-student.html
│       ├── 17-dashboard-parent.html
│       ├── 18-list-page.html   19-create-edit-form.html
│       ├── 20-detail-view.html 21-login-page.html
├── MOBILE_COMPONENTS/
│   ├── README.md  MOBILE_TOKENS.md
│   └── screens/ (01-mobile-buttons … 09-mobile-empty-error-states).md
└── CHANGELOG.md
```

### 9.2 Component Coverage (Web)

Every web HTML file must include:
- **AdminLTE v4.0.0-beta3 base CSS** as foundation. Prefer relative load from `/Users/bkwork/Herd/prime_ai/public/backend/css/adminlte.css`; if you copy it into `04_ASSETS/` for portability, do so and link relatively, or use the matching CDN version. **Do not link into the live app via absolute machine path in a way that breaks for teammates** — prefer a local copy inside the design-system folder + a documented CDN fallback.
- **Light + dark mode toggle** preview.
- **Responsive preview** (desktop + mobile width).
- **Copy-paste code snippet block.**
- **Usage notes** — when/where to use it + which AdminLTE/Bootstrap classes are styled.

**Required components:** Buttons · Forms (text/password-toggle/number/email/textarea/select/multiselect/checkbox/radio/switch/date/date-range/file-upload/search/validation-states) · Tables (default/hover/striped/bordered/search+filter/status-switch/actions/bulk-toolbar/sortable/sticky/responsive-card-stack) · Cards (stat+trend/list/info/accent/widget) · Navigation (navbar/breadcrumb/sidebar/drawer) · Tabs (horizontal/vertical/with search/with create) · Modals (confirm/form/info/delete) · Dropdowns (action/filter/profile/notification) · Badges & Alerts · Pagination · Empty States (no-data/no-results/error/permission-denied) · Loaders (spinner/skeleton/button-loading) · Toasts.

### 9.3 Screen Templates (Web)
Admin Dashboard · Student Dashboard · Parent Dashboard · List Page · Create/Edit Form · Detail View · Login Page — each fully composed, light+dark, responsive.

### 9.4 Mobile Reference (Markdown + Pseudo-Code)
For React Native, create `.md` files (no `.tsx` yet) defining: screen structure + safe-area, header patterns, card/list patterns, form patterns, dashboards (student/parent/teacher), empty/error/loading states, and theme usage referencing the real `constants/theme.ts` in `ADMIN_APP` / `STUDENT_APP`. Each: visual description · recommended composition using existing `components/ui/*` · color-token usage · spacing/type rules · a11y notes.

---

## 10. Required Documentation Files (inside `prime-design-system/`)

- **`README.md`** — overview, how to open HTML files, folder structure, how to contribute.
- **`AI_IMPLEMENTATION_GUIDE.md`** — for AI coding agents: map tokens→project files; implement in Blade using existing `x-backend.*`; implement in RN using existing primitives; where to add custom CSS in Laravel; **AdminLTE v4 compatibility rules** (which classes to reuse, override safely, RTL); naming conventions; common mistakes; one before/after example.
- **`DESIGN_TOKENS.md`** — colors (hex+usage), type scale, spacing scale, radius scale, shadows, breakpoints, z-index scale, animation durations/easings.
- **`ACCESSIBILITY_STANDARDS.md`** — min contrast ratios, focus rules, mobile touch targets, keyboard nav, screen-reader notes, RTL, reduced-motion.
- **`CHANGELOG.md`** — start at v1.0.0.

---

## 11. Implementation Notes

### 11.1 CSS Strategy (AdminLTE v4.0.0-beta3 first)
AdminLTE gives the layout shell (sidebar/navbar/content/cards/tabs/tables); Bootstrap 5.3 gives base components; **you add a modern cosmetic layer.**
- **Base layer:** link `adminlte.css` (v4-beta3, includes BS 5.3), Bootstrap Icons, and `adminlte-custom.css` before your custom CSS in every preview file. Load BS 5.3 JS + Popper 2.11 + jQuery 3.6 if needed to match live backend.
- **Override file (for the real app, documented — not applied in this task):** `public/backend/css/prime-modern-ui.css`. Do **not** modify `adminlte.css` / `adminlte-custom.css` directly.
- **Reuse AdminLTE structure:** `.app-wrapper`, `.app-header`, `.app-sidebar`, `.content-wrapper`, `.card`, `.card-header`, `.table`, `.btn`, `.form-control`, `.nav-tabs`, `.modal`, `.toast`, etc.
- **Modernize via overrides:** CSS custom properties mapped to existing tokens so dark mode works automatically; higher-specificity/utility overrides.
- **Modular & commented**, organized by component for incremental adoption.
- **Test RTL:** AdminLTE v4 ships `adminlte.rtl.css`; don't break it.
- **No Bootstrap 4 assets** (`public/backend/plugins/bootstrap/` is legacy BS 4.6.1). Target BS 5.3 classes.
- **Don't fight the framework:** if AdminLTE provides a pattern (treeview, card tools, tab panes), style it — don't rebuild.

### 11.2 JavaScript Strategy
- Interactive behavior documented for `public/backend/js/prime-modern-ui.js` (real app; not applied here).
- Vanilla JS or jQuery (project already uses jQuery). Self-initializing via `data-*` attributes.

### 11.3 Mobile Strategy
- No `.tsx` files yet — document behavior/structure in markdown.
- Reference real files: `constants/theme.ts`, `components/ui/button.tsx`, `components/ui/input.tsx` in `ADMIN_APP` / `STUDENT_APP`.
- Show how new design composes existing primitives.

---

## 12. Quality Checklist

Before finishing, verify:
- [ ] **READ-ONLY honored:** no file was created/edited/deleted outside `OUTPUT`; no code, DDL, database, config, dependency, or build state was changed anywhere; every finding is a documented recommendation only.
- [ ] All output lives under `OUTPUT` (§0.2); nothing was written into the app repos.
- [ ] `EVIDENCE_LOG.md` lists every file/screenshot inspected with observations.
- [ ] `SCORECARD.md` has all 25 dimensions scored with justification + evidence, and a weighted overall score.
- [ ] Master audit report `01_AUDIT/PRIME_UI_UX_AUDIT_REPORT.md` created.
- [ ] Cross-app consistency, token-drift, component-inventory, accessibility, and competitive-benchmark reports created.
- [ ] `ENHANCEMENT_BACKLOG.md` scored (Impact/Effort/Reach/RICE) and ranked; QUICK_WINS + STRATEGIC_BETS split.
- [ ] `ROADMAP_TO_10.md` phased plan created.
- [ ] Design-system folder built; all HTML previews open in a browser; light/dark toggles work.
- [ ] All required components + screen templates present; CSS/JS organized into separate files.
- [ ] No new frameworks/dependencies introduced; compatible with AdminLTE v4-beta3 + BS 5.3.
- [ ] Existing color palette preserved (values verified against the CSS file).
- [ ] Mobile references use existing RN primitives.
- [ ] Accessibility standards documented and applied.
- [ ] `00_RUN_SUMMARY.md` written last, indexing every artifact with its path.

---

## 13. Output Summary (write `00_RUN_SUMMARY.md` last)

At the end, provide:
1. The overall audit score + top-line findings.
2. Path to the master audit report.
3. Counts from the enhancement backlog (P0/P1/P2/P3, quick wins).
4. Summary of what was created in the design-system folder + its exact path.
5. How to preview the HTML files.
6. The prioritized next steps the team should take to apply this to the real apps.
7. Any open questions / assumptions you had to flag.

---

**Start with Phase 1 (§2): gather evidence → score the 25 dimensions → write the audit + consistency + a11y + benchmark reports. Then build the enhancement backlog (§8). Only then build the design-system folder (§9). Everything is written under `OUTPUT`. Do not assume — ask when unclear.**
