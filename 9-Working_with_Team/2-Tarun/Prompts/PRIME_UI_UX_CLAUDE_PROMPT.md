# Prime School Management — UI/UX Modernization Prompt for Claude

> **Standalone prompt:** This prompt is designed to run on any developer's machine. Replace `{PROJECT_ROOT}` with the absolute path to the folder containing the three applications: `prime_ai`, `primeadmin`, and `primeapp`.
>
> **Important:** Do not assume anything. If you still have queries or something is unclear, ask before proceeding forward.

---
PROJECT_ROOT = /Users/bkwork/Herd/

## 0. Project Setup (Run This First)

Before starting, identify the root folder that contains these three projects:

```
{PROJECT_ROOT}/
├── prime_ai/        # Laravel 12 backend + student/parent portals
├── primeadmin/      # React Native admin app (Expo)
└── primeapp/        # React Native student/parent/teacher app (Expo)
```

Replace `{PROJECT_ROOT}` in all instructions below with your actual path. Example: `/home/user/work/primeworkspace`.

If your teammates use the same repo layout but different base paths, they only need to change `{PROJECT_ROOT}` once.

---

## Phase 1: Audit & Rate the Current UI/UX (Do This First)

> **Reminder:** Do not assume anything. If a path is missing, a screenshot folder is empty, or a module structure looks different than described, ask before proceeding.

Before you design anything, you must **audit the current state** of the Prime applications and give an honest, senior-designer assessment.

### Step 1 — Gather Evidence
Scan the following locations under `{PROJECT_ROOT}` to understand what the UI currently looks like:

- **Screenshots and design assets:** Search for screenshot folders such as `{PROJECT_ROOT}/Prime_context/Screenshots/`, `{PROJECT_ROOT}/prime_ai/tests/Browser/screenshots/`, or any other `screenshots/`, `designs/`, or `mockups/` directories.
- **Backend modules:**
  - `{PROJECT_ROOT}/prime_ai/Modules/Payment/resources/views`
  - `{PROJECT_ROOT}/prime_ai/Modules/LmsQuests/resources/views`
  - `{PROJECT_ROOT}/prime_ai/Modules/TimetableFoundation/resources/views`
  - `{PROJECT_ROOT}/prime_ai/Modules/StudentPortal`
  - `{PROJECT_ROOT}/prime_ai/Modules/ParentPortal`
- **React Native apps:**
  - `{PROJECT_ROOT}/primeadmin/app/`
  - `{PROJECT_ROOT}/primeapp/app/`
  - `{PROJECT_ROOT}/primeadmin/components/ui/`
  - `{PROJECT_ROOT}/primeapp/components/ui/`
- **Current color/theme files:**
  - `{PROJECT_ROOT}/prime_ai/public/backend/css/adminlte-custom.css`
  - `{PROJECT_ROOT}/primeadmin/constants/theme.ts`
  - `{PROJECT_ROOT}/primeapp/constants/theme.ts`

### Step 2 — Rate the Current UI/UX
Give the current UI/UX a score **out of 10** as a senior designer with 10+ years of experience would. Be critical but fair.

Your rating must consider:
- Visual design and modernness
- Layout and information hierarchy
- Component consistency
- Color system usage
- Typography
- Mobile experience
- Accessibility
- Empty/error states
- International readiness
- Brand personality

### Step 3 — Explain the Score
Write a short justification covering:
- What is working well
- The biggest visual/UX problems
- Why it does or does not look international-grade
- What makes it feel like a generic school ERP vs. a premium SaaS product

### Step 4 — Generate a "10/10 Roadmap"
Create a practical report named `PRIME_UI_UX_AUDIT_REPORT.md` inside `{PROJECT_ROOT}/` that includes:
- The score and full justification
- A category-by-category breakdown
- The critical issues found
- A phased roadmap to reach 10/10
- Key design principles
- Immediate next steps

**Only after completing this audit report should you proceed to the design-system work below.**

---

## 2. Role & Mindset

You are a **senior full-stack developer and product designer with 10+ years of experience** building clean, intuitive, and modern UI/UX for enterprise and education software. Your specialty is designing interfaces that:

- Feel **premium, modern, and internationally competitive**.
- Are **effortless for non-technical users** (school staff, teachers, parents, and students).
- Follow **accessibility, readability, and usability best practices** (WCAG AA alignment, clear hierarchy, generous whitespace, consistent affordances).
- Are **mobile-first responsive** and work smoothly across devices and cultures.

You are not just re-skinning — you are **rethinking the experience** while preserving the existing brand identity.

---

## 3. Project Context

This is a **multi-platform school management ecosystem** consisting of:

| App | Path | Stack | Audience |
|-----|------|-------|----------|
| **Prime AI (Backend)** | `{PROJECT_ROOT}/prime_ai` | Laravel 12, modular (`nwidart/laravel-modules`), **AdminLTE v4.0.0-beta3 (Bootstrap 5.3 based)** + jQuery 3.6, Blade components | Admins, accountants, teachers, back-office staff |
| **Prime Admin (Mobile)** | `{PROJECT_ROOT}/primeadmin` | Expo SDK 54, React Native 0.81, TypeScript, file-based routing (`expo-router`) | School admin/staff on mobile |
| **Prime App (Mobile)** | `{PROJECT_ROOT}/primeapp` | Expo SDK 54, React Native 0.81, TypeScript, file-based routing (`expo-router`) | Students, parents, teachers |

### 3.1 Backend UI Architecture

- Layout: `<x-backend.layouts.app>` → `resources/views/backend/v1/layouts/app.blade.php`
- Head/Sidebar/Navbar/Footer: `<x-backend.partials.* />`
- Reusable components: `resources/views/components/backend/*`
  - `x-backend.components.breadcrum`
  - `x-backend.tab.search-bar`, `x-backend.tab.nav-tab`
  - `x-backend.table.action`, `x-backend.table.status-switch`
  - `x-backend.form.input-text`, `x-backend.form.input-textarea`, etc.
- Student portal: `<x-frontend.layout.app>` (Smart University theme)
- Parent portal: `@extends('parentportal::layouts.app')`

### 3.2 React Native UI Architecture

- Design tokens: `constants/theme.ts` in both mobile apps
- UI primitives: `components/ui/button.tsx`, `components/ui/input.tsx`, `components/ui/card.tsx`, `components/ui/badge.tsx`, `components/ui/chip.tsx`, etc.
- Navigation: custom `components/navigation/app-header.tsx`, `drawer-content.tsx`, `screen-header.tsx`
- Layout helpers: `components/layout/screen-wrapper.tsx`, `components/layout/screen-header.tsx`

---

## 4. Hard Constraints (Do Not Violate)

1. **Preserve the current color palette.** The existing brand colors must remain the foundation.
2. **Build on top of AdminLTE v4.0.0-beta3 (Bootstrap 5.3) + jQuery 3.6 on the backend.** The design system must be a layer **on top of AdminLTE 4**, not a replacement. Do **not** introduce new frameworks (no Livewire, no Vue, no React-in-Blade, no new build tools). Do not use the old Bootstrap 4 plugin files under `public/backend/plugins/bootstrap/` for the backend theme.
3. **Use custom CSS overrides** in a separate, well-organized CSS layer to modernize the look. These overrides must work **with** AdminLTE v4.0.0-beta3 classes and components, not against them.
4. **Keep the existing React Native stack** (Expo, React Native, TypeScript, custom primitives). No new UI libraries.
5. **No changes to existing app code yet.** This phase is **design-system reference only**.

---

## 5. Color Scheme to Preserve

Source: `{PROJECT_ROOT}/prime_ai/public/backend/css/adminlte-custom.css`

| Token | Value | Usage |
|-------|-------|-------|
| `--primary` | `#6673fc` | Primary buttons, links, active states, brand accents |
| `--secondary` | `#64748b` | Secondary actions, muted emphasis |
| `--success` | `#3fcc7e` | Success states, approved, paid, present |
| `--info` | `#4abad2` | Information highlights |
| `--warning` | `#facc15` | Warnings, pending |
| `--danger` | `#e44f56` | Errors, deletions, absent, overdue |
| `--light` | `#f4f6f9` | Light backgrounds |
| `--dark` | `#222c3c` | Dark elements, high emphasis text |
| `--surface-bg` | `#ffffff` | Cards, panels, content surfaces |
| `--surface-secondary` | `#f8fafc` | Page backgrounds, alternating rows |
| `--surface-hover` | `#f1f5f9` | Hover states |
| `--surface-active` / `--surface-border` | `#e2e8f0` | Borders, dividers |
| `--text-primary` | `#1e293b` | Primary text |
| `--text-secondary` | `#475569` | Secondary text |
| `--text-muted` | `#94a3b8` | Placeholders, disabled, hints |
| `--text-link` | `#3b82f6` | Inline links |

**Dark mode:** surfaces flip to `#1e1e2d`, `#252536`, `#2a2a3d`; text flips to `#e2e8f0`.

You may use **tints, shades, and opacity variations** of these colors, but the core palette above must remain recognizable.

---

## 6. Modules to Study for Reference

Scan these directories to understand current patterns before designing:

### Backend Modules
- `{PROJECT_ROOT}/prime_ai/Modules/Payment/resources/views`
- `{PROJECT_ROOT}/prime_ai/Modules/LmsQuests/resources/views`
- `{PROJECT_ROOT}/prime_ai/Modules/TimetableFoundation/resources/views`

### Portals
- `{PROJECT_ROOT}/prime_ai/Modules/StudentPortal`
- `{PROJECT_ROOT}/prime_ai/Modules/ParentPortal`

### Mobile Apps
- `{PROJECT_ROOT}/primeadmin/app`
- `{PROJECT_ROOT}/primeapp/app`
- `{PROJECT_ROOT}/primeadmin/components/ui`
- `{PROJECT_ROOT}/primeapp/components/ui`

---

## 7. Design Direction

Create a UI/UX that **stands out from common school management systems**. Avoid cluttered admin panels. Aim for:

### 7.1 Visual Language

- **Clean, spacious layouts** with consistent 8px grid spacing.
- **Soft, modern cards** with subtle shadows, rounded corners, and clear hierarchy.
- **Friendly but professional** typography with readable sizes.
- **Clear status language** using color + icon + label (not just colored dots).
- **Consistent iconography** (Font Awesome / Bootstrap Icons for web, MaterialIcons for mobile).
- **Light and dark mode** versions for every component.

### 7.2 UX Principles

- **Reduce cognitive load:** group related actions, use progressive disclosure, hide advanced options.
- **Clear primary actions:** one obvious next step per screen.
- **Forgiving interfaces:** confirm destructive actions, inline validation, helpful empty states.
- **Accessibility:** focus states, sufficient contrast, readable touch targets (min 44px on mobile), semantic HTML.
- **International readiness:** RTL-aware layouts, flexible text lengths, number/date formatting placeholders.

### 7.3 Differentiators

- Dashboards should feel **alive and personal** (greetings, summaries, quick actions).
- Data tables should feel **scannable and actionable** (sticky headers, hover rows, bulk actions).
- Forms should feel **short and guided** (step indicators, inline help, smart defaults).
- Mobile apps should feel **app-native**, not like wrapped web pages.

---

## 8. Audit-Driven Design Priorities (Must Address)

Based on the audit report you created in Phase 1, the design system and templates must fix these specific problems:

1. **Reduce saturated background colors.** Stat cards should be white or very light surfaces with colored **accents** (left border, top border, icon, or subtle gradient), not full red/green/orange/blue backgrounds.
2. **Unify component styles.** All stat cards, tables, buttons, badges, and tabs must follow one design language across backend, student portal, and parent portal.
3. **Improve information hierarchy.** Dashboards should lead with greeting + key actions, then 3–4 priority stats, then secondary widgets. Avoid vertical stacks of equal-weight cards.
4. **Modernize legacy elements.** Replace heavy shadows, inconsistent radius, and dated copyright footers with clean, current patterns.
5. **Design for mobile-first responsiveness.** Every table must have a responsive card-stacked variant. Touch targets must be ≥ 44px.
6. **Ensure accessibility.** All text must meet WCAG AA contrast. Focus states must be visible. Error pages must be user-friendly, not stack traces.
7. **Prepare for international markets.** Include RTL-aware layouts, localization-ready currency/date placeholders, and culturally neutral copy.
8. **Standardize iconography.** Use one icon family per platform (Font Awesome / Bootstrap Icons for web, MaterialIcons for mobile).

---

## 9. Deliverable: Standalone Design-System Folder

> **Reminder:** Do not assume anything. If a required component pattern is unclear or conflicts with AdminLTE v4/Bootstrap 5 conventions, ask before proceeding.

Create a new folder at:

```
{PROJECT_ROOT}/prime-design-system/
```

Inside this folder, build a **complete, self-contained HTML/CSS/JS component library** that sits **on top of AdminLTE v4.0.0-beta3** and that the team and other AI models can reference and implement from.

### 9.1 Required Folder Structure

```
prime-design-system/
├── index.html                          # Design-system homepage / overview
├── README.md                           # How to use this folder
├── AI_IMPLEMENTATION_GUIDE.md          # How other AI models should implement these components
├── DESIGN_TOKENS.md                    # Colors, typography, spacing, shadows, border-radius
├── ACCESSIBILITY_STANDARDS.md          # Contrast, focus, touch targets, RTL notes
├── WEB_COMPONENTS/
│   ├── css/
│   │   ├── tokens.css                  # CSS custom properties (all colors, spacing, radius, shadows)
│   │   ├── base.css                    # Reset, typography, global utilities
│   │   ├── components/
│   │   │   ├── buttons.css
│   │   │   ├── forms.css
│   │   │   ├── tables.css
│   │   │   ├── cards.css
│   │   │   ├── navigation.css
│   │   │   ├── sidebar.css
│   │   │   ├── tabs.css
│   │   │   ├── modals.css
│   │   │   ├── dropdowns.css
│   │   │   ├── badges.css
│   │   │   ├── alerts.css
│   │   │   ├── pagination.css
│   │   │   ├── empty-state.css
│   │   │   ├── loaders.css
│   │   │   └── toasts.css
│   │   └── dark-mode.css               # Dark mode overrides
│   ├── js/
│   │   ├── main.js                     # Shared utilities
│   │   ├── components/
│   │   │   ├── dropdown.js
│   │   │   ├── modal.js
│   │   │   ├── tabs.js
│   │   │   ├── sidebar.js
│   │   │   ├── toast.js
│   │   │   ├── table-actions.js
│   │   │   └── status-switch.js
│   │   └── utils.js
│   └── html/
│       ├── 01-buttons.html
│       ├── 02-forms.html
│       ├── 03-tables.html
│       ├── 04-cards.html
│       ├── 05-navigation.html
│       ├── 06-sidebar.html
│       ├── 07-tabs.html
│       ├── 08-modals.html
│       ├── 09-dropdowns.html
│       ├── 10-badges-alerts.html
│       ├── 11-pagination.html
│       ├── 12-empty-state.html
│       ├── 13-loaders.html
│       ├── 14-toasts.html
│       ├── 15-dashboard-admin.html
│       ├── 16-dashboard-student.html
│       ├── 17-dashboard-parent.html
│       ├── 18-list-page.html
│       ├── 19-create-edit-form.html
│       ├── 20-detail-view.html
│       └── 21-login-page.html
├── MOBILE_COMPONENTS/
│   ├── README.md
│   ├── MOBILE_TOKENS.md
│   └── screens/
│       ├── 01-mobile-buttons.md
│       ├── 02-mobile-inputs.md
│       ├── 03-mobile-cards.md
│       ├── 04-mobile-list-screen.md
│       ├── 05-mobile-form-screen.md
│       ├── 06-mobile-dashboard-student.md
│       ├── 07-mobile-dashboard-parent.md
│       ├── 08-mobile-dashboard-teacher.md
│       └── 09-mobile-empty-error-states.md
└── CHANGELOG.md
```

### 9.2 Component Coverage (Web)

Every web HTML file must include:

- **AdminLTE v4.0.0-beta3 base CSS** linked as the foundation. Prefer loading from `{PROJECT_ROOT}/prime_ai/public/backend/css/adminlte.css` via relative path, or use the matching CDN version if the file is not available locally.
- **Light and dark mode toggle** preview.
- **Responsive behavior** preview (desktop + mobile width).
- **Code snippet block** so developers can copy.
- **Usage notes** explaining when and where to use the component, including which AdminLTE/Bootstrap classes are being styled.

#### Required Components

1. **Buttons**
   - Primary, secondary, success, danger, warning, info, ghost, outline variants
   - Sizes: small, default, large
   - With icons (left/right), loading state, disabled state, block width

2. **Forms**
   - Text input, password input with toggle, number, email, textarea
   - Select / dropdown (single and multi-select placeholders)
   - Checkbox, radio, switch/toggle
   - Date picker, date range picker
   - File upload with preview
   - Search input with clear button
   - Inline validation states (valid, invalid, hint text)

3. **Tables**
   - Default table, hover row, striped, bordered
   - Table with search bar and filter tags
   - Table with status switch column
   - Table with action buttons (view, edit, delete)
   - Bulk action toolbar
   - Sortable column headers
   - Sticky header
   - Responsive card-stacked table for mobile

4. **Cards**
   - Stat cards (with trend indicator)
   - List cards
   - Info cards
   - Highlight/accent cards
   - Dashboard widget cards

5. **Navigation**
   - Top navbar
   - Breadcrumb
   - Sidebar (collapsible, active state, submenu)
   - Drawer/mobile menu

6. **Tabs**
   - Horizontal tabs
   - Vertical tabs
   - Tab with search/filter bar
   - Tab with create button

7. **Modals / Dialogs**
   - Confirmation modal
   - Form modal
   - Info modal
   - Delete confirmation

8. **Dropdowns**
   - Action dropdown
   - Filter dropdown
   - User profile dropdown
   - Notification dropdown

9. **Badges & Alerts**
   - Status badges (active, inactive, pending, approved, rejected, paid, unpaid)
   - Alert banners (success, info, warning, error)
   - Inline validation messages

10. **Pagination**
    - Default pagination
    - Simple pagination
    - Load more button

11. **Empty States**
    - No data
    - No search results
    - Error state
    - Permission denied

12. **Loaders**
    - Spinner
    - Skeleton loader for cards, tables, lists
    - Button loading state

13. **Toasts / Notifications**
    - Success, info, warning, error toasts
    - Auto-dismiss with progress
    - Toast stack positioning

### 9.3 Screen Templates (Web)

Create full-page HTML templates for:

1. **Admin Dashboard** — stats, charts placeholders, quick actions, recent activity, notifications
2. **Student Dashboard** — greeting, timetable strip, homework, attendance, fee progress, quick links
3. **Parent Dashboard** — child switcher, child summary, fee status, notifications, calendar
4. **List Page** — search bar, filters, bulk actions, data table, pagination
5. **Create / Edit Form Page** — sectioned form with tabs/wizard, save/cancel actions
6. **Detail View Page** — summary header, info cards, action bar, timeline/activity
7. **Login Page** — clean centered card, school branding, form validation

### 9.4 Mobile Reference (Markdown + Pseudo-Code)

For React Native, create `.md` files that define:

- Screen structure and safe-area handling
- Header patterns
- Card and list patterns
- Form input patterns
- Dashboard patterns for student, parent, teacher
- Empty/error/loading states
- Theme usage examples using the existing `constants/theme.ts`

Each mobile reference should include:
- Visual description
- Recommended component composition (using existing `components/ui/*` primitives)
- Color token usage
- Spacing and typography rules
- Accessibility notes (touch targets, contrast, screen reader labels)

---

## 10. Required Documentation Files

Create the following `.md` files inside `{PROJECT_ROOT}/prime-design-system/` so other AI models and developers can implement consistently:

### 10.1 `README.md`
Overview of the design system, how to open the HTML files, folder structure explanation, and how to contribute.

### 10.2 `AI_IMPLEMENTATION_GUIDE.md`
A guide specifically for AI coding agents. Include:
- How to map design tokens to existing project files
- How to implement components in Laravel Blade using existing `x-backend.*` components
- How to implement components in React Native using existing primitives
- Where to add custom CSS in the Laravel project
- **AdminLTE v4.0.0-beta3 compatibility rules:** which AdminLTE classes to reuse, how to override without breaking the layout, and RTL considerations
- Naming conventions and file locations
- Common mistakes to avoid
- Before/after example for one component

### 10.3 `DESIGN_TOKENS.md`
Complete token reference:
- Color palette with hex values and usage
- Typography scale
- Spacing scale
- Border radius scale
- Shadows
- Breakpoints
- Z-index scale
- Animation durations/easings

### 10.4 `ACCESSIBILITY_STANDARDS.md`
- Minimum contrast ratios
- Focus indicator rules
- Touch target sizes (mobile)
- Keyboard navigation rules
- Screen reader considerations
- RTL layout considerations
- Reduced motion preferences

### 10.5 `CHANGELOG.md`
Start with version 1.0.0 documenting the initial design system creation.

---

## 11. Implementation Notes for Claude

### 11.1 CSS Strategy (AdminLTE v4.0.0-beta3 First)

The backend design system **must be built on top of AdminLTE v4.0.0-beta3**, which is based on **Bootstrap 5.3**. AdminLTE provides the layout shell (sidebar, navbar, content wrapper, cards, tabs, tables), Bootstrap 5 provides the base components, and your job is to add a modern cosmetic layer.

- **Base layer:** Link `adminlte.css` (v4.0.0-beta3, includes Bootstrap 5.3), Bootstrap Icons, and `adminlte-custom.css` in every HTML preview file before your custom CSS. If needed, also load Bootstrap 5.3 JS + Popper 2.11 + jQuery 3.6 to match the live backend.
- **Custom override file:** Create `public/backend/css/prime-modern-ui.css` inside the `prime_ai` project. Do **not** modify `adminlte.css` or `adminlte-custom.css` directly unless absolutely necessary.
- **Use AdminLTE's structure:** Reuse AdminLTE classes such as `.app-wrapper`, `.app-header`, `.app-sidebar`, `.content-wrapper`, `.card`, `.card-header`, `.table`, `.btn`, `.form-control`, `.nav-tabs`, `.modal`, `.toast`, etc.
- **Modernize via overrides:** Use CSS custom properties mapped to the existing tokens so dark mode works automatically. Override Bootstrap/AdminLTE classes selectively using higher specificity or utility classes.
- **Keep it modular and commented:** Organize overrides by component (buttons, cards, tables, forms, sidebar, etc.) so the team can apply them incrementally.
- **Test with RTL:** AdminLTE v4 ships with `adminlte.rtl.css`. Ensure your custom CSS does not break RTL layouts.
- **Do not rely on old Bootstrap 4 assets:** The folder `public/backend/plugins/bootstrap/` contains Bootstrap 4.6.1 for legacy plugins. The backend theme uses Bootstrap 5.3 via CDN/bundled in AdminLTE v4. Your design system must target Bootstrap 5.3 classes, not Bootstrap 4.
- **Do not fight the framework:** If AdminLTE already provides a pattern (e.g., sidebar treeview, card tools, tab panes), style it rather than rebuilding it from scratch.

### 11.2 JavaScript Strategy

- Put interactive behavior in `public/backend/js/prime-modern-ui.js` inside the `prime_ai` project.
- Use vanilla JS or jQuery (project already uses jQuery).
- Keep components self-initializing using `data-*` attributes.

### 11.3 Mobile Strategy

- Do not create actual `.tsx` files yet. Document the desired component behavior and structure in markdown.
- Reference existing files like `constants/theme.ts`, `components/ui/button.tsx`, `components/ui/input.tsx`.
- Show how the new design should compose existing primitives.

---

## 12. Quality Checklist

Before finishing, verify:

- [ ] Audit report is created at `{PROJECT_ROOT}/PRIME_UI_UX_AUDIT_REPORT.md`.
- [ ] All HTML preview files open correctly in a browser.
- [ ] Light and dark mode toggles work.
- [ ] All required components are present.
- [ ] All required screen templates are present.
- [ ] CSS is organized into separate files.
- [ ] JS is organized into separate files.
- [ ] Documentation is complete and actionable for both humans and AI.
- [ ] No new frameworks or dependencies were introduced.
- [ ] The design system is compatible with **AdminLTE v4.0.0-beta3** and Bootstrap 5.
- [ ] Existing color palette was preserved.
- [ ] Mobile references use existing React Native primitives.
- [ ] Accessibility standards are documented and applied.

---

## 13. Output Summary

At the end, provide:

1. A brief summary of the audit findings and the score you gave.
2. The path to the audit report (`{PROJECT_ROOT}/PRIME_UI_UX_AUDIT_REPORT.md`).
3. A brief summary of what was created in the design-system folder.
4. The exact path to the design-system folder.
5. Instructions on how to preview the HTML files.
6. A list of the next steps the team should take to apply this design to the actual apps.

---

**Start by auditing and rating the current UI/UX (Phase 1), then generate the audit report, and only then build the design system folder with the structure above.**
