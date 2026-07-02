# Prime Design System — Design Tokens

> The single source of truth for colors, type, spacing, radius, shadow, motion, and z-index across **prime_ai** (web), **mobile_school** (admin app), and **mobile_student** (student/parent/teacher app).
> All values verified against the live theme files on 2026-07-01. Machine-readable equivalents: `WEB_COMPONENTS/css/tokens.css` (web) and each app's `constants/theme.ts` (mobile).

---

## 1. Color

### 1.1 Brand palette (identical on all three apps — do not diverge)

| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| primary | `#6673fc` | 102 115 252 | Primary buttons, links, active states, brand accents |
| primary-hover | `#545ed6` | 84 94 214 | Pressed/hover of primary (mobile `primaryDark`) |
| secondary | `#64748b` | 100 116 139 | Secondary actions, muted emphasis |
| success | `#3fcc7e` | 63 204 126 | Approved, paid, present |
| info | `#4abad2` | 74 186 210 | Information highlights |
| warning | `#facc15` | 250 204 21 | Pending, warnings |
| danger | `#e44f56` | 228 79 86 | Errors, deletions, absent, overdue |
| light | `#f4f6f9` | 244 246 249 | Muted chip/tag background |
| dark | `#222c3c` | 34 44 60 | High-emphasis dark elements |

### 1.2 Surfaces

| Token | Light | Dark |
|-------|-------|------|
| surface-bg (cards/panels) | `#ffffff` | `#1e1e2d` |
| surface-secondary (page bg, rows) | `#f8fafc` | `#252536` |
| surface-hover | `#f1f5f9` | `#2a2a3d` |
| surface-active / border | `#e2e8f0` | `#323248` |
| surface-border-light | `#f1f5f9` | `#2a2a3d` |

> ⚠️ **Drift note:** the mobile apps currently use `#f5f5f5` for `surfaceSecondary`. Canonical value is **`#f8fafc`** — see `01_AUDIT/DESIGN_TOKEN_DRIFT.md` (D1). Align mobile to `#f8fafc`.

### 1.3 Text

| Token | Light | Dark |
|-------|-------|------|
| text-primary | `#1e293b` | `#e2e8f0` |
| text-secondary | `#475569` | `#94a3b8` |
| text-muted | `#94a3b8` | `#64748b` |
| text-link | `#3b82f6` | `#60a5fa` |

> Mobile apps are missing `text-link`; add it (drift D3).

### 1.4 Accent-usage rule (from the audit)
Status and stat surfaces use **color as accent, not fill**: white/`surface-secondary` background + colored left-border / icon / subtle `rgba(brand, 0.08–0.12)` tint. Never full-saturation card fills. Status is always **color + icon + text label**, never color alone (accessibility).

---

## 2. Typography

Canonical scale (adopted from mobile `theme.ts`; web should codify the same):

| Role | Size | Line-height | Weight |
|------|------|-------------|--------|
| h1 | 32px / 2rem | 40px | 700 |
| h2 | 24px / 1.5rem | 32px | 700 |
| h3 | 20px / 1.25rem | 28px | 600 |
| h4 | 18px / 1.125rem | 24px | 600 |
| body | 16px / 1rem | 24px | 400 |
| body-small | 14px / 0.875rem | 20px | 400 |
| label | 14px | 20px | 600 |
| caption | 12px / 0.75rem | 16px | 400 |

**Font family:** system stack — `system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif`. No web-font dependency (fast, consistent). Min body text 14px; never below 12px.

---

## 3. Spacing

Canonical **4/8 grid** — 8px is the default step; 4px reserved for tight controls (chips, dense tables).

| Token | px |
|-------|----|
| space-1 | 4 |
| space-2 | 8 |
| space-3 | 12 |
| space-4 | 16 |
| space-6 | 24 |
| space-8 | 32 |
| space-12 | 48 |

Mobile `Spacing` maps: `xs4 sm8 md16 lg24 xl32 xxl48`.

---

## 4. Border Radius

| Token | px | Usage |
|-------|----|-------|
| sm | 4 | Inputs, small chips |
| md | 8 | Buttons, inputs (default) |
| lg | 12 | Cards |
| xl | 16 | Modals, large cards |
| 2xl | 24 | Feature panels |
| full | 999 | Pills, avatars |

---

## 5. Shadows (elevation)

| Token | Web | Mobile (iOS / elevation) |
|-------|-----|--------------------------|
| sm | `0 1px 3px rgba(0,0,0,.04)` | opacity .05, radius 2 / elev 2 |
| md | `0 10px 25px -5px rgba(0,0,0,.10)` | opacity .08, radius 8 / elev 4 |
| lg | `0 25px 50px -12px rgba(0,0,0,.15)` | opacity .12, radius 16 / elev 8 |

Dark mode increases opacity (.2 / .4 / .5). Prefer **sm** for cards; reserve **lg** for modals/overlays. Avoid the heavy legacy shadows flagged in the audit.

---

## 6. Motion

| Token | Value |
|-------|-------|
| ease | `cubic-bezier(0.4, 0, 0.2, 1)` |
| dur-fast | 120ms (hover, press) |
| dur-base | 200ms (dropdowns, toggles) |
| dur-slow | 320ms (modals, drawers) |

Always gate non-essential motion behind `prefers-reduced-motion: reduce` (web) / `AccessibilityInfo.isReduceMotionEnabled` (mobile).

---

## 7. Breakpoints (web, Bootstrap 5.3 aligned)

| Name | Min-width |
|------|-----------|
| sm | 576px |
| md | 768px |
| lg | 992px |
| xl | 1200px |
| xxl | 1400px |

Tables collapse to card-stack below **md**. Sidebar auto-collapses below **lg**.

---

## 8. Z-index scale

| Layer | Value |
|-------|-------|
| dropdown | 1000 |
| sticky | 1020 |
| fixed | 1030 |
| modal-backdrop | 1040 |
| modal | 1050 |
| toast | 1080 |

---

## 9. Focus ring (accessibility)

`0 0 0 3px rgba(102,115,252,0.35)` — visible on **all** interactive elements. Never `outline: none` without a replacement. See `ACCESSIBILITY_STANDARDS.md`.
