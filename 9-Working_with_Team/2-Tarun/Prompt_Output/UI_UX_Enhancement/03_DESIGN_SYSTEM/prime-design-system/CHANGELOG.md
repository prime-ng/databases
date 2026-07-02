# Changelog — Prime Design System

All notable changes to this design system are documented here. Format loosely follows [Keep a Changelog](https://keepachangelog.com/); versions are design-system versions, independent of the apps.

## [1.0.0] — 2026-07-01

### Added — initial design system
- **Foundation**
  - `DESIGN_TOKENS.md` — canonical color / type / spacing / radius / shadow / motion / z-index tokens, verified against `adminlte-custom.css` and both mobile `theme.ts` files.
  - `WEB_COMPONENTS/css/tokens.css` — machine-readable token layer with a Bootstrap 5.3 / AdminLTE v4 bridge and dark-mode block.
  - `ACCESSIBILITY_STANDARDS.md` — WCAG 2.2 AA rules, verified palette contrast table, component acceptance checklist.
  - `AI_IMPLEMENTATION_GUIDE.md` — how AI agents/devs map these patterns into Laravel Blade and React Native.
- **Web components** (`WEB_COMPONENTS/`) — token, base, and per-component CSS; self-initializing JS; browser-openable galleries `01-buttons.html` … `14-toasts.html`.
- **Web screen templates** — `15-dashboard-admin`, `16-dashboard-student`, `17-dashboard-parent`, `18-list-page`, `19-create-edit-form`, `20-detail-view`, `21-login-page`.
- **Mobile reference** (`MOBILE_COMPONENTS/`) — `MOBILE_TOKENS.md` + screen pattern docs `01`–`09` composing the existing `components/ui/*` primitives.
- **Homepage** `index.html` linking every gallery and doc.

### Motivated by
- The Phase-1 audit in `../../01_AUDIT/` (25-dimension scorecard, cross-app consistency, token drift, accessibility, competitive benchmark).
- The prioritized backlog in `../../02_ENHANCEMENTS/`.

### Design decisions locked in v1
- Preserve the indigo brand (`#6673fc`) and full semantic palette; **accent, don't fill**.
- Canonical secondary surface is `#f8fafc` (aligns web + mobile drift D1).
- Canonical spacing = 4/8 grid, 8px default step.
- Status is always **color + icon + label**, never color alone.
- WCAG 2.2 AA is the baseline for every component.

### Known follow-ups (tracked in the enhancement backlog)
- Codify a web type scale + radius scale to match the mobile `theme.ts` (currently ad-hoc in CSS).
- Add missing mobile tokens: `link`, `surface-hover`, `surface-border-light`, `light`.
