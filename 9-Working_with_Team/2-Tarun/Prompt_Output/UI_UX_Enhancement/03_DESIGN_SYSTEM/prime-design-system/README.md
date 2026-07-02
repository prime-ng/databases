# Prime Design System

A self-contained UI/UX reference that sits **on top of AdminLTE v4.0.0-beta3 (Bootstrap 5.3)** for the Prime School Management ecosystem — **prime_ai** (Laravel web), **mobile_school** (admin app), and **mobile_student** (student/parent/teacher app).

> **This is a REFERENCE / specification, not applied code.** Nothing here is wired into the live apps. Developers and AI agents copy patterns from here into the real projects. See `AI_IMPLEMENTATION_GUIDE.md` for exactly how.

---

## What's inside

```
prime-design-system/
├── index.html                    ← open this first (design-system homepage)
├── README.md                     ← you are here
├── AI_IMPLEMENTATION_GUIDE.md    ← how AI agents/devs implement these in Blade + React Native
├── DESIGN_TOKENS.md              ← colors, type, spacing, radius, shadow, motion, z-index
├── ACCESSIBILITY_STANDARDS.md    ← WCAG 2.2 AA rules every component follows
├── CHANGELOG.md
├── WEB_COMPONENTS/
│   ├── css/tokens.css            ← the token contract (mirrors adminlte-custom.css + theme.ts)
│   ├── css/base.css              ← reset, typography, utilities
│   ├── css/components/*.css      ← one file per component family
│   ├── css/dark-mode.css         ← dark overrides
│   ├── js/*.js                   ← vanilla/jQuery self-initializing behaviors
│   └── html/01..21-*.html        ← live, browser-openable component galleries + screen templates
└── MOBILE_COMPONENTS/
    ├── README.md, MOBILE_TOKENS.md
    └── screens/01..09-*.md       ← React Native patterns (markdown + pseudo-code, no .tsx)
```

---

## How to preview

1. Open `index.html` in any modern browser (Chrome, Safari, Firefox). No build step, no server required.
2. From the homepage, jump to any component gallery (`WEB_COMPONENTS/html/01-buttons.html` … `21-login-page.html`).
3. Each page has a **light/dark toggle** (top-right) and a **responsive width toggle** (desktop ↔ mobile) so you can preview both.
4. Each component shows a **live example**, a **copy-paste code snippet**, and **usage notes** (which AdminLTE/Bootstrap classes it styles).

> The HTML pages load AdminLTE v4 + Bootstrap Icons. They try a **local copy** of `adminlte.css` first and fall back to the matching **CDN** if not present, so the folder is portable across teammates' machines.

---

## The design language in one paragraph

Preserve the existing indigo brand (`#6673fc`) and the full semantic palette. Move from "saturated admin panel" to "calm, premium product": **white/very-light surfaces with colored accents** (left-border, icon, subtle tint) instead of full-color fills; an **8px spacing rhythm**; **soft, consistent radii and light shadows**; **clear hierarchy** (greeting → priority actions → key stats → secondary widgets); **status = color + icon + label**; and **WCAG 2.2 AA** as a baseline, not an afterthought. On mobile, compose the existing `components/ui/*` primitives; don't introduce new libraries.

---

## Hard rules (do not violate)

- **No new frameworks.** Web = AdminLTE v4 + Bootstrap 5.3 + jQuery only. Mobile = existing Expo/RN/TS primitives only.
- **Preserve the palette.** Tints/shades/opacity are fine; the core colors stay recognizable.
- **Override, don't replace.** Style AdminLTE/Bootstrap classes; never rebuild the shell or edit `adminlte.css`.
- **Everything is additive.** In the real app, new CSS lives in `public/backend/css/prime-modern-ui.css`; new JS in `public/backend/js/prime-modern-ui.js`.

---

## How to contribute

1. Add or edit a component CSS file under `WEB_COMPONENTS/css/components/` and demo it in the matching `html/*.html`.
2. Keep it token-driven — reference `tokens.css` custom properties, never hardcode hex.
3. Run the component acceptance checklist in `ACCESSIBILITY_STANDARDS.md` §11.
4. Bump `CHANGELOG.md`.

See the audit that motivated this system in `../../01_AUDIT/` and the prioritized backlog in `../../02_ENHANCEMENTS/`.
